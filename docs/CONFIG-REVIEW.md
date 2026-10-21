# Neovim 配置审查

这些建议已经按 [CONFIG-CHANGES.md](CONFIG-CHANGES.md) 落地。下面保留审查当时的判断，方便和修改记录对照。

审查对象是这份公开配置的当前源码，运行时为 Neovim 0.12.5。结论按「会按错功能」「功能被静默丢掉」「可以以后再收」分开。审查本身没有改代码。

加载顺序决定谁覆盖谁，后面的判断都按这个顺序：

1. `lua/config/lazy.lua` 里 `require("lazy").setup()` 先登记各插件的 `keys`，并立刻执行 `lazy = false` 插件的 `config`（含 multicursor）。
2. `setup()` 返回后才加载 `lua/config/keymaps-defaults.lua`。
3. 最后加载 `lua/config/keymaps.lua`，同名全局映射以这里为准。
4. 打开缓冲之后，buffer-local 映射再压过全局映射。`LspAttach` 晚于 `FileType`。

`<leader>` 是空格。

## 总评

配置已经从 LazyVim 拆成独立规格，Treesitter 走 `main`、剪贴板后端用的是 Neovim 0.12 认可的名字（`wl-copy`、`pbcopy`、`win32yank`、`xclip`、`tmux`、`osc52`），COBOL 和 blink 的句点、回车也有专门配合。问题集中在三件事：同一套键被两套功能抢、折叠有三个主人、诊断被关掉之后仍有插件在生产和展示它。

## 必须先处理的冲突

### 1. 多光标、搜索、Diffview、对齐抢同一批 leader 键

`lua/plugins/multicursor.lua` 在启动时就绑定这些键，后面的文件再覆盖或和它抢前缀。

| 键 | 最后实际生效 | 被盖住或一起等待的功能 | 建议 |
|---|---|---|---|
| `<leader>s` | 多光标「跳过下一个匹配」 | which-key 把 `<leader>s` 标成 search；`<leader>sr`、`<leader>sg`、`<leader>sw`、`<leader>s\|`、`<leader>s-` 都挂在这个前缀下 | 多光标跳过改到 `<leader>n` 那一组里已有的位置，或 `<C-d>` 之外的专用键。`<leader>s` 只做搜索前缀 |
| `<leader>a` | `keymaps.lua` 里的数字加 1（`noremap` 的 `<C-a>`） | multicursor 的 `alignCursors`。同时还有 `<leader>aa`、`<leader>ac`、`<leader>ad`，所以按空格再按 `a` 会空等 `timeoutlen`（300ms） | 对齐改成 `<leader>ca` 以外的明确键，例如 `<leader>A`。数字加 1 保留 `<leader>a` 时，不要再挂 `aa`/`ac`/`ad`，全选继续用 `<C-a>` |
| `<leader>gv` | 多光标 `restoreCursors` | `lua/plugins/diffview.lua` 的 `<leader>gv` 打开 Diffview。`<leader>gd` 仍然能打开 | 删掉 Diffview 的 `<leader>gv`，或把恢复光标改到 `<leader>mc` 一类不和 git 重叠的键 |
| `<Up>` / `<Down>` | `keymaps-defaults.lua` 的 `gj` / `gk` | multicursor 用上下箭头给相邻行加光标。终端里 `<Up>` 和 `<up>` 是同一键 | 行加光标只用 `<leader><Up>` / `<leader><Down>`（这两条没被覆盖）。普通上下箭头保持移动 |
| `n` / `N` | `keymaps-defaults.lua` 的方向感知 `n` + `zv` | `lua/plugins/dev-visual.lua` 里 hlslens 的 `n`/`N` 会调用 `hlslens.start()`。`*` / `#` 仍会启动 lens，之后按 `n` 不一定刷新 | 保留带 `zv` 的映射，在映射末尾调用 `require("hlslens").start()`。不要两套 `n` |

