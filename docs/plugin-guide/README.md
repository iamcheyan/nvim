# 当前 Neovim 插件使用手册

这份手册按当前 `lazy.nvim` 插件规格编写。插件目录共 **48 个条目**（公开 42 个、私有 6 个）；依赖库和管理器也计入总数。分类目录和逐项练习见 [插件使用书](../plugins/PLUGINS.md)。

插件仍然可以因未安装的外部工具、当前 filetype 或 LSP 服务器能力不同而表现不同。`<leader>` 是空格。`<leader>` 后停顿可看 which-key 提示；`<leader>?` 打开帮助搜索，`<leader>hk` 查看当前缓冲的快捷键。

## 快速入口

| 想做什么 | 入口 |
|---|---|
| 搜索文件/内容 | `<leader>ff` / `<leader>fg` |
| 打开文件侧栏 | `<leader>fe`，当前工作目录用 `<leader>fE` |
| 格式化 | `<leader>fo`（由 LSP 提供） |
| Git 行修改 | `<leader>gp` 预览，`<leader>gs` 暂存，`<leader>gb` blame |
| Git 完整差异 | `<leader>gd`；关闭 `<leader>gq` |
| 查看符号大纲 | `<leader>cs` |
| 多文件查找替换 | `<leader>sr` |
| 查看剪贴板历史 | `<leader>fy` |
| Markdown 预览开关 | `<leader>um` |
| 查看个人书签 | `<leader>mm` |
| 包围符号添加/替换/删除 | `gsa` / `gsr` / `gsd` |
| 打开 quickfix 结果 | `<leader>xq`；列表内 `>` 展开上下文，`<` 收起 |
| 查看完整命令/快捷键 | `<leader>` 后稍候；`<leader>hk` 看当前缓冲，`<leader>?` 搜帮助，`:WhichKey` |
| COBOL 定义跳转与返回 | `gd` 跳转，`Ctrl-o` 返回；`:help jumplist` |

## 搜索、文件与界面

### snacks.nvim（公开）

当前配置的主要文件/文本搜索器，也承载通知、状态列、部分小工具和 LazyGit 集成。常用入口：`<leader><space>` / `<leader>ff` 找文件，`<leader>fF` 从 Git 根目录找文件，`<leader>fb` 缓冲区，`<leader>fr` 最近文件，`<leader>fg` 在当前目录搜内容，`<leader>fG` 在 Git 根目录搜内容，`<leader>fw` 在当前目录搜光标词，`<leader>fW` 在 Git 根目录搜光标词，`<leader>/` 用 picker 默认目录搜内容，`<leader>fh` 帮助，`<leader>fS` Treesitter 符号。picker 中输入查询，Enter 打开，Esc 关闭；`Alt-h` 切换隐藏文件，`Alt-i` 切换忽略文件。若系统装有 `lazygit`，`<leader>gg` 在 Git 根目录启动、`<leader>gG` 在当前目录启动。`<leader>gl/gL` 看 Git log，`<leader>gf` 看当前文件历史。复制路径用 `<leader>yp`、`<leader>yP`、`<leader>yd`。

### dashboard-nvim（公开）

启动页使用 Hyper 主题。项目列表展示最近识别到的工作目录（最多 8 个），选中项目会用 Snacks 文件搜索器在该目录内找文件；MRU 列表显示最近打开的文件（最多 10 个，不限于当前目录）。`f` 找文件，`s` 搜索文本，`l` 打开 Lazy。可用 `:Dashboard` 再次打开启动页。启动时若 Auto Session 找到项目会话，会先恢复会话；没有可恢复会话时显示 Dashboard。

配置关闭了 Snacks 自带 Explorer 与 Scroll，文件侧栏由 Neo-tree 提供，边缘滚动标记由 Satellite 提供。编辑器状态栏的 Explorer 项目键也已交给 Neo-tree。

### neo-tree.nvim（公开）

文件树、缓冲区和 Git 状态侧栏。`<leader>fe` 切换项目根目录文件树，`<leader>fE` / `<leader>e` 切换当前工作目录文件树，`<leader>ge` 切换 Git 状态视图，`<leader>be` 切换缓冲区视图；也可运行 `:Neotree`。文件树中 Enter 打开、左右方向/`h`/`l` 展开或收起，具体操作按 `?` 查看 Neo-tree 帮助。Git 状态视图配置了 `ga` 暂存文件、`gu` 取消暂存、`gr` 撤销文件修改、`gc` 提交、`gp` 推送、`gg` 提交并推送。需要 Git 命令可执行。

