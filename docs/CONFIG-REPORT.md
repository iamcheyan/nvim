# 配置改动报告

日期：2026-10-21。改动依据是 [CONFIG-REVIEW.md](CONFIG-REVIEW.md)。按文件的回溯记录在 [CONFIG-CHANGES.md](CONFIG-CHANGES.md)。没有提交。

加载顺序没变。插件的 `keys` 和 `lazy = false` 的 `config` 先执行，然后是 `lua/config/keymaps-defaults.lua`，最后 `lua/config/keymaps.lua` 覆盖同名全局键。缓冲局部映射和 `LspAttach` 更晚。

## 改了什么

### 键位只留一个主人

| 键 | 现在做什么 |
|---|---|
| `<leader>s` | 只做搜索前缀。多光标不再占用 `s` / `S` |
| `Alt+d` / `Alt+Shift+d` | 多光标跳过下一个 / 上一个匹配。终端里对应 `<M-d>` / `<M-D>` |
| `<C-d>` | 半页下滚 |
| `<leader>n` / `<leader>N`、`<C-n>`、`<C-S-n>` | 仍是加匹配光标 |
| `<leader><Up>` / `<leader><Down>` | 跳过一行再加光标。普通上下箭头只移动 |
| `<leader>A` | 多光标对齐列 |
| `<leader>a` | 数字加 1 |
| `<leader>mq` | 暂停或恢复多光标 |
| `<C-q>` | 普通和可视模式进入视觉块。插入模式仍是字面控制字符 |
| `<C-v>` | 仍是智能粘贴 |
| `<leader>gv` | 只恢复多光标。打开差异用 `<leader>gd` |
| `<leader>M` 再加字母 | 设 mark |
| `m` / `mm` / `M` | 仍是剪切到系统剪贴板 |
| `<leader>mm` / `mt` / `mc` / `mC` | 仍是书签 |
| `<leader>yp` / `<leader>yP` / `<leader>yd` | 复制相对路径、绝对路径、所在目录 |
| `<leader>cd` | 当前行诊断 |
| `<leader>bC` | 清空当前缓冲 |
| `<leader>dpp` / `<leader>dph` | profiler。`<leader>d` 不再是黑洞删除 |
| `<leader>?` | 帮助搜索 |
| `<leader>hk` | 当前缓冲的 which-key 列表 |
| `<leader>cg` | COBOL 列标尺 |
| `<leader>cL` | COBOL 记录布局 |
| `<leader>cK` | COBOL 的 `cobc` 检查 |
| `<leader>c=` | COBOL 整缓冲重排 |
| `<leader>cO` | 仍是 COBOL 保留字大小写 |
| `<leader>cr` / `<leader>cl` | 只做 LSP 重命名和 LSP 信息 |
| `<leader>sr` / `<leader>sR` | 项目替换（按当前扩展名预填过滤）/ 当前文件替换 |
| 插入模式 `<C-S-k>` | 签名帮助。`<C-k>` 留给 digraph |
| 插入模式 `<C-a>` | 重新是「插入上次插入的文本」。普通和可视 `<C-a>` 仍是全选 |

删掉的还有：`<leader>aa`、`<leader>ac`、`<leader>ad`、`<leader>d` 黑洞删除、`j`/`k` 的 `gj`/`gk`。`dd` 和 `cc` 会带上次数，所以 `3dd` 删三行。`n` / `N` 仍按搜索方向走，并展开折叠、刷新 hlslens。

COBOL 普通模式的 `<Tab>` 不再缩进，好让 `<Tab>` 继续等于 `<C-i>`。可视模式的 Tab 和 `>` / `<` 还在。

### 折叠只由 UFO 管

Treesitter 不再改 `foldmethod`。Aerial 不再管理折叠，侧栏窗口固定宽度。UFO 往 `fillchars` 里追加折叠符号，不再整段覆盖竖线和横线。

### 诊断重新可见

删掉 `lua/plugins/disable-diagnostics.lua`。标记列和下划线打开，行内虚拟文本仍然关闭。Python 在保存时用 ruff，Shell 在保存时用 shellcheck。basedpyright 只检查已打开的文件。类型检查仍是关的，缺 import 仍不报。

### 缩进和界面

全局默认仍是 Tab，宽度 4，给 COBOL、Go、Makefile。

空格缩进：Lua、JavaScript、TypeScript、JSX、TSX、JSON、JSONC、HTML、CSS、Ruby、YAML 是 2；Python 是 4。Markdown 用空格，并把 `conceallevel` 设为 2。全局 `conceallevel` 是 0。YAML 不再被强制改回 Tab。

