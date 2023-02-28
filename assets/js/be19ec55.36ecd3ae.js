"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[943],{22328:e=>{e.exports=JSON.parse('{"functions":[{"name":"OnClientInvoke","desc":"Called when the client is invoked by [RemoteFunction:InvokeClient].","params":[{"name":"...","desc":"","lua_type":"any"}],"returns":[],"function_type":"static","realm":["Client"],"source":{"line":33,"path":"src/lib/RemoteFunction.lua"}},{"name":"OnServerInvoke","desc":"Called when the server is invoked by [RemoteFunction:InvokeServer].","params":[{"name":"Player","desc":"","lua_type":"Player"},{"name":"...","desc":"","lua_type":"any"}],"returns":[],"function_type":"static","realm":["Server"],"source":{"line":41,"path":"src/lib/RemoteFunction.lua"}},{"name":"inbound","desc":"This function is used to hook into the RemoteFunction in two places: before an invocation callback is called and before an invocation response is returned. All inbound hooks are called in the order they are added.\\n\\n\\n:::caution\\nThis function should only be used when you are registering your remotes!\\n:::","params":[{"name":"hook","desc":"The function to be called when the RemoteFunction receives a request.","lua_type":"function"},{"name":"context","desc":"The context in which the hook should be called.","lua_type":"\\"Shared\\" | \\"Server\\" | \\"Client\\""},{"name":"config","desc":"An optional configuration value to be passed to the hook.","lua_type":"any"}],"returns":[{"desc":"Returns self.","lua_type":"RemoteFunction"}],"function_type":"method","source":{"line":73,"path":"src/lib/RemoteFunction.lua"}},{"name":"outbound","desc":"This function is used to hook into the RemoteFunction in two places: after an invocation callback is called and before the remote is invoked. All outbound hooks are called in the order they are added.\\n\\n\\n:::caution\\nThis function should only be used when you are registering your remotes!\\n:::","params":[{"name":"hook","desc":"The function to be called when the RemoteFunction receives a request.","lua_type":"function"},{"name":"context","desc":"The context in which the hook should be called.","lua_type":"\\"Shared\\" | \\"Server\\" | \\"Client\\""},{"name":"config","desc":"An optional configuration value to be passed to the hook.","lua_type":"any"}],"returns":[{"desc":"Returns self.","lua_type":"RemoteFunction"}],"function_type":"method","source":{"line":98,"path":"src/lib/RemoteFunction.lua"}},{"name":"warn","desc":"This function is used to set a flag that will automatically catch and warn errors thrown by hooks.\\n\\n\\n:::caution\\nThis function should only be used when you are registering your remotes!\\n:::","params":[{"name":"value","desc":"Defaults to false.","lua_type":"boolean"}],"returns":[{"desc":"Returns self.","lua_type":"RemoteFunction"}],"function_type":"method","source":{"line":121,"path":"src/lib/RemoteFunction.lua"}},{"name":"InvokeClient","desc":"Calls the method bound to RemoteFunction by RemoteFunction.OnClientInvoke for the given Player.\\n\\n\\n\\n\\t\\t","params":[{"name":"Client","desc":"The player to invoke.","lua_type":"Player"},{"name":"...","desc":"The arguments to pass to the invocation.","lua_type":"any"}],"returns":[{"desc":"Returns a promise that resolves when the remote has been invoked or fails if any hooks failed.","lua_type":"Promise"}],"function_type":"method","realm":["Server"],"source":{"line":209,"path":"src/lib/RemoteFunction.lua"}},{"name":"InvokeServer","desc":"Calls the method bound to RemoteFunction by RemoteFunction.OnServerInvoke.\\n\\n\\n\\n\\t\\t","params":[{"name":"...","desc":"The arguments to pass to the invocation.","lua_type":"any"}],"returns":[{"desc":"Returns a promise that resolves when the remote has been invoked or fails if any hooks failed.","lua_type":"Promise"}],"function_type":"method","realm":["Client"],"source":{"line":293,"path":"src/lib/RemoteFunction.lua"}}],"properties":[{"name":"Name","desc":"Refers to the name given to the RemoteFunction.","lua_type":"string","readonly":true,"source":{"line":20,"path":"src/lib/RemoteFunction.lua"}},{"name":"ClassName","desc":"Refers to the ClassName Symbol of the RemoteFunction.","lua_type":"symbol","readonly":true,"source":{"line":26,"path":"src/lib/RemoteFunction.lua"}}],"types":[],"name":"RemoteFunction","desc":"A RemoteFunction emulates Roblox RemoteFunctions with RemoteEvents. It has feature parity with Roblox\'s RemoteFunction.","source":{"line":46,"path":"src/lib/RemoteFunction.lua"}}')}}]);