`<C-n>` 加下一个光标、`<C-d>` 跳过当前匹配是有意做成 VS Code 习惯的。代价是普通模式失去半页下滚 `<C-d>`。`<C-f>` / `<C-b>` / `<C-u>` 还在。若还要半页滚动，把跳过匹配留在 `<leader>n` 的跳过键上，把 `<C-d>` 还给滚动。

`<C-q>` 现在是多光标开关。视觉模式的 `<C-v>` 又被粘贴占用（见下一条），终端里没有第二套「块选」键。建议 `<C-q>` 做块选（这是 `<C-v>` 被占用后的常见替代），多光标开关另选，例如 `<leader>mq`。

### 2. 视觉块模式没有入口

`lua/config/keymaps.lua` 把视觉模式 `<C-v>` 和插入模式 `<C-v>` 都交给 smart-paste。普通模式 `<C-v>` 也在 `lua/plugins/smart-paste.lua` 里做块粘贴。

结果：

- 不能再用 `<C-v>` 进入 Visual-block。
- 插入模式不能再用 `<C-v>` 输入字面控制字符。插入模式的 `<C-q>` 仍是 Neovim 的字面输入键，可以留作这条通路。

建议在文档和 which-key 里写明块选键，并真的映射它。`<C-v>` 继续做粘贴是可以的，只要块选有替代键。

### 3. `<leader>m` 同时是 mark、剪切和书签

三套含义叠在一起：

- 普通模式 `m` 是剪切到系统剪贴板，`mm` 剪切整行。这是 `keymaps.lua` 的既定模型。
- `<leader>m` 被映射成原生 `m`，用来设置 mark，所以它要再等一个 mark 字母。
- `lua/plugins/bookmark.lua` 占用 `<leader>mm`、`<leader>mt`、`<leader>mc`、`<leader>mC`。
- which-key 把 `<leader>m` 标成 bookmarks。

因此 `<leader>mm` 打开书签列表，不能把 mark 设到字母 `m`。按 `<leader>m` 也会因为更长的书签映射而等待 300ms。

建议：mark 改成 `'` 或 `<leader>M` 再加字母；书签继续用 `<leader>m` 前缀。剪切继续用 `m` / `mm` 时，which-key 分组名改成和实际行为一致。

### 4. `<leader>d` 同时是黑洞删除和 profiler

`keymaps.lua` 把 `<leader>d` 映射成 `"_d`（操作符，还要再等一个 motion）。`keymaps-defaults.lua` 又把 profiler 放在 `<leader>dpp` 和 `<leader>dph`。which-key 把这一组标成 debug。

每次按 `<leader>d` 都会等超时，才能开始删除。profiler 也很难按到。

建议：`<leader>d` 只做删除，或只做 debug 前缀。profiler 改到 `<leader>up` / `<leader>uP`。黑洞删除如果只是 `d` 的重复（`d` 已经进黑洞寄存器），可以删掉 `<leader>d`。

### 5. `<leader>c` 一组里，后写的映射盖住了诊断和 COBOL 命令

| 键 | 最终行为 | 到不了的功能 | 建议 |
|---|---|---|---|
| `<leader>cd` | `keymaps.lua` 复制当前文件所在目录 | `keymaps-defaults.lua` 的行诊断浮窗 | 复制目录改成 `<leader>fy` 或 `<leader>cP` 这一类。诊断恢复后用 `<leader>cd` 或 `gl` |
| `<leader>uc` | 切换 `conceallevel` | `cobol.lua` 的 `<leader>uc` → `CobolGuideToggle` | 标尺开关改成 `<leader>cg`。`<leader>u*` 只放 UI 开关 |
| `<leader>cO` | COBOL 缓冲里是 `options.lua` 的整文件重排 | 插件键 `CobolFormatCase`（保留字大小写）在 COBOL 缓冲里被 buffer-local 映射盖住 | 整文件格式用 `<leader>cf` 以外的 `<leader>cF` 会和「复制绝对路径」撞车，建议 `<leader>c=` 做格式化，`<leader>cO` 留给 `CobolFormatCase` |
| `<leader>cr` | 无 LSP 的 COBOL 缓冲是记录布局；LSP `on_attach` 之后变成重命名 | 两边都声明了这个键 | COBOL 记录布局固定用 `<leader>cR` 以外、不和 LSP 重叠的键，例如 `<leader>cL`。`<leader>cr` 只做 LSP rename |
| `<leader>cl` | LSP 缓冲里是 Snacks LSP 信息；COBOL 插件 buffer-local 映射是 `cobc` 飞检 | 同一个键 | 飞检用 `<leader>cK`，`<leader>cl` 留给 LSP info |

