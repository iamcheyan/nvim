# 配置修改记录

## 2026-10-24：日常操作与定向重载

- `<leader>N` 固定为默认命名文件的新 tab page；`<leader>fn`、加号及编辑区/文件条右键菜单共用文件名输入流程。
- 多光标下一/上一匹配改为 `<leader>mn` / `<leader>mN`，替代下方旧记录中的 `<leader>n` / `<leader>N`；普通和可视模式一致。
- 文件条保留全局 buffer 列表，显示可点击的 tab page 数字入口；点击已有文件优先返回它所在窗口。
- 新增 `:ConfigReload`、`<leader>uR` 和底部模式菜单重载入口，支持快捷键、文件操作、状态栏三个范围。
- 状态栏菜单与 L/C/P 位置组件拆至 `lua/config/statusline/`，保留跳转行/列和复制位置；移除未显示时钟的定时重绘。
- `:new` / `:tabnew` 均保留原生命令行为。完整使用说明见[新建文件、文件条与配置重载](guides/FILES-TABS-AND-RELOAD.md)。

## 2026-10-21：配置审查落实

日期：2026-10-21。依据是 [CONFIG-REVIEW.md](CONFIG-REVIEW.md)。审查里的建议都已落到源码。给人看的摘要在 [CONFIG-REPORT.md](CONFIG-REPORT.md)。本文按文件记下改了什么、为什么、怎么退回。没有做 git commit。

加载顺序没有变：`lazy.setup()` 先登记插件 `keys` 并执行 `lazy = false` 的 `config`，然后 `lua/config/keymaps-defaults.lua`，最后 `lua/config/keymaps.lua` 覆盖同名全局左键。缓冲局部映射和 `LspAttach` 更晚。

## 键位

### `lua/plugins/multicursor.lua`

| 原来 | 现在 |
|---|---|
| `<up>` / `<down>` 在相邻行加光标 | 删掉。普通箭头保持移动 |
| `<leader><up>` / `<leader><down>` 跳过一行 | 保留，仍是 `lineSkipCursor` |
| `<leader>s` / `<leader>S` 跳过匹配 | 删掉。`<leader>s` 只做搜索前缀 |
| `<C-d>` 跳过匹配 | 删掉，半页下滚回到 Neovim |
| `<leader>a` 对齐列 | 改成 `<leader>A`。`<leader>a` 只做数字加 1 |
| `<C-q>` 暂停光标 | 改成 `<leader>mq`。光标层里 Escape 重新启用的注释同步改了 |
| `<leader>n` / `<leader>N`、`<C-n>`、`<C-S-n>`、`ga`、`<leader>gv`、Ctrl+鼠标 | 没动 |

跳过匹配的新键是 `<M-d>`（下一个）和 `<M-D>`（上一个）。终端里 Alt+Shift+d 一般送 `<M-D>`，没有写成 `<M-S-d>`。

退回：把上表左列的 `vim.keymap.set` 加回这个文件，并删掉右列新增的四条。

### `lua/plugins/diffview.lua`

删掉 `<leader>gv` → `DiffviewOpen`。打开差异仍是 `<leader>gd`。`<leader>gv` 留给多光标恢复。

### `lua/config/keymaps.lua`

- Path copies moved from `<leader>c*` to `<leader>y*`: `<leader>yp` copies a relative path, `<leader>yP` an absolute path, and `<leader>yd` the directory. All go to the `+` register.
- `<leader>cd` remains available for line diagnostics.
- Removed the redundant `<leader>aa`, `<leader>ac`, `<leader>ad`, and `<leader>d` mappings. `d`, `c`, and `x` already use the black-hole register. Clear buffer is now `<leader>bC`.
- `<C-a>` selects all in Normal and Visual modes. Insert mode keeps its native insert-previous-text behavior. `<leader>a` increments the number without triggering select-all.
- `<C-q>` maps to native Visual Block mode. Insert `<C-v>` remains smart paste; Insert `<C-q>` inserts the literal control character.
- `dd` and `cc` use expressions to preserve counts while deleting to the black-hole register.
- `<leader>M` followed by a letter sets a mark. Bookmarks remain under `<leader>m`; cut mappings remain `m`, `mm`, and `M`.

