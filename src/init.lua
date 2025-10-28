--[=[
	@prop Register function
	@within Network

	[Registers](/api/Register) remote objects.
]=]

--[=[
	@prop Event [RemoteEvent]
	@within Network

	[RemoteEvent](/api/RemoteEvent) class.
]=]

--[=[
	@prop Unreliable [UnreliableRemoteEvent]
	@within Network

	[UnreliableRemoteEvent](/api/UnreliableRemoteEvent) class.
]=]

--[=[
	@prop Function [RemoteFunction]
	@within Network

	[RemoteFunction](/api/RemoteFunction) class.
]=]

--[=[
	@prop None Symbol
	@within Network

	Used to represent a `nil` value.
]=]

--[=[
	This is the access point for Network.

	@class Network
]=]

return {
	Register = require(script.Register),
	Event = require(script.lib.RemoteEvent),
	Unreliable = require(script.lib.UnreliableRemoteEvent),
	Function = require(script.lib.RemoteFunction),
	None = require(script.Symbols.None)
}