`<leader>cf` / `<leader>cF` 复制相对/绝对路径，和 which-key 的 code 分组标题不符，功能本身没有被覆盖。分组可以改名为「code / path」，或把复制路径挪到 `<leader>f`。

### 6. `<leader>sr` 的 grug-far 行为被写了两次，扩展名过滤丢了

`lua/plugins/grug-far.lua` 的 `<leader>sr` 会按当前扩展名填 `filesFilter`。`keymaps.lua` 稍后又绑定 `<leader>sr`，调用不带过滤的 `grug-far.open()`，视觉模式用 `with_visual_selection()`。

后一个生效。插件规格里的键是死的，按扩展名缩小范围的行为也没了。

建议只留 `keymaps.lua` 这一处，把 `filesFilter` 并进去。当前文件替换继续用已经写好的 `<leader>sR`。

## 折叠：三套系统在改同一个选项

启动后折叠相关代码会依次动手：

1. `lua/config/options.lua` 设 `foldmethod=indent`、`foldlevel=99`。
2. `lua/plugins/ufo.lua` 在 `BufReadPost` 用 Treesitter + indent 作为 provider，并把 `foldcolumn` 设为 `1`。
3. `lua/plugins/treesitter.lua` 的 `FileType` 回调对已安装 parser 的缓冲执行 `foldmethod=expr`、`foldexpr=v:lua.vim.treesitter.foldexpr()`。
4. `lua/plugins/aerial.lua` 打开 `manage_folds` 和 `link_tree_to_folds`。
5. COBOL 插件默认 `folding.enable = true`，按 Division/Section/Paragraph 折叠。`treesitter` 文件类型表里没有 cobol，所以 COBOL 不走第 3 步，但会和 UFO 重叠。
6. `lua/plugins/lsp.lua` 只在 `foldmethod == "manual"` 时改成 LSP foldexpr。Treesitter 已经把窗口改成 `expr` 之后，这条几乎不会发生。

UFO 自己的折叠在别的插件把 `foldmethod` 改成 `expr` 之后就不再管这个窗口。现象是：有的缓冲是 UFO 折叠，切一次 filetype 或打开 Aerial 后又变成 Treesitter/indent 折叠，`zR` / `zp` 时灵时不灵。

`ufo.lua` 还有一处直接覆盖显示字符：

```lua
vim.o.fillchars = [[eob:~,fold: ,foldopen:,foldsep: ,foldclose:]]
```

这是整项赋值，会清掉 `options.lua` 里的 `vert=│` 和 `horiz=─`。窗口分隔线会回到默认字符。

建议只留一个折叠主人：

- 用 UFO：删掉 Treesitter 回调里的 `foldmethod` / `foldexpr` 赋值，缩进可以留下。Aerial 设 `manage_folds = false`。COBOL 保持 `foldtext = "auto"`，并确认它不再改 `foldmethod`。
- 不用 UFO：去掉 `nvim-ufo`，Treesitter 缓冲用 expr，其余用 indent。
- `fillchars` 用表合并，只补 fold 相关字段：

```lua
vim.opt.fillchars:append({
  fold = " ",
  foldopen = "",
  foldsep = " ",
  foldclose = "",
})
```

`zp` 在没有折叠时去调 `vim.lsp.buf.hover()`，和 `K` 重复，可以留着，但不要把它当成 LSP hover 的唯一入口。

## 诊断被关掉，但仍在计算和绑定

