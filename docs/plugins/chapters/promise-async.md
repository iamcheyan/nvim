# promise-async

> 依赖 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

Neovim 的 Lua API 是同步的，但折叠计算、文件遍历这类操作需要异步。
promise-async 提供 Promise 抽象，让插件能把耗时操作放到后台。

**它不是一个给你用的插件**，是 nvim-ufo 的依赖。

## 在当前配置里怎么用

没有按键，没有命令，没有配置项。它由 lazy.nvim 作为依赖自动安装：

```lua
dependencies = { "kevinhwang91/promise-async" }
```

### 什么时候会注意到它

基本不会——除非它缺失。表现是：

- nvim-ufo 加载失败
- 打开文件时报 `module 'promise' not found`
- 折叠功能整体不可用

## 动手练习

1. `:Lazy` 打开插件管理，搜索 `promise-async`，确认状态是 loaded。
2. `:lua print(vim.inspect(package.loaded["promise"] ~= nil))` 确认已加载。
3. 随便打开一个大文件，确认折叠摘要正常出现（间接证明它在工作）。

**验收**：能找到它存在，且折叠功能正常。

## 注意事项

- **不要手动 `require("promise")`**，它不是给你直接调用的 API。
- **不要单独禁用它**，会让 ufo 直接失效。
- 它没有配置项，改它等于改依赖本身，没有意义。
- 如果排查折叠问题，先看 ufo，再看它是否装上。

## 查快捷键和帮助

```vim
:help promise-async
:Lazy
```