### bufferline.nvim（公开）

顶部缓冲区标签栏。点击标签切换，点标签关闭图标关闭缓冲区，中键关闭，右键打开本配置的缓冲区菜单；点击右侧 `+` 新建空缓冲区。键盘切换使用 `Shift+h` / `Shift+l`，或 `<leader>bh` / `<leader>bl`。`<leader>bb` 切换到上一个缓冲区。`WDIFF_NVIM=1` 时此插件禁用。标签栏不代表 Vim tab page；tab page 列表用 `<leader><tab><tab>`。

### grug-far.nvim（公开）

跨文件搜索替换。`<leader>sr` 打开项目搜索替换窗口，视觉选择后按 `<leader>sr` 会把选中文字带入搜索框；`<leader>sR` 限定当前文件。界面里修改搜索词、替换词和文件过滤条件后先检查匹配，再执行替换。命令入口为 `:GrugFar` / `:GrugFarWithin`。这是实际修改文件的操作，建议先确认路径过滤和预览结果。

### flash.nvim（公开）

快速定位：普通/可视/操作符待决模式按 `s` 输入目标字符，按屏幕上的标签跳到目标；`S` 使用 Treesitter 语法节点跳转；命令行搜索状态下 `<C-s>` 切换 Flash 搜索提示。例：`sword` 快速跳到屏幕内 `word`，`d s )` 可配合操作符跨位置删除。`r` 和 `R` 没有绑定给 Flash，以保留其他编辑操作。

### aerial.nvim（公开；COBOL 后端由私有层扩展）

符号大纲侧栏，按函数、类、章节等结构跳转。`<leader>cs` 或 `:AerialToggle` 开关，`:AerialOpen` 打开，`:AerialInfo` 查看支持情况；大纲内选择条目可跳到定义位置。普通语言用 Treesitter/LSP 等后端，Markdown 等也可显示结构；COBOL 与 Batch 后端由私有插件提供。

### quicker.nvim（公开）

改善 quickfix 结果列表。用 `<leader>xq` 或 `:copen` 打开结果，在列表中按 `>` 展开结果前后各两行上下文，按 `<` 收起，Enter 跳到对应位置；`[q` / `]q` 切换结果。可用 `:vimgrep /TODO/j **/*` 生成练习结果。位置列表仍可用 `:lopen`。

### auto-session（公开）

按项目保存/恢复窗口、缓冲区、目录和侧栏状态。`<leader>ws` 保存当前会话，`<leader>wr` 搜索并恢复会话，`<leader>wa` 切换自动保存，`<leader>wd` 删除会话。通常按项目根目录识别会话；自动保存/恢复也会在启动和退出时运行。会话会记录本地文件路径，不要把生成的本机 session 数据提交到公开配置仓库。

### markview.nvim（公开）

Markdown、Quarto、R Markdown 预览渲染。打开对应文件后默认附着；`<leader>um` 切换预览。它在缓冲区里把标题、列表、代码块等以渲染样式显示，不会改写 Markdown 源文件。关闭后仍可编辑原始文本。


### bookmark.nvim（私有）

在行号旁添加可点击书签，并可按项目保存。`<leader>mt` 或 `:BookmarkToggle` 切换当前行书签；`<leader>mm` / `:BookmarkList` 打开书签列表；`]b`、`[b` 跳到下/上一个；`<leader>mc` 清当前 buffer，`<leader>mC` 清当前项目。书签列表由 Snacks picker 管理。注意：`[b`/`]b` 在 Neovim 默认习惯中常用作缓冲区切换，本配置已经从默认缓冲区映射移除这两个键，缓冲区切换请用 `Shift+h/l` 或 `<leader>bh/bl`。

## 编程、补全与文本编辑

### blink.cmp（公开）

插入模式的 LSP、路径、代码片段和当前缓冲区补全，也补全命令行。输入时出现候选菜单；方向键上下选，Enter 接受（没有候选时保留原有 Enter 行为），`<C-y>` 接受候选，Tab/Shift-Tab 在补全项和 snippet 占位符间移动。`<C-space>` 可手动触发/打开补全菜单，Esc 关闭。Lua 补全还连接 LazyDev。COBOL 固定格式对 Tab/补全字符做专门处理。

### nvim-lspconfig（公开）+ mason-lspconfig.nvim（公开）+ mason.nvim（公开）

