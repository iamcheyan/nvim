# vim-visual-multi

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

在同一缓冲区的多个位置同时放置光标，随后像普通编辑一样输入、删除或替换，从而一次改动多个匹配项。

## 在当前配置里怎么用

本配置**保留插件自带的默认映射**，只在官方支持的 `g:VM_maps` 上追加一个键，不改写插件的 keymap。

| 按键 | 作用 | 来源 |
|---|---|---|
| `Ctrl+n` | Find Under：选中光标下的单词，重复按继续选中下一个匹配 | 插件默认，未改动 |
| `Ctrl+Shift+n` | Select All：选中光标下单词的**全部**匹配 | 本配置新增 |
| `Ctrl+Down` / `Ctrl+Up` | 在下方 / 上方增加光标 | 插件默认 |
| `q` / `Q` | 跳过当前匹配 / 移除当前光标（需在 VM 启动后） | 插件默认 |
| `Esc` | 退出多光标 | 插件默认 |

新增方式写在 `lua/plugins/vim-visual-multi.lua`：在 lazy.nvim 的 `init` 里把 `Select All` 合并进 `g:VM_maps`，这样插件构建映射时只替换这一个条目，其它 VM 映射（含默认的 `Ctrl+n`）保持原样。若别处已经设置过 `g:VM_maps`，这里是在原有字典上追加，不会覆盖其它键。

插件默认的全选键 `\A`（`\` 后接 `A`）仍然可用，新增的 `Ctrl+Shift+n` 只是另一个入口。

## 动手练习

1. 在练习文件里写几处相同的 `old_name`，把光标放在第一个单词上。
2. 按 `Ctrl+n` 选中它；再按一次 `Ctrl+n`，确认第二个匹配被加入（逐个选择）。
3. 按 `Esc` 退出，重新把光标放回单词上，按 `Ctrl+Shift+n`，确认所有匹配一次性全部选中。
4. 按 `c` 输入 `new_name`，`Esc` 结束，确认所有选中位置一起改掉；再用 `u` 撤销练习。

## 如果 `Ctrl+Shift+n` 没有反应

映射存在不等于按键能传到 Neovim。很多终端把 `Ctrl+Shift+n` 和 `Ctrl+n` 编码成同一个控制字符，此时 Neovim 只会收到 `Ctrl+n`，无法区分 Shift。按下面的方法确认终端实际发了什么：

1. 在插入模式下按 `Ctrl+V`（或 `Ctrl+Q`），这是“按字面插入下一个字符”。
2. 再按 `Ctrl+Shift+n`，观察插入的内容：
   - 插入的是 `^N`，且和直接按 `Ctrl+n` 的结果**完全一样** → 终端没有把 Shift 传给 Neovim，`Ctrl+Shift+n` 在这个终端里无法触发。
   - 插入的是一串以 `Esc`（显示为 `^[`）开头的转义序列 → 终端发送了带修饰键的可区分序列，映射可用。
3. 另可用 `:verbose nmap <C-S-n>` 确认映射已建立、来自哪个文件；它只证明映射存在，不证明终端能触发。

终端不支持时的替代办法：

- 继续用插件默认的全选键 `\A`。
- 或者在自己的配置里把 `Select All` 改到终端能区分的键，例如 `g:VM_maps["Select All"] = "<M-n>"`（Alt+n）。
- 或者启用终端的增强键盘协议（如 kitty keyboard protocol、xterm 的 `modifyOtherKeys`、CSI u），具体开关因终端而异，以所用终端文档为准。

## 注意事项

- 本配置只改 `Select All` 一个条目，其余 VM 映射沿用插件默认；修改时同样只追加 `g:VM_maps` 的键，不要整体替换字典。
- `multicursor.nvim` 也提供多光标，两者职责不同：本插件偏向“选中单词并逐步扩展 / 一次性全选”，可共存。
- 修改映射后重启 Neovim 或重载插件，再用 `:verbose nmap <按键>` 复核最终绑定。

## 查快捷键和帮助

`:verbose nmap <C-S-n>` 查看映射来源；`:help vim-visual-multi`、`:help vm-mappings` 查看插件说明与完整映射表。
