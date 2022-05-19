local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Parent.Parent.Promise)
local Defer = require(script.Parent.Defer)
local Symbol = require(script.Parent.Parent.Symbols.Function)
local None = require(script.Parent.Parent.Symbols.None)

local CONTEXT = if RunService:IsServer() then "Server" elseif RunService:IsClient() then "Client" else nil

type HookType<T...> = (T...) -> ()

local RemoteFunction = {}
RemoteFunction.__index = RemoteFunction

function RemoteFunction.new()
	local self = setmetatable({}, RemoteFunction)

	self.ClassName = Symbol
	self._Warn = false

	self._Inbound = {}
	self._Outbound = {}

	return self
end

function RemoteFunction:inbound(hook: HookType, context: string, config: any)
	if context == CONTEXT or context == "Shared" then
		table.insert(self._Inbound, {hook, config})
	end

	return self
end

function RemoteFunction:outbound(hook: HookType, context: string, config: any)
	if context == CONTEXT or context == "Shared" then
		table.insert(self._Outbound, {hook, config})
	end

	return self
end

function RemoteFunction:warn(value: boolean)
	self._Warn = value
	return self
end

function RemoteFunction:__Init(Name, Request, Response)
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

	local function ApplyInbound(args)
		if #self._Inbound == 0 then
			return Promise.resolve(args)
		end
		return ApplyPromises({
			Remote = Response,
			List = self._Inbound,
			args = args
		}, args)
	end

	local function ApplyOutbound(Remote, args)
		if #self._Outbound == 0 then
			return Promise.resolve(args)
		end

		local Type = (Remote == Request and "Request" or "Response")
		return ApplyPromises({
			Remote = Remote,
			List = self._Outbound,
			Type = Type,
			args = args
		}, args)
	end

	if CONTEXT == "Server" then
		local InvokedPromises = {}

		function self:InvokeClient(Client: Player, ...)
			assert(typeof(Client) == "Instance" and Client:IsA("Player"),  "First argument of InvokeClient must be a Player")

			local ok, res = true

			ApplyOutbound(Request, {Client, ...}):andThen(function(args)
				if args == nil then args = {} end
				table.remove(args, 1) -- remove the client
				Request:FireClient(Client, unpack(args))
			end):catch(function(err)
				ok, res = false, err
				if self.Warn then
					warn(err)
				end
			end)

			if not ok then
				return Promise.reject(res)
			end

			local DefferedPromise = Defer()
			table.insert(InvokedPromises, DefferedPromise)

			return DefferedPromise.Promise
		end

		Response.OnServerEvent:Connect(function(Client, ...)
			ApplyInbound({...}):andThen(function(args)
				if args == nil then args = {} end
				for _, ResponsePromise in pairs(InvokedPromises) do
					ResponsePromise.Resolve(unpack(args))
				end
			end):catch(function(err)
				for _, ResponsePromise in pairs(InvokedPromises) do
					ResponsePromise.Reject(err)
				end
				if self.Warn then
					warn(err)
				end
			end)
		end)

		Request.OnServerEvent:Connect(function(Client, ...)
			if self.OnServerInvoke then
				ApplyInbound({Client, ...}):andThen(function(args)
					if args == nil then args = {Client} end
					if args[1] ~= Client then
						table.insert(args, 1, Client)
					end

					local res = {self.OnServerInvoke(unpack(args))}
					ApplyOutbound(Response, {Client, unpack(res)}):andThen(function(args)
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
			local ok, res = true

			ApplyOutbound(Request, {...}):andThen(function(args)
				if args == nil then args = {} end
				Request:FireServer(unpack(args))
			end):catch(function(err)
				ok, res = false, err
				if self.Warn then
					warn(err)
				end
			end)

			if not ok then
				return Promise.reject(res)
			end

			local DefferedPromise = Defer()
			table.insert(InvokedPromises, DefferedPromise)

			return DefferedPromise.Promise
		end

		Response.OnClientEvent:Connect(function(...)
			ApplyInbound({...}):andThen(function(args)
				for _, ResponsePromise in pairs(InvokedPromises) do
					if args == nil then args = {} end
					ResponsePromise.Resolve(unpack(args))
				end
			end):catch(function(err)
				for _, ResponsePromise in pairs(InvokedPromises) do
					ResponsePromise.Reject(err)
				end
				if self.Warn then
					warn(err)
				end
			end)
		end)

		Request.OnClientEvent:Connect(function(...)
			if self.OnClientInvoke then
				ApplyInbound({...}):andThen(function(args)
					if args == nil then args = {} end

					local res = {self.OnClientInvoke(unpack(args))}
					ApplyOutbound(Response, res):andThen(function(args)
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