### `lua/config/keymaps-defaults.lua`

- `n` / `N` follow `vim.v.searchforward`; Normal mode opens folds and starts hlslens only after a successful search, Visual mode does neither, and Operator-pending mode returns a search motion. A missing match ignores E486 while other errors still propagate.
- Grep pickers use the current directory or Git root according to their descriptions; Git-root searches fall back to the current directory.
- `<leader>?` remains the Help picker. Buffer keymaps are listed with `<leader>hk`.
- Profiler toggles are `<leader>dpp` and `<leader>dph`.

### `lua/plugins/which-key.lua`

All root group labels are English. Buffer and window groups expand to entries named from their buffer or window content.

### `lua/plugins/dev-visual.lua`

hlslens 不再绑定 `n` / `N`。`*` `#` `g*` `g#` 仍调用 `hlslens.start()`。

### `lua/plugins/grug-far.lua` 与 `keymaps.lua`

插件规格里的 `<leader>sr` 删掉，只留命令 `GrugFar` / `GrugFarWithin`。唯一的键在 `keymaps.lua`：项目替换带 `filesFilter = "*.<当前扩展名>"` 和 `transient = true`；无扩展名或特殊缓冲不填过滤。可视模式用 `with_visual_selection`。`<leader>sR` 用 `paths` 限定当前文件。

### `lua/plugins/which-key.lua`

- 组名：`<leader>d` 是 profiler，新增 `<leader>y`（yank path）和 `<leader>h`（help）。原先单独的 `<leader>dp` 分组行去掉了，`dpp` / `dph` 仍挂在 `d` 下面。
- `<leader>?` 的 which-key 项改成 `<leader>hk`，调用 `require("which-key").show({ global = false })`。
- `win.title = true`，`title_pos = "center"`，边框仍是 `single`。
- 删掉替换 `View.show` 的那段（winbar 标题、高度加一、页脚挪动）。配色高亮和 `ColorScheme` 自动命令还在，然后自己调用 `wk.setup(opts)`。`WhichKeyTitle` 高亮组现在没有引用它的代码，主题文件里的定义留着。

### `lua/plugins/cobol.lua` 与 `lua/config/options.lua` 的 COBOL 段

插件规格键：

| 原来 | 现在 |
|---|---|
| `<leader>uc` 列标尺 | `<leader>cg` |
| `<leader>cr` 记录布局 | `<leader>cL` |
| `<leader>cl` cobc 检查 | `<leader>cK`，调用 `require("cobol.diagnostics").lint(0, { interactive = true })` |
| `<leader>cO` 保留字大小写 | 不动 |

整缓冲重排从 `<leader>cO` 改成 `<leader>c=`。规格里曾经多写过一条 `<leader>c=` → `CobolFormatCase`，会盖住重排，已经删掉。

安装的 cobol.nvim 仍会在 FileType 里设缓冲局部的 `<leader>cr` / `<leader>cl`。`options.lua` 的 FileType 回调用 `vim.schedule` 在插件之后删掉这两条，再设 `<leader>cL` / `<leader>cK`。没有改插件仓库。运行时用的是 lazy 克隆，不是 `~/development/cobol.nvim`，因为没有 `~/.config/nvim-local.lua`。

普通模式 COBOL 的 `<Tab>` / `<S-Tab>` 删掉，`<Tab>` 重新等于 `<C-i>`。可视和选择模式的 Tab，以及 `>` / `<`，还在。不再使用的 `shift_cobol_current` 删了。

`opts.folding.enable = false`（`foldtext` 仍是 `"auto"`）。插件因此不再把窗口设成自己的 `foldmethod=expr`。代价：COBOL 结构折叠没有了，剩下 UFO 的缩进折叠。要退回结构折叠，把 `enable` 改回 true，并接受它再次覆盖 UFO。

### `lua/plugins/lsp.lua`

