local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Signal = require(script.Parent.Parent.Parent.Signal)

local ERR_FIRST_ARGUMENT = "First argument of %s must be a table, got <%s>"
local ERR_LENGTH = "First argument of %s must be a table with at least on element"
local ERR_NOT_PLAYER = "All elements of the first argument of FireClients must be players, got <%s> at index %s"

local RemoteEvent = {}
RemoteEvent.__index = RemoteEvent

function RemoteEvent.new(Name, Remote)
	local self = setmetatable({}, RemoteEvent)

	self.Name = Name
	self.Remote = Remote

	self:__Init()

	return self
end

function RemoteEvent:__Init()
	if RunService:IsServer() then
		function self:FireClient(...)
			self.Remote:FireClient(...)
		end

		function self:FireAllClients(...)
			self.Remote:FireAllClients(...)
		end

		function self:FireClients(List, ...)
			assert(List, ERR_FIRST_ARGUMENT:format("FireClients", "nil"))
			assert(typeof(List) == "table", ERR_FIRST_ARGUMENT:format("FireClients", typeof(List)))
			assert(#List > 0, ERR_LENGTH:format("FireClients"))

			for key, Player in pairs(List) do
				assert(typeof(Player) == "Instance" and Player:IsA("Player"), ERR_NOT_PLAYER:format(typeof(Player), key))
				self.Remote:FireClient(Player, ...)
			end
		end

		function self:FireClientsExcept(List, ...)
			assert(List, ERR_FIRST_ARGUMENT:format("FireClientsExcept", "nil"))
			assert(typeof(List) == "table", ERR_FIRST_ARGUMENT:format("FireClientsExcept", typeof(List)))

			for _, Player in pairs(Players:GetPlayers()) do
				if table.find(List, Player) then continue end
				self.Remote:FireClient(Player, ...)
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

		self.Remote.OnServerEvent:Connect(function(...)
			Signal:Fire(...)
		end)
	end

	if RunService:IsClient() then
		function self:FireServer(...)
			self.Remote:FireServer(...)
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

		self.Remote.OnClientEvent:Connect(function(...)
			Signal:Fire(...)
		end)
	end
end

return RemoteEvent