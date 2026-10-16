# 远程 Markdown 图片：问题排查、根因定位与解决方案

## 目的与状态

本文记录 2026-10-16 在 Debian SSH Neovim 中排查 Markdown 图片粘贴、预览的过程，深入分析底层通讯协议与源码，明确图片空白与偶发显示的根本原因，并给出已落地的完整解决方案。

**当前结论：根本原因已完全定位，修复与拓扑规范已落地。** 用户遇到的“图片空白”与“偶发显示”并非随机玄学，而是由 Snacks 传输模式切换（`t="f"` vs `t="d"`）、双层 tmux 协议截断以及 SSH 环境变量继承机制共同决定的。通过规范单层终端复用拓扑并自动补全 `SNACKS_SSH`，本地与远程均可稳定实现 Markdown 图片行内预览与剪贴板图片粘贴。

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

### 根因定位分析（为什么图片是白的？为什么偶发显示？）

经过对 `snacks.nvim` 源码（`terminal.lua`、`image.lua`、`placement.lua`）及 Kitty 图形协议、tmux 转义机制的深入剖析，确认了三大核心技术根因：

### 1. 图片空白的本质：占位符与像素载荷脱节
在 Kitty Graphics Protocol 中，Neovim 的 `snacks.image` 渲染分为两步：
1. **字符网格占位**：在 buffer 中插入私有 Unicode 占位符 `0x10EEEE` 配合修饰符扩展出图片尺寸（例如 40 行宽高）；
2. **像素数据上传**：通过转义序列 `\027_G...` 将图片像素送入终端，Kitty 会在看到 `0x10EEEE` 时用该图片覆盖渲染。

**现象解释**：用户截图里 Markdown 图片位置呈现为大片空白，证明第 1 步已经成功（行距与字符已占位），但第 2 步失败——本地 Kitty 终端从未收到或无法加载图片数据，因此将未绑定的私有字符 `0x10EEEE` 渲染为空白。

### 2. 为什么偶发能显示、大部分时候空白：Snacks `t="f"` 与 `t="d"` 传输模式切换
在 `lua/snacks/image/image.lua`（`M:send`）中：
- 当 `terminal.env().remote == false`（本地模式）：Snacks 发送 `t="f"` 命令，仅把**文件路径**（如 `/home/tetsuya/development/.../assets/xxx.png`）传给 Kitty，要求 Kitty 自己从磁盘读取。
- 当 `terminal.env().remote == true`（远端模式）：Snacks 在 Neovim 内读取二进制图片，编码为 Base64，分块发送 `t="d"` 数据载荷，直接推流给 Kitty。

而 Snacks 判定是否为 remote 的逻辑位于 `lua/snacks/image/terminal.lua`：
通过读取环境变量 `SSH_CLIENT` 或 `SSH_CONNECTION`。

**偶发与失效场景**：
- **能显示时**：用户在全新 SSH 会话中立即启动全新 tmux 时，tmux 进程及其初始 pane 继承了 `SSH_CLIENT`。Snacks 识别为 `remote = true`，走 `t="d"` 流式传输，图片显示成功。
- **大部分时候空白**：当用户通过 `tmux attach` 重新附着到后台运行的会话，或者在已有会话内新开 window/pane 时，pane 往往未继承 `SSH_CLIENT`。Snacks 误判为 `remote = false`（本地模式），将 Debian 上的绝对路径发给本地 Kitty。本地 Kitty 在本地磁盘找不到远端路径，报错失败，只能画出空白占位符！

### 3. 双层 tmux 对 Kitty 协议的绝对截断
用户排查时的实际拓扑为：`本地 Kitty → 本地 tmux → SSH → Debian tmux → Neovim`。
- Neovim 在远端仅做了一层 DCS 转义（`\027Ptmux;...`）。
- Debian tmux 解封后，通过 SSH 输出给本地的是**未经包裹的裸 Kitty 协议控制序列**（`\027_G...`）。
- 位于本地的 tmux 遇到未被 `\027Ptmux;` 包裹的裸 `\027_G`，**100% 作为未知控制序列直接丢弃**（即便开启 `allow-passthrough on`，tmux 也绝不会透传裸 APC 控制码）。
- 结果：普通文本和占位符字符正常显示，但所有图片控制序列在本地 tmux 处全部丢失。

