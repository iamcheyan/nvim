# 远程 Markdown 图片：问题记录与当前结论

## 目的与状态

本文记录 2026-10-16 在 Debian SSH Neovim 中排查 Markdown 图片粘贴、预览的过程，区分已经确认的现象与仍未解决的问题，供后续重新设计使用。

**当前结论：此功能尚未通过用户实际连接链路的端到端验收。** 用户提供的截图显示 README 中图片位置为空白；Snacks 报告 `supported=true`、出现占位符，均不能证明 Kitty 实际收到并显示了图像。不要将本记录中的协议探测结果当成预览成功。

## 用户可见的问题

本地 Neovim 中 Markdown 图片粘贴和预览工作。用户通过 Kitty 进入 Debian 后，报告粘贴和预览都不工作。目标文件后来明确为：

`/home/tetsuya/development/cobol.nvim/README.md`

该文件引用多张远端 PNG，例如 `assets/fixed-format-ruler.png`、`assets/outline-aerial.png`。这些文件在 Debian 上存在且是有效 PNG（`fixed-format-ruler.png` 为 1176×672，121553 字节）。因此 README 首图空白不能简单归因于图片文件缺失。

用户发来的实际屏幕截图中，Markdown 图片位置为空白。此前助手把一张 Neovim 截图中的 Unicode 占位符格子误判为图片渲染成功；这项判断错误。占位符只表明 Snacks 为图片安排了行格，没有证明 Kitty Graphics Protocol 的图像载荷已传到最终终端并显示。

## 连接拓扑与终端状态

排查到用户当前使用的路径含多个终端复用层：

```text
本地 Kitty → 本地 tmux → SSH → Debian tmux → Neovim
```

截图中的两条 tmux 状态栏与运行进程、会话记录相符。检查时 Debian `zircon` 会话同时有多个客户端：`xterm-256color`、`xterm-kitty` 和 tmux 自身的 `tmux-256color` 客户端。Neovim pane 的 `TERM` 是 `tmux-256color`，当前客户端并不总是用户期望的 Kitty 客户端。多客户端附着时，仅查询一个 `client_termname` 可能检查到另一客户端。

Debian tmux 为 3.5a，配置中启用了 `allow-passthrough on`；运行时 Snacks 又对 pane 设置了 `allow-passthrough all`。本机当前 tmux 运行时也显示 `allow-passthrough all`。这些配置值只证明 tmux 允许相应 DCS passthrough，并不证明两个 tmux 实例会正确嵌套转义、转发回复并把图像放到用户正在看的 Kitty 窗口。

## 涉及的配置路径

- `lua/config/markdown_image_paste.lua`：Markdown 专用粘贴。先检查 `+`、`*` 剪贴板寄存器中是否为图片路径；否则读取原始图片字节，归档到 Markdown 文件旁的 `assets/`，插入 `![](assets/...)`。原有本机提供者是 `wl-paste`、`xclip`。
- `lua/plugins/snacks.lua`：启用 Snacks Markdown 图片预览。Snacks 自己探测外层终端；在 tmux 中通常收到 tmux 的 XTVERSION，而不是外层 Kitty 的终端名。
- `tests/markdown_image_paste_spec.lua`：图片路径归档及本次加入的 Kitty OSC 协议模拟回归覆盖。
- `docs/guides/MOUSE-AND-CLIPBOARD.md`：原来的文本剪贴板说明；本次加入图片说明。

## 尝试过的实现

### 1. 子进程调用 `kitten clipboard`（已放弃）

最初尝试在 Vim 里运行 `kitten clipboard -g -m . /dev/stdout` 列举 MIME，再以 `kitten clipboard -g -m image/png <临时文件>` 读取图片。Kitty CLI 文档说明它支持 OSC 5522，并支持列出 clipboard MIME 与读取任意 MIME 数据；但从正在运行的 Neovim 通过 `vim.system` 或 `:!` 启动时，子进程不能打开控制终端，实际报错为：

