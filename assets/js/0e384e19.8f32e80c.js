"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[671],{3905:function(e,t,r){r.d(t,{Zo:function(){return c},kt:function(){return d}});var n=r(67294);function o(e,t,r){return t in e?Object.defineProperty(e,t,{value:r,enumerable:!0,configurable:!0,writable:!0}):e[t]=r,e}function i(e,t){var r=Object.keys(e);if(Object.getOwnPropertySymbols){var n=Object.getOwnPropertySymbols(e);t&&(n=n.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),r.push.apply(r,n)}return r}function a(e){for(var t=1;t<arguments.length;t++){var r=null!=arguments[t]?arguments[t]:{};t%2?i(Object(r),!0).forEach((function(t){o(e,t,r[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(r)):i(Object(r)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(r,t))}))}return e}function s(e,t){if(null==e)return{};var r,n,o=function(e,t){if(null==e)return{};var r,n,o={},i=Object.keys(e);for(n=0;n<i.length;n++)r=i[n],t.indexOf(r)>=0||(o[r]=e[r]);return o}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(n=0;n<i.length;n++)r=i[n],t.indexOf(r)>=0||Object.prototype.propertyIsEnumerable.call(e,r)&&(o[r]=e[r])}return o}var l=n.createContext({}),u=function(e){var t=n.useContext(l),r=t;return e&&(r="function"==typeof e?e(t):a(a({},t),e)),r},c=function(e){var t=u(e.components);return n.createElement(l.Provider,{value:t},e.children)},p={inlineCode:"code",wrapper:function(e){var t=e.children;return n.createElement(n.Fragment,{},t)}},m=n.forwardRef((function(e,t){var r=e.components,o=e.mdxType,i=e.originalType,l=e.parentName,c=s(e,["components","mdxType","originalType","parentName"]),m=u(r),d=o,f=m["".concat(l,".").concat(d)]||m[d]||p[d]||i;return r?n.createElement(f,a(a({ref:t},c),{},{components:r})):n.createElement(f,a({ref:t},c))}));function d(e,t){var r=arguments,o=t&&t.mdxType;if("string"==typeof e||o){var i=r.length,a=new Array(i);a[0]=m;var s={};for(var l in t)hasOwnProperty.call(t,l)&&(s[l]=t[l]);s.originalType=e,s.mdxType="string"==typeof e?e:o,a[1]=s;for(var u=2;u<i;u++)a[u]=r[u];return n.createElement.apply(null,a)}return n.createElement.apply(null,r)}m.displayName="MDXCreateElement"},59881:function(e,t,r){r.r(t),r.d(t,{frontMatter:function(){return s},contentTitle:function(){return l},metadata:function(){return u},toc:function(){return c},default:function(){return m}});var n=r(87462),o=r(63366),i=(r(67294),r(3905)),a=["components"],s={sidebar_position:1},l="Introduction",u={unversionedId:"intro",id:"intro",isDocsHomePage:!1,title:"Introduction",description:"Network is a declarative networking library initially based on network and influenced by RbxNet.",source:"@site/docs/intro.md",sourceDirName:".",slug:"/intro",permalink:"/Network/docs/intro",editUrl:"https://github.com/call23re/Network/edit/master/docs/intro.md",tags:[],version:"current",sidebarPosition:1,frontMatter:{sidebar_position:1},sidebar:"defaultSidebar",next:{title:"Installation",permalink:"/Network/docs/Getting Started/Installation"}},c=[],p={toc:c};function m(e){var t=e.components,r=(0,o.Z)(e,a);return(0,i.kt)("wrapper",(0,n.Z)({},p,r,{components:t,mdxType:"MDXLayout"}),(0,i.kt)("h1",{id:"introduction"},"Introduction"),(0,i.kt)("p",null,"Network is a declarative networking library initially based on ",(0,i.kt)("a",{parentName:"p",href:"https://github.com/sircfenner/network"},"network")," and influenced by ",(0,i.kt)("a",{parentName:"p",href:"https://github.com/roblox-aurora/rbx-net"},"RbxNet"),"."),(0,i.kt)("p",null,"It was made with the following goals in mind:"),(0,i.kt)("ul",null,(0,i.kt)("li",{parentName:"ul"},"Feature parity with Roblox's remote objects"),(0,i.kt)("li",{parentName:"ul"},"A familiar and consistent API to reduce friction"),(0,i.kt)("li",{parentName:"ul"},"Support for bidirectional mutable hooks"),(0,i.kt)("li",{parentName:"ul"},"Comprehensive Luau types (soon\u2122)"),(0,i.kt)("li",{parentName:"ul"},"Promisified remotes"),(0,i.kt)("li",{parentName:"ul"},"Built-in, promise-based error handling"),(0,i.kt)("li",{parentName:"ul"},"Asynchronous Remote Functions"),(0,i.kt)("li",{parentName:"ul"},"Easy to integrate in to existing projects"),(0,i.kt)("li",{parentName:"ul"},"Expanded remote API for common methods (",(0,i.kt)("a",{parentName:"li",href:"/api/RemoteEvent#FireClients"},"FireClients"),", ",(0,i.kt)("a",{parentName:"li",href:"/api/RemoteEvent#FireClientsExcept"},"FireClientsExcept"),")")),(0,i.kt)("p",null,"All of these goals have been met in some capacity."),(0,i.kt)("h1",{id:"motivation"},"Motivation"),(0,i.kt)("p",null,"Creating, accessing, modifying, and using remotes in studio is easy. So why should a library do it for you?"),(0,i.kt)("p",null,"Using a remote wrapper means that the source of truth for your remotes exists in your code instead of the data model. It also means that, typically, they're all defined in a single place, which is helpful for organization."),(0,i.kt)("p",null,"This is particularly advantageous when you're using a tool like ",(0,i.kt)("a",{parentName:"p",href:"https://rojo.space/"},"Rojo"),". It allows you to check your remotes in to version control and it saves time switching back-and-forth between studio and your code editor."),(0,i.kt)("p",null,"It is also advantageous because it allows you to easily add extra behavior to your remotes through the form of ",(0,i.kt)("a",{parentName:"p",href:"/docs/Hooks"},"Hooks"),"."),(0,i.kt)("h1",{id:"drawbacks"},"Drawbacks"),(0,i.kt)("p",null,"This isn't a replacement for RbxNet. It was not made for TypeScript and so it doesn't have some of the advantages of RbxNet (like compilation transformers). The scope of this project is also fairly limited in comparison. It doesn't have support for messaging service. It doesn't have any built-in middleware. It doesn't have explicit namespacing. Because it was made to more closely emulate the native remote APIs, some of the RbxNet naming conventions are arguably more clear."),(0,i.kt)("p",null,"If you are using TypeScript, you should probably use RbxNet. If you're using Luau, it's mostly a matter of personal preference."),(0,i.kt)("p",null,"This library relies heavily on promises. It expects the user to be familiar with promises. While there are many advantages to this, if you aren't familiar with them, it may be confusing at first. So, in using this library, you should familiarize yourself with promises as well. ",(0,i.kt)("a",{parentName:"p",href:"https://eryn.io/roblox-lua-promise/"},"https://eryn.io/roblox-lua-promise/")))}m.isMDXComponent=!0}}]);