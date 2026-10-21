# quicker.nvim

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

quickfix 列表只显示一行结果，看不出上下文。quicker 让你**在列表里就地展开**
前后的代码，不必跳过去再跳回来判断。

配置还修了 quickfix 的默认行为：原本会抢 `<CR>`，现在保留原生语义。

## 在当前配置里怎么用

| 按键 | 作用 |
|---|---|
| `<leader>xq` 或 `:copen` | 打开 quickfix |
| `>` | 展开当前结果前后各两行上下文 |
| `<` | 收起 |
| `Enter` | 跳到对应位置 |
| `[q` / `]q` | 上一条 / 下一条结果 |
| `:lopen` | location list（另一套列表） |

### 产生结果的方式

quickfix 的内容来自别处，常见来源：

```vim
:vimgrep /TODO/j **/*        " 全项目搜
:lua vim.diagnostic.setqflist()   " LSP 诊断
```

grep 类操作通常经过 Snacks picker，按列表里的键发送到 quickfix。

## 动手练习

1. 在项目里 `:vimgrep /function/j lua/**/*.lua` 生成结果。
2. `<leader>xq` 打开列表。
3. 在某条结果上按 `>`，看清上下文；按 `<` 收起。
4. `]q` 连续跳三条，`[q` 退回。
5. 按 `Enter` 跳进文件，用 `Ctrl-o` 返回。

**验收**：能不离列表判断某条结果是否相关，并只在必要时跳转。

## 注意事项

- **`<` 在普通模式本来会取消缩进**。在 quickfix 缓冲区里它被 quicker 接管，
  这是 buffer-local 映射，回到编辑缓冲区后 `<` 仍是缩进。
- **location list 和 quickfix 是两个列表**。`[q`/`]q` 走 quickfix，
  `:lopen` 的列表用 `[l`/`]l`。
- **展开只改显示，不改文件**。可以放心按。
- 大量结果时展开会稍微卡顿，属正常。

## 查快捷键和帮助

```vim
:help quicker
:help quickfix
```
