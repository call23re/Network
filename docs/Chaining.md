---
sidebar_position: 6
---

In the context of this library, chaining is when methods return self or when promises return new promises.

You use chaining to apply hooks when registering remotes.

```lua
Encoded = Network.Event.new()
				:inbound(Middleware.Logger, "Shared")
				:inbound(Transformers.Decode, "Shared")
				:outbound(Middleware.Logger, "Shared")
				:outbound(Transformers.Encode, "Shared")
				:warn(true)
```

Because `inbound`, `outbound`, and `warn` return `self`, you can call them in succession in a single statement.

You also use chaining in any case in which promises are used.
```lua
TestFunction:InvokeServer(1, 2, 3)
	:andThen(function(a, b, c)
		assert(a == 2)
		assert(b == 3)
		assert(c == 4)
		print(a, b, c)
	end)
	:catch(warn)
```
See: <https://eryn.io/roblox-lua-promise/docs/Tour#chaining> for more information.

It's also used in a special case when catching hook errors from connections. In this example, `:catch` is chained on to `:Connect`.
```lua
Foo.OnServerEvent:Connect(function(value)
	print(value)
end):catch(warn)
```