- 插入模式签名帮助从 `<C-k>` 改成 `<C-S-k>`。`<C-k>` 留给 digraph。普通模式 `gK` 不动。
- 删掉 `on_attach` 里把 `foldmethod` 改成 LSP 表达式的那段。
- basedpyright `diagnosticMode` 从全工作区改成 `openFilesOnly`。`typeCheckingMode = "off"` 和 `reportMissingImports = false` 没动。
- 过时注释（`plugins/lsp-keymaps.lua`、substitute.nvim、诊断被 disable-diagnostics 关掉）改成与现状一致。`grn` / `grr` / `gra` / `gri` 仍是内建映射。
- blink 里对 `vim.lsp._snippet_grammar` 和 `vim.snippet._session` 的调用本来就在 `pcall` 里，没有改代码。

### `lua/plugins/flash.lua`

只改了注释：`r` / `R` 保持原生。

### 明确没改的键

`<S-h>` / `<S-l>` 切缓冲。选择模式可打印字符进黑洞寄存器。`<C-s>` 保存没改；若终端吞掉 Ctrl-S，在 shell 里 `stty -ixon`。`<leader>fe` 仍关着 snacks explorer，不会拆掉 neo-tree。剪贴板 provider 的字符串名字在 Neovim 0.12.5 上有效，没有改。

## 折叠

- `lua/plugins/treesitter.lua` 的 `enable_treesitter` 只设 `indentexpr`。不再写 `foldmethod` / `foldexpr`。
- `lua/plugins/aerial.lua`：`manage_folds = false`，`link_tree_to_folds = false`。`win_opts.winfixwidth = true`。cobol.lua 里另一份 aerial 规格只扩展 backends，lazy 合并后这两项还在。
- `lua/plugins/ufo.lua`：`vim.o.fillchars = "eob:~,..."` 整段字符串赋值改成 `vim.opt.fillchars:append({ eob="~", fold=" ", foldopen="", foldsep=" ", foldclose="" })`。这样不会冲掉 `options.lua` 里的 `vert` / `horiz`。
- `options.lua` 里启动时的 `foldmethod=indent`、`foldlevel=99` 还在，作为 UFO 接管前的底。

## 诊断

- 删除 `lua/plugins/disable-diagnostics.lua`。它把 `textDocument/publishDiagnostics` 和 `textDocument/diagnostic` 的 handler 换成空函数。
- `options.lua` 的 `vim.diagnostic.config` 从全部关闭改成：`virtual_text = false`，`signs = true`，`underline = true`，`update_in_insert = false`，`severity_sort = true`。没有设 `enabled = false`。
- `lua/plugins/shellcheck.lua` 增加 `python = { "ruff" }`。自动命令只留 `BufWritePost`，组名 `NvimLintOnWrite`，有 linter 的 filetype 才 `lint.try_lint()`。不再在 `BufEnter` / `InsertLeave` 跑。
- bufferline 的 `diagnostics = false` 没动，标签栏不画诊断。

## 选项、缩进、界面

### `lua/config/options.lua`

- `fileencodings` 从含 `cp932,euc-jp,iso-2022-jp` 收成 `ucs-bom,utf-8,default,latin1`。损坏的 UTF-8 不再被当成日文打开再存坏。若还需要日文误判回退，把那三项加回去。
- `*.conf` 的 shell 探测：shell 特征阈值从 `>= 5` 提到 `>= 8`，并且仍要求 shell 分高于 ini。
- `showmode = false`。模式在 heirline 上，`cmdheight = 0`。
- `conceallevel = 0`。Markdown 在 `after/ftplugin/markdown.lua` 里设回 2。
- `listchars` 去掉 `eol=↴`，`trail` 还在。
- `smoothscroll = false`，不再包 `vim.version().minor >= 10`。
- `winwidth` / `winminwidth` 从 1 改成 10。`equalalways` 仍是 false。
- 注释与代码对齐：`cursorcolumn = false`。
- 删掉 YAML FileType 里强制 `expandtab = false` 的自动命令。YAML 用空格。
- 空白 `statusline = " "` 保留。heirline 是 VeryLazy，这行挡住默认文件名状态栏闪一下。审查里倾向留着，实现中一度删过，已加回。

