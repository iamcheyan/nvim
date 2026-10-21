# aerial.nvim

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

长文件里「有哪些函数 / 类 / 段落」需要一份目录。Aerial 提供符号大纲侧栏，
点条目跳到定义。它和 Neo-tree 共用侧栏位置，由 `config.sidebar_tabs` 统一管理。

## 在当前配置里怎么用

| 按键 | 作用 |
|---|---|
| `<leader>cs` | 开关符号大纲（走 sidebar_tabs，不是直接 toggle） |
| `:AerialToggle` | 插件原生开关 |
| `:AerialOpen` | 打开 |
| `:AerialInfo` | 查看当前 buffer 支持的后端 |

`<leader>cs` 绑的是配置自己的 `config.sidebar_tabs.toggle_symbols()`，
所以它会和文件树、Git 视图共享同一个侧栏槽位，不会开出第二个侧栏。

### 后端

普通语言用 Treesitter 或 LSP 提供符号。**COBOL 和 Batch 用私有插件提供的后端**——
这也是为什么在 COBOL 文件里能列出段落和 Division，而其它编辑器不行。

## 动手练习

1. 打开一个 LSP 已就绪的 Lua 文件，`<leader>cs` 打开大纲。
2. 在大纲里选一个函数，确认跳到了定义。
3. `:AerialInfo` 看当前文件用的是哪个后端。
4. 打开一个 COBOL 文件，重复第 1 步，确认结构条目来自私有后端。
5. 再按一次 `<leader>cs` 关闭，确认侧栏位置让回给文件树。

**验收**：两种语言的符号都能列出，且侧栏不会同时出现两个。

## 注意事项

- **没装 LSP / 没有 parser 时大纲为空**。这不是故障，`:AerialInfo` 会说明原因。
- **COBOL 后端来自私有插件**。只装公开配置的话，COBOL 大纲不可用。
- `<leader>cs` 不是插件的 `AerialToggle`，两者行为在侧栏管理上不同。
- 大纲会跟随光标自动高亮当前符号，这是默认行为，可以在 `win_opts` 里调。

## 查快捷键和帮助

```vim
:help aerial
:help aerial-options
```
