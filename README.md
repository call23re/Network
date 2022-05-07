## Network
Networking library. Based on [Network](https://github.com/sircfenner/network) (soo original). Not finished.

## Motivation
Using a remote wrapper means that the source of truth for your remotes exists in your code instead of the data model. This helps keep things organized and it's easier than manually adding them in Studio or with Rojo.

The core API is designed to look like the default remote APIs in order to reduce friction.

Other advantages include:
- Middleware
- Asynchronous Remote Functions
- Promisified Remote Functions
- An expanded core API (`FireClients`, `FireClientsExcept`)

## Usage
```lua
-- ReplicatedStorage/Remotes
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Packages.Network)

return Network.Register({
	TestEvent = Network.Event,
	TestFunction = Network.Function,
})
```

```lua
-- StarterPlayerScripts/Main
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Remotes)

Remotes.GetEvent("TestEvent"):FireServer(1, 2, 3)

Remotes.GetFunction("TestFunction"):InvokeServer(1, 2, 3)
	:andThen(function(a, b, c)
		assert(a == 2)
		assert(b == 3)
		assert(c == 4)
		print(a, b, c)
	end)
	:catch(warn)
```

```lua
-- ServerScriptService/Main
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Remotes)

Remotes.GetEvent("TestEvent").OnServerEvent:Connect(function(player, a, b, c)
	print("Received", player, a, b, c)
end)

Remotes.GetFunction("TestFunction").OnServerInvoke = function(Player, a, b, c)
	return a + 1, b + 1, c + 1
end
```

todo
- Middleware
- Complete Promise support
- Value Objects