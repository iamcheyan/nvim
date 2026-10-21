# bufferline.nvim

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

Neovim 的 buffer 和 window 是两回事，但多数人需要的是「像浏览器标签一样」
在已打开文件之间切换。bufferline 把 buffer 列表画成顶部标签栏。

它**不代表 tab page**。真正的 tab page 用 `<leader><tab>` 那一组键。

## 在当前配置里怎么用

| 操作 | 按键 / 动作 |
|---|---|
| 下一个 / 上一个缓冲区 | `Shift+l` / `Shift+h` |
| 同上（备用键） | `<leader>bl` / `<leader>bh` |
| 上一个访问过的缓冲区 | `<leader>bb` |
| 关闭当前标签 | 点标签上的关闭图标，或中键点击 |
| 新建空缓冲区 | 点右侧 `+` |
| 右键标签 | 打开缓冲区菜单 |

点击标签切换；中键关闭；右键菜单是配置自己装的（`config.context_menu`），
不是 bufferline 自带。

### 视觉上的取舍

- `diagnostics = false`：标签上不显示错误角标。诊断改用状态栏和 `]d`/`]d` 跳转，
  避免标签栏闪红。
- `color_icons = false`：文件类型图标**继承选中/未选中标签的文字颜色**。
  关掉 per-filetype 颜色是为了防止选中时图标变白或留残色。
- `show_tab_indicators = false`：不画那条选中指示线，改用高亮区分。
- 侧栏（neo-tree / aerial）通过 `offsets` 让出位置，所以第一标签正好在编辑区上方。

## 动手练习

1. 打开 5 个文件，用 `Shift+l` / `Shift+h` 循环。
2. 按 `<leader>bb` 在两个文件间来回跳，感受「最近访问」和「列表顺序」的差别。
3. 右键一个标签，用菜单关闭它。
4. 点右侧 `+`，确认新建了一个空缓冲区。
5. `<leader><tab><tab>` 看真正的 tab page 列表，确认和标签栏不是一回事。

**验收**：能区分 buffer（标签栏）和 tab page 两组概念，切换都不出错。

## 注意事项

- **`WDIFF_NVIM=1` 时整个插件禁用**。这是给特定调试场景留的开关，
  如果标签栏突然消失，先检查这个环境变量。
- **`[b` / `]b` 不是缓冲区切换**。这两个键给了书签（见 bookmark 章节），
  缓冲区切换请用 `Shift+h/l`。
- **标签栏宽度有限**。文件多时会截断文件名，悬停不一定有完整路径，
  找文件还是用搜索器。
- 侧栏占位是通过 `offsets` 实现的，改侧栏宽度后标签起点会跟着变，属正常。

## 查快捷键和帮助

```vim
:help bufferline
:verbose nmap <leader>bb
```
