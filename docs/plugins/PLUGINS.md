# Neovim 插件使用书

这本书按当前 `lazy.nvim` 注册结果整理，共 **52 章**，覆盖 50 个插件（公开 43 个、私有 7 个）。其中四个依赖库共用一章，因为它们是给其它插件调用的库，没有用户入口。私有插件在章节标题和目录中标明。

## 怎么使用这本书

1. 找到想了解的插件，点击表格中的章节链接。
2. 先看“它解决什么问题”和“本配置里怎么用”，再照着“练习”操作。
3. 不确定按键是否生效时，在 Neovim 运行 `:verbose nmap <按键>`，例如 `:verbose nmap gd`，查看当前映射和来源。
4. 查看 Neovim 自带功能帮助，可运行 `:help <主题>`，例如 `:help jumplist`、`:help text-objects`。

`<leader>` 是空格。`<C-x>` 表示按住 Ctrl 再按 x；`<M-x>` 表示 Alt/Meta+x。插件可能受当前文件类型、LSP 服务、外部命令和项目状态影响；章节会注明这些前提。

## 学习路线

可以按这个顺序熟悉：

1. **先熟悉入口与找文件**：Which-key、Dashboard、Snacks、Neo-tree、Bufferline。
2. **再练编辑**：Flash、mini.ai、mini.pairs、mini.surround、multicursor.nvim、Smart Paste。
3. **然后学代码理解与格式化**：LSP、Treesitter、Aerial、Markview。
4. **再练 Git 与会话**：Gitsigns、Diffview、Auto Session。
5. **最后按需探索语言辅助和视觉插件**：COBOL、Batch、Contextline、VimQuest、颜色、折叠和状态显示。

## 搜索、启动与窗口

| 插件 | 类型 | 章节 |
|---|---|---|
| [dashboard-nvim](chapters/dashboard-nvim.md) | 公开 | 启动页、最近文件和项目目录 |
| [snacks.nvim](chapters/snacks.nvim.md) | 公开 | 文件/内容搜索、通知和工具 |
| [neo-tree.nvim](chapters/neo-tree.nvim.md) | 公开 | 文件树、缓冲区和 Git 视图 |
| [bufferline.nvim](chapters/bufferline.nvim.md) | 公开 | 缓冲区标签栏 |
| [grug-far.nvim](chapters/grug-far.nvim.md) | 公开 | 跨文件查找替换 |
| [auto-session](chapters/auto-session.md) | 公开 | 项目会话保存和恢复 |
| [aerial.nvim](chapters/aerial.md) | 公开 | 代码符号大纲 |

## 编辑、补全与代码导航

| 插件 | 类型 | 章节 |
|---|---|---|
| [blink.cmp](chapters/blink-cmp.md) | 公开 | 输入补全和代码片段 |
| [nvim-lspconfig](chapters/nvim-lspconfig.md) | 公开 | 语言服务器与跳转 |
| [mason.nvim](chapters/mason.md) | 公开 | 安装语言服务器和工具 |
| [mason-lspconfig.nvim](chapters/mason-lspconfig.md) | 公开 | Mason 与 LSP 的连接 |
| [nvim-treesitter](chapters/nvim-treesitter.md) | 公开 | 语法解析和高亮 |
| [nvim-treesitter-textobjects](chapters/nvim-treesitter-textobjects.md) | 公开 | 语法对象和结构跳转 |
| [mini.ai](chapters/mini-ai.md) | 公开 | 代码结构文本对象 |
| [mini.surround](chapters/mini-surround.md) | 公开 | 添加、删除和替换包围符号 |
| [flash.nvim](chapters/flash.nvim.md) | 公开 | 屏幕内快速定位 |
| [markview.nvim](chapters/markview.md) | 公开 | Markdown 等文档预览 |
| [multicursor.nvim](chapters/multicursor.nvim.md) | 公开 | 多光标匹配与批量编辑 |
| [nvim-ufo](chapters/nvim-ufo.md) | 公开 | 代码折叠 |

## 阅读、诊断与撤销

| 插件 | 类型 | 章节 |
|---|---|---|
| [hover.nvim](chapters/hover-nvim.md) | 公开 | 统一的悬浮文档窗口 |
| [trouble.nvim](chapters/trouble-nvim.md) | 公开 | 诊断、符号与引用面板 |
| [nvim-bqf](chapters/nvim-bqf.md) | 公开 | 快速修复列表的预览与高亮 |

## 阅读与上下文