### `after/ftplugin/`

全局默认仍是 Tab（`expandtab = false`，`tabstop` / `shiftwidth` 4，`softtabstop` 0），给 COBOL、Go、Makefile。

| 文件 | 设置 |
|---|---|
| lua、javascript、javascriptreact、typescript、typescriptreact、json、jsonc、html、css、ruby、yaml | `expandtab`，`shiftwidth` 2，`softtabstop` 2 |
| python | `expandtab`，宽度 4 |
| markdown | `expandtab`，`conceallevel` 2。不改 `shiftwidth`，运行时 ftplugin 的 4 保留 |

`javascriptreact` / `typescriptreact` 不在审查清单里。不加的话 JSX/TSX 会留在全局 Tab 上，和同语言的 2 空格不一致，所以一起加了。

### `lua/config/autocmds.lua`

- Dashboard：不再在每个空的无名 `BufEnter` 上打开。具名普通缓冲 `BufDelete` 时做标记；紧接着的 `BufEnter` 若是空无名缓冲，且没有别的具名文件缓冲，才 `:Dashboard`。`:enew` / `<leader>fn` 仍是草稿。用 `nvim_list_bufs()` 看全部缓冲，不只看当前标签页窗口。
- 删掉 GitSigns 的 `*Ln` 高亮覆盖，以及 `#00ff00` / `#ffff00` / `#ff0000` 符号色。颜色交给配色。`linehl` 本来就没开。命令行高亮的 `ColorScheme` 组留着，组名 `CmdlineHighlights`。
- `SwapExists`：读 `vim.fn.swapinfo(vim.v.swapname).pid`。pid 大于 0 且 `ps -p` 显示进程还在，就不设 `swapchoice`。否则 `swapchoice = "e"`。全局 `swapfile` 仍是 false。

### 窗口宽度在会话恢复时

`lua/config/sidebar_session.lua` 和 `lua/plugins/auto-session.lua` 的 `post_restore_cmds` 曾把 `winwidth` / `winminwidth` 设回 1，会盖掉上面的 10。两处都改成先设 `winwidth` 再设 `winminwidth`。neo-tree 进入时设 `winfixwidth`，宽度仍是 32。aerial 见上。

会话脚本自己会先 `set winwidth=1`，再把开头读到的 `winminwidth` 写回去。平时这个值是 10，恢复就会报 `E592` 并停在半截会话上，which-key 也被错误弹窗挡住。`pre_restore_cmds` 里先把 `winminwidth` / `winminheight` 降到 0，会话读到的是 0；`post_restore_cmds` 再升回 10。

### `lua/plugins/markview.lua`

去掉 `lazy = false`，让已有的 `ft` 生效，Markdown 缓冲才加载。

### `lua/config/lazy.lua`

- `checker.enabled = false`。更新用手动 `:Lazy check`。`notify` 仍是 false。
- `defaults.lazy` 保持 `false`。审查明确说不要为了启动速度把它改成 true：`mason-lspconfig` 和 `nvim-web-devicons` 没有 event/cmd/keys/ft，改成 true 后 `vim.lsp.enable` 和图标覆盖要等别的插件去 `require` 才跑。实现中一度设成 true，并且只给 bufferline、smart-paste 补了 `lazy = false`，发现 Mason 的 VeryLazy 安装回调和语言服务器都不会在启动时注册，已改回 false。这两条显式 `lazy = false` 留着，以后若再改默认值，标签栏和粘贴仍会启动。
- `require("config.markdown_typography").setup()` 改成只在 `FileType markdown` 时调用。`delek_palette.lua` 不再在启动时解析。quarto / rmd 不触发；`setup` 自己也只处理 markdown。

### `lua/config/markdown_typography.lua`

`M.setup` 若 `M._ready` 已设就返回。当前缓冲已是 markdown 时会再应用一次。模块顶层的 `require("config.delek_palette")` 仍在第一次 `require` 这个模块时执行，推迟的是第一次 require 的时机。

### `lua/plugins/snacks.lua`