两处把诊断显示和传入都停了：

- `options.lua`：`vim.diagnostic.config({ enabled = false, virtual_text = false, signs = false, underline = false })`。
- `lua/plugins/disable-diagnostics.lua`：`textDocument/publishDiagnostics` 和 `textDocument/diagnostic` 的 handler 都是空函数。

下面这些仍按「诊断可用」在工作：

- `]d` `[d` `]e` `[w` 和原来的 `<leader>cd`（后者已被复制目录覆盖）。
- heirline 状态栏的 error/warning 徽章，点击会 `vim.diagnostic.get`。
- `satellite.nvim` 的 diagnostic handler。
- `nvim-lint` 对 `sh` / `bash` 在 `BufEnter`、`BufWritePost`、`InsertLeave` 运行 shellcheck。结果进诊断命名空间，界面不显示。
- Mason 在 `VeryLazy` 自动安装 `ruff` 和 `shellcheck`。没有任何地方把 ruff 配成 linter 或 formatter。
- `basedpyright` 的 `typeCheckingMode = "off"`、`reportMissingImports = false`，再加上 handler 被吞掉。服务器仍会做 workspace 分析，界面没有任何 Python 诊断。
- `batch.nvim` 的 `enable_diagnostics = true`。
- COBOL 默认 `diagnostics.enable = true`，保存和改动都会跑 `cobc`。全局 `enabled = false` 让这些诊断不画出来。`vim.diagnostic.setqflist` 仍可能在 `<leader>cq` 里看到，和「完全关闭」不一致。

建议二选一，并写进哪一侧：

- 保持安静界面：shellcheck、COBOL `cobc`、batch 诊断、ruff 安装、状态栏徽章、滚动条诊断标记一起关掉或改成显式命令（`:Lint`、`:CobolLint`）。basedpyright 继续只做补全和 hover 时，把 `diagnosticMode` 调到 `openFilesOnly`，减少空转。
- 恢复诊断：删掉空 handler，把 `vim.diagnostic.config` 改成只关虚拟文本、保留 signs 或 underline。shellcheck 只挂 `BufWritePost`。ruff 要么配进 `nvim-lint` 的 python，要么从 Mason `wanted` 里去掉。

`lua/plugins/lsp.lua` 注释写着 `plugins/lsp-keymaps.lua` 会为了 substitute.nvim 删掉 `gr`。这两个文件/插件都不在当前规格里。Neovim 0.11+ 默认的 `grn` / `grr` / `gra` / `gri` 还在，和 `<leader>cr`、`<leader>ca`、`gI` 重复，但不互相覆盖。`flash.lua` 里「避开 substitute.nvim」的注释同样过时。`flash` 的 `s` / `S` 仍会占用原生 `s`（替换字符）和 `S`（整行修改）。整行修改还有 `cc`。

## 缩进和文件类型

全局是字面 tab：`expandtab = false`，`tabstop = 4`，`shiftwidth = 4`，`softtabstop = 0`。注释写明这是为了保留 tab，COBOL 也依赖它。

Neovim 运行时 ftplugin 会在部分语言里改回空格：Python 和 Markdown 会 `setlocal expandtab`。Lua、JavaScript、TypeScript、JSON、HTML、CSS、Ruby 的运行时 ftplugin **不**设置 `expandtab`，所以这些缓冲会插入 tab。JSON 不允许 tab。这个仓库的 Lua 若用 StyLua，默认也是空格，保存时会和手插的 tab 打架。

`options.lua` 的 YAML `FileType` 在运行时 ftplugin 之后强制 `expandtab = false`。YAML 的缩进必须是空格，这是规格，不是风格偏好。这条 autocmd 会写出无效 YAML。

建议：