```text
Error: open /dev/tty: no such device or address
```

因此“远端有 `kitten` 可执行文件”不等于 Neovim 能用这个子进程访问本地 Kitty 剪贴板。该子进程方案不应恢复使用。

### 2. 在 Neovim 内直接发 OSC 5522（已实现，当前链路仍待验收）

`markdown_image_paste.lua` 现在由 Neovim 直接通过 `nvim_ui_send()` 发送 Kitty OSC 5522 读取请求，在 `TermResponse` 中按每个请求独有的 `id` 收集 MIME 列表和图像数据；经过 tmux 时包上 tmux DCS passthrough。响应设有超时，拒绝、超时、损坏数据和空数据不应该创建有效图片。当前偏好 PNG、JPEG、WebP，本机 Wayland/X11 路径仍优先。

真实 Kitty 会话的探针曾在纯 SSH 和**一层**远端 tmux 中观察到 `OK`、`DATA`、`DONE` 响应；图片粘贴的一层 tmux smoke 曾成功生成 Markdown 链接，归档文件 SHA-256 与源图相同。这只证明那些探针覆盖的路径。

另一条更早的纯 SSH 尝试失败，随后一次一层 tmux 尝试也因 tmux 服务器退出而没有结果。后续不能把一次成功覆盖到当前用户的双层复用链路。

本地及 Debian 的 `markdown_image_paste_spec.lua` 均通过。该新增测试用模拟的 `TermResponse` 回调验证协议状态机、二进制分块、文件归档及 EPERM/EBUSY 失败路径；它不是真实终端或嵌套 tmux 的集成证明。

### 3. Snacks Kitty 能力识别覆盖（不能证明图片预览成功）

`snacks.lua` 在 tmux 扩展键关闭且客户端报告通用 `xterm-256color` 时，向外层终端发一个无 clipboard 内容读取的 OSC 5522 MIME 列表请求；收到匹配回复后设置 `SNACKS_KITTY=1`。这是针对 Snacks 无法从 tmux 的 XTVERSION 回复辨认外层终端的覆盖。

实际远端 Neovim 中观察到：

```text
env.name = kitty/tmux/ssh
supported = true
placeholders = true
remote = true
```

这只能证明识别逻辑收到 Kitty clipboard 协议的回应。它没有验证 Snacks 随后的 Kitty Graphics Protocol 图片传输是否通过所有转发层，也没有证明图像最终可见。用户截图的空白正是反证：能力检测成功与实际预览成功不是同一件事。

## 已有验证及其边界

| 检查 | 结果 | 能证明什么 | 不能证明什么 |
|---|---|---|---|
| 本地与 Debian `markdown_image_paste_spec.lua` | 通过 | Lua 状态机、模拟终端响应与归档逻辑符合测试预期 | 真实 Kitty、剪贴板权限、嵌套 tmux 转发 |
| OSC 5522 在纯 SSH/单层 tmux 的探针 | 收到协议响应 | 对应单层路径存在 OSC 5522 往返 | 用户当前两层 tmux 路径 |
| 一层远端 tmux 图片粘贴 smoke | 链接成功，文件哈希与源图片一致 | 该 smoke 终端路径能取回原始图片数据 | 用户当前附着的 Kitty 客户端及预览图形传输 |
| Snacks `supported=true`、Unicode 占位符 | 观察到 | 检测和布局阶段认为终端受支持 | Kitty 收到图像、图像可见 |
| README 实际用户截图 | 图片空白 | 当前用户链路没有得到期望的可见预览 | 单凭截图不能唯一定位是哪一层丢失载荷 |
| `kitten icat --detect-support` 返回 `stream` | 曾在一层 Kitty/tmux pane 成功 | 那条命令测试的终端能检测到 Kitty graphics stream | 命令未在同一时刻、同一 pane、同样的双 tmux 链路中完成真实可见图片验收 |

