local RunService = game:GetService("RunService")

local Objects = script.Parent.Objects
local Symbols = script.Parent.Symbols

local Event = require(Objects.RemoteEvent)
local Function = require(Objects.RemoteFunction)

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
		for name, kind in pairs(Remotes) do
			if kind == EventSymbol then
				local remote = Instance.new("RemoteEvent")
				remote.Name = name
				remote.Parent = remoteEventsFolder

				if not REMOTES.EVENTS[name] then
					local object = Event.new(name, remote)
					REMOTES.EVENTS[name] = object
				end
			elseif kind == FunctionSymbol then
				local remote = Instance.new("RemoteEvent")
				remote.Name = name
				remote.Parent = remoteFunctionsFolder

				if not REMOTES.FUNCTIONS[name] then
					local object = Function.new(name, remote)
					REMOTES.FUNCTIONS[name] = object
				end
			else
				error(string.format(ERR_INVALID_KIND, name))
			end
		end
	else
		for name, kind in pairs(Remotes) do
			if kind == EventSymbol then
				local remote = remoteEventsFolder:WaitForChild(name)

				if not REMOTES.EVENTS[name] then
					local object = Event.new(name, remote)
					REMOTES.EVENTS[name] = object
				end
			elseif kind == FunctionSymbol then
				local remote = remoteFunctionsFolder:WaitForChild(name)

				if not REMOTES.FUNCTIONS[name] then
					local object = Function.new(name, remote)
					REMOTES.FUNCTIONS[name] = object
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