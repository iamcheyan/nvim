# noice.nvim

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

Neovim 的消息区和命令行都在最底部一行，信息一多就被挤掉。noice 把命令行、消息、
确认框重新路由到可配置的浮层里。

这份配置**只用它的一小部分**：把阻塞式确认框（比如未保存时 `:q`）居中显示，
其余一概保持原生底栏。所以你在使用中几乎感觉不到它的存在，直到弹出确认框。

## 在当前配置里怎么用

没有独立按键，全部是被动生效。可以注意到的场景：

| 场景 | 表现 |
|---|---|
| 未保存时 `:q` | 居中的圆角确认框，带 `Confirm` 标题 |
| 复制文本 | 底部出现 `yanked into …` 提示，约 2.2 秒后消失 |
| 普通消息 / 错误 | 仍在底部命令行区，和原生一致 |
| `:` 命令行 | 仍是原生 `:` 前缀，没有换成图标 |

### 为什么大部分功能被关掉

配置里显式关闭了这些：

```lua
popupmenu = { enabled = false }
notify = { enabled = false }
lsp = { progress = false, message = false, hover = false, signature = false }
```

原因是不想和已有组件重复：通知交给 Snacks，LSP 进度交给 fidget，
补全菜单交给 blink.cmp。**让每个功能只有一个主人**是这份配置反复出现的取舍。

## 动手练习

1. 打开一个文件随便改点内容，不保存，执行 `:q`。
2. 观察确认框是居中的圆角浮层，不是底部一行提示。
3. 按 `n` 或 `Esc` 取消，回到编辑。
4. 用 `yy` 复制一行，注意底部出现的 yank 提示，等它自己消失。
5. 执行一个会报错的操作，比如 `:edit /nonexistent`，确认错误**仍在底部**，不是浮层。

**验收**：确认框居中、yank 提示自动消失、普通消息保持在底栏。

## 注意事项

- **确认框的按键由 `config.confirm_dialog` 接管**，不是 noice 默认行为。
- **不要打开 `notify`**，会和 Snacks 的通知重复。
- **不要打开 LSP 相关项**，会和 fidget、原生 hover 冲突。
- 浮层样式来自 nui，改外观见 [浮窗 UI 设计约定](../guides/floating-window-ui.html)。

## 查快捷键和帮助

```vim
:help noice
:Noice
```

相关：[fidget](fidget.html)（LSP 进度）、[nui](dependencies.html)（浮层依赖）。