这是三项协同工作的 LSP 安装和连接设施。Mason 用 `:Mason` / `<leader>cm` 浏览安装服务器和工具；当前管理 basedpyright、lua_ls、ruff、shellcheck。Ruff 与 ShellCheck 由 nvim-lint 在写入后检查 Python 与 Shell。mason-lspconfig 把已安装服务器连接到 Neovim，nvim-lspconfig 提供服务器配置。LSP 附加后：`gd` 定义，`gD` 声明，`K` 悬浮文档，`gI` 实现，`gy` 类型定义，`gK` 签名帮助（插入模式 `<C-S-k>`，`<C-k>` 留给 digraph），`<leader>ca` 代码操作，`<leader>cr` 重命名，`<leader>co` 整理 imports，`<leader>cl` 查看 LSP 配置。诊断有下划线和标记列，行内虚拟文本关闭。`<leader>cd` 打开当前行诊断。`]d`/`[d` 仍是诊断跳转。

### mini.surround（公开）

以 `gs` 前缀操作包围符号：`gsa` 添加，`gsd` 删除，`gsr` 替换，`gsf` / `gsF` 向右/向左查找，`gsh` 高亮范围。例如 `gsaiw)` 给当前单词加括号，`gsr)'` 把括号改成单引号。可用 `:help mini.surround` 查看完整说明。

### nvim-treesitter（公开）

提供语法解析和高亮，并被折叠、文本对象、符号列表等插件调用。多数受支持语言自动安装配置的 parser；`:TSInstall <语言>` 安装，`:TSUpdate` 更新/重建，`:TSLog` 查看日志，`:TSUninstall <语言>` 卸载。安装目录在 `~/.local/share/nvim/site/parser`。**最低 Neovim 0.12，nvim-treesitter 和 textobjects 都固定 main 分支**；升级/换分支后需要重建 parser。细节见公开配置 `config/nvim/TREESITTER.md`。

### nvim-treesitter-textobjects（公开）

为支持的语言增加语法树文本对象和结构跳转。普通/可视模式可配合 `vaf` / `dif`（函数）、`vac` / `dic`（类）、`vaa` / `dia`（参数）等 mini.ai 对象；移动到函数起点 `]f` / `[f`，函数终点 `]F` / `[F`，类起点 `]c` / `[c`，参数 `]a` / `[a`。效果依赖对应 parser 和查询；COBOL 当前没有 Treesitter parser。

### mini.ai（公开）

扩展 `i`（inside）和 `a`（around）文本对象，可与删除、修改、复制组合。例：`dif` 删除函数内部，`caf` 修改整个函数，`via` 选择参数，`ciq` 修改引号内容，`yag` 复制整个文件。对象还包括 `o` 代码块/条件/循环，`c` 类，`t` 标签，`d` 数字，`e` CamelCase/snake_case 单词，`g` 整个文件，`u/U` 函数调用。`an/in` 查找光标之后对象，`al/il` 查找之前对象。查看 `<leader>` 提示或 mini.ai 帮助可了解 `a`、`i` 和对象字母组合。

### mini.pairs（公开）

插入模式和命令行输入括号/引号时自动成对补全；已有右括号、字符串内部和不平衡括号有跳过逻辑。Markdown 代码围栏也有特殊补全。`<leader>up` 开关。测试时可在插入模式输入 `(` 或 `"`，再继续输入内容；如果很少需要自动闭合，可关闭或移除。

### mini.hipatterns（公开）

在文本中直接显示 `#RRGGBB`、`#RGB` 等十六进制颜色背景，打开文件自动生效，无快捷键。仅负责轻量文本高亮；需要颜色滑块编辑时用 ccc.nvim。

### ccc.nvim（公开）

取色和颜色格式转换。光标位于颜色值时按 `<leader>cp` / `:CccPick` 打开交互式颜色滑块，`<leader>cC` / `:CccConvert` 转换当前颜色表示。也可双击十六进制颜色唤起取色器。常驻颜色文本高亮由 mini.hipatterns 处理，ccc 自身高亮默认关闭。


### smart-paste.nvim（私有）

智能处理系统剪贴板和多行粘贴缩进。Normal 模式 `<leader>p` 或 `<C-v>` 粘贴系统剪贴板；Insert 模式 `<C-v>` 粘贴；Visual 模式 `<C-v>` 用系统剪贴板替换选区。多行代码会根据目标缩进重新对齐，保留块内相对缩进；在 COBOL 中包含专门的定格式对齐处理。普通 `p/P` 也由插件增强。适合从网页、文档或其他编辑器复制多行代码后粘贴。

### multicursor.nvim（公开）

