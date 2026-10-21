# ccc.nvim

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

写主题或 CSS 时需要选颜色、看颜色、转格式（hex ↔ rgb ↔ hsl）。
ccc 提供取色器和转换工具，比在浏览器里试快得多。

## 在当前配置里怎么用

| 按键 | 作用 |
|---|---|
| `<leader>cp` | 打开取色器 |
| `<leader>cC` | 颜色格式转换 |

| 命令 | 作用 |
|---|---|
| `:CccPick` | 取色器 |
| `:CccConvert` | 转换光标下的颜色 |

### 配置的取舍

```lua
highlighter = {
  auto_enable = false,  -- 禁用自带 buffer 高亮，避免与 mini.hipatterns 争抢
  lsp = false,
}
```

**它不做高亮**，只做取色和转换。高亮由 [mini.hipatterns](mini-hipatterns.md) 负责。
这样职责清晰，也不会两个插件抢同一个高亮组。

## 动手练习

1. 光标放在一个 `#3ddc97` 上，`<leader>cp` 打开取色器。
2. 在取色器里调整色相/明度，观察预览。
3. 确认后看文本被替换成新值。
4. 光标放在颜色值上，`<leader>cC` 转换格式（hex → rgb 等）。
5. 确认颜色块的高亮仍由 hipatterns 提供（没有双色块）。

**验收**：能选色并写回文本，能转换格式，高亮不冲突。

## 注意事项

- **取色器需要终端支持真彩色**，否则预览颜色不准。
- **`<leader>cp` 与 `<leader>c` 组共存**，不是 `<leader>c` 的组标题。
- **转换会改文本**，确认后再保存；用 `u` 可撤销。
- 它不参与主题渲染，只操作文本里的颜色字面量。

## 查快捷键和帮助

```vim
:help ccc
:CccPick
```
