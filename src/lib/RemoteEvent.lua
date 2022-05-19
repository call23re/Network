local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Parent.Parent.Promise)
local Signal = require(script.Parent.Parent.Parent.Signal)
local Symbol = require(script.Parent.Parent.Symbols.Event)
local None = require(script.Parent.Parent.Symbols.None)

local CONTEXT = if RunService:IsServer() then "Server" elseif RunService:IsClient() then "Client" else nil
local ERR_FIRST_ARGUMENT = "First argument of %s must be a table, got <%s>"
local ERR_LENGTH = "First argument of %s must be a table with at least on element"
local ERR_NOT_PLAYER = "All elements of the first argument of FireClients must be players, got <%s> at index %s"

type HookType<T...> = (T...) -> ()

local RemoteEvent = {}
RemoteEvent.__index = RemoteEvent

function RemoteEvent.new()
	local self = setmetatable({}, RemoteEvent)

	self.ClassName = Symbol
	self._Warn = false

	self._Inbound = {}
	self._InboundMap = {}
	self._Outbound = {}
	self._OutboundMap = {}

	return self
end

function RemoteEvent:inbound(hook: HookType, context: string, config: any)
	if self._InboundMap[hook] then return self end

	if context == CONTEXT or context == "Shared" then
		table.insert(self._Inbound, {hook, config})
		self._InboundMap[hook] = true
	end

	return self
end

function RemoteEvent:outbound(hook: HookType, context: string, config: any)
	if self._OutboundMap[hook] then return self end

	if context == CONTEXT or context == "Shared" then
		table.insert(self._Outbound, {hook, config})
		self._OutboundMap[hook] = true
	end

	return self
end

function RemoteEvent:warn(value: boolean)
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
			ApplyOutbound({...}):andThen(function(args)
				if args == nil then args = {} end
				Remote:FireClient(Player, unpack(args))
			end):catch(function(err)
				if self._Warn then
					warn(err)
				end
			end)
		end

		function self:FireAllClients(...)
			ApplyOutbound({...}):andThen(function(args)
				if args == nil then args = {} end
				Remote:FireAllClients(unpack(args))
			end):catch(function(err)
				if self._Warn then
					warn(err)
				end
			end)
		end

		function self:FireClients(List, ...)
			assert(List, ERR_FIRST_ARGUMENT:format("FireClients", "nil"))
			assert(typeof(List) == "table", ERR_FIRST_ARGUMENT:format("FireClients", typeof(List)))
			assert(#List > 0, ERR_LENGTH:format("FireClients"))

			ApplyOutbound({...}):andThen(function(args)
				if args == nil then args = {} end
				for key, Player: Player in pairs(List) do
					assert(typeof(Player) == "Instance" and Player:IsA("Player"), ERR_NOT_PLAYER:format(typeof(Player), key))
					Remote:FireClient(Player, unpack(args))
				end
			end):catch(function(err)
				if self._Warn then
					warn(err)
				end
			end)
		end

		function self:FireClientsExcept(List, ...)
			assert(List, ERR_FIRST_ARGUMENT:format("FireClientsExcept", "nil"))
			assert(typeof(List) == "table", ERR_FIRST_ARGUMENT:format("FireClientsExcept", typeof(List)))

			ApplyOutbound({...}):andThen(function(args)
				if args == nil then args = {} end
				for _, Player: Player in pairs(Players:GetPlayers()) do
					if table.find(List, Player) then continue end
					Remote:FireClient(Player, unpack(args))
				end
			end):catch(function(err)
				if self._Warn then
					warn(err)
				end
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
			end,
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
			ApplyOutbound({...}):andThen(function(args)
				if args == nil then args = {} end
				Remote:FireServer(unpack(args))
			end):catch(function(err)
				if self._Warn then
					warn(err)
				end
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
			end,
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