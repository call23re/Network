local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Signal = require(script.Parent.Parent.Parent.Signal)
local Symbol = require(script.Parent.Parent.Symbols.Event)

local ERR_FIRST_ARGUMENT = "First argument of %s must be a table, got <%s>"
local ERR_LENGTH = "First argument of %s must be a table with at least on element"
local ERR_NOT_PLAYER = "All elements of the first argument of FireClients must be players, got <%s> at index %s"

local RemoteEvent = {}
RemoteEvent.__index = RemoteEvent

function RemoteEvent.new()
	local self = setmetatable({}, RemoteEvent)

	self.Type = Symbol

	return self
end

function RemoteEvent:Init(Name, Remote)
	if self.Instantiated then return end
	self.Instantiated = true

	self.Name = Name

	if RunService:IsServer() then
		function self:FireClient(...)
			Remote:FireClient(...)
		end

		function self:FireAllClients(...)
			Remote:FireAllClients(...)
		end

		function self:FireClients(List, ...)
			assert(List, ERR_FIRST_ARGUMENT:format("FireClients", "nil"))
			assert(typeof(List) == "table", ERR_FIRST_ARGUMENT:format("FireClients", typeof(List)))
			assert(#List > 0, ERR_LENGTH:format("FireClients"))

			for key, Player in pairs(List) do
				assert(typeof(Player) == "Instance" and Player:IsA("Player"), ERR_NOT_PLAYER:format(typeof(Player), key))
				Remote:FireClient(Player, ...)
			end
		end

		function self:FireClientsExcept(List, ...)
			assert(List, ERR_FIRST_ARGUMENT:format("FireClientsExcept", "nil"))
			assert(typeof(List) == "table", ERR_FIRST_ARGUMENT:format("FireClientsExcept", typeof(List)))

			for _, Player in pairs(Players:GetPlayers()) do
				if table.find(List, Player) then continue end
				Remote:FireClient(Player, ...)
			end
		end

		local Signal = Signal.new()

		self.OnServerEvent = {
			Connect = function(_, cb)
				return Signal:Connect(cb)
			end,
			Wait = function()
				return Signal:Wait()
			end,
			DisconnectAll = function()
				return Signal:DisconnectAll()
			end,
		}

		Remote.OnServerEvent:Connect(function(...)
			Signal:Fire(...)
		end)
	end

	if RunService:IsClient() then
		function self:FireServer(...)
			Remote:FireServer(...)
		end

		local Signal = Signal.new()

		self.OnClientEvent = {
			Connect = function(_, ...)
				return Signal:Connect(...)
			end,
			Wait = function()
				return Signal:Wait()
			end,
			DisconnectAll = function()
				return Signal:DisconnectAll()
			end,
		}

		Remote.OnClientEvent:Connect(function(...)
			Signal:Fire(...)
		end)
	end
end

return RemoteEvent