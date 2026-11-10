# todo-comments.nvim（TODO 关键字与分类侧栏）

> [回到插件目录](../PLUGINS.md)

## 它解决什么问题

代码里的 `TODO`、`HACK`、`WARN` 不只是待办，也是阅读时给自己留下的路标。todo-comments.nvim 会识别注释里的关键字，着色、加 sign，并提供检索；配置里再补上插入、删除、分类侧栏和跳转，就成了一套完整的「代码待办」工作流。

关键点：关键字就写在源码注释里，Git 提交后就永久保存，不依赖 session、shada 或任何缓存数据库。

## 支持的关键字

只有插件官方的六个，和上游默认行为一致：

| 关键字 | 图标 | 用途 |
|---|---|---|
| `TODO` | 󰄱 | 待完成 |
| `HACK` | 󰈸 | 临时绕行 |
| `WARN` | 󰀪 | 需要注意（`WARNING` 同义） |
| `PERF` | 󰒡 | 性能问题（`OPTIMIZE` 等官方别名） |
| `NOTE` | 󰋼 | 说明（`INFO` 同义） |
| `TEST` | 󰙨 | 测试相关 |

没有 `BOOKMARK`、`MARK`、`FIXME`、`CUSTOM`：`FIX` 及 `FIXME` 别名已关闭，写出来不会被识别。

## 插入与删除

| 按键 | 作用 |
|---|---|
| `<leader>tt` | 插入 `TODO:` |
| `<leader>th` | 插入 `HACK:` |
| `<leader>tw` | 插入 `WARN:` |
| `<leader>tp` | 插入 `PERF:` |
| `<leader>tn` | 插入 `NOTE:` |
| `<leader>ts` | 插入 `TEST:` |
| `<leader>td` | 删除光标所在的关键字行（只在命中关键字时生效） |

插入会按当前 buffer 的 `commentstring` 生成注释前缀并保持缩进，然后直接进入插入模式停在冒号后面：

```python
# TODO: |
```

```lua
-- HACK: |
```

```sql
-- WARN: |
```

## 列表

| 按键 | 作用 |
|---|---|
| `<leader>ta` | 项目全部关键字：优先 Snacks picker，其次 Telescope，再次 fzf-lua |
| `<leader>tf` | 仅当前 buffer（Telescope 列表 + 预览） |
| `<leader>to` | 打开侧栏 Todo 标签 |

`<leader>ta` 会调用 `Snacks.picker.todo_comments()`（本机已安装 Snacks，走这一条）；没有 Snacks 时用 `:TodoTelescope`，再退化到 fzf-lua，最后兜底 quickfix。

## 跳转

| 按键 | 作用 |
|---|---|
| `]t` | 下一个关键字（官方 `jump_next`） |
| `[t` | 上一个关键字（官方 `jump_prev`） |

只在当前 buffer 内移动，配合侧栏或列表做跨文件跳转。

## 分类侧栏

侧栏顶部的 **Todo** 标签（原 Bufs 位置）展示项目里所有关键字，按类型分组：

```
󰄱 TODO (2)
  etl/load.py
    CSV列不足チェック  L3
󰋼 NOTE (1)
  dbt/models.yml
    YAMLの列マッピング確認  L1
```

- 扫描结果来自 todo-comments 的 rg 搜索，实时生成，不写 json/sqlite/缓存文件
- 回车 / `o` / `l` 跳到对应行；`R` 立即重扫
- 图标走 Nerd Font，可在 `require("config.todo").setup({ icons = { TODO = "" } })` 里覆盖

## 自动刷新

侧栏在下列时机自动重建，无需手动刷新：

- 新增、删除、修改关键字（TextChanged / InsertLeave，300ms 防抖）
- 保存文件（BufWritePost）
- 切换 buffer（BufEnter）
- Git checkout：监听 `.git/HEAD` 的 fs_event

## 性能

- 项目扫描异步执行（todo-comments 的 rg job），不阻塞编辑
- 结果带 800ms 缓存，连续刷新不会重复全量扫描
- 扫描进行中产生新请求时用 generation 号丢弃过期结果
- 侧栏条目超过 200 条时只展开类型分组，文件保持折叠，避免一次性渲染上千行

## 命令

| 命令 | 作用 |
|---|---|
| `:TodoAdd [KEYWORD]` | 插入关键字注释 |
| `:TodoDelete` | 删除当前行的关键字注释 |
| `:TodoList` | 项目列表 |
| `:TodoBuffer` | 当前 buffer 列表 |
| `:TodoPanel` | 打开侧栏 |
| `:TodoNext` / `:TodoPrev` | 上下跳转 |
| `:TodoTelescope` / `:TodoQuickFix` / `:TodoTrouble` | 插件自带入口 |

## 配置位置

- `lua/plugins/todo-comments.lua`：关键字、图标、sign、快捷键
- `lua/config/todo.lua`：插入、删除、跳转、列表、扫描缓存、自动刷新
- `lua/config/neotree_todos.lua`：neo-tree 的 `todos` source
- `lua/plugins/neo-tree.lua`：侧栏标签与渲染器
