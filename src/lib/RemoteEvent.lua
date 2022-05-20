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

function RemoteEvent:inbound(hook, context: string, config: any)
	assert(typeof(hook) == "function", ERROR_FIRST_ARGUMENT:format("inbound", "function", typeof(hook)))
	assert(typeof(context) == "string", ERROR_FIRST_ARGUMENT:format("inbound", "string", typeof(context)))

	config = config ~= nil and config or {}

	if context == CONTEXT or context == "Shared" then
		table.insert(self._Inbound, {hook, config})
	end

	return self
end

function RemoteEvent:outbound(hook, context: string, config: any)
	assert(typeof(hook) == "function", ERROR_FIRST_ARGUMENT:format("outbound", "function", typeof(hook)))
	assert(typeof(context) == "string", ERROR_FIRST_ARGUMENT:format("outbound", "string", typeof(context)))

	config = config ~= nil and config or {}

	if context == CONTEXT or context == "Shared" then
		table.insert(self._Outbound, {hook, config})
	end

	return self
end

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
				Reject(err)
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
					reject(err)
				end)
			end)
		end

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
					reject(err)
				end)
			end)
		end

		function self:FireClients(List, ...)
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
					reject(err)
				end)
			end)
		end

		function self:FireClientsExcept(List, ...)
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
					reject(err)
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
			end):catch(function(err)
				if self._Warn then
					warn(err)
				end
			end)
		end)
	end

	if CONTEXT == "Client" then
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
					reject(err)
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
			end):catch(function(err)
				if self._Warn then
					warn(err)
				end
			end)
		end)
	end
end

return RemoteEvent