local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Parent.Parent.Promise)
local Signal = require(script.Parent.Parent.Parent.Signal)
local Symbol = require(script.Parent.Parent.Symbols.Unreliable)
local None = require(script.Parent.Parent.Symbols.None)

local CONTEXT = if RunService:IsServer() then "Server" elseif RunService:IsClient() then "Client" else nil

local ERROR_FIRST_ARGUMENT = "First argument of %s must be a %s, got <%s>" :: any
local ERROR_LENGTH = "First argument of %s must be a table with at least on element" :: any
local ERROR_NOT_PLAYER = "All elements of the first argument of FireClients must be players, got <%s> at index %s" :: any

type HeaderType = "Request" | "Response"
type hook = (header: {Remote: UnreliableRemoteEvent, Type: HeaderType?}, config: any) -> typeof(Promise.new())

--[=[
	@prop Name string
	@readonly
	@within UnreliableRemoteEvent
	Refers to the name given to the UnreliableRemoteEvent.
]=]
--[=[
	@prop ClassName symbol
	@readonly
	@within UnreliableRemoteEvent
	Refers to the ClassName Symbol of the UnreliableRemoteEvent.
]=]
--[=[
	Fires listening functions when the server fires the UnreliableRemoteEvent at this client.

	@function OnClientEvent
	@param ... any
	@client
	@within UnreliableRemoteEvent

	@return Connection(...)
]=]
--[=[
	Fires listening functions when the client fires the UnreliableRemoteEvent.

	@function OnServerEvent
	@param Player Player
	@param ... any
	@server
	@within UnreliableRemoteEvent

	@return Connection(Player, ...)
	
]=]
--[=[
	A UnreliableRemoteEvent wraps a Roblox UnreliableRemoteEvent and provides ways to hook into it. It has feature parity with a regular UnreliableRemoteEvent.

	@class UnreliableRemoteEvent
]=]
local UnreliableRemoteEvent = {}
UnreliableRemoteEvent.__index = UnreliableRemoteEvent

function UnreliableRemoteEvent.new()
	local self = setmetatable({}, UnreliableRemoteEvent)

	self.ClassName = Symbol
	self._Warn = false

	self._Inbound = {}
	self._Outbound = {}

	return self
end

--[=[
	This function is used to hook into the UnreliableRemoteEvent listener. All inbound hooks are called in the order they are added.
	
	@param hook function -- The function to be called when the UnreliableRemoteEvent receives a request.
	@param context "Shared" | "Server" | "Client" -- The context in which the hook should be called.
	@param config any -- An optional configuration value to be passed to the hook.
	@return UnreliableRemoteEvent -- Returns self.

	:::tip
	This function can be chained.
	```lua
	UnreliableRemoteEvent
		:inbound(Middleware.Logger, "Client")
		:inbound(Transformers.Decode, "Client")
	```
	:::
	:::caution
	This function should only be used when you are registering your remotes!
	:::
]=]
function UnreliableRemoteEvent:inbound(hook: hook, context: "Shared" | "Server" | "Client", config: any)
	assert(typeof(hook) == "function", ERROR_FIRST_ARGUMENT:format("inbound", "function", typeof(hook)))
	assert(typeof(context) == "string", ERROR_FIRST_ARGUMENT:format("inbound", "string", typeof(context)))

	config = config ~= nil and config or {}

	if context == CONTEXT or context == "Shared" then
		table.insert(self._Inbound, {hook, config})
	end

	return self
end


