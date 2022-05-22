---
sidebar_position: 1
---

# Introduction
Network is a declarative networking library initially based on [network](https://github.com/sircfenner/network) and influenced by [RbxNet](https://github.com/roblox-aurora/rbx-net).

It was made with the following goals in mind:
- Feature parity with Roblox's remote objects
- A familiar and consistent API to reduce friction
- Support for bidirectional mutable hooks
- Comprehensive Luau types (soon™)
- Promisified remotes
- Built-in, promise-based error handling
- Asynchronous Remote Functions
- Easy to integrate in to existing projects
- Expanded remote API for common methods ([FireClients](/api/RemoteEvent#FireClients), [FireClientsExcept](/api/RemoteEvent#FireClientsExcept))

All of these goals have been met in some capacity.

# Motivation
Creating, accessing, modifying, and using remotes in studio is easy. So why should a library do it for you?

Using a remote wrapper means that the source of truth for your remotes exists in your code instead of the data model. It also means that, typically, they're all defined in a single place, which is helpful for organization.

This is particularly advantageous when you're using a tool like [Rojo](https://rojo.space/). It allows you to check your remotes in to version control and it saves time switching back-and-forth between studio and your code editor.

It is also advantageous because it allows you to easily add extra behavior to your remotes through the form of [Hooks](/docs/Hooks).

# Drawbacks
This isn't a replacement for RbxNet. It was not made for TypeScript and so it doesn't have some of the advantages of RbxNet (like compilation transformers). The scope of this project is also fairly limited in comparison. It doesn't have support for messaging service. It doesn't have any built-in middleware. It doesn't have explicit namespacing. Because it was made to more closely emulate the native remote APIs, some of the RbxNet naming conventions are arguably more clear.

If you are using TypeScript, you should probably use RbxNet. If you're using Luau, it's mostly a matter of personal preference.

This library relies heavily on promises. It expects the user to be familiar with promises. While there are many advantages to this, if you aren't familiar with them, it may be confusing at first. So, in using this library, you should familiarize yourself with promises as well. <https://eryn.io/roblox-lua-promise/>