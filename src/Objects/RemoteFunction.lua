local RunService = game:GetService("RunService")

local Defer = require(script.Parent.Defer)

local RemoteFunction = {}
RemoteFunction.__index = RemoteFunction

function RemoteFunction.new(Name, Request, Response)
	local self = setmetatable({}, RemoteFunction)

	self.Name = Name
	self.Request = Request
	self.Response = Response

	self:__Init()

	return self
end

function RemoteFunction:__Init()
	if RunService:IsServer() then
		local InvokedPromises = {}

		function self:InvokeClient(Client, ...)
			assert(typeof(Client) == "Instance" and Client:IsA("Player"),  "First argument of InvokeClient must be a Player")

			self.Request:FireClient(Client, ...)

			local DefferedPromise = Defer()
			table.insert(InvokedPromises, DefferedPromise)

			return DefferedPromise.Promise
		end

		self.Response.OnServerEvent:Connect(function(Client, ...)
			for _, Promise in pairs(InvokedPromises) do
				Promise.Resolve(...)
			end
		end)

		self.Request.OnServerEvent:Connect(function(Client, ...)
			if self.OnServerInvoke then
				local res = {self.OnServerInvoke(Client, ...)}
				self.Response:FireClient(Client, unpack(res))
			else
				self.Response:FireClient(Client)
			end
		end)
	end

	if RunService:IsClient() then
		local InvokedPromises = {}

		function self:InvokeServer(...)
			self.Request:FireServer(...)

			local DefferedPromise = Defer()
			table.insert(InvokedPromises, DefferedPromise)
			
			return DefferedPromise.Promise
		end

		self.Response.OnClientEvent:Connect(function(...)
			for _, Promise in pairs(InvokedPromises) do
				Promise.Resolve(...)
			end
		end)

		self.Request.OnClientEvent:Connect(function(...)
			if self.OnClientInvoke then
				local res = {self.OnClientInvoke(...)}
				self.Response:FireServer(unpack(res))
			else
				self.Response:FireServer()
			end
		end)
	end
end

return RemoteFunction