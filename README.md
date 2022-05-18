## Network
Declarative networking library. Based on [Network](https://github.com/sircfenner/network) (soo original). Not finished.

## Motivation
Using a remote wrapper means that the source of truth for your remotes exists in your code instead of the data model. This helps keep things organized and it's easier than manually adding them in Studio or with Rojo.

The core API is designed to look like the default remote APIs in order to reduce friction.

Other advantages include:
- Middleware & Transformers
- Luau Types (soon™)
- Asynchronous Remote Functions
- Promisified Remote Functions
- An expanded core API (`FireClients`, `FireClientsExcept`)

## Installation

### With Wally
```toml
[dependencies]
Network = "call23re/network@1.1.0"
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

## Middleware
Middleware is just a function that returns a promise. The function is called just before any Remote Event or Function listeners are activated. 

Middleware functions have three parameters: `Header`, `Config`, and `args`.

**Header** is a dictionary that looks like so:
```lua
{ Remote = Remote_Instance } -- Literal instance of your RemoteEvent
```
**Config** is a value (usually a dictionary) that is specified when you are defining your middleware.

**args** is a variadic parameter (`...`) that refers to the arguments received from the RemoteEvent.

Middleware can mutate args however it wants. Other middleware down the chain will receive the mutated arguments when you resolve them. These arguments are eventually passed through to the corresponding listener.

**Resolve** the Promise returned by middleware with your new args. If you resolve _nil_, it will use the current reference to args. If you want to overwrite args with nil, resolve `Network.None`.

**Reject** the Promise if there is an error. This will abort the middleware chain and the corresponding signal will never fire.

**Define** middleware in a central _Remotes_ file. It must be defined per remote as a parameter of your remote class definition. When defining your middleware, you must include your middleware function and the context that it runs in (Server, Client, or Shared) in the form of a table. This is where you can also optionally include a `Config` value.

**Middleware is called in the order that it is defined.**

Example:
```lua
-- ReplicatedStorage/Middleware
local function Logger(Header, Config, ...)
	print(("[%s]"):format(Header.Remote.Name), ...)
	return Promise.resolve()
end

return {
	Logger = Logger
}
```
```lua
-- ReplicatedStorage/Remotes
local Middleware = require(...Middleware)

return Network.Register({
	FooEvent = Network.Event.new({
		Warn = true, -- optional flag, warns caught rejections
		Middleware = {
			{Middleware.Logger, "Shared"},
			{Middleware.RateLimit, "Server", {
				Max = 10
			}} -- the third entry is passed in as Config
		}
	}),
	BarFunction = Network.Function.new({
		Warn = true,
		Middleware = {
			{Middleware.Logger, "Client"}
		}
	})
})
```

## Transformers
Transformers are the same as Middleware, but they work in the outbound direction instead. They run just before you fire or invoke a remote.

Transformers have an extra header value for Remote Functions: `Type`. It can be either "Request" or "Response". Request is when an `Invoke` (InvokeServer, InvokeClient) method is called. Response is when the server/client is responding to an invocation.

Transformers are defined in the same way Middleware is. Transformers are _also_ called in the order that they are defined.

Example:

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

return {
	Encode = Encode
}

-- ReplicatedStorage/Middleware
local base64 = require(...base64)

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
	Decode = Decode
}
```
```lua
-- ReplicatedStorage/Remotes
local Middleware = require(...Middleware)
local Transformers = require(...Transformers)

return Network.Register({
	Encoded = Network.Event.new({
		Warn = true,
		Middleware = {
			{Middleware.Logger, "Shared"},
			{Middleware.Decode, "Shared"}
		},
		Transformers = {
			{Middleware.Logger, "Shared"}, -- middleware and transformers that don't care about Type are interchangable
			{Transformers.Encode, "Shared"}
		}
	})
})
```
```lua
-- StarterPlayerScripts/Main
local Remotes = require(...Remotes)
Remotes.GetEvent("Encoded"):FireServer("do re me fa", "so la ti do")
```
```lua
-- ServerScriptService/Main
local Remotes = require(...Remotes)

Remotes.GetEvent("Encoded").OnServerEvent:Connect(function(player, message)
	print("got", player, message)
	-- got player do re me fa so la ti do
end)
```

Middleware and Transformers still need some work and further testing.