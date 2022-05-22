---
sidebar_position: 2
---

# Register
In order to use your remotes you have to register them. This is done via [Network.Register](/api/Register).

`Network.Register` takes in a dictionary in which the keys are the names of your remotes and the values are the corresponding remote classes.

You can create a remote class via [Network.Event.new](/api/RemoteEvent) or [Network.Function.new](/api/RemoteFunction).

For more information, see the [API Reference](/api/Register).

:::tip
In most cases, to keep them organized, you should register all of your remotes at once in a single file.
:::

Example:
```lua title="ReplicatedStorage/Remotes.lua"
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Packages.Network)

return Network.Register({
	Foo = Network.Event.new(),
	Bar = Network.Function.new()
})
```

## Registering Hooks
If you are using any [Hooks](/docs/Hooks), they need to be registered here as well. This can be done by [chaining](/docs/Chaining) them on to your remote classes.

Example:
```lua title="ReplicatedStorage/Remotes.lua"
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Packages.Network)

local Middleware = require(script.Parent.Middleware)
local Transformers = require(script.Parent.Transformers)

return Network.Register({
	Encoded = Network.Event.new()
				:inbound(Middleware.Logger, "Shared")
				:inbound(Transformers.Decode, "Shared")
				:outbound(Middleware.Logger, "Shared")
				:outbound(Transformers.Encode, "Shared")
				:warn(true)
})
```