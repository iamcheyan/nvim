# telescope.nvim

> [回到插件目录](../PLUGINS.md)

## 它解决什么问题

在项目里找文件、找字符串、找符号、翻书签。Telescope 的定位是「先输入再缩小范围」：打开时列出候选，敲字实时过滤，右侧显示预览。

## 在当前配置里怎么用

| 入口 | 作用 |
|---|---|
| `<leader>tf` | 当前 buffer 的 TODO 列表（带预览） |
| `<leader>ta` | 项目全部 TODO（优先 Snacks picker） |
| `:Telescope find_files` | 文件列表 |
| `<C-q>` | 把当前选中项送进 quickfix 并打开列表 |

列表内：`<C-n>/<C-p>` 或 `↑/↓` 移动，`Enter` 打开，`<Esc>` 关闭，输入即过滤。预览面板在窗口宽度足够时出现；宽度不足 60 列时自动隐藏，给结果列表让位。

## 和 Snacks picker 的分工

配置里的日常搜索（`<leader><space>`、`<leader>sg` 等）仍然走 Snacks picker；Telescope 承载当前 buffer 的 TODO 列表；项目级列表优先用 Snacks，二者都遵循同一套关键字。

## 注意事项

- 布局在 `lua/plugins/telescope.lua` 里统一设置：`prompt_position=top`、`preview_cutoff=60`。终端太窄时看不到预览是预期行为。
- 当前 buffer 的 TODO 列表在 `lua/config/todo.lua`（`list_buffer`），不要把逻辑写进插件配置。
