# 15 映射与 Leader 设计

> 最后这一篇讲怎么改键。改得好会让操作变顺，改得乱会毁掉整个配置。

## 先搞清楚三种模式

| 模式 | 映射命令 | 你在干什么 |
|---|---|---|
| 普通 | `nmap` | 下达命令 |
| 插入 | `imap` | 打字 |
| 可视 | `xmap` | 选中 |
| 命令行 | `cmap` | 输入 `:` 命令 |
| 操作符待决 | `omap` | 按了 `d` 等后续 |

**新手最常犯的错**：想映射普通模式的键，结果用了 `imap`，然后在插入模式里打字时误触发。

## 递归 vs 非递归

| 命令 | 会展开已有映射 |
|---|---|
| `nmap` `imap` | **会**（递归） |
| `nnoremap` `inoremap` | **不会**（非递归） |

**永远用非递归的**（`nnoremap` 等）。

原因：`nmap x y` 之后如果 `y` 又有映射，会继续展开。不小心就绕成全循环。

这份配置用 Lua：

```lua
vim.keymap.set("n", "<leader>q", ":q<CR>")
```

`vim.keymap.set` **默认就是非递归的**，不用额外写 `nore`。

## Lua 里的写法

```lua
-- 基本形式
vim.keymap.set(模式, 键, 动作, 选项)
```

| 参数 | 值 |
|---|---|
| 模式 | `"n"` `"i"` `"v"` `"x"` `"o"` `"c"` `"t"` 或它们的组合 `{"n","x"}` |
| 键 | `"<leader>ff"`、`"gd"`、`"<C-s>"` |
| 动作 | 字符串（按键序列）或函数 |
| 选项 | `{ desc = "...", silent = true, buffer = 0 }` |

例子：

```lua
-- 字符串形式：按 <C-s> 等于按 :w<CR>
vim.keymap.set("n", "<C-s>", ":w<CR>", { desc = "Save" })

-- 函数形式
vim.keymap.set("n", "<leader>w", function()
  vim.cmd("write")
end, { desc = "Write" })

-- 给多个模式
vim.keymap.set({"n", "x"}, "<leader>y", '"+y', { desc = "Yank to system" })
```

**`desc` 一定要写**。它是 which-key 菜单显示的文字，也是 `:verbose nmap` 的输出。

## Leader 是什么

`<leader>` 是一个「前缀占位符」，默认是反斜杠 `\`。

这份配置把它设成空格：

```lua
vim.g.mapleader = " "
```

所以 `<leader>ff` 实际是按 `空格` `f` `f`。

**为什么要用 leader**：给自定义键一个统一的命名空间，避免和 Vim 原生键冲突。

## 你的配置怎么设计的

这份配置的 leader 分组（按 which-key 定义）：

| 前缀 | 管什么 |
|---|---|
| `<leader>f` | 文件与搜索 |
| `<leader>g` | Git |
| `<leader>c` | 代码与 LSP |
| `<leader>s` | 搜索替换 |
| `<leader>b` | 缓冲区 |
| `<leader>w` | 窗口 / 会话 |
| `<leader>x` | 诊断与 quickfix |
| `<leader>m` | 书签 |
| `<leader>u` | 界面开关 |
| `<leader>t` | 终端 / 标签 |
| `<leader>q` | 退出 |

**规律**：一个字母一个域。

想加新键时先问：它属于哪个域？如果都不属于，可能不该加。

## 半途停顿看菜单

按 `<leader>` 不要继续，等 300 毫秒（`timeoutlen`），which-key 会列出这个前缀下所有键。

**这是发现键位的主要方式**，比查文档快。

## buffer 局部映射

有些键只对当前 buffer 有效：

```lua
vim.keymap.set("n", "<leader>r", function() ... end, { buffer = 0 })
```

`buffer = 0` 表示当前 buffer。这样做的好处：不会污染全局，关掉文件就失效。

LSP 和 gitsigns 的键都是这样注册的——所以你在没有 LSP 的文件里按 `gd`，行为不同。

**这也解释了为什么文档写的键有时不存在**：它只在特定 buffer 里有。

## 什么时候该加映射

**该加**：

- 一个操作每天做几十次
- 原生的键太长（比如 `:w !sudo tee %`）
- 某个操作在你的工作流里特别重要

**不该加**：

- 一次性的操作（用命令就行）
- 和原生语义冲突的（比如把 `w` 映射成别的）
- 别人看不懂的（没有 `desc` 的）

## 冲突检测

两个插件抢同一个键时，**后加载的赢**。

查实际生效的是谁：

```vim
:verbose nmap <leader>gd
```

会显示定义文件和行号。

这份配置为此做过一次全面清理：`<leader>s` 还给搜索、`<C-d>` 还给滚动、`<C-q>` 还给块选。详见 [配置审阅](../CONFIG-REVIEW.html)。

## 练习

1. `:verbose nmap <leader>ff` 看它定义在哪
2. `:nmap <leader>` 列出所有 leader 键
3. 在 `lua/config/keymaps.lua` 里加一个映射：
   ```lua
   vim.keymap.set("n", "<leader>zz", ":echo 'test'<CR>", { desc = "Test" })
   ```
4. 重启 Neovim，按 `<leader>zz`，应该显示 `test`
5. 按 `<leader>` 停顿，确认 `zz` 出现在菜单里
6. 删掉这个映射

**验收**：能加一个带 `desc` 的映射，并能在 which-key 里看到它。

## 一个建议

**先别急着改键**。用默认配置两周，你会发现自己真的在重复按什么，那时候再加映射才有依据。

盲目抄别人的配置，加了一堆自己用不上的键，反而增加记忆负担。

## 完成

15 篇教程到这里结束。

- 想查具体按键：[按键速查](../keys.html)
- 想了解某个插件：[插件手册](../plugins.html)
- 想理解机制：[学习 · 概念百科](../learn.html)
- 想随手查： [学习 · 速查知识](../reference.html)
