# neo-tree.nvim

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

搜索器擅长「我知道我要找什么」，侧栏擅长「我想看看这里有什么」。
Neo-tree 提供持久的三视图：文件系统、缓冲区、Git 状态。

配置对它的改造主要是**让出空间**：根节点被隐藏、缩进降一级，选中行的箭头、箭头后的空格、目录图标和名称共享连续的行高亮背景。expander/indent 高亮组使用透明背景，避免盖住行选区。

## 在当前配置里怎么用

| 按键 | 视图 |
|---|---|
| `<leader>fe` | 文件树（项目根目录） |
| `<leader>fE` / `<leader>e` | 文件树（当前工作目录） |
| `<leader>ge` | Git 状态 |
| `<leader>be` | 缓冲区列表 |
| `:Neotree` | 直接打开 |

`<leader>fe` 和 `<leader>fE` 的区别在**根目录取哪个**：前者固定用项目根，
后者跟随 `:cd`。在 monorepo 里切子项目时这个差别很关键。

### 在树里的操作

| 按键 | 作用 |
|---|---|
| `Enter` | 打开文件 |
| `h` / `l` | 收起 / 展开 |
| `?` | 显示该视图的完整按键表 |

Git 视图额外绑定：`ga` 暂存、`gu` 取消暂存、`gr` 撤销文件修改、`gc` 提交、
`gp` 推送、`gg` 提交并推送。**这些是真实写操作**，不是预览。

### 与 bufferline 的配合

侧栏顶部没有自己的源切换栏（`source_selector.winbar = false`），
三个视图的标签由 bufferline 的 offset 区域渲染。这样侧栏和编辑区共用同一行高度，
不会出现两条标签栏。

## 动手练习

1. `<leader>fe` 打开文件树，用 `h`/`l` 展开收起两层目录。
2. 按 `?` 看该视图的按键表，找到「新建文件」的键并试一次。
3. 改一个已跟踪文件并保存，`<leader>ge` 切到 Git 视图，确认文件出现在 unstaged 区。
4. 在 Git 视图里 `ga` 暂存，确认文件移到 staged 区。
5. `<leader>be` 看缓冲区视图，确认当前打开的文件都在。

**验收**：三个视图能互相切换，Git 视图能显示并暂存你的修改。

## 注意事项

- **`<leader>fe` 抢回了 Snacks 的 explorer 键**。配置里显式把 Snacks 的
  `<leader>fe` / `<leader>fE` / `<leader>e` / `<leader>E` 设为 `false`，
  避免两个插件争同一组键。
- **Git 视图的操作会真的改仓库状态**。`gr`（撤销文件修改）会丢改动，
  执行前先看一眼 diff。
- **根节点隐藏后路径少一级**。列表第一行不是项目名，属正常，
  不是加载失败。
- **树里打开文件不会替换特殊窗口**。terminal、quickfix、Outline 之类不会被顶掉，
  这是 `open_files_do_not_replace_types` 的作用。
- 侧栏宽度是固定的（`winfixwidth`），恢复会话时不会被 `winwidth` 压扁。

## 查快捷键和帮助

```vim
:help neo-tree
:Neotree help
```

`:Neotree help` 会在树里直接打开内置帮助页，比查文档快。
