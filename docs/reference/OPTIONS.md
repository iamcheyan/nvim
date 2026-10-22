# 选项总表

> 按用途分组的常用选项。查某个选项用 `:help '选项名'`。

## 显示

| 选项 | 默认 | 作用 |
|---|---|---|
| `number` | off | 绝对行号 |
| `relativenumber` | off | 相对行号 |
| `cursorline` | off | 高亮当前行 |
| `cursorcolumn` | off | 高亮当前列 |
| `wrap` | on | 超长行折行 |
| `linebreak` | off | 折行时按词断，不切断单词 |
| `scrolloff` | 0 | 光标距边缘保留行数 |
| `sidescrolloff` | 0 | 水平方向的同上 |
| `signcolumn` | auto | 标记列 |
| `colorcolumn` | "" | 高亮指定列（如 `80`） |
| `showtabline` | 1 | tab 栏显示策略 |
| `laststatus` | 2 | 状态栏显示策略 |
| `ruler` | on | 显示光标位置 |
| `showcmd` | on | 命令行显示未完成命令 |

## 缩进

| 选项 | 默认 | 作用 |
|---|---|---|
| `tabstop` | 8 | Tab 显示宽度 |
| `shiftwidth` | 8 | 自动缩进宽度 |
| `softtabstop` | 0 | 按 Tab 时的退格宽度 |
| `expandtab` | off | Tab 转空格 |
| `autoindent` | off | 新行沿用上行缩进 |
| `smartindent` | off | 按语法智能缩进 |
| `shiftround` | off | 缩进量对齐到 shiftwidth 的倍数 |

**最常见的混乱**：`tabstop` 是「显示」，`shiftwidth` 是「缩进量」。
改缩进改 `shiftwidth`。

## 搜索

| 选项 | 默认 | 作用 |
|---|---|---|
| `hlsearch` | on | 高亮所有匹配 |
| `incsearch` | on | 边输入边跳 |
| `ignorecase` | off | 忽略大小写 |
| `smartcase` | off | 有大写就区分 |
| `wrapscan` | on | 搜到结尾回到开头 |

`ignorecase` + `smartcase` 组合最常用。

## 编辑行为

| 选项 | 默认 | 作用 |
|---|---|---|
| `clipboard` | "" | 与系统剪贴板同步 |
| `mouse` | off | 鼠标支持 |
| `undofile` | off | 撤销历史存盘 |
| `undolevels` | 1000 | 撤销层数 |
| `backup` | off | 保存时留备份 |
| `writebackup` | on | 写入时临时备份 |
| `swapfile` | on | 交换文件 |
| `backspace` | "" | 退格能删什么 |
| `virtualedit` | "" | 允许光标移到字符之外 |
| `selection` | inclusive | 鼠标选择行为 |
| `whichwrap` | b,s | 哪些键能跨行移动 |

`undofile` 推荐打开——重开文件还能撤销。

## 文件与编码

| 选项 | 默认 | 作用 |
|---|---|---|
| `fileencoding` | "" | 当前文件编码 |
| `fileencodings` | ucs-bom,utf-8,... | 打开时的尝试顺序 |
| `fileformat` | unix | 换行符格式 |
| `fileformats` | unix,dos | 打开时的尝试顺序 |
| `bomb` | off | 是否写 BOM |
| `autochdir` | off | 自动切到文件所在目录 |
| `modeline` | on | 读取文件里的模式行 |

## 界面与终端

| 选项 | 默认 | 作用 |
|---|---|---|
| `termguicolors` | off | 24 位真彩色 |
| `background` | light | 背景明暗（影响主题） |
| `ambiwidth` | single | 歧义宽度字符占几列 |
| `cmdheight` | 1 | 命令行高度 |
| `pumheight` | 0 | 补全菜单最多显示几项 |
| `pumwidth` | 15 | 补全菜单最小宽度 |
| `shortmess` | ... | 缩短哪些消息 |
| `updatetime` | 4000 | 空闲多久触发事件（毫秒） |
| `timeoutlen` | 1000 | 等待后续键的时间（毫秒） |

`timeoutlen` 影响 which-key 弹出的快慢。设小一点菜单出得快。

## 折叠

| 选项 | 默认 | 作用 |
|---|---|---|
| `foldmethod` | manual | 折法 |
| `foldlevel` | 0 | 展开到第几层 |
| `foldlevelstart` | -1 | 打开文件时的折叠层级 |
| `foldenable` | on | 是否启用折叠 |
| `foldcolumn` | 0 | 折叠标记列宽度 |
| `foldtext` | foldtext() | 折叠行显示什么 |

## 按键相关的特殊选项

| 选项 | 作用 |
|---|---|
| `timeoutlen` | 前缀键等待多久（影响 leader） |
| `ttimeoutlen` | 终端键码的等待时间 |
| `matchtime` | 高亮配对括号的时长 |
| `report` | 多少行改动才报告 |

## 怎么查

| 命令 | 作用 |
|---|---|
| `:help 'option'` | 官方文档 |
| `:set option?` | 当前值 |
| `:verbose set option?` | 当前值 + 谁设的 |
| `:set option&` | 恢复默认 |
| `:set all` | 列出所有选项（很长） |

## 这份配置的选项在哪

主文件：`lua/config/options.lua`

按文件类型的：`after/ftplugin/<ft>.lua`

临时改：直接 `:set`，关掉 Neovim 就失效。

## 下一步

- [02 命令与 Ex 历史](commands.html)
- [03 术语对照](glossary.html)
