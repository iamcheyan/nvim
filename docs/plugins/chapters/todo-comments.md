# todo-comments.nvim（BOOKMARK 书签系统）

> [回到插件目录](../PLUGINS.md)

## 它解决什么问题

读代码时需要「记住这几处，等下回来」。`Ctrl-o` 只是访问历史，Vim 的 `m` 标记又活在内存/shada 里，换机器、换会话就没了。

这里的做法是**把书签写成代码注释**：`BOOKMARK` 关键字由 todo-comments.nvim 识别、着色、加到 sign 列，位置永远跟着代码走，`git commit` 之后天然持久化，换机器 checkout 即恢复。

## 语法

```python
# BOOKMARK: CSV列不足チェック
def check(row):
    return len(row) == 12
```

```lua
-- BOOKMARK: aws profile切换逻辑
-- BOOKMARK-BEGIN: Lambda COPY処理
local function copy() ... end
-- BOOKMARK-END
```

```sql
-- BOOKMARK: ANGNR_CLM列映射
```

```sh
# region BOOKMARK: DDL差分処理
...
# endregion
```

| 写法 | 含义 |
|---|---|
| `BOOKMARK: 名称` | 单行书签，列表显示「名称」 |
| `BOOKMARK-BEGIN: 名称` … `BOOKMARK-END` | 代码段书签，列表显示行范围和整段预览 |
| `region BOOKMARK: 名称` … `endregion` | 代码段书签的另一种写法（shell/vim 风格） |

注释符号按文件类型自动选（`#`、`--`、`//` 等取自 `commentstring`），所以 Python、Lua、SQL、Shell、YAML 都直接可用。

## 视觉

- **sign 列**：hint 色书签图标 `󰃀`，优先级高于 gitsigns，所以和 TODO（`󰀌`）/ FIXME（``）一眼可分。
- **关键字**：`BOOKMARK` 用 hint 色底（`TodoBgBOOKMARK`），行尾文字用前景色。
- **当前行**：光标停在任何含 `BOOKMARK` 的行时，整行加一层淡底（`BookmarkLine`），离开即消失。
- 颜色全部由 `DiagnosticHint` 推导，切主题时自动跟随。

## 快捷键

| 按键 | 作用 |
|---|---|
| `<leader>bb` | 添加书签（普通模式加在当前行；可视模式把选区包成 `BOOKMARK-BEGIN/END` 块） |
| `<leader>bl` | 打开书签列表（Telescope） |
| `<leader>bn` | 跳到下一个书签 |
| `<leader>bp` | 跳到上一个书签 |
| `<leader>bt` | 只看 BOOKMARK（Telescope，过滤掉 TODO/FIXME） |
| `<leader>bq` | 把项目书签送进 quickfix |
| `<leader>bs` | 打开侧栏书签列表 |

缓冲区切换改成 `<leader>b]` / `<leader>b[`，把 `bn` / `bp` 让给书签。

## 列表与导航

- **Telescope**：`<leader>bl` / `:BookmarkList`。按文件、行号排序，条目形如 `CSV列不足チェック  etl/load.py:3`；右侧预览显示书签内容，块书签只预览 `[起始-结束]` 范围；回车跳转，`<C-q>` 送 quickfix。
- **侧栏**：`<leader>bs` / `:BookmarkPanel`，或点侧栏顶部的 **Marks** 标签。按项目根目录扫描，按文件分组，`回车/o/l` 跳到对应行；`R` 立即重扫。
- **Quickfix**：`:BookmarkQF`，跳转、批量处理都走原生 quickfix。
- **TODO 面板**：todo-comments 自带 `:TodoTelescope`、`:TodoQuickFix`、`:TodoTrouble`，只处理关键字。

## 命令

| 命令 | 作用 |
|---|---|
| `:BookmarkList` | 打开 Telescope 列表 |
| `:BookmarkAdd [名称]` | 添加书签但不弹输入框 |
| `:BookmarkNext` / `:BookmarkPrev` | 上/下一个 |
| `:BookmarkQF` | 生成 quickfix |
| `:BookmarkPanel` | 打开侧栏 |

## 为什么比 bookmark.nvim 更适合长期读代码

1. **持久化靠 Git**：书签是源码的一部分，`git blame`、diff、PR 里都能看到；不依赖 shada、session 或插件私有数据库，换机器 clone 就有。
2. **可搜索**：`rg BOOKMARK`、GitHub 搜索、代码评审工具都能命中；bookmark.nvim 的标记只存在于本机文件里。
3. **可评审**：书签是团队可见的注释，能解释「为什么这行重要」，而不是一个人桌面上的隐形标记。
4. **不破坏代码语义**：todo-comments 的注释识别基于 treesitter，只在注释里着色，不误伤字符串和变量名。
5. **少一个插件**：删掉 bookmark.nvim，sign/列表/搜索全部由同一个关键字体系提供。

## 配置位置

- `lua/plugins/todo-comments.lua`：关键字、sign、颜色、搜索模式。
- `lua/config/bookmarks.lua`：扫描、命名、块合并、列表、quickfix、当前行高亮。
- `lua/config/neotree_bookmarks.lua`：neo-tree 的 `bookmarks` source。
- `lua/plugins/neo-tree.lua`：侧栏标签与 source 注册。
- `lua/plugins/telescope.lua`：picker 默认项与预览面板。