| 插件 | 类型 | 章节 |
|---|---|---|
| [vim-illuminate](chapters/vim-illuminate.md) | 公开 | 同词引用高亮与跳转 |
| [nvim-treesitter-context](chapters/nvim-treesitter-context.md) | 公开 | 固定在窗口顶部的结构上下文 |
| [hlchunk.nvim](chapters/hlchunk.nvim.md) | 公开 | 当前代码块高亮 |

## 导航、标记与编辑辅助

| 插件 | 类型 | 章节 |
|---|---|---|
| [grapple.nvim](chapters/grapple.nvim.md) | 公开 | 按分支保存的文件标签 |
| [portal.nvim](chapters/portal.nvim.md) | 公开 | 可搜索的跳转与改动历史 |
| [vim-matchup](chapters/vim-matchup.md) | 公开 | 增强的 % 匹配与结构选中 |
| [vim-abolish](chapters/vim-abolish.md) | 公开 | 命名风格转换与批量替换 |
| [dial.nvim](chapters/dial.nvim.md) | 公开 | 可扩展的递增与递减 |

## Git 与项目记录

| 插件 | 类型 | 章节 |
|---|---|---|
| [gitsigns.nvim](chapters/gitsigns.md) | 公开 | Git 行变更与 hunk 操作 |
| [diffview.nvim](chapters/diffview.md) | 公开 | 分支差异和文件历史 |
| [bookmark.nvim](chapters/bookmark.md) | 私有 | 项目书签 |

## 界面、颜色和辅助操作

| 插件 | 类型 | 章节 |
|---|---|---|
| [heirline.nvim](chapters/heirline.md) | 公开 | 状态栏和上下文栏 |
| [which-key.nvim](chapters/which-key.md) | 公开 | 快捷键提示 |
| [snacks.nvim 缩进线](chapters/indent-guides.md) | 公开 | 缩进参考线与范围线 |
| [rainbow-delimiters.nvim](chapters/rainbow-delimiters.md) | 公开 | 成对括号着色 |
| [satellite.nvim](chapters/satellite.md) | 公开 | 窗口边缘位置标记 |
| [nvim-hlslens](chapters/nvim-hlslens.md) | 公开 | 搜索结果位置提示 |
| [fidget.nvim](chapters/fidget.md) | 公开 | LSP 任务进度提示 |
| [mini.pairs](chapters/mini-pairs.md) | 公开 | 自动补全括号和引号 |
| [mini.hipatterns](chapters/mini-hipatterns.md) | 公开 | 颜色值文本高亮 |
| [ccc.nvim](chapters/ccc.md) | 公开 | 取色与颜色转换 |
| [smart-paste.nvim](chapters/smart-paste.md) | 私有 | 系统剪贴板和缩进粘贴 |

## 私有语言工具

| 插件 | 章节 |
|---|---|
| [cobol.nvim](chapters/cobol.md) | COBOL 导航、格式和辅助 |
| [batch.nvim](chapters/batch.md) | Windows Batch 标签导航和分析 |
| [contextline.nvim](chapters/contextline.md) | 语言结构上下文栏 |
| [VimQuest.nvim](chapters/vimquest.md) | 词汇练习 |

## 管理器、图标和内部依赖

| 插件 | 类型 | 章节 |
|---|---|---|
| [lazy.nvim](chapters/lazy.md) | 管理器 | 插件安装和更新 |
| [依赖库](chapters/dependencies.md) | 依赖 | plenary.nvim、nui.nvim、promise-async、nvim-web-devicons |

## 按键冲突与常见误解

- COBOL 文件中的 `gd` 由私有 `cobol.nvim` 接管；普通语言中的 `gd` 通常由 LSP 提供。跳转后按 `Ctrl-o` 返回、`Ctrl-i` 前进。参见 [COBOL 章节](chapters/cobol.md) 和 `:help jumplist`。
- 缓冲区切换使用 `Shift+h` / `Shift+l`。`[b` / `]b` 留给私有书签。
- `<leader>gd` 是打开 Git 差异视图；普通 `gd` 是跳到定义，两者不是同一个映射。
- Snacks Dashboard 已关闭，启动页由 `dashboard-nvim` 提供；Snacks 本体仍用于搜索器、工具和私有插件集成。

## 配置位置

- 公开插件规格：`config/nvim/lua/plugins/`
- 本书章节：`config/nvim/docs/plugins/chapters/`
- 本机私有插件说明和源码：独立公开插件仓库，由 lazy.nvim 安装。

编辑快捷键后，重新打开 Neovim 或重载对应插件，再用 `:verbose nmap <按键>` 查最终绑定。插件管理操作见 [lazy.nvim 章节](chapters/lazy.md)。
