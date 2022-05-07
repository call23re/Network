local RunService = game:GetService("RunService")

local Defer = require(script.Parent.Defer)
local Symbol = require(script.Parent.Parent.Symbols.Function)

local RemoteFunction = {}
RemoteFunction.__index = RemoteFunction

function RemoteFunction.new()
	local self = setmetatable({}, RemoteFunction)

	self.Type = Symbol

	return self
end

function RemoteFunction:Init(Name, Request, Response)
	if self.Instantiated then return end
	self.Instantiated = true

	self.Name = Name

	if RunService:IsServer() then
		local InvokedPromises = {}

		function self:InvokeClient(Client, ...)
			assert(typeof(Client) == "Instance" and Client:IsA("Player"),  "First argument of InvokeClient must be a Player")

			Request:FireClient(Client, ...)

			local DefferedPromise = Defer()
			table.insert(InvokedPromises, DefferedPromise)

			return DefferedPromise.Promise
		end

		Response.OnServerEvent:Connect(function(Client, ...)
			for _, Promise in pairs(InvokedPromises) do
				Promise.Resolve(...)
			end
		end)

		Request.OnServerEvent:Connect(function(Client, ...)
			if self.OnServerInvoke then
				local res = {self.OnServerInvoke(Client, ...)}
				Response:FireClient(Client, unpack(res))
			else
				Response:FireClient(Client)
			end
		end)
	end

	if RunService:IsClient() then
		local InvokedPromises = {}

		function self:InvokeServer(...)
			Request:FireServer(...)

			local DefferedPromise = Defer()
			table.insert(InvokedPromises, DefferedPromise)
			
			return DefferedPromise.Promise
		end

		Response.OnClientEvent:Connect(function(...)
			for _, Promise in pairs(InvokedPromises) do
				Promise.Resolve(...)
			end
		end)

		Request.OnClientEvent:Connect(function(...)
			if self.OnClientInvoke then
				local res = {self.OnClientInvoke(...)}
				Response:FireServer(unpack(res))
			else
				Response:FireServer()
			end
		end)
	end
end

return RemoteFunction