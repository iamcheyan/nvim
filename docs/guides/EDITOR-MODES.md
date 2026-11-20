# 日常模式与增强模式

这两种模式共用同一份配置。**日常模式**面向代码阅读、Git 状态查看和少量编辑；**增强模式**启用完整的公共插件配置。下表列出每个插件在两种模式下是否启用，以及它在增强模式下的加载条件。日常模式保留的插件使用相同的加载条件。

## 切换方式

- 按 `<leader>uM`（Space、u、Shift+m）或运行 `:NvimMode`，每次在日常和增强模式之间切换**下次启动**的选择；提示会显示当前模式和重启要求。
- 重启 Neovim 才会完整应用切换；启动时不再提示当前模式，未选择过时默认使用增强模式。
- 选择保存在本机 Neovim 状态目录的 `editor-mode` 文件中，不属于仓库。连续按两次会把保存的选择切回去。
- 临时使用另一种模式而不改变保存的选择：`NVIM_MODE=daily nvim` 或 `NVIM_MODE=full nvim`。环境变量优先，因此设置了它时，重启仍会使用环境变量指定的模式。

## 使用体验对比

| 项目 | 日常模式 | 增强模式 |
| --- | --- | --- |
| 阅读与编辑 | 文件树、搜索、语法高亮、基础补全、多光标、折叠 | 在日常功能上增加完整的开发工具 |
| Git 与 Todo | 保留 Git 变更标记和侧栏 File、Todo、Git | 另有 Diffview 和完整侧栏符号入口 |
| 顶部界面 | 保留文件标签栏；隐藏路径和代码位置栏 | 保留文件标签栏和 Dropbar 路径、代码位置栏 |
| LSP 和专用工具 | 不启用下表标明关闭的 LSP、COBOL、Batch、AWS 等插件 | 启用；语言服务器本身仍需安装且符合启动条件 |

日常模式不会加载关闭的插件；这些插件仍登记在 Lazy 配置中，因此 `:Lazy clean` 不会把它们当成无用插件删除。配置、会话与数据也不会因切换模式而删除。两种模式的资源差异取决于打开的文件和触发的插件，不能仅凭插件数量判断。

## 如何阅读插件表

“启用”表示插件属于该模式的可用规格，**不表示启动时已经加载**。“启动”表示该插件没有延迟条件或明确设置为启动时加载；“延迟”后列出事件、文件类型、命令或快捷键。依赖可在依赖它的插件加载时提前加载；`init` 阶段的配置也可能早于插件主体执行。`VeryLazy` 是启动后触发的延迟事件，`LazyFile` 对应读取、新建或写入文件，不等同于一直不加载。

下面基于仓库的公共配置，未包括机器本地的 `nvim-local.lua` 和桌面环境可能额外提供的主题。`WDIFF_NVIM=1` 等条件也可能改变个别插件状态。LSP 相关能力在日常模式关闭，即使其他保留插件支持 LSP 来源，也不会因此自动启用 LSP。

