local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Parent.Parent.Promise)
local Defer = require(script.Parent.Defer)
local Symbol = require(script.Parent.Parent.Symbols.Function)
local None = require(script.Parent.Parent.Symbols.None)

local CONTEXT = if RunService:IsServer() then "Server" elseif RunService:IsClient() then "Client" else nil
local ERROR_FIRST_ARGUMENT = "First argument of %s must be a %s, got <%s>" :: any

type HeaderType = "Request" | "Response"
type hook = (header: {Remote: RemoteEvent, Type: HeaderType?}, config: any) -> typeof(Promise.new())

--[=[
	@prop Name string
	@readonly
	@within RemoteFunction
	Refers to the name given to the RemoteFunction.
]=]
--[=[
	@prop ClassName symbol
	@readonly
	@within RemoteFunction
	Refers to the ClassName Symbol of the RemoteFunction.
]=]
--[=[
	@function OnClientInvoke
	@param ... any
	@client
	@within RemoteFunction
	Called when the client is invoked by [RemoteFunction:InvokeClient].
]=]
--[=[
	@function OnServerInvoke
	@param Player Player
	@param ... any
	@server
	@within RemoteFunction
	Called when the server is invoked by [RemoteFunction:InvokeServer].
]=]
--[=[
	A RemoteFunction emulates Roblox RemoteFunctions with RemoteEvents. It has feature parity with Roblox's RemoteFunction.

	@class RemoteFunction
]=]
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

--[=[
	This function is used to hook into the RemoteFunction in two places: before an invocation callback is called and before an invocation response is returned. All inbound hooks are called in the order they are added.
	
	@param hook function -- The function to be called when the RemoteFunction receives a request.
	@param context "Shared" | "Server" | "Client" -- The context in which the hook should be called.
	@param config any -- An optional configuration value to be passed to the hook.
	@return RemoteFunction -- Returns self.

	:::caution
	This function should only be used when you are registering your remotes!
	:::
]=]
function RemoteFunction:inbound(hook: hook, context: "Shared" | "Server" | "Client", config: any)
	assert(typeof(hook) == "function", ERROR_FIRST_ARGUMENT:format("inbound", "function", typeof(hook)))
	assert(typeof(context) == "string", ERROR_FIRST_ARGUMENT:format("inbound", "string", typeof(context)))

	config = config ~= nil and config or {}

	if context == CONTEXT or context == "Shared" then
		table.insert(self._Inbound, {hook, config})
	end

	return self
end

--[=[
	This function is used to hook into the RemoteFunction in two places: after an invocation callback is called and before the remote is invoked. All outbound hooks are called in the order they are added.
	
	@param hook function -- The function to be called when the RemoteFunction receives a request.
	@param context "Shared" | "Server" | "Client" -- The context in which the hook should be called.
	@param config any -- An optional configuration value to be passed to the hook.
	@return RemoteFunction -- Returns self.

	:::caution
	This function should only be used when you are registering your remotes!
	:::
]=]
function RemoteFunction:outbound(hook: hook, context: "Shared" | "Server" | "Client", config: any)
	assert(typeof(hook) == "function", ERROR_FIRST_ARGUMENT:format("outbound", "function", typeof(hook)))
	assert(typeof(context) == "string", ERROR_FIRST_ARGUMENT:format("outbound", "string", typeof(context)))

	config = config ~= nil and config or {}

	if context == CONTEXT or context == "Shared" then
		table.insert(self._Outbound, {hook, config})
	end

	return self
end

--[=[
	This function is used to set a flag that will automatically catch and warn errors thrown by hooks.
	
	@param value boolean -- Defaults to false.
	@return RemoteFunction -- Returns self.
	
	:::caution
	This function should only be used when you are registering your remotes!
	:::
]=]
function RemoteFunction:warn(value: boolean)
	assert(typeof(value) == "boolean", ERROR_FIRST_ARGUMENT:format("warn", "boolean", typeof(value)))

	self._Warn = value
	return self
end

