# telescope.nvim

> [回到插件目录](../PLUGINS.md)

## 它解决什么问题

Telescope 是备用的候选列表界面。本配置用它提供文件搜索入口，并作为 TODO 搜索的后备 picker；日常文件和内容搜索主要由 Snacks 承担。

## 在当前配置里怎么用

| 入口 | 作用 |
|---|---|
| `<leader>bl` | 用 Telescope 搜索文件 |
| `:Telescope find_files` | 文件列表 |
| `<C-q>` | 把当前选中项送进 quickfix 并打开列表 |

列表内：`<C-n>/<C-p>` 或 `↑/↓` 移动，`Enter` 打开，`<Esc>` 关闭，输入即过滤。预览面板在窗口宽度足够时出现；宽度不足 60 列时自动隐藏，给结果列表让位。

## 和 Snacks picker 的分工

配置里的日常搜索（如 `<leader><space>`、`<leader>ff`、`<leader>fg`）走 Snacks picker。TODO 的 `<leader>ta` / `<leader>tf` 也优先使用 Snacks；Telescope 是其后备实现。

## 注意事项

- 布局在 `lua/plugins/telescope.lua` 里统一设置：`prompt_position=top`、`preview_cutoff=60`。终端太窄时看不到预览是预期行为。
- TODO 列表逻辑在 `lua/config/todo.lua`；Telescope 只在 TODO picker 的后备路径中使用。