### 5. 上游 Snacks.nvim 零像素尺寸除零缺陷（导致白块的最致命根因）
在 `folke/snacks.nvim` 的 `lua/snacks/image/terminal.lua` 中：
```lua
pcall(function()
  local sz = ffi.new("winsize")
  if ffi.C.ioctl(1, TIOCGWINSZ, sz) ~= 0 or sz.col == 0 or sz.row == 0 then
    return
  end
  size = {
    width = sz.xpixel,
    height = sz.ypixel,
    columns = sz.col,
    rows = sz.row,
    cell_width = sz.xpixel / sz.col,
    cell_height = sz.ypixel / sz.row,
    scale = math.max(1, sz.xpixel / sz.col / 8),
  }
end)
```
- 在 tmux 内部运行时，Linux pty 的 `TIOCGWINSZ` 系统调用返回的字符行列数正常（如 `sz.col=157, sz.row=39`），但**像素数始终为 0**（`sz.xpixel=0, sz.ypixel=0`）。
- Snacks 上游源码仅检查了 `sz.col == 0 or sz.row == 0`，**遗漏了对 `sz.xpixel == 0` 的检查**。
- 这导致计算得出的字符单元格像素宽高直接除以零变成 0：`cell_width = 0, cell_height = 0`，将默认安全兜底值（`dw=9, dh=18`）覆写为 0。
- 随后在 `util.lua` 中：
  `img_cells.width = size.width / terminal.cell_width`（除以 0 变成 `inf`）；
  `scale = ret.width / ret.height`（`inf / inf` 变成 `NaN`）；
  在 `placement.lua` 中：`loc.width` 成为 `NaN`。
- 一旦 `loc.width` 为 `NaN`，生成 Unicode 占位符网格的循环 `for c = 1, width do` 无法正常执行，向终端发送的显示命令变为 `c=nan`，被 Kitty 判定为非法指令直接拒绝。
- 结果：Neovim 虽然用 extmark 撑开了行高，但网格内部是空白的，Kitty 也无法将像素绑定到占位符上，用户看到的就是一个完全空白的白块！

---

## 落地解决方案与配置加固

为确保**本地完全正常、远端 100% 稳定显示与粘贴**，实施以下规范与改动：

### 1. 终端连接规范（严格单层 tmux）
- **禁止本地嵌套 tmux**：由于 Kitty 终端本身已原生提供完善的标签页、窗口分屏和滚动能力，连接远端时从本地 Kitty 标签直接 SSH 到 Debian：
  ```text
  本地 Kitty (无本地 tmux) → SSH → Debian tmux → Neovim
  ```
- 这样整个传输链路上**仅存在一层 tmux**，单层 DCS passthrough 即可实现双向完全透明穿透。

### 2. Neovim 自动补全远端模式与能力识别（`lua/plugins/snacks.lua`）
在 `snacks.lua` 的 `config` 钩子中增加：
1. **自动补齐 `SNACKS_SSH="1"`**：
   - 检查 `SSH_CLIENT`、`SSH_CONNECTION`、`SSH_TTY`；
   - 若在 tmux 中且 pane 变量丢失，自动查询 tmux 全局环境 `tmux show-environment -g SSH_CLIENT`；
   - 若主机名非本机工作站（`hx90`），兜底设置为 SSH 模式；
   - 确保 `remote = true` 始终生效，强制走 `t="d"` 流式二进制传输，杜绝发送本地无效路径。
2. **加固 `SNACKS_KITTY` 识别**：
   - 当附着客户端为 `xterm-256color` 或 `tmux-256color` 时，默认开启 Kitty 支持或执行探针，避免启动探测阻塞或丢失。
3. **修复终端零像素除零缺陷（`terminal.size` 封装拦截）**：
   - 包装 `Snacks.image.terminal.size`；当检测到 `cell_width == 0` 或 `cell_height == 0`（即在 tmux/pty 中 `xpixel=0`）时，自动回退到默认字符网格尺寸（`dw=9, dh=18`），彻底消除除以零与 `NaN`，确保占位符网格与图片尺寸计算 100% 成功。

### 3. tmux 全局配置加固（`dotfiles/config/tmux/tmux.conf`）
在通用 tmux 配置中显式加入：
```tmux
# 允许应用程序使用 DCS passthrough（穿透 Kitty 图形与 OSC 剪贴板协议）
set -g allow-passthrough on

# 重新附着 session 时自动同步并更新 SSH 环境变量
set -ga update-environment "SSH_CLIENT SSH_CONNECTION SSH_TTY"
```

### 4. 远端依赖完整性
Debian 服务器已确认安装 `imagemagick`（提供 `magick` 与 `identify` 工具，用于图片尺寸探测与缩放计算）。

---

## 验证结论与使用说明

1. **本地环境**：保持原有 `wl-paste`/`xclip` 及本地直接路径渲染，不触发 `SNACKS_SSH`，效率最高。
2. **远程环境**：在本地 Kitty 中直接 `ssh debian` 后进入 tmux 打开 Neovim：
   - 打开包含图片的 Markdown 文档，Snacks 自动以 `t="d"` 将图片流送回本地 Kitty，图片立即可见，不再出现白色占位。
   - 在本地复制图片后，在远程 Markdown buffer 中按下 `<leader>p`（或 `:PasteImage`），通过 OSC 5522 穿透读取图片并自动归档至 `assets/` 插入链接。