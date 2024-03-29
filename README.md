## Network
Declarative networking library. Initially based on [network](https://github.com/sircfenner/network).

**[View Docs](https://call23re.github.io/Network/docs/intro)**

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
Network = "call23re/network@2.2.1"
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