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
Network = "call23re/network@0.1.0"
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
Middleware is just a function that returns a promise. The function is called (in order) just before any Remote Event or Function listeners are activated. 

Middleware functions have two arguments: `Remote` and `args`. **Remote** refers to the literal RemoteEvent / RemoteFunction instance being called. **args** refers to the arguments that were sent with that remote.

Middleware can mutate these arguments however it wants. Other middleware down the chain will receive the mutated arguments as well. These arguments are eventually passed through to the corresponding listener.

The promise returned by the middleware must either resolve or reject. Resolve should _only_ resolve your `args` or nil. If you resolve nil, `args` will not be overwritten with nil. If you reject the promise, the middleware chain will abort and the signal will never fire. Resolve doesn't currently support variadic parameters.

Middleware is defined in your central _Remotes_ file. It must be defined per remote as a parameter of your remote class definition. When defining your middleware, you must include your middleware function and the context that it runs in (Server, Client, or Shared) in the form of a table. In the future this will be somewhat implicit.

Example:
```lua
-- ReplicatedStorage/Middleware
local function Logger(remote, args)
	print(("[%s]"):format(remote.Name), unpack(args))
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
			{Middleware.RateLimit, "Server"}
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
Transformers are the same as Middleware, but they work in the outbound direction instead. They run just before you fire a remote.

Transformers have an extra argument for Remote Functions: `Type`. **Type** is passed in as the third parameter after `Remote` and `args`. It can be either "Request" or "Response". Request is when an `Invoke` (InvokeServer, InvokeClient) method is called. Response is when the server/client is responding to an invocation. This will be changed to be more idiomatic in the future.

Transformers are defined in the same way Middleware is.

Example:

RemoteEvent that encodes data before it's sent and decodes it when it's received.
```lua
-- ReplicatedStorage/Transformers
local base64 = require(...base64)

local function Encode(remote, data)
	return Promise.new(function(resolve, reject)
		for key, value in pairs(data) do
			if type(value) == "string" then
				data[key] = base64.encode(value)
			end
		end
		resolve(data)
	end)
end

return {
	Encode = Encode
}

-- ReplicatedStorage/Middleware
local base64 = require(...base64)

local function Decode(remote, data)
	return Promise.new(function(resolve, reject)
		for key, value in pairs(data) do
			if type(value) == "string" then
				data[key] = base64.decode(value)
			end
		end
		resolve(data)
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
			{Middleware.Decode, "Shared"}
		},
		Transformers = {
			{Transformers.Encode, "Shared"}
		}
	})
})
```
```lua
-- StarterPlayerScripts/Main
local Remotes = require(...Remotes)
Remotes.GetEvent("Encoded"):FireServer("do re me fa so la ti do")
```
```lua
-- ServerScriptService/Main
local Remotes = require(...Remotes)

Remotes.GetEvent("Encoded").OnServerEvent:Connect(function(player, message)
	print("got", player, message)
	-- got player do re me fa so la ti do
end)
```

Middleware and Transformers still need some work and further testing. In the future Middleware and Transformers will support optional configuration objects.