# 安装与更新

一套配置要能长期用，安装过程必须是可重复、可回退的。这个页面按实际执行顺序说明：
先确认依赖，再决定用哪种装法，最后是出问题时怎么退回上一步。

`init.sh` 只做三件事：检查并补齐依赖、把仓库链接到 Neovim 的配置目录、装插件。
它不会覆盖你已有的配置，也不会碰 Neovim 的数据目录（书签、会话、插件缓存）——
所以卸载配置不等于丢掉历史。

## 一、环境要求

| 项目 | 要求 | 为什么会卡住 |
|---|---|---|
| Neovim | **0.12 或更新** | Treesitter 走 `main` 分支，需要 ABI-15 parser；0.10 上高亮会整体失效 |
| 系统 | Linux、macOS；WSL 走 Linux 路径 | `xclip` / `pbcopy` / `win32yank` 后端按平台选 |
| 字体 | Nerd Font | 状态栏和文件图标是私有区字符，普通字体显示成方块 |

依赖分两类。**运行时依赖**缺了会直接报错；**可选工具**缺了只是对应功能不可用。

| 依赖 | 用途 | 缺失后果 |
|---|---|---|
| `git` `curl` | 克隆配置和插件 | 无法安装 |
| `rg`（ripgrep） | 文件与内容搜索 | `<leader>fg` 搜不到结果 |
| `jq` | 安装脚本解析 GitHub API | 安装中断 |
| `cc`（C 编译器） | 编译 Treesitter parser | 语法高亮、折叠失效 |
| `python3` + `python3-venv` | 部分插件与脚本 | Mason 装不了东西 |
| `tree-sitter` CLI **0.26.1+** | 编译 grammar | parser 装不上 |
| `unzip` `tar` | 解包语言服务器 | Mason 安装失败 |
| **可选**：`lazygit` | `<leader>gg` 打开 Git 界面 | 该键无反应 |

安装脚本会自己检查这些工具，缺了就用 `apt` / `pacman` / `brew` 装上。
**NixOS 是例外**：脚本不会改系统状态，只报出缺了哪些，需要你自己写进系统配置。

## 二、两种装法

### 方式 A：独立仓库（单机最省事）

```sh
git clone https://github.com/iamcheyan/nvim.git ~/nvim
bash ~/nvim/init.sh
```