function RemoteFunction:__Init(Name: string, Request: RemoteEvent, Response: RemoteEvent)
	if self.Instantiated then return end
	self.Instantiated = true

	self.Name = Name

	local function ApplyPromises(Options, args)
		return Promise.new(function(Resolve, Reject)
			Promise.each(Options.List, function(data: {hook})
				return Promise.new(function(Resolve, Reject)

					local hook, config = unpack(data)
					local header = {
						Remote = Options.Remote,
						Type = Options.Type
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

	local function ApplyInbound(Remote: RemoteEvent, args: {any})
		local inboundHooks = self._Inbound :: {any}
		if typeof(inboundHooks) ~= "table" or #inboundHooks == 0 then
			return Promise.resolve(args)
		end

		local Type = if Remote == Request then "Request" else "Response"
		return ApplyPromises({
			Remote = Response,
			List = inboundHooks,
			Type = Type,
			args = args
		}, args)
	end

	local function ApplyOutbound<T>(Remote, args: {T})
		local outboundHooks = self._Outbound :: {any}
		if typeof(outboundHooks) ~= "table" or #outboundHooks == 0 then
			return Promise.resolve(args)
		end

		local Type = if Remote == Request then "Request" else "Response"
		return ApplyPromises({
			Remote = Remote,
			List = outboundHooks,
			Type = Type,
			args = args
		}, args)
	end

	if CONTEXT == "Server" then
		local InvokedPromises = {} :: {any}

		--[=[
			Calls the method bound to RemoteFunction by RemoteFunction.OnClientInvoke for the given Player.

			@server
			@within RemoteFunction

			@param Client Player -- The player to invoke.
			@param ... any -- The arguments to pass to the invocation.

			@return Promise -- Returns a promise that resolves when the remote has been invoked or fails if any hooks failed.
		]=]
		function self:InvokeClient(Client: Player, ...)
			assert(typeof(Client) == "Instance" and Client:IsA("Player"),  "First argument of InvokeClient must be a Player")

			local ok, res = true, nil

			ApplyOutbound(Request, {Client, ...}):andThen(function(args: {Player}?)
				args = if args == nil then {} else args
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
			ApplyInbound(Response, {...}):andThen(function(args: {any}?)
				args = if args == nil then {} else args
				for _, ResponsePromise in InvokedPromises do
					ResponsePromise.Resolve(unpack(args))
				end
			end):catch(function(err)
				for _, ResponsePromise in InvokedPromises do
					ResponsePromise.Reject(err)
				end
				if self.Warn then
					warn(err)
				end
			end)
		end)

		Request.OnServerEvent:Connect(function(Client: Player, ...)
			if self.OnServerInvoke then
				ApplyInbound(Request, {Client, ...}):andThen(function(args: {any}?)
					args = if args == nil then {Client} else args
					if args[1] ~= Client then
						table.insert(args, 1, Client)
					end

					local res = {self.OnServerInvoke(unpack(args))}
					ApplyOutbound(Response, {Client, unpack(res)}):andThen(function(args: {any}?)
						args = if args == nil then {} else args
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
		local InvokedPromises = {} :: {any}

		--[=[
			Calls the method bound to RemoteFunction by RemoteFunction.OnServerInvoke.

			@client
			@within RemoteFunction

			@param ... any -- The arguments to pass to the invocation.

			@return Promise -- Returns a promise that resolves when the remote has been invoked or fails if any hooks failed.
		]=]
		function self:InvokeServer(...)
			local ok, res = true, nil

			ApplyOutbound(Request, {...}):andThen(function(args: {any}?)
				args = if args == nil then {} else args
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
			ApplyInbound(Response, {...}):andThen(function(args: {any}?)
				for _, ResponsePromise in InvokedPromises do
					args = if args == nil then {} else args
					ResponsePromise.Resolve(unpack(args))
				end
			end):catch(function(err)
				for _, ResponsePromise in InvokedPromises do
					ResponsePromise.Reject(err)
				end
				if self.Warn then
					warn(err)
				end
			end)
		end)

		Request.OnClientEvent:Connect(function(...)
			if self.OnClientInvoke then
				ApplyInbound(Request, {...}):andThen(function(args: {any}?)
					args = if args == nil then {} else args

					local res = {self.OnClientInvoke(unpack(args))}
					ApplyOutbound(Response, res):andThen(function(args: {any}?)
						args = if args == nil then {} else args
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