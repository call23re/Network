local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Parent.Parent.Promise)
local Defer = require(script.Parent.Defer)
local Symbol = require(script.Parent.Parent.Symbols.Function)

local CONTEXT = if RunService:IsServer() then "Server" else "Client"

local RemoteFunction = {}
RemoteFunction.__index = RemoteFunction

function RemoteFunction.new(Options)
	local self = setmetatable({}, RemoteFunction)

	self.Type = Symbol

	Options = Options or {}

	-- for debugging
	if Options.Warn ~= nil then
		self.Warn = true
	end

	local Middleware = {}
	local Transformers = {}

	if Options.Middleware then
		for _, MiddlewareOptions in pairs(Options.Middleware) do
			local func, context = unpack(MiddlewareOptions)
			if context == CONTEXT or context == "Shared" then
				table.insert(Middleware, func)
			end
		end
	end

	if Options.Transformers then
		for _, TransformerOptions in pairs(Options.Transformers) do
			local func, context = unpack(TransformerOptions)
			if context == CONTEXT or context == "Shared" then
				table.insert(Transformers, func)
			end
		end
	end

	self.Middleware = Middleware
	self.Transformers = Transformers

	return self
end

function RemoteFunction:Init(Name, Request, Response)
	if self.Instantiated then return end
	self.Instantiated = true

	self.Name = Name

	local function ApplyPromises(Options, args)
		return Promise.new(function(Resolve, Reject)
			Promise.each(Options.List, function(func)
				return Promise.new(function(Resolve, Reject)

					local params = {Options.Type, Options.Remote, args}
					if params[1] == nil then
						-- shift params to the left to fill hole
						params = table.move(params, 2, 3, 1, {})
					end

					func(unpack(params)):andThen(function(res)
						args = (res ~= nil and {res} or args)
						Resolve()
					end):catch(function()
						Reject()
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

	local function ApplyMiddleware(args)
		if #self.Middleware == 0 then
			return Promise.resolve(args)
		end
		return ApplyPromises({
			Remote = Response,
			List = self.Middleware,
			args = args
		})
	end

	local function ApplyTransformers(Remote, args)
		if #self.Transformers == 0 then
			return Promise.resolve(args)
		end

		local Type = (Remote == Request and "Request" or "Response")
		return ApplyPromises({
			Remote = Remote, 
			List = self.Transformers,
			Type = Type,
			args = args
		})
	end

	if CONTEXT == "Server" then
		local InvokedPromises = {}

		function self:InvokeClient(Client: Player, ...)
			assert(typeof(Client) == "Instance" and Client:IsA("Player"),  "First argument of InvokeClient must be a Player")

			local ok = true

			ApplyTransformers(Request, {Client, ...}):andThen(function(args)
				Request:FireClient(Client, unpack(args))
			end):catch(function(err)
				ok = false
				if self.Warn then
					warn(err)
				end
			end)

			if not ok then return end

			local DefferedPromise = Defer()
			table.insert(InvokedPromises, DefferedPromise)

			return DefferedPromise.Promise
		end

		Response.OnServerEvent:Connect(function(Client, ...)
			ApplyMiddleware({...}):andThen(function(args)
				for _, Promise in pairs(InvokedPromises) do
					Promise.Resolve(unpack(args))
				end
			end):catch(function(err)
				if self.Warn then
					warn(err)
				end
			end)
		end)

		Request.OnServerEvent:Connect(function(Client, ...)
			if self.OnServerInvoke then
				ApplyTransformers(Response, {Client, ...}):andThen(function(args)
					local res = {self.OnServerInvoke(Client, unpack(args))}
					Response:FireClient(Client, unpack(res))
				end):catch(function(err)
					if self.Warn then
						warn(("[%s] RemoteFunction.Request: %s"):format(self.Name, err))
					end
				end)
			else
				Response:FireClient(Client)
			end
		end)
	end

	if CONTEXT == "Client" then
		local InvokedPromises = {}

		function self:InvokeServer(...)
			local ok = true

			ApplyTransformers(Request, {...}):andThen(function(args)
				Request:FireServer(unpack(args))
			end):catch(function(err)
				ok = false
				if self.Warn then
					warn(err)
				end
			end)

			if not ok then return end

			local DefferedPromise = Defer()
			table.insert(InvokedPromises, DefferedPromise)
			
			return DefferedPromise.Promise
		end

		Response.OnClientEvent:Connect(function(...)
			ApplyMiddleware({...}):andThen(function(args)
				for _, Promise in pairs(InvokedPromises) do
					Promise.Resolve(unpack(args))
				end
			end):catch(function(err)
				if self.Warn then
					warn(err)
				end
			end)
		end)

		Request.OnClientEvent:Connect(function(...)
			if self.OnClientInvoke then
				ApplyTransformers(Response, {...}):andThen(function(args)
					local res = {self.OnClientInvoke(unpack(args))}
					Response:FireServer(unpack(res))
				end):catch(function(err)
					if self.Warn then
						warn(err)
					end
				end)
			else
				Response:FireServer()
			end
		end)
	end
end

return RemoteFunction