- 删掉主机名 `hx90` 判断，也删掉 tmux `show-environment SSH_CLIENT`。远程只看 `SSH_CONNECTION`、`SSH_CLIENT`、`SSH_TTY`，或已经设置的 `SNACKS_SSH`。
- `SNACKS_KITTY=1` 只在 `TERM` / `TERM_PROGRAM` 含 kitty、tmux `client_termname` 含 kitty、或变量已经设置时写入。`xterm-256color` 和 `tmux-256color` 不再当成 Kitty。
- grep 的 transform：`pcall` 失败时，只有错误字符串含 `file_sep` 才返回 false；其他错误 `error(ret)` 重新抛出。
- picker `min_width` 不再写死 120。`snacks.setup` 之前计算 `math.min(120, math.max(40, vim.o.columns - 4))`。

### `lua/plugins/gitsigns.lua`

第二份规格里用 `opts = function()` 副作用去映射 `<leader>uG` 的写法删了。第一份规格的 `config` 先 `require("gitsigns").setup(opts)`，再用 `pcall(require, "snacks")` 注册 Git Signs 开关到 `<leader>uG`。版本钉在 `v2.1.0`。定义 `config` 后 lazy 不再自动 setup，所以这里必须自己调用。

### `lua/plugins/heirline.lua`

打开状态栏菜单时若还没装上 `_G._statusline_menu_close`，`vim.schedule` 把 `mousemoveevent` 设回打开前的值。成功关掉菜单的路径本来就会恢复。

### `lua/plugins/neo-tree.lua`

`config.ui_highlights` 将 Neo-tree 的 expander/indent 高亮组背景设为透明，防止组默认链接中的深蓝底色盖住 `CursorLine`，造成展开箭头后的空格颜色断层。进入 Neo-tree 窗口时也会关闭 fold、sign 和 status gutter，避免选中行高亮前出现多余空格；`winfixwidth` 保持不变。

## 文档

会和上述行为矛盾的说明已改：

- `docs/guides/MOUSE-AND-CLIPBOARD.md`：插入 `<C-a>`、`<C-q>` 视觉块、`<leader>M` 设 mark、`<leader>y*` 复制路径。
- `docs/plugin-guide/README.md`：搜索目录、诊断、多光标、which-key、路径复制。
- `docs/plugins/chapters/multicursor.nvim.md`、`which-key.md`、`cobol.md`、`grug-far.nvim.md`、`snacks.nvim.md`。
- `docs/guides/REMOTE-MARKDOWN-IMAGES-INVESTIGATION.md` 保留当时的探测描述，并加了一段说明当前代码已经不再那样做。
- `nvim-lint` 章节在这次改键之前已经写成与新行为一致，没有再改段落。
- `docs/plugins/chapters/` 里相对 HEAD 还有一批更早的教程体扩写。这次没有回退它们，只改正了仍写着旧键的 COBOL、多光标、which-key、snacks、grug-far。

`docs/CONFIG-REVIEW.md` 开头加了指向本文的一句。正文仍是审查时的判断，不是现状。

## 核对

2026-10-21，Neovim 0.12.5，`nvim --headless -u NONE -l`：

- `tests/blink_keymap_spec.lua`
- `tests/cobol_indent_spec.lua`
- `tests/cobol_backspace_spec.lua`
- `tests/cobol_whitespace_spec.lua`
- `tests/markdown_image_paste_spec.lua`
- `tests/sidebar_session_spec.lua`（35 项）
- `tests/fresh_menu_spec.lua`
- `tests/snacks_image_terminal_size_spec.lua`

另外用 `loadfile` 检查了 `lua/**/*.lua` 和 `after/ftplugin/*.lua`（77 个文件），并用无界面 Neovim 确认 lua/yaml 宽度 2、python 宽度 4、typescriptreact 宽度 2、markdown `conceallevel` 2。`git diff --check` 没有空白错误。

同一天晚些时候用真实终端再启动了一次：会话恢复不再报 `E592`，按下空格后 which-key 的 Leader 菜单能打开。Dashboard 在关掉最后一个文件后出现、以及真实 LSP 诊断，仍然没有在界面里点过。未提交。