- 全局可以继续默认 tab，照顾 COBOL、Go、Makefile。
- 删掉 YAML 那段强制 tab。
- 在 `after/ftplugin/` 里为 `lua`、`javascript`、`typescript`、`json`、`jsonc`、`html`、`css`、`ruby`、`python`、`markdown`、`yaml` 设 `expandtab` 和各自的 `shiftwidth`（Python/Markdown 已由运行时处理，写一份本地文件可以把意图固定下来，避免以后调 autocmd 顺序时回退）。
- `options.lua` 末尾注释写「cursorcolumn=true 保持不动」，实际是 `cursorcolumn = false`。改注释，避免以后有人按注释改回去。

`fileencodings` 在 UTF-8 失败后会试 `cp932` 和 `euc-jp`。这适合日文环境。二进制或损坏的 UTF-8 可能被当成 CP932 打开，保存时再写坏。若这台机器不以日文源码为主，把列表收成 `ucs-bom,utf-8,default,latin1`。

`*.conf` / `*.cnf` / `*.config` 的内容探测把「像 shell」的文件标成 `sh`，把带 `=` 的标成 `dosini`。阈值偏松：一个含几行 `KEY=VALUE` 的 shell 片段可能变成 ini，反过来 5 行 shell 特征就会盖过 ini。探测只看前 120 行，这是合理的。建议 shell 阈值再提高，并且要求 shell 特征明显多于 `=` 行（现在已经要求 `shell > ini`，保留即可）。不要让这条规则去匹配已经有专门 filetype 的路径；`priority = -1` 已经在做这件事。

## 键位模型里另外几条容易误伤的映射

这些看起来是故意的，只是和别的层叠在一起之后代价变大。

- 普通模式 `d` / `c` / `x` / `D` / `C` 和对应的行操作进黑洞寄存器，剪切只走 `m`。配合 `clipboard=unnamedplus`，这个模型是成立的：yank 进系统剪贴板，删除不冲掉它。`cc` 映射到 `"_S` 而不是 `"_cc`。`S` 与 `cc` 等价，但带计数的 `3cc` 在 rhs 以寄存器开头时，计数有时不会作用到预期的行数。建议改成表达式映射，显式使用 `vim.v.count1`。
- 选择模式为 ASCII 33–126 每个字符都做了 `"_c` 映射，避免 snippet 占位符替换时污染剪贴板。映射数量很大。blink 使用原生 snippet，占位符是选择模式。若占位符替换手感异常，先查这组映射。
- COBOL 普通模式 `<Tab>` / `<S-Tab>` 在 `options.lua` 里做整行缩进。终端把 `<Tab>` 和 `<C-i>` 当成同一个键，所以 COBOL 缓冲里 `<C-i>` 不能再沿 jumplist 向前跳。`<C-o>` 还在。缩进改用 `>` / `<`（视觉模式已经有），把普通模式 `<Tab>` 还给 jumplist。插入模式的 COBOL smart tab 在插件里，和这条不是同一个模式。
- 插入模式 `<C-k>` 在带 signature help 的 LSP 缓冲里被 `on_attach` 占用，digraph 输入不可用。可以改成 `<C-S-k>` 做签名帮助，`<C-k>` 留作 digraph。
- `<C-s>` 保存映射在插入/普通/视觉/选择模式。终端若开了 XON/XOFF，`<C-s>` 会在到达 Neovim 之前冻结输出。那是终端设置（`stty -ixon`），不是映射写错。
- `<S-h>` / `<S-l>` 切缓冲，原生的 `H` / `L`（屏幕顶/底）没有了。这是 LazyVim 习惯。`M` 也已经被剪切映射占用。
- `j` / `k` 的 `gj` / `gk` 表达式在 `wrap = false` 时和 `j` / `k` 相同，还让宏和操作符略有差别（`o` 模式没有这套映射）。可以去掉。
- 插入模式 `<C-a>` 变成全选。原生「再次插入上次插入的文本」没有了。全选在普通模式已有 `<C-a>`。
- `flash` 的 `s` 占用字符替换。`S` 占用整行修改。注释里的 substitute.nvim 可以删。
- `<leader>?`：which-key 规格想打开当前缓冲映射，`keymaps-defaults.lua` 在其后把它改成帮助搜索。帮助搜索生效。缓冲映射可以用 which-key 默认流程，或改键到 `<leader>hk`。`<leader>fh` 已经是帮助页。
- `<leader>fg` 和 `<leader>fG`、`<leader>fw` 和 `<leader>fW`、`<leader>fc` 的实现相同，描述却写成 cwd 和 git root 两套。`ff` 用 picker 默认目录，`fF` 才传 git root。把描述改成和参数一致，或给 `fG` / `fW` 补上 `dirs` / `cwd`。

