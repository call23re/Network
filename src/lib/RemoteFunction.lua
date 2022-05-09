local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Parent.Parent.Promise)
local Defer = require(script.Parent.Defer)
local Symbol = require(script.Parent.Parent.Symbols.Function)
local None = require(script.Parent.Parent.Symbols.None)

local CONTEXT = if RunService:IsServer() then "Server" elseif RunService:IsClient() then "Client" else nil

local RemoteFunction = {}
RemoteFunction.__index = RemoteFunction

function RemoteFunction.new(Options)
	local self = setmetatable({}, RemoteFunction)

	self.Type = Symbol

	Options = Options or {}

	-- for debugging
	if Options.Warn ~= nil then
		self.Warn = Options.Warn
	end

	local Middleware = {}
	local Transformers = {}

	if Options.Middleware then
		for _, MiddlewareOptions in pairs(Options.Middleware) do
			local func, context, config = unpack(MiddlewareOptions)
			config = config or {}
			if context == CONTEXT or context == "Shared" then
				table.insert(Middleware, {func, config})
			end
		end
	end

	if Options.Transformers then
		for _, TransformerOptions in pairs(Options.Transformers) do
			local func, context, config = unpack(TransformerOptions)
			config = config or {}
			if context == CONTEXT or context == "Shared" then
				table.insert(Transformers, {func, config})
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
			Promise.each(Options.List, function(data)
				return Promise.new(function(Resolve, Reject)

					local func, config = unpack(data)
					local header = {
						Remote = Options.Remote,
						Type = Options.Type
					}

					func(header, config, unpack(args)):andThen(function(...)
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

	local function ApplyMiddleware(args)
		if #self.Middleware == 0 then
			return Promise.resolve(args)
		end
		return ApplyPromises({
			Remote = Response,
			List = self.Middleware,
			args = args
		}, args)
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
		}, args)
	end

	if CONTEXT == "Server" then
		local InvokedPromises = {}

		function self:InvokeClient(Client: Player, ...)
			assert(typeof(Client) == "Instance" and Client:IsA("Player"),  "First argument of InvokeClient must be a Player")

			local ok = true

			ApplyTransformers(Request, {Client, ...}):andThen(function(args)
				if args == nil then args = {} end
				table.remove(args, 1) -- remove the client
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
				if args == nil then args = {} end
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
				ApplyMiddleware({Client, ...}):andThen(function(args)
					if args == nil then args = {Client} end
					if args[1] ~= Client then
						table.insert(args, 1, Client)
					end
					
					local res = {self.OnServerInvoke(unpack(args))}
					ApplyTransformers(Response, {Client, unpack(res)}):andThen(function(args)
						if args == nil then args = {} end
						table.remove(args, 1) -- remove the client
						Response:FireClient(Client, unpack(args))
					end):catch(function(err)
						if self.Warn then
							warn(err)
						end
					end)

				end):catch(function(err)
					if self.Warn then
						warn(err)
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
				if args == nil then args = {} end
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
					if args == nil then args = {} end
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
				ApplyMiddleware({...}):andThen(function(args)
					if args == nil then args = {} end
					
					local res = {self.OnClientInvoke(unpack(args))}
					ApplyTransformers(Response, res):andThen(function(args)
						if args == nil then args = {} end
						Response:FireServer(unpack(args))
					end):catch(function(err)
						if self.Warn then
							warn(err)
						end
					end)

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