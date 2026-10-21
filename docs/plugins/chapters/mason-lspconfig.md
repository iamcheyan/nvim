# mason-lspconfig.nvim

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

Mason 装了一堆服务器，lspconfig 需要知道「装好的这些要不要自动启用」。
mason-lspconfig 就是这两者之间的桥：它读取 Mason 的安装状态，
自动为已安装的服务器调用 `vim.lsp.enable()`。

没有它，你每次装完服务器都要手动写一行 `require("lspconfig").xxx.setup{}`。

## 在当前配置里怎么用

配置里没有额外的按键，它是一个**纯连接层**：

1. Mason 装好服务器。
2. mason-lspconfig 在启动时枚举已安装项。
3. 对每个匹配的服务器调用 `vim.lsp.enable(name)`。
4. lspconfig 建立连接，触发 `LspAttach`，键位才出现。

所以「装了服务器但键没反应」通常是这一环断了，不是键位没写。

### 验证链路

```vim
:LspInfo            " 看当前 buffer 挂上了哪些服务器
:Mason              " 看安装了哪些
:checkhealth lsp    " 整体健康检查
```

## 动手练习

1. `:Mason` 确认至少装了一个语言服务器。
2. 打开对应语言的文件，`:LspInfo` 确认服务器已 attach。
3. `:verbose nmap gd` 确认映射来源是 LSP。
4. 在 Mason 里卸载该服务器，重新打开文件，确认 `gd` 消失。

**验收**：能说清「Mason 安装 → mason-lspconfig 启用 → lspconfig 连接 → 键位出现」
这条链路，并能在任意一环出问题时定位。

## 注意事项

- **它不装东西**。安装是 Mason 的职责，别在这里找安装命令。
- **服务器名必须匹配**。Mason 的包名和 lspconfig 的 server 名不总是一致，
  不一致的需要在 mason-lspconfig 里额外配置。
- **自动启用不等于自动配置**。某些服务器需要额外 `settings`，
  那是 lspconfig 的 `setup{}` 负责的。
- 卸载服务器后当前会话仍然连接着，需要重开 buffer。

## 查快捷键和帮助

```vim
:help mason-lspconfig
:LspInfo
```
