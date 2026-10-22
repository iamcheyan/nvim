# 折叠机制

> 折叠有三个候选主人：缩进、Treesitter、LSP。这份配置只让一个赢。

## 为什么要折叠

几百行的文件里，先把不关心的部分收起来，剩下的能看到结构。

## 折叠的基础操作

| 键 | 作用 |
|---|---|
| `za` | 开关当前折叠 |
| `zc` | 关闭 |
| `zo` | 打开 |
| `zR` | 全部打开 |
| `zM` | 全部关闭 |
| `zm` / `zr` | 逐层关闭 / 打开 |
| `zp` | 预览折叠内容（不打开） |

`zp` 是这份配置加的，很实用：看一眼里面是什么，不用真的展开。

## `foldmethod` 有六种

| 值 | 按什么折 |
|---|---|
| `manual` | 手动 `zf` 标记 |
| `indent` | 按缩进层级 |
| `expr` | 按 `foldexpr` 表达式 |
| `marker` | 按 `{{{` `}}}` 标记 |
| `syntax` | 按语法高亮分组 |
| `diff` | 只折未改动部分（diff 模式自动） |

这份配置用 `expr`——由 nvim-ufo 提供表达式，优先用 Treesitter，没有则退回 `indent`。

## 三个想当主人的

| 候选 | 它会怎么折 |
|---|---|
| **缩进** | 按空格层级猜，嵌套结构容易错 |
| **Treesitter** | 按语法树节点，准确 |
| **LSP** | 按 server 返回的 foldingRange |

**问题**：三个同时开，会互相覆盖。文件打开时折叠范围跳来跳去。

## 这份配置的决定

**只有 nvim-ufo 管折叠。**

具体做法：

1. `nvim-ufo` 设 `foldmethod=expr`，provider 是 `{"treesitter", "indent"}`
2. **Treesitter 不在 `FileType` 时改 `foldmethod`**（配置里删掉了这段）
3. **LSP 不在 `LspAttach` 时改 `foldmethod`**（配置里也删掉了）
4. **cobol.nvim 的折叠关掉**（`folding.enable = false`），否则它会覆盖 ufo
5. **aerial 不管理折叠**（`manage_folds = false`）

每一条都是踩过坑之后加的。改这四行里的任何一行，折叠就会开始出错。

## COBOL 的折叠

COBOL 没有 Treesitter parser，所以 ufo 退回按缩进折。

但 COBOL 的缩进是固定的（Area A 第 8 列、Area B 第 12 列），按缩进折不准。

`cobol.nvim` 有自己的一套实现（按 Division / Section / Paragraph 的文本规则），
但它和 ufo 冲突——所以配置里**关掉了 cobol.nvim 的折叠**，接受 ufo 的近似结果。

这是取舍：宁可粗略一致，不要两套互相打架。

## 摘要行显示什么

折叠后那一行显示 `⋯ N lines` 这样的后缀，说明折了多少行。

如果窗口太窄看不到数字，说明空间不够。

## 折叠和搜索的配合

搜索时如果结果在折叠区域内：

- 默认不会自动展开
- 这份配置的 `n` / `N` 映射里带了 `zv`——跳转时自动展开当前折叠

这样搜索不会「跳过去但看不到」。

## 常见问题

| 现象 | 原因 |
|---|---|
| 折叠范围乱跳 | 多个 provider 在抢 |
| 折叠不准 | 没有 parser，退回按缩进 |
| COBOL 折叠不符合结构 | ufo 按缩进，不是按 Division |
| 搜索跳过去看不到内容 | 缺 `zv` |
| 大文件折叠很慢 | 表达式折叠要逐行求值 |

## 自己临时改

想试别的折法（不改配置）：

```vim
:set foldmethod=indent
:set foldmethod=manual
```

改完记得 `zR` 全部展开，不然会看到奇怪的结果。

## 下一步

- [07 编码与换行符](07-encoding.html)
- [插件手册：nvim-ufo](../plugins/nvim-ufo.html)
