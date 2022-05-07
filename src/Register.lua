local RunService = game:GetService("RunService")

local lib = script.Parent.lib
local Symbols = script.Parent.Symbols

local Event = require(lib.RemoteEvent)
local Function = require(lib.RemoteFunction)

local EventSymbol = require(Symbols.Event)
local FunctionSymbol = require(Symbols.Function)

local DIR = script.Parent
local DIR_NAME_EVENTS = "RemoteEvents"
local DIR_NAME_FUNCTIONS = "RemoteFunctions"

local ERR_NO_EVENT = "RemoteEvent `%s` was not registered"
local ERR_NO_FUNCTION = "RemoteFunction `%s` was not registered"
local ERR_INVALID_KIND = "Invalid remote type registered for key `%s`"

local REMOTES = {
	EVENTS = {},
	FUNCTIONS = {}
}

local function Register(Remotes)
	local remoteEventsFolder
	local remoteFunctionsFolder

	if RunService:IsServer() then
		remoteEventsFolder = Instance.new("Folder")
		remoteEventsFolder.Name = DIR_NAME_EVENTS
		remoteEventsFolder.Parent = DIR
		remoteFunctionsFolder = Instance.new("Folder")
		remoteFunctionsFolder.Name = DIR_NAME_FUNCTIONS
		remoteFunctionsFolder.Parent = DIR
	else
		remoteEventsFolder = DIR:WaitForChild(DIR_NAME_EVENTS)
		remoteFunctionsFolder = DIR:WaitForChild(DIR_NAME_FUNCTIONS)
	end

	if RunService:IsServer() then
		for name, class in pairs(Remotes) do
			if class.Type == EventSymbol then
				local remote = Instance.new("RemoteEvent")
				remote.Name = name
				remote.Parent = remoteEventsFolder

				if not REMOTES.EVENTS[name] then
					class:Init(name, remote)
					REMOTES.EVENTS[name] = class
				end
			elseif class.Type == FunctionSymbol then
				local RequestRemote = Instance.new("RemoteEvent")
				RequestRemote.Name = "Request" .. name
				RequestRemote.Parent = remoteFunctionsFolder

				local ResponseRemote = Instance.new("RemoteEvent")
				ResponseRemote.Name = "Response" .. name
				ResponseRemote.Parent = remoteFunctionsFolder

				if not REMOTES.FUNCTIONS[name] then
					class:Init(name, RequestRemote, ResponseRemote)
					REMOTES.FUNCTIONS[name] = class
				end
			else
				error(string.format(ERR_INVALID_KIND, name))
			end
		end
	else
		for name, class in pairs(Remotes) do
			if class.Type == EventSymbol then
				local remote = remoteEventsFolder:WaitForChild(name)

				if not REMOTES.EVENTS[name] then
					class:Init(name, remote)
					REMOTES.EVENTS[name] = class
				end
			elseif class.Type == FunctionSymbol then
				local RequestRemote = remoteFunctionsFolder:WaitForChild("Request" .. name)
				local ResponseRemote = remoteFunctionsFolder:WaitForChild("Response" .. name)

				if not REMOTES.FUNCTIONS[name] then
					class:Init(name, RequestRemote, ResponseRemote)
					REMOTES.FUNCTIONS[name] = class
				end
			else
				error(string.format(ERR_INVALID_KIND, name))
			end
		end
	end

	local function GetEvent(name)
		local remote = REMOTES.EVENTS[name]
		if not remote then
			error(string.format(ERR_NO_EVENT, name))
		end
		return remote
	end

	local function GetFunction(name)
		local remote = REMOTES.FUNCTIONS[name]
		if not remote then
			error(string.format(ERR_NO_FUNCTION, name))
		end
		return remote
	end

	return {
		GetEvent = GetEvent,
		GetFunction = GetFunction
	}
end

return Register