# 剪贴板与系统集成

> 为什么 `y` 复制的东西粘不到浏览器？这一篇讲清 Neovim 的剪贴板模型。

## 两套「剪贴板」

Neovim 内部有寄存器系统，操作系统有自己的剪贴板。默认**两者不通**。

| | 内部寄存器 | 系统剪贴板 |
|---|---|---|
| 访问方式 | `"a` 到 `"z` | `"+` |
| 默认 yank 进哪个 | `""` 无名寄存器 | 不进去 |
| 跨应用可用 | 否 | 是 |

## `clipboard` 选项

想打通，设置 `clipboard`：

```lua
vim.o.clipboard = "unnamedplus"
```

效果：

- `y` 复制 → 同时写入系统剪贴板
- `p` 粘贴 → 从系统剪贴板读

**这份配置已经打开了。** 所以你在这里 `y`，去浏览器 `Ctrl-v` 能粘出来。

### 三种取值

| 值 | 含义 |
|---|---|
| （空） | 完全隔离 |
| `unnamed` | `*` 寄存器（X11 主选区） |
| `unnamedplus` | `+` 寄存器（系统剪贴板） |

Linux 上两者有区别：`*` 是「选中即复制」的主选区，`+` 是 `Ctrl-c` 的剪贴板。
大多数情况用 `unnamedplus`。

## 后端程序

Neovim 自己不直接访问系统剪贴板，它调用外部程序：

| 平台 / 环境 | 用的程序 |
|---|---|
| macOS | `pbcopy` / `pbpaste` |
| Linux X11 | `xclip` 或 `xsel` |
| Linux Wayland | `wl-copy` / `wl-paste` |
| WSL | `win32yank` |
| Windows | 原生 |
| SSH 远端 | OSC 52（终端转发） |

**没装对应程序时，`"+y` 静默失败**——不报错，就是没复制上。这是最常见的「剪贴板不工作」原因。

检查方法：

```vim
:checkhealth
```

会列出 clipboard 工具的状态。

## SSH 里怎么复制

远端服务器上没有你的本地剪贴板。两条路：

**OSC 52**：终端把复制内容转义转发给本地终端，由本地终端写进剪贴板。

需要：

- 终端支持 OSC 52
- Neovim 侧启用（Neovim 0.10+ 原生支持）

**通过 tmux**：tmux 需要开 `set -g set-clipboard on`。

## 那份配置的额外处理

`smart-paste.nvim` 处理**粘贴时的缩进**：

从浏览器复制一段缩进的代码，直接 `p` 粘进来，缩进通常是错的（贴着第 0 列）。
`smart-paste` 保留块内相对缩进，但把第一行对齐到当前光标位置。配置对行式粘贴做清洗与空行占位替换，彻底解决了以往多出空行的缺陷：

| 按键 | 场景 |
|---|---|
| `p` / `P` | 智能缩进粘贴（内部寄存器与系统剪贴板，自动对齐目标上下文并防多余空行） |
| `<leader>p` | 系统剪贴板块粘贴（智能缩进，在空行处直接替换占位） |
| `<C-v>` | 智能粘贴（普通模式块粘贴、可视模式覆盖、插入模式重排） |

**注意 `<C-v>` 被粘贴占用了**，所以视觉块模式要用 `<C-q>`。

详见 [插件手册：smart-paste](../plugins/smart-paste.html)。

## 常见问题

| 现象 | 原因 | 处理 |
|---|---|---|
| `y` 之后浏览器粘不出来 | 没设 `clipboard`，或后端程序缺失 | 检查 `:checkhealth` |
| `"+y` 没反应也不报错 | 外部程序没装 | 装 `xclip` / `wl-clipboard` |
| SSH 里复制不了 | 终端不支持 OSC 52 或 tmux 没开 | 见上文 |
| 粘进来缩进全乱 | 源文本缩进和当前上下文不同 | 正常按 `p` 或用 `<leader>p` / `<C-v>` |
| 粘贴很慢 | 大段内容逐行处理缩进 | 属正常，几千行会慢一两秒 |

## 一个反直觉的点

**删除也会占剪贴板。**

`dd` 删掉的行进了 `"1` 和 `""`。如果 `clipboard=unnamedplus`，`dd` 会**覆盖系统剪贴板**。

结果：你想复制一段代码，中间删了几行，再去粘贴——粘出来的是删掉的那几行。

避免方法：

- 删除后立刻 `"0p`（`"0` 永远指向最近一次 yank）
- 或者删除时用黑洞寄存器：`"_dd`

这一条在 [05 复制与寄存器](../tutorials/05-yank-and-registers.html) 里详细讲了。

## 本配置的历史说明

旧版配置曾把 `d`、`c`、`x`、`D`、`C`、`X`、`<Del>` 以及选择模式下所有可打印字符都映射到黑洞寄存器 `"_`，并把 `m`/`M`/`mm` 改成专用剪切键。目的是让删除不冲掉系统剪贴板。但这样做的代价是：Vim 的原生寄存器模型被重写，`dd` 后 `p` 粘出来的不再是刚删的行，`ciw` 不再把被替换的词送进寄存器，计数行为也不直观。

**当前配置的行为说明**：
- `d`、`c`、`x` 等操作完全按 Vim 原生逻辑把内容送进 `"1` 和 `""`，`clipboard=unnamedplus` 时会同步系统剪贴板。
- `p`、`P` 维持强大的上下文智能缩进能力，同时已彻底修复系统剪贴板末尾换行带来的多余空行问题（空白占位行上粘贴自动替换，清洗无效空白行）。
- 智能缩进粘贴也可通过 `<leader>p`、`<C-v>` 显式使用。

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

## 下一步

- [03 文件类型与语法高亮](03-filetypes.html)
- [插件手册：smart-paste](../plugins/smart-paste.html)