另外：`showmode` 关掉；行尾的 `↴` 去掉；`smoothscroll` 关掉；窗口最小宽度从 1 改成 10；Git 符号颜色交给配色；旧的 swap 只在进程已经不在时直接编辑；插件更新检查改成手动 `:Lazy check`；Markdown 调色板推迟到第一次打开 Markdown；markview 随 Markdown 加载；图片远程判断不再看主机名 `hx90`。

Dashboard 只在关掉最后一个具名文件之后出现。`:enew` 和新文件仍是草稿。

### 启动报错（改完之后补的）

`winminwidth = 10` 和 auto-session 的会话脚本冲突。脚本先把 `winwidth` 设成 1，再把开头读到的 `winminwidth` 写回去，于是报 `E592`，错误框挡住空格，Leader 菜单打不开。

现在读会话之前先把 `winminwidth` 和 `winminheight` 降到 0，读完再设回 10。用真实终端复现过：错误不再出现，按空格能打开 which-key。

## 你可能会想改回去的地方

下面两处是当时专门留出来的。其余几条是行为变了、以后觉得不对可以直接改回的。

### 1. 日文编码回退

文件：`lua/config/options.lua` 的 `fileencodings`。

现在是 `ucs-bom,utf-8,default,latin1`。去掉了 `iso-2022-jp`、`cp932`、`euc-jp`，避免损坏的 UTF-8 被当成日文打开再存坏。

如果还要靠这三项去打开编码不对的日文文件，把它们加回这一行，放在 `utf-8` 后面、`default` 前面：

```lua
vim.opt.fileencodings = "ucs-bom,utf-8,iso-2022-jp,cp932,euc-jp,default,latin1"
```

### 2. COBOL 结构折叠

文件：`lua/plugins/cobol.lua` 的 `opts.folding.enable`。

现在是 `false`。插件不再把窗口改成自己的 `foldmethod=expr`，折叠统一交给 UFO，COBOL 只剩缩进折叠，段落和数据部的结构折叠没有了。

要结构折叠，把 `enable` 改回 `true`。代价是这个缓冲的折叠又会离开 UFO，`zR` / `zp` 可能和别的文件不一致。

### 3. 其它容易改回的行为

| 现象 | 现在 | 想改回去时 |
|---|---|---|
| YAML 用空格，宽度 2 | `after/ftplugin/yaml.lua` | 删掉这个文件，并在 `options.lua` 里恢复原来的 YAML FileType 自动命令（`expandtab = false`，宽度 4） |
| 只有 Markdown 隐藏标记 | 全局 `conceallevel = 0` | 在 `options.lua` 把 `conceallevel` 设回 `2`。Markdown 的 ftplugin 可以留着 |
| 行尾不再显示 `↴` | `listchars` 没有 `eol` | 在 `options.lua` 的 `listchars` 里加回 `eol = "↴"` |
| `*.conf` 更不容易被当成 shell | shell 特征要 `>= 8` 且高于 ini | 在 `options.lua` 的 `detect_generic_config` 里把 `8` 改回 `5` |
| 诊断不在行尾插文字 | `virtual_text = false` | 在 `options.lua` 的 `vim.diagnostic.config` 里改成 `true` |
| Python 类型检查仍关着 | `typeCheckingMode = "off"` | 这不是这次关掉的，原来就是关的。要开就改 `lua/plugins/lsp.lua` |
| 远程图片不再认主机名 | 只看 `SSH_CONNECTION` / `SSH_CLIENT` / `SSH_TTY` 或 `SNACKS_SSH=1` | 在 `lua/plugins/snacks.lua` 里恢复主机名和 tmux `show-environment`。本地 tmux 若被误判成远程，设 `SNACKS_SSH=0` 并不够，当前代码只在变量未设置时探测；已经是远程时导出 `SNACKS_SSH=1` |
| Kitty 图片 | `xterm-256color` / `tmux-256color` 不再当成 Kitty | 真的是 Kitty 却没图时，启动前设 `SNACKS_KITTY=1` |
| 窗口最窄 10 列 | `winminwidth = 10` | 若还和会话或其他布局冲突，把 `options.lua`、`auto-session.lua` 的 `post_restore_cmds`、`sidebar_session.lua` 里的 `10` 改回 `1`，并可以去掉 `relax_window_minimums` |
| 终端里 `<C-s>` 保存没反应 | 映射没改 | 在 shell 里执行 `stty -ixon`，终端才把 Ctrl-S 交给 Neovim |

`defaults.lazy` 保持 `false`。不要为了启动快把它改成 `true`，否则 Mason 和语言服务器不会在启动时加载。
