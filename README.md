## Network
Declarative networking library. Based on [Network](https://github.com/sircfenner/network). Not finished.

## Motivation
Using a remote wrapper means that the source of truth for your remotes exists in your code instead of the data model. This helps keep things organized and it's easier than manually adding them in Studio or with Rojo.

The core API is designed to look like the default remote APIs in order to reduce friction.

Other advantages include:
- Hooks
- Luau Types (soon™)
- Asynchronous Remote Functions
- Promisified Remotes
- An expanded core API (`FireClients`, `FireClientsExcept`)

## Installation

### With Wally
```toml
[dependencies]
Network = "call23re/network@2.0.0"
```

## Usage
Basic Examples:
```lua
-- ReplicatedStorage/Remotes
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Packages.Network)

return Network.Register({
	TestEvent = Network.Event.new(),
	TestFunction = Network.Function.new(),
})
```

```lua
-- StarterPlayerScripts/Main
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Remotes)

Remotes.GetEvent("TestEvent"):FireServer(1, 2, 3)

local TestFunction = Remotes.GetFunction("TestFunction")

TestFunction:InvokeServer(1, 2, 3)
	:andThen(function(a, b, c)
		assert(a == 2)
		assert(b == 3)
		assert(c == 4)
		print(a, b, c)
	end)
	:catch(warn)

-- or
local ok, a, b, c = TestFunction:InvokeServer(1, 2, 3):await()
```

```lua
-- ServerScriptService/Main
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Remotes)

Remotes.GetEvent("TestEvent").OnServerEvent:Connect(function(Player, a, b, c)
	print("Received", Player, a, b, c)
end)

Remotes.GetFunction("TestFunction").OnServerInvoke = function(Player, a, b, c)
	return a + 1, b + 1, c + 1
end
```

## Hooks
It can be convenient to track or modify data being sent or received from remotes. Hooks allow you to do this by hooking in to remote logic at different stages in its life cycle. This is useful for things like logging, rate limiting, permission systems, type checking, serializing data, and more.

Hooks are very similar to middleware except they can mutate data and they work in both the inbound and outbound directions. It can be helpful to think of non-mutating hooks as _Middleware_ and mutating hooks as _Transformers_. Hooks are functions with specific parameters that return a promise. Hooks are called in the order that they are defined. Inbound hooks are called just before any remote listeners are activated. Outbound hooks are called just before a remote is actually fired/invoked.

### Structure
Hooks have at least three parameters: `Header`, `Config`, and `varargs`.

**Header** is a dictionary that looks like so:
```lua
{
	Remote = Remote_Instance, -- Literal instance of your RemoteEvent
	Type = "Request" | "Response" -- This field will only appear for outbound hooks
}
```
**Config** is a single value (usually a dictionary) that is specified when you are defining your hook. This defaults to an empty table.

**varargs** (`...`) refers to the arguments received from the RemoteEvent.

### Promise
Hooks **must** return a Promise.

**Resolve** the Promise with your mutated data. If you resolve _nil_, it will use the current reference. If you want to overwrite your data with nil, resolve `Network.None`.

**Reject** the Promise if there is an error. This will abort the hook chain and the corresponding signal will never fire. You can catch this error with the promise returned by whatever method you used to Fire/Invoke the remote.

## Register
Define and register your remotes and hooks in a central _Remotes_ file via `Network.Register`.

`Network.Register` registers a table of remotes.

Remotes are created via `Network.Event.new()` or `Network.Function.new()`.

Add hooks to your remotes by chaining them on via `Remote:inbound(...)` and `Remote:outbound(...)`. The order that you chain them is the order that they will run. Both methods have three arguments: `Hook`, `Context`, `Config`.

**Hook** is the corresponding hook function.

**Context** is the context that the hook runs in: Server, Client, or Shared.

**Config** is extra data that is passed in to the hook function.

```lua
-- ReplicatedStorage/Remotes
local Middleware = require(...Middleware)

return Network.Register({
	FooEvent = Network.Event.new()
		:inbound(Middleware.Logger, "Shared")
		:inbound(Middleware.RateLimit, "Server", {Max = 10}) -- the third entry is passed in as Config
		:warn(true), -- optional flag, warns caught rejections
	BarFunction = Network.Function.new()
		:inbound(Middleware.Logger, "Client")
		:warn(true)
})
```

You can now access these remotes via `Remotes.GetEvent(name)` and `Remotes.GetFunction(name)`
```lua
-- ServerScriptService/Main
local Remotes = require(game.ReplicatedStorage.Remotes)
local FooEvent = Remotes.GetEvent("FooEvent")
local BarFunction = Remotes.GetFunction("BarFunction")
```

### Extended Example
RemoteEvent that encodes data before it's sent and decodes it when it's received.
```lua
-- ReplicatedStorage/Transformers
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
```lua
-- ReplicatedStorage/Remotes
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
```lua
-- StarterPlayerScripts/Main
local Remotes = require(...Remotes)
Remotes.GetEvent("Encoded"):FireServer("do re me fa", "so la ti do"):catch(warn)
```
```lua
-- ServerScriptService/Main
local Remotes = require(...Remotes)
Remotes.GetEvent("Encoded").OnServerEvent:Connect(function(player, message)
	print("got", player, message)
	-- got player do re me fa so la ti do
end)
```