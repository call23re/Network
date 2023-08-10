local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Parent.Parent.Promise)
local Signal = require(script.Parent.Parent.Parent.Signal)
local Symbol = require(script.Parent.Parent.Symbols.Event)
local None = require(script.Parent.Parent.Symbols.None)

local CONTEXT = if RunService:IsServer() then "Server" elseif RunService:IsClient() then "Client" else nil

local ERROR_FIRST_ARGUMENT = "First argument of %s must be a %s, got <%s>"
local ERROR_LENGTH = "First argument of %s must be a table with at least on element"
local ERROR_NOT_PLAYER = "All elements of the first argument of FireClients must be players, got <%s> at index %s"

type HeaderType = "Request" | "Response"
type hook = (header: {Remote: RemoteEvent, Type: HeaderType?}, config: any) -> typeof(Promise.new())

--[=[
	@prop Name string
	@readonly
	@within RemoteEvent
	Refers to the name given to the RemoteEvent.
]=]
--[=[
	@prop ClassName symbol
	@readonly
	@within RemoteEvent
	Refers to the ClassName Symbol of the RemoteEvent.
]=]
--[=[
	Fires listening functions when the server fires the RemoteEvent at this client.

	@function OnClientEvent
	@param ... any
	@client
	@within RemoteEvent

	@return Connection(...)
]=]
--[=[
	Fires listening functions when the client fires the RemoteEvent.

	@function OnServerEvent
	@param Player Player
	@param ... any
	@server
	@within RemoteEvent

	@return Connection(Player, ...)
	
]=]
--[=[
	A RemoteEvent wraps a Roblox RemoteEvent and provides ways to hook into it. It has feature parity with a regular RemoteEvent.

	@class RemoteEvent
]=]
local RemoteEvent = {}
RemoteEvent.__index = RemoteEvent

function RemoteEvent.new()
	local self = setmetatable({}, RemoteEvent)

	self.ClassName = Symbol
	self._Warn = false

	self._Inbound = {}
	self._Outbound = {}

	return self
end

--[=[
	This function is used to hook into the RemoteEvent listener. All inbound hooks are called in the order they are added.
	
	@param hook function -- The function to be called when the RemoteEvent receives a request.
	@param context "Shared" | "Server" | "Client" -- The context in which the hook should be called.
	@param config any -- An optional configuration value to be passed to the hook.
	@return RemoteEvent -- Returns self.

	:::tip
	This function can be chained.
	```lua
	RemoteEvent
		:inbound(Middleware.Logger, "Client")
		:inbound(Transformers.Decode, "Client")
	```
	:::
	:::caution
	This function should only be used when you are registering your remotes!
	:::
]=]
function RemoteEvent:inbound(hook: hook, context: "Shared" | "Server" | "Client", config: any)
	assert(typeof(hook) == "function", ERROR_FIRST_ARGUMENT:format("inbound", "function", typeof(hook)))
	assert(typeof(context) == "string", ERROR_FIRST_ARGUMENT:format("inbound", "string", typeof(context)))

	config = config ~= nil and config or {}

	if context == CONTEXT or context == "Shared" then
		table.insert(self._Inbound, {hook, config})
	end

	return self
end


--[=[
	This function is used to hook into the RemoteEvent before it fires. All outbound hooks are called in the order they are added.
	
	@param hook function -- The function to be called when the RemoteEvent receives a request.
	@param context "Shared" | "Server" | "Client" -- The context in which the hook should be called.
	@param config any -- An optional configuration value to be passed to the hook.
	@return RemoteEvent -- Returns self.

	:::tip
	This function can be chained.
	```lua
	RemoteEvent
		:outbound(Middleware.Logger, "Server")
		:outbound(Transformers.Encode, "Server")
	```
	:::
	:::caution
	This function should only be used when you are registering your remotes!
	:::
]=]
function RemoteEvent:outbound(hook: hook, context: "Shared" | "Server" | "Client", config: any)
	assert(typeof(hook) == "function", ERROR_FIRST_ARGUMENT:format("outbound", "function", typeof(hook)))
	assert(typeof(context) == "string", ERROR_FIRST_ARGUMENT:format("outbound", "string", typeof(context)))

	config = config ~= nil and config or {}

	if context == CONTEXT or context == "Shared" then
		table.insert(self._Outbound, {hook, config})
	end

	return self
