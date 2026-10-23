# 05 复制与寄存器：`p` 的内容从哪来

> 这一篇解释 Vim 的剪贴板模型。理解它之后，「为什么粘出来的不是我想要的东西」这类问题会消失。

## 最基本的一组

| 键 | 作用 |
|---|---|
| `yy` | 复制整行（yank） |
| `yw` | 复制一个词 |
| `y$` | 复制到行尾 |
| `p` | 粘在光标**后** |
| `P` | 粘在光标**前** |

`y` 是 yank（拽）。和 `d` 一样是操作符，接范围：`y` + `w`、`y` + `$`、`yy` 整行。

## 关键概念：寄存器

你复制的东西不是放进「一个剪贴板」，而是放进**寄存器**。Vim 有几十个寄存器。

最常用的几个：

| 寄存器 | 内容 | 怎么用 |
|---|---|---|
| `""` | 无名寄存器（默认） | `p` 用的就是它 |
| `"0` | 最近一次 **yank** | `"0p` |
| `"1`–`"9` | 最近删除的历史，1 最新 | `"1p` |
| `"a`–`"z` | 你自己命名的 | `"ayy` 存，`"ap` 取 |
| `"_` | 黑洞，存进去就没了 | `"_dd` 删除但不覆盖剪贴板 |
| `"+` | 系统剪贴板 | `"+y` |
| `"*` | 系统选区（X11） | `"*y` |

### 那个最容易踩的坑

**`dd` 会覆盖无名寄存器。**

所以这个操作会出问题：

```
yy        复制一行（进了 ""）
dd        想删另一行 —— 但把 "" 覆盖了！
p         粘出来的是刚删的那行，不是刚才复制的
```

正确做法是用 `"0p`——它永远指向最近一次 **yank**，不受删除影响。

**记住这一条，能省掉很多困惑。**

### 命名寄存器

想暂存两段内容来回用：

```
"ayy      复制这行进 a
"byy      复制那行进 b
"ap       粘 a
"bp       粘 b
```

大写是「追加」：`"Ayy` 把行追加到 a 寄存器末尾，而不是覆盖。

## 和系统剪贴板打通

默认 Vim 和系统剪贴板是隔离的。这份配置打开了 `clipboard=unnamedplus`，所以：

- `y` 复制的东西会自动进系统剪贴板
- `p` 粘的是系统剪贴板的内容

也就是说**可以直接和浏览器、其它应用互相复制**。

如果只想用系统剪贴板而不改变默认行为，用显式寄存器：`"+y` 复制到系统，`"+p` 从系统粘。

详见 [百科：剪贴板与系统集成](../wiki/02-clipboard.html)。

## 删除也是剪切

这点前面提过，这里说清楚：

| 操作 | 内容去了哪 |
|---|---|
| `yy` | `"0` 和 `""` |
| `dd` | `"1` 和 `""` |
| `x` | `"1` 和 `""` |

所以 `dd` 之后 `p` 能粘回来。Vim 没有真正的「删除」，只有「移到寄存器」。

如果确实想删了不占寄存器：`"_dd`。

## 本配置的说明

旧版配置把 `d`、`c`、`x`、`D`、`C`、`X`、`<Del>` 以及选择模式下所有可打印字符都映射到黑洞寄存器 `"_`，并把 `m`/`M`/`mm` 改成专用剪切键。目的是让删除不冲掉系统剪贴板。

**当前配置已恢复 Vim 默认**：`d`、`c`、`x` 等按 Vim 原生逻辑把内容送进 `"1` 和 `""`，`clipboard=unnamedplus` 时会覆盖系统剪贴板。

如果想重新启用黑洞映射，把下面的代码加回 `lua/config/keymaps.lua`（在 smart-paste 映射之后）：

```lua
local blackhole_opts = { noremap = true, silent = true }

vim.keymap.set({ "n", "x" }, "d", '"_d', vim.tbl_extend("force", blackhole_opts, { desc = "Delete (black hole, no yank)" }))
vim.keymap.set("n", "dd", function()
  return '"_' .. vim.v.count1 .. "dd"
end, vim.tbl_extend("force", blackhole_opts, { expr = true, desc = "Delete line (black hole)" }))
vim.keymap.set({ "n", "x" }, "D", '"_D', vim.tbl_extend("force", blackhole_opts, { desc = "Delete to end of line (black hole)" }))
vim.keymap.set({ "n", "x" }, "x", '"_x', vim.tbl_extend("force", blackhole_opts, { desc = "Delete char (black hole)" }))
vim.keymap.set({ "n", "x" }, "X", '"_X', vim.tbl_extend("force", blackhole_opts, { desc = "Delete char before cursor (black hole)" }))
vim.keymap.set("n", "<Del>", '"_x', vim.tbl_extend("force", blackhole_opts, { desc = "Delete key (black hole)" }))
vim.keymap.set("x", "<Del>", '"_d', vim.tbl_extend("force", blackhole_opts, { desc = "Delete selection (black hole)" }))

vim.keymap.set({ "n", "x" }, "c", '"_c', vim.tbl_extend("force", blackhole_opts, { desc = "Change (black hole, no yank)" }))
vim.keymap.set("n", "cc", function()
  return '"_' .. vim.v.count1 .. "S"
end, vim.tbl_extend("force", blackhole_opts, { expr = true, desc = "Change line (black hole)" }))
vim.keymap.set({ "n", "x" }, "C", '"_C', vim.tbl_extend("force", blackhole_opts, { desc = "Change to end of line (black hole)" }))

for char_nr = 33, 126 do
  local char = vim.fn.nr2char(char_nr)
  vim.keymap.set("s", char, '<c-o>"_c' .. (char == "\\" and "\\" or char), blackhole_opts)
end
vim.keymap.set("s", "<bs>", '<c-o>"_c', blackhole_opts)
vim.keymap.set("s", "<space>", '<c-o>"_c<space>', blackhole_opts)

vim.keymap.set("n", "<leader>M", "m", { desc = "Set mark" })
vim.keymap.set("n", "m", '"+d', { desc = "Cut to system clipboard" })
vim.keymap.set("n", "mm", '"+dd', { desc = "Cut line to system clipboard" })
vim.keymap.set("n", "M", '"+D', { desc = "Cut to end of line to system clipboard" })
vim.keymap.set("x", "m", '"+d', { desc = "Cut selection to system clipboard" })
```

建议先在小文件上练习 `dd`、`p`、`"0p` 的区别，再决定要不要重新启用。

## 几个高频组合

| 想做什么 | 按键 |
|---|---|
| 复制整行粘到下面 | `yyp` |
| 复制整行粘到上面 | `yyP` |
| 把下面 3 行挪到上面 | `3dd`，移到位置，`P` |
| 复制到文件末尾 | `ggyG` |
| 用刚删的内容替换当前行 | `dd` 之后 `Vp` |

`yyp` 是复制行的最省事写法，改配置文件时天天用。

## 练习

1. `yy` 复制一行，`p` 粘到下面
2. `yyp` 一步完成上一步
3. `yy` 复制一行，`dd` 删另一行，然后 `p` 看粘的是什么
4. 用 `"0p` 粘贴刚才复制的那行，确认是对的
5. `"ayy` 存一行到 a，`"byy` 存另一行到 b，分别 `"ap` `"bp` 取出来
6. 复制一段文字，切到浏览器粘进去（验证系统剪贴板打通）

**验收**：能解释为什么 `yy` 之后 `dd` 再 `p` 得到的不是最初复制的内容。

## 下一步

[06 查找与替换](06-search-and-replace.html)——在文件里定位和批量改。
