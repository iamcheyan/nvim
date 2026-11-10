# telescope.nvim

> [回到插件目录](../PLUGINS.md)

## 它解决什么问题

在项目里找文件、找字符串、找符号、翻书签。Telescope 的定位是「先输入再缩小范围」：打开时列出候选，敲字实时过滤，右侧显示预览。

## 在当前配置里怎么用

| 入口 | 作用 |
|---|---|
| `<leader>bl` | BOOKMARK 书签列表（按文件、行号排序，块书签只预览对应行段） |
| `<leader>bt` | 只看 BOOKMARK 关键字的 todo-comments 列表 |
| `:Telescope find_files` | 文件列表 |
| `<C-q>` | 把当前选中项送进 quickfix 并打开列表 |

列表内：`<C-n>/<C-p>` 或 `↑/↓` 移动，`Enter` 打开，`<Esc>` 关闭，输入即过滤。预览面板在窗口宽度足够时出现；宽度不足 60 列时自动隐藏，给结果列表让位。

## 和 Snacks picker 的分工

配置里的日常搜索（`<leader><space>`、`<leader>sg` 等）仍然走 Snacks picker；Telescope 专门承载书签列表和 todo-comments 的检索，因为这两个源需要按文件/行号稳定排序和自定义预览。

## 注意事项

- 布局在 `lua/plugins/telescope.lua` 里统一设置：`prompt_position=top`、`preview_cutoff=60`。终端太窄时看不到预览是预期行为。
- 书签列表的 finder、预览和排序在 `lua/config/bookmarks.lua`，不要把逻辑写进插件配置。
