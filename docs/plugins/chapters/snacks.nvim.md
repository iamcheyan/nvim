# snacks.nvim

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

这份配置里最重的「基础设施」插件。它不是一个功能，而是一组：

- **picker**：文件、内容、缓冲区、帮助、最近文件、符号
- **通知**：替代 `:messages` 的浮窗
- **状态列与滚动条**的辅助
- **终端**、**LazyGit** 入口
- **图片渲染**（本地 Kitty/WezTerm 等）
- 若干小工具，包括书签和练习插件的列表后端

配置把它的 Dashboard 和 Explorer 都关掉了——启动页交给 dashboard-nvim，
文件树交给 Neo-tree。所以**它是搜索层，不是界面框架**。

## 在当前配置里怎么用

### 搜索入口

| 按键 | 作用 |
|---|---|
| `<leader>ff` | 找文件（项目根目录） |
| `<leader>fF` | 找文件（从 Git 根目录） |
| `<leader>fb` | 缓冲区列表 |
| `<leader>fr` | 最近文件 |
| `<leader>fg` | 在当前工作目录搜内容 |
| `<leader>fG` | 在 Git 根目录搜内容 |
| `<leader>fw` / `<leader>fc` | 在当前工作目录搜光标下单词 |
| `<leader>fW` | 在 Git 根目录搜光标下单词 |
| `<leader>sg` / `<leader>sw` | 在 Git 根目录搜内容 / 光标词 |
| `<leader>/` | 搜内容（picker 默认目录） |
| `<leader>fh` | 帮助文档 |
| `<leader>fS` | Treesitter 符号 |
| `<leader><space>` | 快速找文件 |

### picker 内部按键

| 按键 | 作用 |
|---|---|
| 输入字符 | 实时过滤 |
| `Enter` | 打开选中项 |
| `Esc` | 关闭 |
| `Alt-h` / `Ctrl-h` | 切换显示隐藏文件 |
| `Alt-i` | 切换是否显示被 `.gitignore` 忽略的文件 |

`Alt-h` 有两个绑定（`<a-h>` 和 `<c-h>`），因为部分终端把 Alt 和 Ctrl 混在一起送。

### Git 入口

`<leader>gg` 在 **Git 根目录**启动 LazyGit，`<leader>gG` 在**当前目录**启动。
两者的差别在子目录里很明显：改动在仓库根，就应该用前者。

`<leader>gl` / `<leader>gL` 看 Git log，`<leader>gf` 看当前文件历史。

## 动手练习

1. 在项目里按 `<leader>ff`，输入文件名片段，回车打开。
2. 按 `<leader>fg`，搜一个你确定出现在多个文件里的词，观察列表带行号和预览。
3. 在 picker 里按 `Alt-h`，确认出现了 `.git` 等隐藏项；再按一次取消。
4. 按 `<leader>fw` 在光标下单词上搜索，验证它自动带入了当前词。
5. 按 `<leader>gg` 打开 LazyGit（需已安装），按 `q` 退出。

**验收**：五个入口都能打开对应 picker，且 `<leader>gg` 打开的是仓库根目录。

## 注意事项

- **`<leader>ff` 与 Neo-tree 的 `<leader>fe` 不是一类**：前者是浮动搜索器，
  后者是持久侧栏。找文件用搜索器，浏览目录结构用侧栏。
- **WSL 下图片渲染被禁用**。WSL 的终端图形协议通常不可用，会输出乱码转义序列，
  所以配置在检测到 WSL 时关闭 image 模块。这不是故障。
- **SSH / tmux 里图片可能不显示**。配置会在检测到真实 SSH 会话时设置
  `SNACKS_SSH=1`；在 tmux 里会探测 `client_termname` 是否含 kitty。
  如果仍然空白，先确认终端本身支持图片协议。
- **LazyGit 是外部依赖**。没装 `lazygit` 时 `<leader>gg` 会报错而不是静默失败。
- **隐藏文件过滤依赖 ripgrep**。搜索器的源用 `--no-messages` 参数，
  项目很大时首次搜索会慢一点，属正常。

## 查快捷键和帮助

```vim
:help snacks
:help snacks-picker
```

`<leader>fh` 打开帮助搜索器后输入 `snacks` 可以直接跳到相关 help 标签。
