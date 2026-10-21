# mini.ai

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

原生 `ai` / `ii` 只认缩进和括号。mini.ai 允许定义**语义边界**：
「这个引号里」「这个括号里」「这个数字」「整个 buffer」。

配置定义了一批自定义对象，其中最关键的一条是 **COBOL 下主动失效**。

## 在当前配置里怎么用

| 对象 | 按键 | 范围 |
|---|---|---|
| 代码块（Treesitter） | `ao` / `io` | 外层 / 内层块 |
| 函数 | `af` / `if` | 函数 |
| 类 | `ac` / `ic` | 类 |
| 标签 | `at` / `it` | HTML/XML 标签 |
| 数字 | `ad` / `id` | 连续数字 |
| 大小写词 | `ae` / `ie` | 驼峰/下划线词 |
| 整个 buffer | `ag` / `ig` | 全文（`ig` 跳过首尾空行） |
| 函数调用 | `au` / `iu` | 调用表达式 |

`n_lines = 500`：只向上搜索 500 行，防止大文件里搜索过慢。

### COBOL 特殊处理

```lua
if vim.tbl_contains({ "cobol", "cbl", "cob" }, vim.bo.filetype) then
  return {}
end
```

原因：**COBOL 在这份配置里没有 Treesitter parser**。如果不禁用，
Treesitter 类对象会在 COBOL buffer 里抛错。返回空表让这些对象安静失效，
其它基于模式的对象（数字、大小写词、buffer）仍然可用。

## 动手练习

1. 在 Lua 文件里把光标放在一个字符串上，`ciq` 改引号内容。
2. 在数字上 `cid`，确认只选中数字本身。
3. `cig` 选中整个 buffer（跳过首尾空行），`u` 撤销。
4. 在 COBOL 文件里试 `cio`（Treesitter 块对象），确认**不报错**。
5. 在 COBOL 里试 `cid` 在数字上，确认模式类对象仍然可用。

**验收**：Treesitter 类对象在 COBOL 里静默失效，模式类对象正常工作。

## 注意事项

- **和 nvim-treesitter-textobjects 有重叠**。`af`/`if` 两边都提供，
  以加载顺序靠后的为准。
- **COBOL 里 Treesitter 对象不可用**，不要试图打开；
  需要结构对象时用 `cobol.nvim` 提供的结构移动。
- `n_lines` 限制意味着超大文件里向上找对象可能失败。
- 自定义对象改了之后需要重开 buffer 才生效。

## 查快捷键和帮助

```vim
:help mini.ai
```
