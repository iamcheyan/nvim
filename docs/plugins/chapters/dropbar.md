# dropbar.nvim

> 官方公开插件 · [回到插件目录](../PLUGINS.md)

顶部 winbar 使用官方 `Bekaboo/dropbar.nvim`，不依赖 fork 或 contextline。
顶部路径按“目录 → 文件 → 代码层级”排列。路径由官方 `dropbar.sources.path` 提供；目录与文件使用黑色 Nerd Font 图标，目录名与左侧箭头点击后都展开子菜单，文件名称点击切换缓冲区。
顶部左右各留一格；菜单使用统一的 FreshMenu 蓝色 UI、选中行和边框。菜单箭头紧挨图标，图标与名称之间保留一个空格。
菜单的边框由 dropbar 自行计算；关闭路径预览。鼠标打开菜单或展开子菜单时，键盘焦点和光标仍留在文档中；点击文件或代码名称才执行跳转。
通用结构解析适配位于 `lua/config/dropbar.lua`，层级菜单使用 dropbar 原生 API。
优先使用实时 Treesitter 结构，缺少 parser 时使用 LSP 文档符号。

点击结构路径或运行 `:DropbarContextMenu` 打开层级菜单，选择名称跳转，展开箭头浏览子层级。
鼠标打开的菜单支持上下键选择、回车确认、向右方向键展开、向左方向键返回上级、Esc 关闭；这些操作不移动文档光标。
COBOL 的括号链、右侧待闭合块与 AST 菜单由 `cobol.dropbar` 提供，Batch 标签由 `batch.dropbar` 提供。
两者都接入同一个 dropbar winbar 和原生菜单。Heirline 负责底部状态栏。

打开 Python、TypeScript、JavaScript、Shell、Batch 或 COBOL 文件，移动光标并点击路径检查跳转。
TXT、CSV、TSV、DAT、LST、CTL 等文本数据文件（扩展名不区分大小写）使用位置标尺。
其余普通文件使用 dropbar；Makefile、未知文件类型或缺少 parser/LSP 时仍显示文件路径，顶部不会留空。