曾试图从工具里通过 `grim` 看桌面；获取到的截图要么是其他工作区应用，要么是空白桌面，并非用户屏幕上目标 Kitty 窗口。因此不能把这些捕获作为显示成功证据。排查期间也误把命令发送给 Neovim，造成临时命令文本污染缓冲区；通过 `:edit! README.md` 恢复过该 README 缓冲区。没有证据表明该误操作写入了 README 文件，但未来检查必须先确认前台窗口与目标 pane，再发送按键。

## 仍未定位的具体故障点

目前能确定的是端到端图像显示路径没有被正确验证，且用户实际截图显示功能失败。还未证实问题发生在下列哪一处：

1. 当前 Kitty 图像请求没有从本机 tmux 正确穿过 SSH 与 Debian tmux；
2. 双层 DCS passthrough 的转义层数或 `allow-passthrough` pane/client 作用域不匹配；
3. tmux 的多个附着客户端导致侦测或回复走向另一个终端；
4. Kitty graphics 数据到达了外层 Kitty，但远端文件/传输模式或复绘/占位符生命周期导致图片没有可见；
5. 图片已经发出，但当前用户看到的窗口/工作区不是正在运行预览的那一个。

最后一项很现实：用户截图显示的真实视图是权威结果；工具对会话的文字输出、pane 捕获、环境报告和模拟回调都不能替代该结果。

## 下一次诊断建议

按一条可重复的真实链路从外向内定位，不再同时开多个 Kitty/tmux 会话：

1. 先确认用户当前前台 Kitty 窗口、它的 tmux pane、SSH 子进程和 Debian tmux pane 的关系；确认 Kitty 窗口标题、PID、pane TTY 与活动客户端一致。
2. 在**同一个 Neovim pane**先运行 `:checkhealth snacks`，记录客户端、terminal env、placeholders、remote、文件解析与转换错误。
3. 用 Kitty 的 `kitten icat --transfer-mode=stream --place=... <远端有效 PNG>` 在完全相同的 SSH/嵌套 tmux pane 显示真实图片。必须由用户确认 Kitty 窗口中肉眼可见图片；仅 `--detect-support` 返回 `stream` 不够。
4. 若 icat 失败，先隔离 tmux 层：同一 Kitty 窗口直连 SSH、不进任一 tmux；再依次加本地 tmux、远端 tmux。每次只增一层。检查终端回应和真实可见输出，不凭 options 值推断。
5. 若 icat 成功，再在相同窗口单独验证 Snacks；打开一份最小 Markdown，只含一个短路径的已存在 PNG。打开 `debug.request`，从 Kitty/终端记录确认 graphics transfer、place、delete 的请求和 Kitty 响应/错误；确认图像确实可见后才判定完成。
6. 剪贴板粘贴单独验证：本地 Kitty 剪贴板放入已知 PNG，在同一目标 pane 使用 `:PasteImage`，检查链接、文件尺寸和 SHA-256。图片路径粘贴与原始剪贴板字节读取是不同输入路径，需分别测。
7. 验证双层 tmux 时测试 DCS 嵌套：每经过一个 tmux 都必须额外转义 ESC，响应还要能逐层退回产生请求的 Neovim。当前实现只依据 `vim.env.TMUX` 包一层，未建立适用于任意嵌套层数的可靠机制；这是一个值得优先验证的设计缺口。

如果用户日常必须使用双层 tmux，而 Graphics Protocol 不能稳定逐层往返，保守方案是减少一层（例如本地 Kitty 标签直接 SSH 到 Debian 的 tmux），或采用明确支持嵌套 Kitty passthrough 的连接方式；不要通过强制 `SNACKS_KITTY` 把“已知失败的显示链路”伪装成已支持。

## 仓库与发布说明

该调查期间已直接复制过配置文件到 Debian 工作树用于 smoke。此前报告“已提交/拉取”不准确：当时并未提交或拉取，代码是逐文件复制的。本记录的后续提交应作为完整状态的基线；提交前再次检查本地和 Debian 的工作树，仅纳入图片相关文件及本记录，保留其他用户改动。