## 界面选项互相覆盖

- `showmode = true`，同时 heirline 有 Mode 组件，`cmdheight = 0`。模式会在状态栏显示；`showmode` 还想在命令行显示，而命令行高度是 0，消息改由 noice 的 cmdline 视图接手。建议 `showmode = false`，只留状态栏。
- `conceallevel = 2` 是全局的。JSON 字符串引号、帮助页标记都会藏。markview 又在 Markdown 里做一层预览。建议全局 `conceallevel = 0`，只在 markdown `FileType` 里设 `2`，或完全交给 markview。`<leader>uc` 的开关可以保留。
- `listchars` 包含 `eol = "↴"`。每一行行尾都有标记，和相对行号叠在一起，重绘也更贵。COBOL 已经按窗口关掉 `list`。建议默认去掉 `eol`，`trail` 留着即可。
- `vim.opt.statusline = " "` 在 heirline（`VeryLazy`）之前清空状态栏，启动后会空一拍。可以留到 heirline 里设置。
- `laststatus = 3` 与 heirline 全局状态栏一致，这个是对的。
- `mousemoveevent` 在 `options.lua` 里关掉，注释说明原生 confirm 会把鼠标移动当成非法回答。heirline 打开状态栏菜单时临时设成 `true`。菜单关闭路径必须把它设回去；打开失败或中途抛错时要放在 `finally` 式的 `pcall` 收尾里，避免 confirm 再次被鼠标移动刷屏。
- `equalalways = false`、`winwidth = 1`、`winminwidth = 1` 是为了避免侧栏被等分挤成一列。副作用是普通分割也能缩到 1 列。侧栏用 `winfixwidth` 加明确宽度即可，全局 `winminwidth` 可以回到 10 左右。
- GitSigns 的 `*Ln` 高亮在 `autocmds.lua` 里设置了，gitsigns 配置没有打开 `linehl`。这些整行背景不会出现。符号色 `#00ff00` / `#ffff00` / `#ff0000` 会盖过 `blue` 配色里的 git 色。要么删掉未使用的 `*Ln`，要么把符号色改成主题色。
- snacks `picker.layout` 的 `min_width = 120`。窄终端或分屏里 picker 可能画不开。把 `min_width` 降到 `math.min(120, vim.o.columns - 2)` 一类的值。
- markview 同时写了 `lazy = false` 和 `ft`。`lazy = false` 让它启动即加载，`ft` 不起延迟作用。Markdown 预览不需要堵在启动路径上，去掉 `lazy = false` 即可。
- `defaults.lazy = false` 让没写 `lazy` / `event` / `cmd` / `keys` / `ft` 的规格在启动时加载。多数插件自己写了延迟，真正常驻的还有 snacks、multicursor、dashboard、auto-session、markview。`checker.enabled = true` 会在后台访问 GitHub 查更新。启动变慢时先关 checker 通知以外的自动检查，或改成手动 `:Lazy check`。

## 远程图片和机器相关逻辑

`lua/plugins/snacks.lua` 里有两段只适合某一台机器、放进公开仓库会误伤别人：

- 主机名等于 `hx90` 时不当作远程；其他主机名在 tmux 里会设 `SNACKS_SSH=1`。换机器或本地 tmux 也会走远程图片路径。判断应只看 `SSH_CONNECTION` / `SSH_CLIENT` / `SSH_TTY`，或一个显式环境变量，不要写死主机名。
- tmux 的 `client_termname` 只要是 `xterm-256color` 或 `tmux-256color` 就把 `SNACKS_KITTY=1`。非 Kitty 终端会收到 Kitty 图形序列，屏幕上是乱码。只在 `client_termname` 含 `kitty`，或用户设置了 `SNACKS_KITTY=1` 时打开。

