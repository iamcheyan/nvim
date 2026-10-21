# contextline.nvim

> 私有插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

在深层嵌套或有长函数的文件里，你容易忘记「现在在哪个函数/类/标签里」。
contextline 显示一条可点击的结构路径（面包屑），点任意一级可以跳转或列出同级项。

## 在当前配置里怎么用

| 按键 | 作用 |
|---|---|
| `<leader>cb` | 打开结构下拉菜单 |
| `:ContextlineMenu` | 同上 |

### 三个数据源

```lua
use_lsp = true
use_navic = true
use_treesitter = true
```

按顺序尝试：LSP → nvim-navic → Treesitter。**哪个有数据用哪个**，
所以它在多种语言里都能工作。

### 显示内容

| 选项 | 值 | 含义 |
|---|---|---|
| `separator` | `  ` | 层级分隔符（带图标） |
| `show_path` | `false` | 不显示文件路径 |
| `show_file` | `false` | 不显示文件名 |
| `show_icons` | `true` | 显示层级图标 |

关掉路径和文件名是有意的：**状态栏空间有限，结构路径比路径更有信息量**。

## 动手练习

1. 打开一个多层嵌套的 Lua 文件，把光标移进一个内层函数。
2. 观察状态栏的结构路径变化。
3. `<leader>cb` 打开下拉菜单，选一个上级结构跳过去。
4. 在 COBOL 文件里重复，确认它由 cobol.nvim 提供数据。
5. 在一个没有结构的纯文本文件里确认它安静地不显示。

**验收**：结构路径跟随光标，菜单能跳转。

## 注意事项

- **数据源依赖**：没有 LSP 也没有 parser 时路径为空。这是降级，不是坏掉。
- **COBOL 走的是 cobol.nvim 提供的结构**，不是 LSP。
- **与 winbar 是两处**：winbar 显示结构摘要，contextline 提供可交互菜单。
- 不显示文件名是设计，避免和状态栏其它段重复。

## 查快捷键和帮助

```vim
:help contextline
:ContextlineMenu
```