`<leader><up>` / `<leader><down>` 跳过相邻行再加光标；`<leader>n` / `<leader>N` 添加下一个/上一个匹配，`Alt+d` / `Alt+Shift+d` 跳过匹配。`Ctrl+n` 添加下一个匹配，`Ctrl+Shift+n` 选中全部匹配。`Ctrl+d` 仍是半页下滚。Ctrl 加鼠标左键可添加/移除光标并拖动。`<leader>mq` 暂停或恢复多光标，`<leader>A` 对齐列，`<leader>gv` 恢复刚清掉的光标。左右方向键切换主光标，`<leader>x` 删除主光标，Esc 清除全部光标。`<C-q>` 是视觉块模式。

### nvim-ufo（公开）+ promise-async（依赖）

使用 Treesitter/缩进结果管理代码折叠。`zR` 全部展开，`zM` 全部折叠，`zr` 展开一层，`zm` 折叠一层，`zp` 预览光标下折叠内容。`promise-async` 只供 ufo 异步工作，不需要直接调用。

### indent-blankline.nvim（公开）

显示缩进参考线，便于阅读嵌套代码；`<leader>ug` 开关。COBOL 文件会排除通用缩进线，避免与 COBOL 列标尺重叠。

### rainbow-delimiters.nvim（公开）

自动按层级为括号、方括号等嵌套分隔符着色，便于看清配对范围；无命令和快捷键。若颜色干扰阅读，可从插件规格移除或调整主题高亮。

### nvim-lint（公开；ShellCheck）

打开、保存或离开插入模式时自动对 `sh`、`bash` 文件运行 ShellCheck。命令行可用 `shellcheck script.sh` 检查，或用 `shellcheck -s bash script.sh` 指定 Bash 语法。当前 Neovim 全局关闭诊断显示，因此自动 lint 结果不会显示在编辑区；需要查看报告时直接运行 ShellCheck 命令。

## Git 与导航信息

### gitsigns.nvim（公开）

在行号栏标出相对 Git 的新增/修改/删除。`]h` / `[h` 跳到下一/上一 hunk，`]H` / `[H` 到最后/最初 hunk。`<leader>gs` 暂存 hunk，`<leader>gr` 重置 hunk，`<leader>gS` 暂存文件，`<leader>gR` 重置文件，`<leader>gu` 撤销暂存，`<leader>gp` 行内预览，`<leader>gb` 当前行 blame，`<leader>gB` 文件 blame，`<leader>gy` 复制 hunk，`ih` 在 Visual/Operator 模式选择 hunk。另有 `<leader>gh*` 的显式 hunk 命名映射。`<leader>uG` 切换标记。重置操作会丢弃本地改动，执行前确认 hunk。

### diffview.nvim（公开）

`<leader>gd` 打开当前分支与基线差异视图；`<leader>gD` 查看当前文件历史；`<leader>gV` 查看仓库历史；`<leader>gq` 关闭。`<leader>gv` 不再打开差异，已改归 multicursor.nvim 的“恢复光标”。`:DiffviewOpen`、`:DiffviewFileHistory`、`:DiffviewClose` 也可直接用。适合成组审查多个文件变更；单个 hunk 快速预览用 Gitsigns。

### satellite.nvim（公开）

在窗口右侧边缘显示类似迷你滚动槽的标记，包括滚动位置、搜索、诊断等。自动附加到文件窗口，不需要操作；帮助用户快速看出标记在文档中的位置。部分浮窗和 Neo-tree/Aerial 等侧栏排除显示。

### nvim-hlslens（公开）

增强搜索匹配的位置/数量提示。正常用 `/pattern` 后按 `n` / `N`；也可 `*`、`#`、`g*`、`g#` 搜光标单词/部分单词。配置在执行这些操作后启动 lens 高亮，退出搜索后由 `:nohlsearch` 或 Esc 清掉。

### fidget.nvim（公开）

LSP 服务器执行索引、诊断等工作时显示进度通知；自动运行，无命令。若没有配置或启动 LSP 服务器，就不会出现进度提示。

### contextline.nvim（私有）

为顶部上下文栏提供文件路径、当前语言结构、函数/类层级等信息；大纲上下文可点击。`<leader>cb` / `:ContextlineMenu` 打开上下文层级菜单并选择跳转位置。优先读取 LSP/navic 信息，并可用 Treesitter 回退；在受支持语言中随光标更新。

## 状态栏、快捷键与基础库

### heirline.nvim（公开）