grep 的 transform 包了一层 `pcall`，`file_sep` 错误会丢掉该行。两个分支都 `return false`，所以**任何** transform 错误都被静默吞掉，picker 会少结果且没有提示。只在错误文本含 `file_sep` 时丢弃，其他错误应重新抛出。

`min_width`、主机名和 Kitty 探测是公开配置里最应该收干净的三处，它们和本机 Kitty/tmux 调试绑在一起。

## 启动时加载的大表

`lua/config/markdown_typography.lua` 在 `lazy.lua` 末尾无条件 `setup()`，并 `require("config.delek_palette")`。调色板文件有七千行以上的高亮定义，即使用户当天不打开 Markdown 也会解析。把 `setup()` 挪到 markdown `FileType` 里，或把调色板改成按组查询的小表。

which-key 的 `View.show` 被整段替换，用来加 winbar 标题和改高度。which-key 升级后内部字段 `View.view`、`View.footer`、`State.state` 一变就会在按 `<leader>` 时报错。升级 which-key 后要先按一次空格验证。能用官方 `win.title` 就不要包 `View.show`。

blink 的 snippet 修复使用 `vim.lsp._snippet_grammar` 和 `vim.snippet._session`。这是私有 API，Neovim 小版本升级可能直接报错。包在 `pcall` 里是有的；升级后打开一个带 snippet 的 LSP 补全确认仍能展开。

`lua/plugins/gitsigns.lua` 第二个规格的 `opts` 函数不接收、也不返回 opts，只为了登记 `<leader>uG`。lazy.nvim 在函数返回 nil 时会保留已合并的 opts，所以 signs 和 `on_attach` 还在。这种副作用应挪到 `config` 里，避免以后 lazy 的合并规则变化时把 gitsigns 配置清掉。版本钉在 `v2.1.0`，其余插件跟随主分支。钉版没有错，只是修安全问题时要记得抬版本。

`lua/config/lazy.lua` 用 `vim.version().minor >= 10` 判断 `smoothscroll`。0.12 上成立。若将来是 1.0，`minor` 为 0，判断会失败。这个选项在 0.12 上可以直接设。

## 空缓冲和 Dashboard

`lua/config/autocmds.lua` 在 `BufEnter` 时，若当前是未命名、未修改、只有一行空文本的普通缓冲，并且当前 tab 没有其他已命名文件缓冲，就执行 `:Dashboard`。

因此：

- 关掉最后一个文件后回到 Dashboard，这是想要的。
- `<leader>fn`（`:enew`）在没有其他文件时也会立刻被送回 Dashboard，scratch 缓冲建不出来。
- Dashboard 自己的 New file 走 `file_actions.new_file()`，会先问路径再 `:edit`，不受这条影响。

建议：Dashboard 只在「最后一个真实文件被关掉」时出现，例如在 `BufDelete` 里判断，而不是每一个空的未命名缓冲。`<leader>fn` 保持 `:enew`。

`SwapExists` 无条件 `vim.v.swapchoice = "e"`。全局已经 `swapfile = false`，新的交换文件不会再创建。若磁盘上还留着旧 swap，这个 autocmd 会直接继续编辑，不提示另一侧可能有未保存内容。可以改成只在 `swapfile` 已关、且 swap 的进程不存在时才选 `e`。

## 建议的修改顺序

