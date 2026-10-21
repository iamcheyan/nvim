# which-key.nvim

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

按键太多记不住。which-key 在你按下前缀后停顿的一瞬间，把「这个前缀下还有什么」
列出来。它是**发现键位的主要途径**，比查文档快得多。

## 在当前配置里怎么用

| 按键 | 作用 |
|---|---|
| `<leader>`（停顿） | 显示下一层可选键 |
| `<leader>hk` | 列出当前 buffer 的全部映射 |
| `<leader>?` | 帮助搜索 |
| `<c-w>`（停顿） | 显示窗口操作 |

### 分组结构

配置为常用前缀都起了组名，这样菜单显示的是语义而不是单键：

| 前缀 | 组 |
|---|---|
| `<leader>c` | code |
| `<leader>d` | profiler |
| `<leader>y` | yank path |
| `<leader>h` | help |
| `<leader>f` | file/find |
| `<leader>g` | git |
| `<leader>gh` | hunks |
| `<leader>s` | search |
| `<leader>u` | ui |
| `<leader>x` | diagnostics/quickfix |
| `<leader>m` | bookmarks |
| `<leader>w` | windows |
| `gs` | surround |
| `z` | fold |

### 动态展开

`<leader>b`（buffer）和 `<leader>w`（windows）用 `expand` 动态展开：
菜单里显示的是**当前真实的缓冲区列表和窗口操作**，不是静态列表。

## 动手练习

1. 按 `<leader>` 不要继续，观察菜单。
2. 按 `f` 进入 file 组，看二级菜单，再 `Esc` 退出。
3. 按 `<leader>hk` 看当前缓冲映射，或 `<leader>?` 搜帮助。
4. 按 `<c-w>` 停顿，看窗口操作菜单。
5. `<leader>b` 停顿，确认列出的是当前真实的 buffer。

**验收**：能用菜单发现至少 3 个原先不知道的按键。

## 注意事项

- **它有 300ms 延迟**。`timeoutlen` 决定停顿多久才弹出；
  按得快就不会弹，所以熟练后不影响效率。
- **菜单只显示已注册的映射**，不是所有 Neovim 原生命令。
- **显示受当前模式与 buffer 影响**，插入模式看到的和普通模式不同。
- `show_keys = false`：配置关掉了菜单里的按键列，只显示描述——更紧凑。

## 查快捷键和帮助

```vim
:help which-key
:WhichKey
```