绘制底部状态栏和顶部上下文栏，并承载本地交互菜单；通常不用手动开启。状态栏的模式、文件、Git 状态等区域会随当前 buffer 更新；点击状态栏/上下文栏可触发菜单，Enter/空格执行当前项，方向键/滚轮浏览，Esc 或 `q` 关闭。状态栏内具体项目由本配置和 contextline 适配器定义。

### which-key.nvim（公开）

显示按键组合提示。按 `<leader>` 后稍停显示可用下一键；`<leader>hk` 查看当前缓冲映射，`<leader>?` 是帮助搜索，`<C-w>` 后稍停查看窗口操作。提示可帮助探索快捷键，不会改变编辑行为。

### nvim-web-devicons（公开依赖）

根据文件类型提供图标，供 Neo-tree、Bufferline 等 UI 插件显示；不单独调用。Oil 已删除，因此此处只保留前两项相关用途。

### lazy.nvim（公开管理器）

插件安装和加载管理。`:Lazy` 或 `<leader>l` 打开管理界面；其中可查看插件状态、安装、更新、清理未再配置的插件。移除插件规格后，运行 `:Lazy clean` 可删除管理器认为已不再使用的缓存。`lazy-lock.json` 在此配置中不入库。

### plenary.nvim、nui.nvim（公开依赖库）

两者分别提供 Lua 通用异步/测试工具和 Neovim UI 组件，被其他插件调用（如 Neo-tree、Diffview、Todo-comments）。没有单独用户入口；只有当依赖它们的插件也被移除时才可评估删除。

## 私有语言与个人工具

### cobol.nvim（私有）

独立插件，源码、配置说明、完整用法和练习统一维护在 [cobol.nvim 插件章节](../plugins/chapters/cobol.md) 和插件仓库；安装后可在 Neovim 中运行 `:help cobol.nvim`。这里仅保留目录入口，避免手册分散。

### batch.nvim（私有）

Windows Batch 文件结构解析与导航。支持 `:BatchCheck` 检查、`:BatchJumpToLabel` 跳到 label、`:BatchReferences` 找 label 引用、`:BatchOutline` 打开大纲、`:BatchPeek` 预览目标；关联 filetype 为 `dosbatch` / `batch`。诊断、折叠、状态栏集成启用，但插件自己的快捷键关闭，全部使用显式命令。

### VimQuest.nvim（私有）

在 Neovim 内做词汇练习。`:VimQuestStart` 开始，`:VimQuestStop` 停止，`:VimQuestNext` / `:VimQuestPrev` 切换题目，`:VimQuestNextRound` 下一轮。词库和详细玩法见私有插件 README；如果从不使用，是容易移除的独立插件。

## 建议清理顺序与目前发现

1. **Oil 已按要求删除**：`config/nvim/lua/plugins/oil.lua` 已移除；运行时规格核对也不再出现 `oil.nvim`。重启 Neovim 后可用 `:Lazy clean` 清理缓存。插件清单中不再把它列为当前插件。
2. **插件统计**：插件手册统计需随插件增删同步；独立插件仓库和依赖项不计入该分类数量。
3. **发现 `[b` / `]b` 冲突**：私有书签把它们用于前/后书签，公开默认映射此前又用于前/后缓冲区。已删除默认缓冲区映射；请用 `Shift+h/l` 或 `<leader>bh/bl` 切换缓冲区。
4. **格式化** 使用 LSP 提供程序格式化能力，快捷键为 `<leader>fo`。
5. **诊断**：标记列和下划线打开，行内虚拟文本关闭。Python 用 ruff、Shell 用 shellcheck，都在写入后跑。`disable-diagnostics.lua` 已删除。
6. **候选取舍**：Oil 已移除后 Neo-tree 是唯一文件侧栏；`ccc.nvim` 是按需取色；`mini.hipatterns` 是颜色值自动高亮；`flash.nvim` 是跳转；`nvim-hlslens` 是搜索命中提示；两者不是完全相同功能。`fidget.nvim`、`satellite.nvim`、`rainbow-delimiters.nvim`、`mini.pairs` 属于自动生效 UI/编辑便利，是否保留按日常感受判断。

## 怎样确认插件是否真的在运行

在 Neovim 执行 `:Lazy` 查看插件状态；`cond`/`ft`/`cmd`/`event` 插件可能未触发前显示待加载。运行 `:Lazy profile` 查看启动加载情况。查看快捷键可用 `:map <键>`，命令用 `:command <前缀>`。配置源文件位置：全部插件规格在 `~/nvim/lua/plugins/`；自研插件源码在各自独立仓库。编辑源文件后按各自仓库规则维护，不要改 `~/.config/nvim` 下的部署输出。
