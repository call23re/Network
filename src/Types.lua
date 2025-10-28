local Promise = require(script.Parent.Parent.Promise)

export type Signal<T...> = {
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> RBXScriptConnection,
	Once: (self: Signal<T...>, callback: (T...) -> ()) -> RBXScriptConnection,
	Wait: (self: Signal<T...>) -> T...
}

export type RemoteEvent<T...> = {
	FireServer: (self: RemoteEvent<T...>, T...) -> (),
	FireClient: (self: RemoteEvent<T...>, player: Player, T...) -> (),
	FireClients: (self: RemoteEvent<T...>, players: {Player}, T...) -> (),
	FireClientsExcept: (self: RemoteEvent<T...>, players: {Player}, T...) -> (),
	FireAllClients: (self: RemoteEvent<T...>, T...) -> (),
	OnClientEvent: Signal<T...>,
	OnServerEvent: Signal<(Player, T...)>,
}

export type UnreliableRemoteEvent<T...> = {
	FireServer: (self: UnreliableRemoteEvent<T...>, T...) -> (),
	FireClient: (self: UnreliableRemoteEvent<T...>, player: Player, T...) -> (),
	FireClients: (self: UnreliableRemoteEvent<T...>, players: {Player}, T...) -> (),
	FireClientsExcept: (self: UnreliableRemoteEvent<T...>, players: {Player}, T...) -> (),
	FireAllClients: (self: UnreliableRemoteEvent<T...>, T...) -> (),
	OnClientEvent: Signal<T...>,
	OnServerEvent: Signal<(Player, T...)>,
}

export type RemoteFunction<T..., U...> = {
	InvokeClient: (self: RemoteFunction<T..., U...>, T...) -> typeof(Promise.new()),
	InvokeServer: (self: RemoteFunction<T..., U...>, T...) -> typeof(Promise.new()),
	OnClientInvoke: (T...) -> U...,
	OnServerInvoke: (Player, T...) -> U...
}

return {}