## Network
Networking library. Based on [Network](https://github.com/sircfenner/network) (soo original). Not finished.

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
- Proper Promise support
- Value Objects