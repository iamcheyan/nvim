# multicursor.nvim

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

在多个文本位置同时放置光标，像普通 Vim 编辑一样输入、删除或替换，从而一次修改多个匹配项。本仓库现在只用这一个多光标插件（`vim-visual-multi` 已移除）。

## 在当前配置里怎么用

VS Code 风格快捷键（Normal / Visual）：

| 按键 | 作用 | 对应 API |
|---|---|---|
| `Ctrl+n` | 添加下一个匹配 | `mc.matchAddCursor(1)` |
| `Ctrl+Shift+n` | 选中当前单词 / 选区的**全部**匹配 | `mc.matchAllAddCursors()` |
| `Ctrl+d` | 跳过当前匹配 | `mc.matchSkipCursor(1)` |
| `Esc` | 存在多光标时清除所有光标；没有多光标时保持默认 Esc 行为 | `mc.clearCursors()` |

原有的 `<leader>` 系列仍然保留：

- `<leader>n` / `<leader>N`：添加下一个 / 上一个匹配；`<leader>s` / `<leader>S`：跳过下一个 / 上一个。
- `<up>` / `<down>`：在上下方添加光标；`<leader><up>` / `<leader><down>`：跳过上下行。
- `<C-q>`：暂停或恢复多光标；`<left>` / `<right>` 切换主光标，`<leader>x` 删除主光标。
- 鼠标：`Ctrl+左键` 添加或删除光标，拖动可连续添加。

保留的高级功能：

| 按键 | 作用 | 对应 API |
|---|---|---|
| `ga` | 光标操作符；`gaip` 给段落每一行添加光标，`ga` 后接其它文本对象同理 | `mc.addCursorOperator` |
| `<leader>a` | 对齐各光标的列 | `mc.alignCursors` |
| `<leader>gv` | 误清除后恢复光标 | `mc.restoreCursors` |

## 动手练习

1. 写下四行相同的 `foo`，光标放在第一个 `foo` 上。
2. 按 `Ctrl+n` 两次：只应选中前两个匹配。
3. 按 `Esc` 清除，重新放回第一个 `foo`，按 `Ctrl+Shift+n`：应选中全部 `foo`。
4. 把光标移到某个段落中间，按 `gaip`：应为该段落每一行创建一个光标。
5. 用 `c` 输入新内容后 `Esc` 结束，再用 `u` 撤销练习。

## 注意事项

- `Ctrl+n` / `Ctrl+d` 只在 Normal 与 Visual 模式映射，插入模式下 `Ctrl+n` 仍是关键字补全。
- `Ctrl+d` 在 Vim 里默认是向下滚动半屏；本配置把它改成了“跳过当前匹配”。需要滚动请用 `Ctrl+f` / `Ctrl+b` 或 `Ctrl+u`。
- `<leader>gv` 原本是 diffview 打开差异的别名，现已归本插件的“恢复光标”；打开差异仍用 `<leader>gd`。
- `<leader>a`（对齐光标）只在 Normal 模式生效，避免与可视模式的选择操作冲突。

## 查快捷键和帮助

`:verbose nmap <C-n>` 等可查看最终映射和来源；`:help multicursor` 查看插件帮助。
