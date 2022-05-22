---
sidebar_position: 4
---
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

A RemoteFunction is used to create in-game APIs that both the client and the server can use to communicate with each other. A RemoteFunction can be invoked (called) to do a certain action and return the results. If you don't need a response, use a [RemoteEvent](/docs/Getting%20Started/Remote%20Events) instead.

For more information, see the [API Reference](/api/RemoteFunction).

:::note
While native Roblox RemoteFunctions will yield, `Network` RemoteFunctions are asynchronous. This is because they use RemoteEvents under the hood. RemoteFunction invocations are promise-based, so if you prefer to yield, use [Promise:await](https://eryn.io/roblox-lua-promise/api/Promise#await).
:::

## Invoking the Server
<Tabs defaultValue="Server" groupId="Server" values={[
	{ label: 'Server', value: 'Server'},
	{ label: 'Client', value: 'Client'}
]}>

<TabItem value="Server">

```lua title="ServerScriptService/Main.lua"
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Remotes)

local State = {...}

local GetState = Remotes.GetFunction("GetState")
GetState.OnClientInvoke = function() return State end
```

</TabItem>

<TabItem value="Client">

```lua title="StarterPlayerScripts/Main.lua"
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Remotes)

local GetState = Remotes.GetFunction("GetState")
local ok, State = GetState:InvokeServer():await()
```

</TabItem>
</Tabs>

## Invoking the Client
<Tabs defaultValue="Server" groupId="Client" values={[
	{ label: 'Server', value: 'Server'},
	{ label: 'Client', value: 'Client'}
]}>

<TabItem value="Server">

```lua title="ServerScriptService/Main.lua"
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Remotes)

local Player = ...

local Ready = Remotes.GetFunction("Ready")
Ready:InvokeClient(Player)
		:andThen(function(isReady)
			assert(type(isReady) == "boolean")
			print(Player, "is", isReady and "ready" or "not ready")
		end)
		:catch(warn)
```

</TabItem>

<TabItem value="Client">

```lua title="StarterPlayerScripts/Main.lua"
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Remotes)

local Ready = Remotes.GetFunction("Ready")
Ready.OnServerInvoke = function()
	return math.random() > 0.5
end
```

</TabItem>
</Tabs>

:::warning
Even though you _can_ invoke the client, the client can still wait indefinitely to respond. While this won't yield, you still need some logic to clean up the promise under certain circumstances (like if the player leaves the game). Generally, it is bad practice to invoke the client.
:::