local RunService = game:GetService("RunService")

local Symbols = script.Parent.Symbols

local EventSymbol = require(Symbols.Event)
local FunctionSymbol = require(Symbols.Function)

local DIR = script.Parent
local DIR_NAME_EVENTS = "RemoteEvents"
local DIR_NAME_FUNCTIONS = "RemoteFunctions"

local ERROR_NO_EVENT = "RemoteEvent `%s` was not registered"
local ERROR_NO_FUNCTION = "RemoteFunction `%s` was not registered"
local ERROR_INVALID_KIND = "Invalid remote type registered for key `%s`"

local REMOTES = {
	EVENTS = {},
	FUNCTIONS = {}
}

--[=[
	Registers a dictionary of remotes where the key is the name of the remote and the value is a RemoteEvent or RemoteFunction class.

	```lua
		-- ReplicatedStorage/Remotes.lua
		local Network = require(...Network)
		return Network.Register({
			FooEvent = Network.Event.new(),
			BarFunction = Network.Function.new()
		})
	```

	@class Register
]=]
local function Register(Remotes)
	local RemoteEventsFolder
	local RemoteFunctionsFolder

	if RunService:IsServer() then

		RemoteEventsFolder = DIR:FindFirstChild(DIR_NAME_EVENTS)
		RemoteFunctionsFolder = DIR:FindFirstChild(DIR_NAME_FUNCTIONS)

		if not RemoteEventsFolder then
			RemoteEventsFolder = Instance.new("Folder")
			RemoteEventsFolder.Name = DIR_NAME_EVENTS
			RemoteEventsFolder.Parent = DIR
		end

		if not RemoteFunctionsFolder then
			RemoteFunctionsFolder = Instance.new("Folder")
			RemoteFunctionsFolder.Name = DIR_NAME_FUNCTIONS
			RemoteFunctionsFolder.Parent = DIR
		end

		for name, class in pairs(Remotes) do
			if class.ClassName == EventSymbol then
				if not REMOTES.EVENTS[name] then
					local remote = Instance.new("RemoteEvent")
					remote.Name = name
					remote.Parent = RemoteEventsFolder

					class:__Init(name, remote)
					REMOTES.EVENTS[name] = class
				end
			elseif class.ClassName == FunctionSymbol then
				if not REMOTES.FUNCTIONS[name] then
					local RequestRemote = Instance.new("RemoteEvent")
					RequestRemote.Name = "Request" .. name
					RequestRemote.Parent = RemoteFunctionsFolder

					local ResponseRemote = Instance.new("RemoteEvent")
					ResponseRemote.Name = "Response" .. name
					ResponseRemote.Parent = RemoteFunctionsFolder

					class:__Init(name, RequestRemote, ResponseRemote)
					REMOTES.FUNCTIONS[name] = class
				end
			else
				error(ERROR_INVALID_KIND:format(name))
			end
		end
	elseif RunService:IsClient() then
		RemoteEventsFolder = DIR:WaitForChild(DIR_NAME_EVENTS)
		RemoteFunctionsFolder = DIR:WaitForChild(DIR_NAME_FUNCTIONS)

		for name, class in pairs(Remotes) do
			if class.ClassName == EventSymbol then
				local remote = RemoteEventsFolder:WaitForChild(name)

				if not REMOTES.EVENTS[name] then
					class:__Init(name, remote)
					REMOTES.EVENTS[name] = class
				end
			elseif class.ClassName == FunctionSymbol then
				local RequestRemote = RemoteFunctionsFolder:WaitForChild("Request" .. name)
				local ResponseRemote = RemoteFunctionsFolder:WaitForChild("Response" .. name)

				if not REMOTES.FUNCTIONS[name] then
					class:__Init(name, RequestRemote, ResponseRemote)
					REMOTES.FUNCTIONS[name] = class
				end
			else
				error(ERROR_INVALID_KIND:format(name))
			end
		end
	end

	--[=[
		@function GetEvent
		@within Register
		@param name string -- The name of the remote event.
		@return RemoteEvent
	]=]
	local function GetEvent(name)
		local remote = REMOTES.EVENTS[name]
		if not remote then
			error(ERROR_NO_EVENT:format(name))
		end
		return remote
	end

	--[=[
		@function GetFunction
		@within Register
		@param name string -- The name of the remote function.
		@return RemoteFunction
	]=]
	local function GetFunction(name)
		local remote = REMOTES.FUNCTIONS[name]
		if not remote then
			error(ERROR_NO_FUNCTION:format(name))
		end
		return remote
	end

	return {
		GetEvent = GetEvent,
		GetFunction = GetFunction
	}
end

return Register