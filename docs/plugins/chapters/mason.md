# mason.nvim

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

语言服务器、格式化器、linter 都是外部程序。手动下载解压、放到 PATH、保证版本匹配
很麻烦。Mason 用一个界面管理这些工具的安装和更新。

它**只管安装**，不负责把工具接到 Neovim 上——那是 lspconfig 和 nvim-lint 的事。

## 在当前配置里怎么用

| 入口 | 作用 |
|---|---|
| `<leader>cm` | 打开 Mason 界面 |
| `:Mason` | 同上 |
| `:MasonInstall <名字>` | 直接装 |
| `:MasonUpdate` | 更新注册表 |

界面里三列：已安装 / 可安装 / 更新。选中条目按 `i` 安装、`X` 卸载、`u` 更新。

### 依赖

Mason 装的东西大多是单文件二进制或 npm 包，所以需要：

- `unzip` / `tar`：解包
- `python3` + `python3-venv`：Python 系工具
- `node` / `npm`：部分语言服务器

缺这些会安装失败，但**错误信息通常只说解压失败**，容易误判成网络问题。

## 动手练习

1. `<leader>cm` 打开界面，切到可安装列表。
2. 找 `lua-language-server`，按 `i` 安装，观察进度。
3. 装完后打开一个 Lua 文件，确认 `LspAttach` 生效（`gd` 有反应）。
4. `:MasonUpdate` 更新注册表，确认列表有变化。
5. 在界面里按 `?` 看完整按键。

**验收**：能从界面装一个服务器并让它在文件里生效。

## 注意事项

- **Mason 装在 Neovim 的数据目录**，不在系统 PATH 里。
  想在命令行直接用这些工具，需要另外处理 PATH。
- **装完要重启或者重新打开文件**才能让 lspconfig 发现新服务器。
- **NixOS 上不要用 Mason 装系统层工具**，会绕开系统包管理；配置里也说明了这点。
- 安装失败先确认 `unzip`、`node`、`python3-venv` 是否存在，再怀疑网络。

## 查快捷键和帮助

```vim
:help mason
:Mason
```
