---
sidebar_position: 3
---
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

A RemoteEvent is designed to provide a one-way message between the server and clients, allowing Scripts to call code in LocalScripts and vice-versa. This message can be directed from one client to the server, from the server to a particular client, from the server to all clients, from the server to a list of clients, or from the server to all clients except some list of clients.

For more information, see the [API Reference](/api/RemoteEvent).

## Sending Data
<Tabs defaultValue="Server" groupId="Send" values={[
	{ label: 'Server', value: 'Server'},
	{ label: 'Client', value: 'Client'}
]}>

<TabItem value="Server">

```lua title="ServerScriptService/Main.lua"
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Remotes)

local Player = ...

local Foo = Remotes.GetEvent("Foo")
Foo:FireClient(Player, "bar", "baz"):catch(warn)
```

</TabItem>

<TabItem value="Client">

```lua title="StarterPlayerScripts/Main.lua"
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Remotes)

local Foo = Remotes.GetEvent("Foo")
Foo:FireServer("bar", "baz"):catch(warn)
```

</TabItem>

</Tabs>

Firing a Remote Event returns a promise. This is because hooks can fail, and if they do, it is important to [catch](https://eryn.io/roblox-lua-promise/api/Promise#catch) them. If you have a hook that mutates data in any way, you can use [andThen](https://eryn.io/roblox-lua-promise/api/Promise#andThen) to grab a snapshot of the data that is ultimately sent. If you're not using any hooks, you don't need to chain anything.

## Receiving Data
<Tabs defaultValue="Server" groupId="Receive" values={[
	{ label: 'Server', value: 'Server' },
	{ label: 'Client', value: 'Client' }
]}>

<TabItem value="Server">

```lua title="ServerScriptService/Main.lua"
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Remotes)

local Foo = Remotes.GetEvent("Foo")
Foo:FireAllClients("bar")

Foo.OnServerEvent:Connect(function(value)
	print(value)
	-- qux
end):catch(warn)
```

</TabItem>

<TabItem value="Client">

```lua title="StarterPlayerScripts/Main.lua"
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Remotes)

local Foo = Remotes.GetEvent("Foo")
Foo:FireServer("qux")

Foo.OnClientEvent:Connect(function(value)
	print(value)
	-- bar
end):catch(warn)
```

</TabItem>

</Tabs>

Inbound hooks are fired on event as well. Events can catch hook errors via `catch`. If you're not using any hooks, you don't need to include catch.