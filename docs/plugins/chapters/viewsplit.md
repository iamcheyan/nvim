# viewsplit.nvim：分屏独立视图状态

<!-- source: lua/plugins/viewsplit.lua -->

[项目仓库与完整说明](https://github.com/iamcheyan/viewsplit.nvim)

## 它解决什么问题

Neovim 的分屏共享同一 buffer。`viewsplit.nvim` 为显示同一 buffer 的不同窗口分别保存视图状态，同时保留文本、撤销历史、诊断、Treesitter 和 Git 集成的原生共享行为。

## 在当前配置里怎么用

本配置启用每窗口独立的 `/`、`?` 搜索模式和匹配。切换窗口时会恢复该窗口的搜索寄存器，因此 `n` / `N` 继续当前分屏自己的搜索。

折叠、跳转历史、命名标记、滚动位置和 Visual 选择功能可单独启用；其中 Visual 选择仍属实验功能。完整 API、状态边界及验证情况见[项目 README](https://github.com/iamcheyan/viewsplit.nvim#readme)。

## 动手练习

1. 用 `:vsplit` 在两个窗口打开同一文件。
2. 左窗搜索一个词，右窗搜索另一个词。
3. 在两个窗口间切换，分别按 `n`，确认各窗口恢复自己的搜索。
4. 查看 `:ViewInfo`，了解当前窗口保存的状态。

## 注意事项

窗口状态以进程内的 window ID 保存；关闭窗口后状态会丢弃。buffer 内容和撤销历史仍由 Neovim 共享。

## 查快捷键和帮助

插件提供 `:ViewInfo` 和 `:ViewSync`。配置位于 `lua/plugins/viewsplit.lua`。
