local RunService = game:GetService("RunService")

local Defer = require(script.Parent.Defer)

local RemoteFunction = {}
RemoteFunction.__index = RemoteFunction

function RemoteFunction.new(Name, Remote)
	local self = setmetatable({}, RemoteFunction)

	self.Name = Name
	self.Remote = Remote

	self:__Init()

	return self
end

function RemoteFunction:__Init()
	if RunService:IsServer() then
		local InvokedPromises = {}

		function self:InvokeClient(...)
			self.Remote:FireClient({Status = "Request", Data = {...}})
			local DefferedPromise = Defer()
			table.insert(InvokedPromises, DefferedPromise)
			return DefferedPromise.Promise
		end

		self.Remote.OnServerEvent:Connect(function(Client, Result)
			if Result.Status == "Response" then
				for _, Promise in pairs(InvokedPromises) do
					Promise.Resolve(unpack(Result.Data))
				end
				return
			end

			if self.OnServerInvoke then
				local res = {self.OnServerInvoke(Client, unpack(Result.Data))}
				self.Remote:FireClient(Client, {Status = "Response", Data = res})
			end
		end)
	end

	if RunService:IsClient() then
		local InvokedPromises = {}

		function self:InvokeServer(...)
			self.Remote:FireServer({Status = "Request", Data = {...}})
			local DefferedPromise = Defer()
			table.insert(InvokedPromises, DefferedPromise)
			return DefferedPromise.Promise
		end

		self.Remote.OnClientEvent:Connect(function(Result)
			if Result.Status == "Response" then
				for _, Promise in pairs(InvokedPromises) do
					Promise.Resolve(unpack(Result.Data))
				end
				return
			end

			if self.OnClientInvoke then
				local res = {self.OnClientInvoke(unpack(Result.Data))}
				self.Remote:FireServer({Status = "Response", Data = res})
			end
		end)
	end
end

return RemoteFunction