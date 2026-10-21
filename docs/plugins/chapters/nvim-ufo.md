# nvim-ufo

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

原生折叠按缩进猜，嵌套结构容易错。nvim-ufo 用 Treesitter 的折叠范围，
并在摘要行显示「折了多少行」。

这份配置里**折叠只有一个主人**：ufo。LSP 被明确禁止改 `foldmethod`，
`cobol.nvim` 也只在没有 ufo 接管时才用自己的摘要格式。

## 在当前配置里怎么用

| 按键 | 作用 |
|---|---|
| `za` | 开关当前折叠 |
| `zM` | 全部关闭 |
| `zR` | 全部打开 |
| `zm` / `zr` | 逐层关闭 / 打开 |
| `zp` | 预览光标下的折叠内容 |

### provider 顺序

```lua
return { "treesitter", "indent" }
```

先试 Treesitter，没有 parser 时退回按缩进。这个顺序解释了为什么
Lua 文件折叠精确，而某些冷门语言只能按缩进折。

### 摘要样式

折叠行显示 `⋯ N lines 󰁂` 这样的后缀，宽度按可用空间截断。
看不见行数说明窗口太窄。

## 动手练习

1. 打开一个 Lua 文件，`zM` 全部折叠，观察摘要行。
2. `zr` 逐层展开两层，再 `zm` 收回。
3. 在折叠行上 `zp` 预览内容，不打开折叠。
4. `za` 单独开关一个折叠。
5. 打开 COBOL 文件，`za` 在 Division 上，确认折叠按结构而非缩进。

**验收**：普通语言靠 Treesitter 精确折叠，COBOL 靠插件自己的结构折叠。

## 注意事项

- **COBOL 的折叠不来自 Treesitter**，因为没有 parser；由 `cobol.nvim` 提供
  Division/Section/Paragraph 折叠。
- **不要同时开 LSP 折叠**，两个 provider 会打架；配置已经避免了。
- **依赖 promise-async**，它是 ufo 的异步依赖，不需要单独配置。
- 超大文件折叠计算会慢，属正常。

## 查快捷键和帮助

```vim
:help nvim-ufo
```
