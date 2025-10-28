local RunService = game:GetService("RunService")

local Symbols = script.Parent.Symbols

local Types = require(script.Parent.Types)

local EventSymbol = require(Symbols.Event)
local UnreliableSymbol = require(Symbols.Unreliable)
local FunctionSymbol = require(Symbols.Function)

local DIR = script.Parent
local DIR_NAME_EVENTS = "RemoteEvents"
local DIR_NAME_UNRELIABLE_EVENTS = "UnreliableRemoteEvents"
local DIR_NAME_FUNCTIONS = "RemoteFunctions"

local ERROR_NO_EVENT = "RemoteEvent `%s` was not registered" :: any
local ERROR_NO_RELIABLE = "UnreliableRemoteEvent `%s` was not registered" :: any
local ERROR_NO_FUNCTION = "RemoteFunction `%s` was not registered" :: any
local ERROR_INVALID_KIND = "Invalid remote type registered for key `%s`" :: any

local REMOTES = {
	EVENTS = {},
	UNRELIABLE_EVENTS = {},
	FUNCTIONS = {}
}

type Remotes = {
	[string]: {
		ClassName: string,
		__Init: (self: any, string, (RemoteEvent | UnreliableRemoteEvent), RemoteEvent?) -> ()
	}
}

--[=[
	Registers a dictionary of remotes where the key is the name of the remote and the value is a RemoteEvent, UnreliableRemoteEvent, or RemoteFunction class.

	```lua
		-- ReplicatedStorage/Remotes.lua
		local Network = require(...Network)
		return Network.Register({
			FooEvent = Network.Event.new(),
			BarEvent = Network.Unreliable.new(),
			BazFunction = Network.Function.new()
		})
	```

	@class Register
]=]
local function Register(Remotes: Remotes)
	local RemoteEventsFolder = nil
	local UnreliableEventsFolder = nil
	local RemoteFunctionsFolder = nil

	if RunService:IsServer() then

		RemoteEventsFolder = DIR:FindFirstChild(DIR_NAME_EVENTS)
		UnreliableEventsFolder = DIR:FindFirstChild(DIR_NAME_UNRELIABLE_EVENTS)
		RemoteFunctionsFolder = DIR:FindFirstChild(DIR_NAME_FUNCTIONS)

		if not RemoteEventsFolder then
			RemoteEventsFolder = Instance.new("Folder")
			RemoteEventsFolder.Name = DIR_NAME_EVENTS
			RemoteEventsFolder.Parent = DIR
		end

		if not UnreliableEventsFolder then
			UnreliableEventsFolder = Instance.new("Folder")
			UnreliableEventsFolder.Name = DIR_NAME_UNRELIABLE_EVENTS
			UnreliableEventsFolder.Parent = DIR
		end

		if not RemoteFunctionsFolder then
			RemoteFunctionsFolder = Instance.new("Folder")
			RemoteFunctionsFolder.Name = DIR_NAME_FUNCTIONS
			RemoteFunctionsFolder.Parent = DIR
		end

		for name, class in Remotes do
			if class.ClassName == EventSymbol then
				if not REMOTES.EVENTS[name] then
					local remote = Instance.new("RemoteEvent")
					remote.Name = name
					remote.Parent = RemoteEventsFolder

					class:__Init(name, remote)
					REMOTES.EVENTS[name] = class
				end
			elseif class.ClassName == UnreliableSymbol then
				if not REMOTES.UNRELIABLE_EVENTS[name] then
					local remote = Instance.new("UnreliableRemoteEvent")
					remote.Name = name
					remote.Parent = UnreliableEventsFolder

					class:__Init(name, remote)
					REMOTES.UNRELIABLE_EVENTS[name] = class
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
		UnreliableEventsFolder = DIR:WaitForChild(DIR_NAME_UNRELIABLE_EVENTS)
		RemoteFunctionsFolder = DIR:WaitForChild(DIR_NAME_FUNCTIONS)

		for name, class in Remotes do
			if class.ClassName == EventSymbol then
				local remote = RemoteEventsFolder:WaitForChild(name) :: RemoteEvent

				if not REMOTES.EVENTS[name] then
					class:__Init(name, remote)
					REMOTES.EVENTS[name] = class
				end
			elseif class.ClassName == UnreliableSymbol then
				local remote = UnreliableEventsFolder:WaitForChild(name) :: UnreliableRemoteEvent

				if not REMOTES.UNRELIABLE_EVENTS[name] then
					class:__Init(name, remote)
					REMOTES.UNRELIABLE_EVENTS[name] = class
				end
			elseif class.ClassName == FunctionSymbol then
				local RequestRemote = RemoteFunctionsFolder:WaitForChild("Request" .. name) :: RemoteEvent
				local ResponseRemote = RemoteFunctionsFolder:WaitForChild("Response" .. name) :: RemoteEvent

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
	local function GetEvent(name: string)
		local remote = REMOTES.EVENTS[name]
		if not remote then
			error(ERROR_NO_EVENT:format(name))
		end
		return remote :: Types.RemoteEvent<any>
	end

	--[=[
		@function GetUnreliable
		@within Register
		@param name string -- The name of the unreliable remote event.
		@return UnreliableRemoteEvent
	]=]
	local function GetUnreliable(name: string)
		local remote = REMOTES.UNRELIABLE_EVENTS[name]
		if not remote then
			error(ERROR_NO_RELIABLE:format(name))
		end
		return remote :: Types.UnreliableRemoteEvent<any>
	end

	--[=[
		@function GetFunction
		@within Register
		@param name string -- The name of the remote function.
		@return RemoteFunction
	]=]
	local function GetFunction<T..., U...>(name: string)
		local remote = REMOTES.FUNCTIONS[name]
		if not remote then
			error(ERROR_NO_FUNCTION:format(name))
		end
		return remote :: Types.RemoteFunction<T..., U...>
	end

	return {
		GetEvent = GetEvent,
		GetUnreliable = GetUnreliable,
		GetFunction = GetFunction
	}
end

return Register