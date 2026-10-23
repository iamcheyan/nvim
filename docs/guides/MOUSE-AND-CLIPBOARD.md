# Neovim 鼠标与剪贴板

这份说明按当前公开配置和可选私有 `smart-paste.nvim` 集成整理。`<leader>` 默认为空格。

## 鼠标选择

- `mouse=a` 开启 Neovim 的鼠标支持，可在窗口中定位和拖选。
- Visual/Select 选区释放鼠标时不会自动复制；按 `y` 或 Visual `<C-c>` 可显式复制。
- 双击的自定义处理只检查鼠标所在位置是不是 `#RGB` 或 `#RRGGBB`。命中颜色值时打开 ccc 取色器；其他位置只移动光标，不会由本配置执行“选中单词”。

## 常用键位

| 操作 | 键位 | 行为 |
|---|---|---|
| 全选文件 | `<C-a>` | Normal/Visual 进入全文件选区。Insert `<C-a>` 仍是“插入上次插入的文本” |
| 视觉块 | `<C-q>` | Normal/Visual 进入 Visual-block。Insert `<C-q>` 仍是字面控制字符 |
| 复制选区 | Visual `<C-c>` | 复制到系统剪贴板 |
| 剪切选区 | Visual `<C-x>` | 写入系统剪贴板并删除选区 |
| 智能粘贴系统剪贴板 | Normal `<C-v>` / `<leader>p`（非 Markdown），Insert `<C-v>`，Visual `<C-v>` | 私有 `smart-paste.nvim` 提供；多行内容按目标缩进调整 |
| 智能缩进 put | `p`、`P`、`gp`、`gP`、`]p`、`[p` | 自动匹配上下文缩进，已修复多余空行缺陷（空行占位自动替换） |
| 原生 yank | `y`、`yy`、`Y` | 原生 Vim 行为（寄存器与系统剪贴板同步） |
| 原生删除/修改 | `d`、`c`、`x` 等 | 原生 Vim 行为（内容进寄存器并同步系统剪贴板） |
| 复制路径 | `<leader>yp` / `<leader>yP` / `<leader>yd` | 相对路径、绝对路径、所在目录，写入系统剪贴板 |

私有 `smart-paste.nvim` 不存在时，系统剪贴板的多行智能缩进映射不可用；公开配置仍通过 Neovim 的 `+` 寄存器和系统剪贴板适配器工作。

## 跨平台剪贴板适配

配置设置 `clipboard=unnamedplus`，并按可用环境选择剪贴板后端，顺序为：

1. Wayland：`wl-copy` / `wl-paste`
2. macOS：`pbcopy`
3. Windows/WSL：`win32yank.exe`
4. X11：`xclip`
5. tmux：`tmux`
6. 以上皆不可用时：终端 OSC 52

选择的外部工具需要在 `PATH` 中可执行。远程终端是否支持 OSC 52 也取决于终端模拟器设置。

## Markdown 图片（含 Kitty SSH / tmux）

在 Markdown 缓冲区，`<leader>p`、`<leader>pi` 或 `:PasteImage` 把剪贴板图片保存到当前文档旁的 `assets/`，并插入 `![](assets/...)`。优先读取本机 Wayland/X11 图片；通过 SSH 时，配置直接向 Kitty 发送 OSC 5522 请求，可在 tmux 中读取本地 Kitty 剪贴板的 PNG、JPEG 或 WebP 数据。Kitty 可能要求允许读取剪贴板；tmux 必须允许终端直通（`allow-passthrough on`）。这与上面的文本剪贴板/OSC 52 适配器是两条独立路径。

从终端粘贴**已上传到远端的图片路径**时，Markdown 的 `vim.paste` 钩子同样会把文件归档到 `assets/`；纯本地路径若未上传到远端则无法读取。Snacks 使用 Kitty graphics protocol 显示 Markdown 图片；SSH/tmux 隐藏终端名称时，配置会通过 Kitty 的 OSC 5522 能力查询识别客户端（不读取剪贴板内容），再启用行内图片。终端不支持该协议或禁止 tmux 直通时不会强行发送图片；可用 `:checkhealth snacks` 查看检测结果。

## 配置位置

- 鼠标、全局剪贴板选项与双击颜色检测：[`lua/config/keymaps.lua`](../../lua/config/keymaps.lua)、[`lua/config/options.lua`](../../lua/config/options.lua)
 - 普通 yank/put：Neovim 内置寄存器映射
- 私有智能粘贴：`lua/plugins/smart-paste.lua`
