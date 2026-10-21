# multicursor.nvim

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

在多个文本位置同时放置光标，像普通 Vim 编辑一样输入、删除或替换，从而一次修改多个匹配项。

## 在当前配置里怎么用

Normal/Visual 模式中：

- `<up>` / `<down>`：在主光标上方 / 下方添加光标。
- `<leader><up>` / `<leader><down>`：跳过上方 / 下方行。
- `<leader>n` / `<leader>N`：按光标下单词或选区，添加下一个 / 上一个匹配。
- `<leader>s` / `<leader>S`：跳过下一个 / 上一个匹配。
- `<leader>A`：为光标下的单词或 Visual 选区添加当前缓冲区中的全部匹配光标。
- `<C-q>`：暂停或恢复多光标；暂停时只移动主光标，再按可在当前位置添加光标。
[docs/plugins/chapters/multicursor.nvim.md#EBF6]

有多个光标后照常使用 Vim 操作编辑。左右方向键切换主光标；`<leader>x` 删除当前主光标；Esc 清除光标并退出，若光标暂停则恢复多光标。

## 动手练习

在练习文件里写下几处重复的 `old_name`。光标放在第一个单词上，连续按 `<leader>mn` 选中下一个匹配，按 `c` 输入 `new_name`，最后按 Esc 结束。确认只改动选中的匹配，再用 `u` 撤销练习。

## 注意事项

仓库同时配置了 `vim-visual-multi` 和 `multicursor-line.nvim`，多光标操作可能重叠；本插件使用 `<leader>mn` 系列入口，避免覆盖现有 `<C-n>` 和 `<leader>m` 书签前缀。批量编辑前确认所有光标位置，避免修改不想要的匹配。

## 查快捷键和帮助

在 Neovim 里用 `:verbose nmap <按键>` 查看最终映射和定义来源；按 `<leader>` 后稍等可看 which-key 提示。可用命令可用 `:command <前缀>` 查询。
