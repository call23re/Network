local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Signal = require(script.Parent.Parent.Parent.Signal)

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
			for _, Player in pairs(List) do
				self.Remote:FireClient(Player, ...)
			end
		end

		function self:FireClientsExcept(List, ...)
			for _, Player in pairs(Players:GetPlayers()) do
				if table.find(List, Player) == nil then
					self.Remote:FireClient(Player, ...)
				end
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