end

--[=[
	This function is used to set a flag that will automatically catch and warn errors thrown by hooks.
	
	@param value boolean -- Defaults to false.
	@return RemoteEvent -- Returns self.

	:::tip
	This function can be chained.
	```lua
	RemoteEvent
		:inbound(Middleware.Logger, "Shared")
		:inbound(Transformers.Decode, "Client")
		:outbound(Middleware.Logger, "Server")
		:outbound(Transformers.Encode, "Server")
		:warn(true)
	```
	:::
	:::caution
	This function should only be used when you are registering your remotes!
	:::
]=]
function RemoteEvent:warn(value: boolean)
	assert(typeof(value) == "boolean", ERROR_FIRST_ARGUMENT:format("warn", "boolean", typeof(value)))

	self._Warn = value
	return self
end

function RemoteEvent:__Init(Name, Remote)
	if self.Instantiated then return end
	self.Instantiated = true

	self.Name = Name

	local function ApplyPromises(List, args)
		return Promise.new(function(Resolve, Reject)
			Promise.each(List, function(data)
				return Promise.new(function(Resolve, Reject)

					local hook, config = unpack(data)
					local header = {
						Remote = Remote
					}

					hook(header, config, unpack(args)):andThen(function(...)
						local res = {...}

						args = if #res == 0 then args else res
						args = if #res == 1 and res[1] == None then {} else args

						Resolve()
					end):catch(function(err)
						Reject(err)
					end)

				end)
			end)
			:catch(function(err)
				Reject(err, args)
			end)
			:finally(function()
				Resolve(args)
			end)
		end)
	end

	local function ApplyInbound(args)
		if #self._Inbound == 0 then
			return Promise.resolve(args)
		end
		return ApplyPromises(self._Inbound, args)
	end

	local function ApplyOutbound(args)
		if #self._Outbound == 0 then
			return Promise.resolve(args)
		end
		return ApplyPromises(self._Outbound, args)
	end

	if CONTEXT == "Server" then
		--[=[
			Fires RemoteEvent.OnClientEvent for the specified player.

			@server
			@within RemoteEvent

			@param Player Player -- The player to fire the event for.
			@param ... any -- The arguments to pass to the event.

			@return Promise -- Returns a promise that resolves when the event has been fired or fails if any hooks failed.
		]=]
		function self:FireClient(Player: Player, ...)
			local args = {...}

			return Promise.new(function(resolve, reject)
				ApplyOutbound(args):andThen(function(new_args)
					if new_args == nil then new_args = {} end
					Remote:FireClient(Player, unpack(new_args))
					resolve(unpack(new_args))
				end):catch(function(err)
					if self._Warn then
						warn(err)
					end
					reject(err, args)
				end)
			end)
		end

		--[=[
			Fires RemoteEvent.OnClientEvent for all players.

			@server
			@within RemoteEvent

			@param ... any -- The arguments to pass to the event.

			@return Promise -- Returns a promise that resolves when the event has been fired or fails if any hooks failed.
		]=]
		function self:FireAllClients(...)
			local args = {...}

			return Promise.new(function(resolve, reject)
				ApplyOutbound(args):andThen(function(new_args)
					if new_args == nil then new_args = {} end
					Remote:FireAllClients(unpack(new_args))
					resolve(unpack(new_args))
				end):catch(function(err)
					if self._Warn then
						warn(err)
					end
					reject(err, args)
				end)
			end)
		end

		--[=[
			Fires RemoteEvent.OnClientEvent for specified players.

			@server
			@within RemoteEvent

			@param List {[number]: Player} -- The players to fire the event for.
			@param ... any -- The arguments to pass to the event.

			@return Promise -- Returns a promise that resolves when the event has been fired or fails if any hooks failed.
		]=]
		function self:FireClients(List: {[number]: Player}, ...)
			assert(List, ERROR_FIRST_ARGUMENT:format("FireClients", "table", "nil"))
			assert(typeof(List) == "table", ERROR_FIRST_ARGUMENT:format("FireClients", "table", typeof(List)))
			assert(#List > 0, ERROR_LENGTH:format("FireClients"))

			local args = {...}

			return Promise.new(function(resolve, reject)
				ApplyOutbound(args):andThen(function(new_args)
					if new_args == nil then new_args = {} end
					for key, Player: Player in pairs(List) do
						assert(typeof(Player) == "Instance" and Player:IsA("Player"), ERROR_NOT_PLAYER:format(typeof(Player), key))
						Remote:FireClient(Player, unpack(new_args))
					end
					resolve(unpack(new_args))
				end):catch(function(err)
					if self._Warn then
						warn(err)
					end
					reject(err, args)
				end)
			end)
		end

		--[=[
			Fires RemoteEvent.OnClientEvent for all players except those in the list.

			@server
			@within RemoteEvent

			@param List {[number]: Player} -- The players not to fire the event for.
			@param ... any -- The arguments to pass to the event.

			@return Promise -- Returns a promise that resolves when the event has been fired or fails if any hooks failed.
		]=]
		function self:FireClientsExcept(List: {[number]: Player}, ...)
			assert(List, ERROR_FIRST_ARGUMENT:format("FireClientsExcept", "table", "nil"))
			assert(typeof(List) == "table", ERROR_FIRST_ARGUMENT:format("FireClientsExcept", "table", typeof(List)))

			local args = {...}

			return Promise.new(function(resolve, reject)
				ApplyOutbound(args):andThen(function(new_args)
					if new_args == nil then new_args = {} end
					for _, Player: Player in pairs(Players:GetPlayers()) do
						if table.find(List, Player) then continue end
						Remote:FireClient(Player, unpack(new_args))
					end
					resolve(unpack(new_args))
				end):catch(function(err)
					if self._Warn then
						warn(err)
					end
					reject(err, args)
				end)
			end)
		end

		local newSignal = Signal.new()

		self.OnServerEvent = {
			Connect = function(_, cb)
				return newSignal:Connect(cb)
			end,
			Wait = function()
				return newSignal:Wait()
			end,
			DisconnectAll = function()
				return newSignal:DisconnectAll()
			end
		}

		Remote.OnServerEvent:Connect(function(Player, ...)
			ApplyInbound({Player, ...}):andThen(function(args)
				if args == nil then args = {Player} end
				if args[1] ~= Player then
					table.insert(args, 1, Player)
				end
				newSignal:Fire(unpack(args))
			end):catch(function(err, ...)
				if self._Warn then
					warn(err)
				end
				newSignal:Throw(err, ...)
			end)
		end)
	end

	if CONTEXT == "Client" then
		--[=[
			Fires RemoteEvent.OnServerEvent on the server using the arguments specified with an additional player argument at the beginning.

			@client
			@within RemoteEvent

			@param ... any -- The arguments to pass to the event.

			@return Promise -- Returns a promise that resolves when the event has been fired or fails if any hooks failed.
		]=]
		function self:FireServer(...)
			local args = {...}

			return Promise.new(function(resolve, reject)
				ApplyOutbound(args):andThen(function(new_args)
					if new_args == nil then new_args = {} end
					Remote:FireServer(unpack(new_args))
					resolve(unpack(new_args))
				end):catch(function(err)
					if self._Warn then
						warn(err)
					end
					reject(err, args)
				end)
			end)
		end

		local newSignal = Signal.new()

		self.OnClientEvent = {
			Connect = function(_, ...)
				return newSignal:Connect(...)
			end,
			Wait = function()
				return newSignal:Wait()
			end,
			DisconnectAll = function()
				return newSignal:DisconnectAll()
			end
		}

		Remote.OnClientEvent:Connect(function(...)
			ApplyInbound({...}):andThen(function(args)
				if args == nil then args = {} end
				newSignal:Fire(unpack(args))
			end):catch(function(err, ...)
				if self._Warn then
					warn(err)
				end
				newSignal:Throw(err, ...)
			end)
		end)
	end
end

return RemoteEvent