--[=[
	This function is used to hook into the UnreliableRemoteEvent before it fires. All outbound hooks are called in the order they are added.
	
	@param hook function -- The function to be called when the UnreliableRemoteEvent receives a request.
	@param context "Shared" | "Server" | "Client" -- The context in which the hook should be called.
	@param config any -- An optional configuration value to be passed to the hook.
	@return UnreliableRemoteEvent -- Returns self.

	:::tip
	This function can be chained.
	```lua
	UnreliableRemoteEvent
		:outbound(Middleware.Logger, "Server")
		:outbound(Transformers.Encode, "Server")
	```
	:::
	:::caution
	This function should only be used when you are registering your remotes!
	:::
]=]
function UnreliableRemoteEvent:outbound(hook: hook, context: "Shared" | "Server" | "Client", config: any)
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
	@return UnreliableRemoteEvent -- Returns self.

	:::tip
	This function can be chained.
	```lua
	UnreliableRemoteEvent
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
function UnreliableRemoteEvent:warn(value: boolean)
	assert(typeof(value) == "boolean", ERROR_FIRST_ARGUMENT:format("warn", "boolean", typeof(value)))

	self._Warn = value
	return self
end

function UnreliableRemoteEvent:__Init(Name: string, Remote: UnreliableRemoteEvent)
	if self.Instantiated then return end
	self.Instantiated = true

	self.Name = Name

	local function ApplyPromises(List, args)
		return Promise.new(function(Resolve, Reject)
			Promise.each(List, function(data: {hook})
				return Promise.new(function(Resolve, Reject)
					local hook, config = unpack(data)
					local header: {Remote: UnreliableRemoteEvent, Type: HeaderType?} = {
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

	local function ApplyInbound<T>(args: {T})
		local inboundHooks = self._Inbound :: {any}
		if typeof(inboundHooks) ~= "table" or #inboundHooks == 0 then
			return Promise.resolve(args)
		end
		return ApplyPromises(inboundHooks, args)
	end

	local function ApplyOutbound(args)
		local outboundHooks = self._Outbound :: {any}
		if typeof(outboundHooks) ~= "table" or #outboundHooks == 0 then
			return Promise.resolve(args)
		end
		return ApplyPromises(self._Outbound, args)
	end

	if CONTEXT == "Server" then
		--[=[
			Fires UnreliableRemoteEvent.OnClientEvent for the specified player.

			@server
			@within UnreliableRemoteEvent

			@param Player Player -- The player to fire the event for.
			@param ... any -- The arguments to pass to the event.

			@return Promise -- Returns a promise that resolves when the event has been fired or fails if any hooks failed.
		]=]
		function self:FireClient(Player: Player, ...)
			local args = {...}

			return Promise.new(function(resolve, reject)
				ApplyOutbound(args):andThen(function(newArgs: {any}?)
					newArgs = if newArgs == nil then {} else newArgs
					Remote:FireClient(Player, unpack(newArgs))
					resolve(unpack(newArgs))
				end):catch(function(err)
					if self._Warn then
						warn(err)
					end
					reject(err, args)
				end)
			end)
		end

		--[=[
			Fires UnreliableRemoteEvent.OnClientEvent for all players.

			@server
			@within UnreliableRemoteEvent

			@param ... any -- The arguments to pass to the event.

			@return Promise -- Returns a promise that resolves when the event has been fired or fails if any hooks failed.
		]=]
		function self:FireAllClients(...)
			local args = {...}

			return Promise.new(function(resolve, reject)
				ApplyOutbound(args):andThen(function(newArgs: {any}?)
					newArgs = if newArgs == nil then {} else newArgs
					Remote:FireAllClients(unpack(newArgs))
					resolve(unpack(newArgs))
				end):catch(function(err)
					if self._Warn then
						warn(err)
					end
					reject(err, args)
				end)
			end)
		end

		--[=[
			Fires UnreliableRemoteEvent.OnClientEvent for specified players.

			@server
			@within UnreliableRemoteEvent

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
				ApplyOutbound(args):andThen(function(newArgs: {any}?)
					newArgs = if newArgs == nil then {} else newArgs
					for key, Player: Player in List do
						assert(typeof(Player) == "Instance" and Player:IsA("Player"), ERROR_NOT_PLAYER:format(typeof(Player), key))
						Remote:FireClient(Player, unpack(newArgs))
					end
					resolve(unpack(newArgs))
				end):catch(function(err)
					if self._Warn then
						warn(err)
					end
					reject(err, args)
				end)
			end)
		end

		--[=[
			Fires UnreliableRemoteEvent.OnClientEvent for all players except those in the list.

			@server
			@within UnreliableRemoteEvent

			@param List {[number]: Player} -- The players not to fire the event for.
			@param ... any -- The arguments to pass to the event.

			@return Promise -- Returns a promise that resolves when the event has been fired or fails if any hooks failed.
		]=]
		function self:FireClientsExcept(List: {[number]: Player}, ...)
			assert(List, ERROR_FIRST_ARGUMENT:format("FireClientsExcept", "table", "nil"))
			assert(typeof(List) == "table", ERROR_FIRST_ARGUMENT:format("FireClientsExcept", "table", typeof(List)))

			local args = {...}

			return Promise.new(function(resolve, reject)
				ApplyOutbound(args):andThen(function(newArgs: {any}?)
					newArgs = if newArgs == nil then {} else newArgs
					for _, Player: Player in Players:GetPlayers() do
						if table.find(List, Player) then continue end
						Remote:FireClient(Player, unpack(newArgs))
					end
					resolve(unpack(newArgs))
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

		Remote.OnServerEvent:Connect(function(Player: Player, ...)
			ApplyInbound({Player, ...}):andThen(function(args: {Player}?)
				args = if args == nil then {Player} else args
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
			Fires UnreliableRemoteEvent.OnServerEvent on the server using the arguments specified with an additional player argument at the beginning.

			@client
			@within UnreliableRemoteEvent

			@param ... any -- The arguments to pass to the event.

			@return Promise -- Returns a promise that resolves when the event has been fired or fails if any hooks failed.
		]=]
		function self:FireServer(...)
			local args = {...}

			return Promise.new(function(resolve, reject)
				ApplyOutbound(args):andThen(function(newArgs: {any}?)
					newArgs = if newArgs == nil then {} else newArgs
					Remote:FireServer(unpack(newArgs))
					resolve(unpack(newArgs))
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
			ApplyInbound({...}):andThen(function(args: {any}?)
				args = if args == nil then {} else args
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

return UnreliableRemoteEvent