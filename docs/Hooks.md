---
sidebar_position: 5
---

# Hooks
It can be convenient to track or modify data being sent or received from remotes. Hooks allow you to do this by hooking in to remote logic at different stages in its life cycle. This is useful for things like logging, rate limiting, permission systems, type checking, serializing data, and more.

Hooks are functions with specific parameters that return a promise. They are very similar to middleware except they can mutate data and they work in both the inbound and outbound directions. It can be helpful to think of non-mutating hooks as [Middleware](#middleware) and mutating hooks as [Transformers](#transformers). Hooks are called in the order that they are defined. Inbound hooks are called just before any remote listeners are activated. Outbound hooks are called just before a remote is actually fired/invoked.

## Input
Hooks have at least three parameters: `Header`, `Config`, and `varargs`.

**Header** is a dictionary that looks like so:
```lua
{
	Remote = Remote_Instance, -- Literal instance of your remote
	Type = "Request" | "Response" -- This field will only appear for RemoteFunction hooks
}
```
**Config** is a single value (usually a dictionary) that is specified when you are defining your hook. This defaults to an empty table.

**varargs** (`...`) refers to the arguments received from the remote.

## Output
Hooks **must** return a [Promise](https://eryn.io/roblox-lua-promise/).

**Resolve** the Promise with your mutated data. If you resolve _nil_, it will use the current reference. If you want to overwrite your data with nil, resolve `Network.None`.

**Reject** the Promise if there is an error. This will abort the hook chain and the corresponding signal will never fire. You can catch this error with the promise returned by whatever method you used to Fire/Invoke the remote.

## Register
See [Register](./Getting%20Started/Register) for more information on registering hooks.

## Lifecycle
Understanding _when_ and _where_ hooks run is important. In general, inbound hooks run before data is received and outbound hooks run before data is sent. The specifics vary depending on the type of remote.

### Remote Event Pipeline
1. FireClient/FireServer is called via Network API. This returns a promise.
2. Outbound hooks are applied in order to corresponding arguments.
	- If this fails, it halts here and the rejection is sent up the chain to step 1
	- If this succeeds, it continues and the final version of the data is sent up the chain to step 1
3. FireClient/FireServer is actually called with new arguments via RemoteEvent instance.
4. RemoteEvent received.
5. Inbound hooks are applied in order to corresponding arguments.
	- If this fails, the event handler is thrown.
	- If this succeeds, the event handlers run.

### Remote Function Pipeline
Internally, Remote Functions use two RemoteEvent instances instead of a RemoteFunction instance. This is because native RemoteFunctions can yield indefinitely. One RemoteEvent, _Response_, is used to listen for invocations. The other, _Request_, is used to invoke.

1. InvokeServer/InvokeClient is called via Network API. This returns a promise.
2. Outbound hooks are applied in order to corresponding arguments.
	- If this fails, it halts here and the rejection is sent up the chain to step 1
3. _Request_ RemoteEvent instance is called with the new arguments.
4. RemoteEvent received.
5. If there is no OnClientInvoke/OnServerInvoke callback, the _Response_ RemoteEvent is fired with nil. Skip to step 9.
6. Inbound hooks are applied in order to corresponding arguments.
	- If this fails, it fails silently (unless Warn is true), and aborts the process
	- If this succeeds, OnClientInvoke/OnServerInvoke callback is called with (nil, ...new arguments)
7. Outbound hooks are applied in order to response from callback.
	- If this fails, it fails silently (unless Warn is true), and aborts the process
8. _Response_ RemoteEvent instance is called with the new response.
9. Response received.
10. Inbound hooks are applied in order to corresponding arguments.
	- If this fails, promise from step 1 is rejected with corresponding error.
	- If this succeeds, promise from step 1 is resolved with new response.

### Type Header
You may have noticed that for RemoteFunctions inbound and outbound hooks are called both when data is sent and when data is received. This means that they have to contextually handle different kinds of data depending on the stage of the lifecycle they are being called in. This is what the `Type` field of the header is for.

The Type is `Request` when:
- Outbound hooks are processing InvokeServer / InvokeClient
- Inbound hooks are processing data received from an invocation

The Type is `Response` when:
- Outbound hooks are processing data to be returned from an invocation
- Inbound hooks are processing data that has just been returned from an invocation

## Middleware
Middleware hooks are just hooks that don't mutate data. Some examples include:
- Logger
- Rate Limiter
- Type Checker
- Permission System

It may be helpful to define these in a `Middleware.lua` file.

```lua title="ReplicatedStorage/Middleware.lua"
local Promise = require(...Promise)

local function Logger(Header, Config, ...)
	print(("[%s]"):format(Header.Remote.Name), ...)
	return Promise.resolve()
end

return {
	Logger = Logger
}
```

## Transformers
Transformers are hooks that do mutate data. Some examples include:
- Instance Serializer
- Data Encoder

It may be helpful to define these in a `Transformers.lua` file.

```lua title="ReplicatedStorage/Transformers.lua"
local Promise = require(...Promise)
local base64 = require(...base64)

local function Encode(Header, Config, ...)
	local data = {...}
	return Promise.new(function(resolve, reject)
		for key, value in pairs(data) do
			if type(value) == "string" then
				data[key] = base64.encode(value)
			end
		end
		resolve(unpack(data))
	end)
end

return {
	Encode = Encode
}
```

## Example
RemoteEvent that encodes data before it's sent and decodes it when it's received.

```lua title="ReplicatedStorage/Transformers.lua"
local base64 = require(...base64)

local function Encode(Header, Config, ...)
	local data = {...}
	return Promise.new(function(resolve, reject)
		for key, value in pairs(data) do
			if type(value) == "string" then
				data[key] = base64.encode(value)
			end
		end
		resolve(unpack(data))
	end)
end

local function Decode(Header, Config, ...)
	local data = {...}
	return Promise.new(function(resolve, reject)
		for key, value in pairs(data) do
			if type(value) == "string" then
				data[key] = base64.decode(value)
			end
		end
		resolve(unpack(data))
	end)
end

return {
	Encode = Encode,
	Decode = Decode
}
```
```lua title="ReplicatedStorage/Remotes.lua"
local Middleware = require(...Middleware)
local Transformers = require(...Transformers)

return Network.Register({
	Encoded = Network.Event.new()
		:inbound(Middleware.Logger, "Shared")
		:inbound(Transformers.Decode, "Shared")
		:outbound(Middleware.Logger, "Shared")
		:outbound(Transformers.Encode, "Shared")
		:warn(true)
})
```
```lua title="StarterPlayerScripts/Main.lua"
local Remotes = require(...Remotes)
Remotes.GetEvent("Encoded"):FireServer("do re me fa", "so la ti do"):catch(warn)
```
```lua title="ServerScriptService/Main.lua"
local Remotes = require(...Remotes)
Remotes.GetEvent("Encoded").OnServerEvent:Connect(function(player, message)
	print("got", player, message)
	-- got player do re me fa so la ti do
end):catch(warn)
```