| 插件 | 日常 | 增强 | 加载条件 |
| --- | --- | --- | --- |
| `VimQuest.nvim` | **关闭** | 启用 | 延迟：命令（`VimQuestStart`、`VimQuestStop` 等） |
| `aerial.nvim` | **关闭** | 启用 | 延迟：命令（`AerialToggle`、`AerialOpen` 等） / 快捷键 |
| `auto-session` | 启用 | 启用 | 启动 |
| `aws.nvim` | **关闭** | 启用 | 延迟：事件（`VeryLazy`） / 命令（`AwsPicker`、`AwsCF` 等） / 快捷键 |
| `batch.nvim` | **关闭** | 启用 | 延迟：文件类型（`dosbatch`） |
| `blink.cmp` | 启用 | 启用 | 延迟：事件（`InsertEnter`、`CmdlineEnter`） |
| `bufferline.nvim` | 启用 | 启用 | 启动 |
| `ccc.nvim` | **关闭** | 启用 | 延迟：命令（`CccPick`、`CccConvert`） / 快捷键 |
| `cobol.nvim` | **关闭** | 启用 | 延迟：文件类型（`cobol`、`cbl`、`cob`） / 命令（`CobolGuideToggle`、`CobolGuideEnable` 等） / 快捷键 |
| `dashboard-nvim` | 启用 | 启用 | 启动 |
| `diffview.nvim` | **关闭** | 启用 | 延迟：命令（`DiffviewOpen`、`DiffviewClose` 等） / 快捷键 |
| `dropbar.nvim` | **关闭** | 启用 | 延迟：事件（`BufReadPost`、`BufNewFile`、`FileType`） / 命令（`DropbarContextMenu`） |
| `fidget.nvim` | **关闭** | 启用 | 延迟：事件（`LspAttach`） |
| `flash.nvim` | 启用 | 启用 | 延迟：快捷键 |
| `gitsigns.nvim` | 启用 | 启用 | 延迟：事件（`LazyFile`） |
| `grug-far.nvim` | **关闭** | 启用 | 延迟：命令（`GrugFar`、`GrugFarWithin`） |
| `heirline.nvim` | 启用 | 启用 | 延迟：事件（`VeryLazy`） |
| `hlchunk.nvim` | **关闭** | 启用 | 延迟：事件（`UIEnter`） |
| `hover.nvim` | **关闭** | 启用 | 延迟：事件（`LspAttach`） / 快捷键 |
| `lazy.nvim` | 启用 | 启用 | 启动：插件管理器自身 |
| `markview.nvim` | 启用 | 启用 | 延迟：文件类型（`markdown`、`markdown.mdx`、`quarto`、`rmd`） / 快捷键 |
| `mason-lspconfig.nvim` | **关闭** | 启用 | 启动 |
| `mason.nvim` | **关闭** | 启用 | 延迟：命令（`Mason`） / 快捷键 |
| `mini.ai` | 启用 | 启用 | 延迟：事件（`VeryLazy`） |
| `mini.hipatterns` | 启用 | 启用 | 延迟：事件（`LazyFile`） |
| `mini.pairs` | 启用 | 启用 | 延迟：事件（`VeryLazy`） |
| `multicursor.nvim` | 启用 | 启用 | 启动 |
| `neo-tree.nvim` | 启用 | 启用 | 延迟：命令（`Neotree`） / 快捷键 |
| `noice.nvim` | 启用 | 启用 | 延迟：事件（`VeryLazy`） |
| `nui.nvim` | 启用 | 启用 | 延迟：依赖或模块调用 |
| `nvim-hlslens` | 启用 | 启用 | 延迟：事件（`VeryLazy`） / 快捷键 |
| `nvim-lspconfig` | **关闭** | 启用 | 延迟：依赖或模块调用 |
| `nvim-treesitter` | 启用 | 启用 | 延迟：事件（`LazyFile`、`VeryLazy`） / 命令（`TSUpdate`、`TSInstall` 等） |
| `nvim-treesitter-context` | **关闭** | 启用 | 延迟：事件（`VeryLazy`） |
| `nvim-treesitter-textobjects` | 启用 | 启用 | 延迟：事件（`VeryLazy`） |
| `nvim-ufo` | 启用 | 启用 | 延迟：事件（`BufReadPost`） |
| `nvim-web-devicons` | 启用 | 启用 | 启动 |
| `plenary.nvim` | 启用 | 启用 | 延迟：依赖或模块调用 |
| `portal.nvim` | 启用 | 启用 | 延迟：命令（`Portal`） / 快捷键 |
| `position-ruler.nvim` | 启用 | 启用 | 延迟：文件类型（`text`、`txt`、`csv`、`tsv`） / 命令（`PositionJump`、`PositionRange` 等） |
| `promise-async` | 启用 | 启用 | 延迟：依赖或模块调用 |
| `rainbow-delimiters.nvim` | **关闭** | 启用 | 延迟：事件（`LazyFile`） |
| `satellite.nvim` | 启用 | 启用 | 延迟：事件（`BufReadPost`、`BufNewFile`） |
| `smart-paste.nvim` | 启用 | 启用 | 启动 |
| `snacks.nvim` | 启用 | 启用 | 启动 |
| `telescope.nvim` | **关闭** | 启用 | 延迟：命令（`Telescope`） / 快捷键 |
| `todo-comments.nvim` | 启用 | 启用 | 延迟：事件（`BufReadPost`、`BufNewFile`） / 命令（`TodoTelescope`、`TodoQuickFix` 等） / 快捷键 |
| `viewsplit.nvim` | 启用 | 启用 | 启动 |
| `vim-matchup` | 启用 | 启用 | 延迟：事件（`VeryLazy`） / 快捷键 |
| `which-key.nvim` | 启用 | 启用 | 延迟：事件（`VeryLazy`） / 快捷键 |


## 相关文档

- [插件使用书](../plugins/PLUGINS.md)：每个插件的功能与具体用法。
- [文件、标签与配置重载](FILES-TABS-AND-RELOAD.md)：文件标签栏和配置重载。
- [Treesitter 运行要求](../reference/TREESITTER.md)：解析器与安装要求。
