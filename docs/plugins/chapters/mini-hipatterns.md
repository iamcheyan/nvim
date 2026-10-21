# mini.hipatterns

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

代码里写着 `#3ddc97`、`#ff6b6b` 这样的颜色值，你只能靠想象。
hipatterns 直接在这些文本上画出对应颜色，改主题配色时不用反复运行看效果。

## 在当前配置里怎么用

只启用了一个 highlighter：`hex_color`，只匹配形如 `#RRGGBB` 的
十六进制颜色值会被着色。

```lua
highlighters = {
  hex_color = hi.gen_highlighter.hex_color(),
}
```

加载时机是 `LazyFile`——打开文件后按需加载，不拖慢启动。

### 与 ccc.nvim 的分工

配置在这里做了一个明确取舍：

```lua
highlighter = {
  auto_enable = false,  -- 禁用 ccc 自带的 buffer 高亮，避免与 hipatterns 争抢高亮组
}
```

**高亮归 hipatterns，取色与转换归 ccc**。两个插件都能画颜色块，
同时开启会互相覆盖高亮组。

## 动手练习

1. 打开本仓库的 `site/site.css`，观察 `#3ddc97` 这类值被着色。
2. 在旁边写一个新的 `#ff0000`，确认实时着色。
3. `<leader>cp` 打开 ccc 取色器，确认它能读到当前颜色。
4. 确认没有出现双重色块（说明高亮没打架）。
5. 打开一个不含十六进制颜色的文件，确认没有误着色。

**验收**：十六进制颜色被着色，且只有一层高亮。

## 注意事项

- **只支持十六进制颜色**。`rgb()`、HSL、命名颜色不会被着色。
  需要这些用 ccc 的取色器。
- **不要同时开启 ccc 的 auto highlighter**，会与 hipatterns 抢高亮组。
- **着色是虚拟的**，不改文本内容，`y` 复制的是原始字符串。
- 在浅色主题下部分颜色与背景对比不足，这是色彩本身的问题。

## 查快捷键和帮助

```vim
:help mini.hipatterns
```
