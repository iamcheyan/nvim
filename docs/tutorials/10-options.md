# 10 选项与配置

> 原书这一章讲 `:set`。今天的 Neovim 有更清楚的写法，但也有必须知道的坑。

## 三种作用域

选项分三个层级，搞混了会出现「为什么有时生效有时不生效」：

| 层级 | 范围 | 写法 |
|---|---|---|
| 全局 | 所有 buffer / window | `vim.o` |
| buffer 局部 | 只对当前 buffer | `vim.bo` |
| window 局部 | 只对当前窗口 | `vim.wo` |

同一个选项在不同层级可能有不同值。比如 `number` 是 window 局部的——两个窗口可以一个显示行号一个不显示。

## 用 Lua 设置

这份配置全部用 Lua。三种写法：

```lua
vim.o.number = true            -- 全局（会自动落到合适的层级）
vim.wo.number = true           -- 明确指定 window 局部
vim.bo.shiftwidth = 2          -- 明确指定 buffer 局部
```

改当前 buffer 的：

```lua
vim.opt_local.shiftwidth = 2   -- 只影响当前 buffer
vim.opt_global.shiftwidth = 2  -- 影响全局默认
```

### 和老的 `:set` 对照

| 老写法 | Lua 写法 |
|---|---|
| `set number` | `vim.o.number = true` |
| `set nonumber` | `vim.o.number = false` |
| `set shiftwidth=2` | `vim.o.shiftwidth = 2` |
| `set tabstop=4 shiftwidth=4` | 两行分别写 |
| `set list` | `vim.o.list = true` |

**布尔选项**：`set foo` 开，`set nofoo` 关。Lua 里统一用 `true` / `false`，不用记 `no` 前缀。

### 追加值

有些选项是列表（`fillchars`、`shortmess`、`clipboard`）：

```lua
vim.opt.fillchars:append({ eob = "~" })
vim.opt.shortmess:append("c")
```

**不要直接赋值**，那会丢掉已有内容。用 `:append()`。

## 查当前值

| 命令 | 作用 |
|---|---|
| `:set number?` | 看 number 的值 |
| `:set number` | 看所有被改过的选项 |
| `:verbose set number?` | 看值 + **谁改的** |

`:verbose set` 是排查配置问题的主力——它告诉你这个值最后是被哪个文件设的。

## 值得知道的选项

### 显示

| 选项 | 作用 |
|---|---|
| `number` / `relativenumber` | 绝对行号 / 相对行号 |
| `cursorline` | 高亮当前行 |
| `wrap` | 折行（代码一般关） |
| `scrolloff` | 光标距上下边缘至少保留几行 |
| `signcolumn` | 行号左边的标记列 |

`scrolloff=5` 很推荐：光标永远离边缘 5 行，不会贴边看不到上下文。

### 缩进

| 选项 | 作用 |
|---|---|
| `tabstop` | 一个 Tab 显示几个字符宽 |
| `shiftwidth` | `>>` 缩进用几个空格 |
| `expandtab` | Tab 转成空格 |
| `autoindent` | 新行跟随上一行缩进 |
| `smartindent` | 按语法智能缩进 |

**最常踩的坑**：`tabstop` 和 `shiftwidth` 混了。`tabstop` 是「显示宽度」，`shiftwidth` 是「缩进量」。改缩进改 `shiftwidth`。

### 搜索

| 选项 | 作用 |
|---|---|
| `hlsearch` | 高亮所有匹配 |
| `incsearch` | 边输入边跳 |
| `ignorecase` | 忽略大小写 |
| `smartcase` | 有大写就区分 |

### 编辑行为

| 选项 | 作用 |
|---|---|
| `clipboard` | 和系统剪贴板打通 |
| `mouse` | 鼠标支持 |
| `undofile` | 撤销历史存盘，重开文件还能撤销 |
| `backup` / `swapfile` | 备份 / 交换文件 |
| `termguicolors` | 真彩色 |

`undofile` 值得开——关掉 Vim 再打开，`u` 仍能撤销之前的修改。

## 在哪写这些

| 位置 | 用途 |
|---|---|
| `lua/config/options.lua` | 这份配置的选项集中地 |
| `after/ftplugin/<ft>.lua` | 只对某个文件类型生效 |
| `:set` 临时改 | 只在当前会话有效 |

这份配置用 `after/ftplugin/` 给不同语言设缩进，比如 CSS 是 2 空格、Python 是 4 空格。

## 练习

1. `:set scrolloff?` 看当前值
2. `:verbose set shiftwidth?` 看它被谁设的
3. `:set scrolloff=10` 临时改，移动光标感受差别
4. `:set nohlsearch` 关掉高亮，再 `:set hlsearch` 打开
5. 打开一个 `.css` 文件，`:set shiftwidth?` 确认是 2
6. 打开一个 `.py` 文件，确认缩进设置不同

**验收**：能用 `:verbose set` 查出任意选项的来源。

## 下一步

[11 正则与 `:g`](11-regex-and-global.html)——Vim 里最像「编程」的部分。