也可以不先克隆，直接跑远端脚本（脚本检测到没有本地 checkout 时会自己克隆到 `~/nvim`）：

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/iamcheyan/nvim/main/init.sh)
```

装完 `~/.config/nvim` 是一个指向 `~/nvim` 的符号链接。之后改配置就是改 `~/nvim` 里的文件。

### 方式 B：dotfiles 子模块（多机同步）

如果这台机器已经用 dotfiles 管理配置，nvim 作为子模块存在，不需要单独 clone：

```sh
cd ~/dotfiles
git pull --recurse-submodules
git submodule update --init --recursive
bash dotlink/dotlink link
```

从「原来就是个普通目录」迁移过来的话，**先把 `config/nvim` 里的本地修改提交或备份**，
再执行上面的命令。子模块更新默认会 checkout 到游离 revision，所以要在里面改代码，
先 `git switch main`。

> 两条路径都保持可用，是这份配置的约束之一。改动安装逻辑后要跑
> `bash tests/init_spec.sh` 和 `bash -n init.sh` 才算通过。

## 三、安装脚本的选项

| 选项 | 作用 | 什么时候用 |
|---|---|---|
| （无） | 补齐依赖 + 链接 + 装插件 | 全新机器 |
| `--link-only` | 只建立符号链接，不装任何东西 | 依赖已经齐了，或在离线环境 |
| `--skip-plugins` | 准备依赖并链接，插件留到首次启动再装 | 想先看一眼配置再决定 |
| `--skip-install` | 只用现有依赖，缺任何必需项就报错退出 | CI、或严格控制环境的机器 |

`--skip-install` 和前面几个的差别在于**它不会替你装东西**：缺依赖就失败，
这样你能确定环境是被谁改的。

## 四、安装过程实际做了什么

按脚本执行顺序：

1. **判断来源**。如果是在 checkout 里跑，用当前目录；如果是从 `/dev/fd` 管道执行，
   先确认或克隆到 `~/nvim`，再用那个目录重新执行自己。
2. **检查依赖**。逐个探测 `git curl jq tar rg cc unzip python3 tree-sitter`，
   另外单独验证 `python3 -m venv` 能不能用。
3. **处理 Tree-sitter CLI 版本**。低于 0.26.1 时用 `cargo install` 装 0.26.8。
4. **检查 Neovim 版本**。低于 0.12 时调用 `scripts/install-neovim.sh`，
   从 GitHub 下最新稳定版，校验 SHA-256 后装到 `~/.local/opt/neovim`，
   不替换系统包。
5. **链接配置**。已有 `~/.config/nvim` 会先改名备份成
   `nvim.backup.<时间戳>.<pid>`，然后建符号链接。
6. **装插件**。以 headless 模式跑 `Lazy! sync`。

第 5 步的判断用的是物理路径（`pwd -P`），所以重复执行不会把链接改成嵌套链接。

## 五、更新

配置和插件是分开更新的：

```sh
git -C ~/nvim pull --ff-only      # 更新配置本身
```

然后在 Neovim 里执行 `:Lazy sync` 更新插件。两者不要混在一次操作里，
否则出问题时分不清是配置变了还是插件变了。

`lazy-lock.json` 是**机器本地文件**，被 `.gitignore` 忽略。它记录的是你实际装的插件
revision；想复现某台机器的状态，就保留它；想试最新上游，删掉它再 `:Lazy sync`。

## 六、卸载与回退

配置和数据是分开的，所以回退很轻：

```sh
rm ~/.config/nvim                          # 去掉链接（不会删仓库）
mv ~/.config/nvim.backup.<时间戳>.<pid> ~/.config/nvim   # 恢复旧配置
```

已有备份目录的名字会打印在安装输出里。如果想彻底清掉插件缓存：

```sh
rm -rf ~/.local/share/nvim ~/.local/state/nvim
```

书签、会话默认在 Neovim 的数据/状态目录里；删上面这两个目录会一起清掉，**先确认再执行**。

## 七、装完第一次打开

1. 首次启动会安装剩余插件，等它跑完。
2. 按 <kbd>Space</kbd> 停顿一下，应该出现 which-key 菜单。出现不了说明插件没装全。
3. 按 <kbd>Space</kbd> <kbd>?</kbd> 看当前 buffer 的全部映射。
4. 用 `:checkhealth` 检查 Treesitter、LSP、剪贴板后端。

装完之后建议直接看 [按键速查](keys.html)，按你实际要做的事找键，比从头背一遍有用。

## 八、常见失败

| 现象 | 原因 | 处理 |
|---|---|---|
| 高亮全没了 | Neovim < 0.12 却拉了 `main` 分支 | 升级 Neovim 到 0.12+ |
| 图标是方块 | 终端字体不是 Nerd Font | 换字体，并确认终端真的用上了 |
| `<leader>gg` 没反应 | 没装 `lazygit` | `brew install lazygit` 或对应包管理器 |
| Mason 装不上语言服务器 | 缺 `python3-venv` 或 `unzip` | 补装后重试 |
| 复制到系统剪贴板失败 | 平台后端缺失 | 见 [鼠标与剪贴板](guides/mouse-and-clipboard.html) |
| 启动报 Treesitter 错误 | CLI 版本低于 0.26.1 | `cargo install tree-sitter-cli --version 0.26.8` |

排查顺序建议：先 `:checkhealth`，再用 `:verbose nmap <键>` 确认映射来源，
最后看 [指南](guides.html) 里对应主题的记录。