1. 键位只留一个主人。按上一节的表改 multicursor、`<leader>m`、`<leader>d`、`<leader>c*`、`<leader>sr`，并补上块选键。改完用 `:map <leader>s`、`:map <leader>a`、`:map <leader>gv`、`:map <leader>uc`、`:map <leader>cd` 核对。
2. 折叠只留 UFO 或只留 Treesitter expr。修 `fillchars` 赋值。打开 Lua 文件看 `foldmethod`，再开一次 Aerial，确认没有被改回去。
3. 诊断策略写死一种。要么界面真的安静、后台也不跑 shellcheck/cobc/ruff；要么把空 handler 去掉并让徽章、`]d`、shellcheck 指向同一套可见诊断。
4. 删掉 YAML 强制 tab。为会提交到 Git 的空格语言补 `after/ftplugin`。
5. 去掉主机名和「所有 256 色 tmux 都是 Kitty」的判断。grep transform 只吞 `file_sep`。
6. Markdown 调色板和 markview 改为按 filetype 加载。which-key 的 `View.show` 包装列成升级检查项。

每一步之后跑已经在仓库里的相关规格，而不是只看界面：

- 键位和粘贴：`tests/blink_keymap_spec.lua`、`tests/markdown_image_paste_spec.lua`
- COBOL 缩进、回车、空白：`tests/cobol_indent_spec.lua`、`tests/cobol_backspace_spec.lua`、`tests/cobol_whitespace_spec.lua`
- 状态栏和菜单：`tests/statusline_menu_ui_spec.py`、`tests/bar_feedback_runtime_spec.lua`
- 安装脚本若没改：不必跑 `tests/init_spec.sh`

改 Lua 后执行 `git diff --check`。

## 已经做对、不必为了「像 LazyVim」再改的部分

- `init.lua` 只引导 lazy，选项在 leader 设置之后、插件加载之前执行。
- 剪贴板字符串后端和 Neovim 0.12 的 `provider/clipboard.vim` 一致；先找可用的 `wayland-*` socket 再选 `wl-copy`，能避开 tmux 里过期的 `WAYLAND_DISPLAY`。
- `lazydev` 不存在时会从 blink 源里拿掉，不会在 Lua 补全时报模块缺失。
- Treesitter `main` 与 textobjects `main` 符合仓库要求；`indentexpr()` 在当前安装的插件里存在。
- snacks explorer 关着，文件树只走 neo-tree。`<leader>fe` 设为 `false` 只作用于 snacks 自己的键表，不会拆掉 neo-tree。
- noice 关了 notify 和 LSP hover/signature，避免和 snacks notifier、原生 `K`、fidget 各画一层。
- 黑洞寄存器 + 专用剪切这条编辑模型是连贯的，问题只在它和书签、profiler、多光标抢前缀。
- COBOL 插入回车会先接受可见的 blink 菜单，句点会关掉补全。这和 `cobol_indent_spec.lua` 的断言一致。
- `lazy-lock.json` 被忽略、`nvim-local.lua` 留在配置目录外面，和 `AGENTS.md` 一致。

## 源码位置

| 主题 | 文件 |
|---|---|
| 选项、诊断开关、YAML tab、COBOL 缩进键、fillchars、剪贴板 | `lua/config/options.lua` |
| 加载顺序 | `lua/config/lazy.lua` |
| 被覆盖的 LazyVim 风格键 | `lua/config/keymaps-defaults.lua` |
| 个人键，最终覆盖全局同名映射 | `lua/config/keymaps.lua` |
| 多光标 | `lua/plugins/multicursor.lua` |
| 搜索替换两套 `<leader>sr` | `lua/plugins/grug-far.lua` |
| 折叠与 fillchars | `lua/plugins/ufo.lua`、`lua/plugins/treesitter.lua`、`lua/plugins/aerial.lua` |
| 诊断 handler | `lua/plugins/disable-diagnostics.lua`、`lua/plugins/shellcheck.lua`、`lua/plugins/lsp.lua` |
| 书签与 `<leader>m` | `lua/plugins/bookmark.lua` |
| 图片探测与 grep 补丁 | `lua/plugins/snacks.lua` |
| which-key 分组与 `View.show` | `lua/plugins/which-key.lua` |
| 空缓冲打开 Dashboard | `lua/config/autocmds.lua` |
| 启动时加载的大调色板 | `lua/config/markdown_typography.lua`、`lua/config/delek_palette.lua` |
