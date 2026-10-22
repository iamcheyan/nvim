# portal.nvim

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

`Ctrl-o` / `Ctrl-i` 只能沿着跳转历史一步一步走，跳了十几次之后，想回到中间某一次就得反复试。Portal 把跳转历史和改动历史列成一个可搜索的列表：输入关键字，直接挑那一次跳转。

## 在当前配置里怎么用

| 按键 | 作用 |
|---|---|
| `<leader>jo` | 打开跳转历史（向后，相当于回退） |
| `<leader>jO` | 打开跳转历史（向前） |
| `<leader>jc` | 打开改动历史 |
| `<leader>jg` | 在 Grapple 标签里搜索 |

打开后输入关键字过滤，`<Esc>`、`q` 或 `Ctrl-c` 退出。命令形式：`:Portal jumplist backward`、`:Portal changelist backward`、`:Portal grapple`。

## 动手练习

1. 在几个文件之间跳转几次（或用 `gg`、`G`、`:lua` 制造跳转点）。
2. `<leader>jo` 打开跳转列表，输入目标文件名的一部分。
3. 选中一次跳转，确认直接回到那一处。
4. 改几处内容后 `<leader>jc`，确认能列出改动位置。

**验收**：列表可过滤，选中后直接跳到目标位置；退出后回到原来的窗口。

## 注意

- Portal 显示的是 Neovim 的 jumplist / changelist，历史被清空后列表为空。
- `Ctrl-o` 仍然可用，两者不冲突：前者适合最近一次，Portal 适合很久以前的一次。
