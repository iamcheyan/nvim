# nvim-web-devicons

> 依赖 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

给不同文件类型配上图标和颜色，让文件树、标签栏、状态栏一眼能区分类型。
它是多个插件的共同依赖，不是独立功能。

## 在当前配置里怎么用

| 配置 | 值 |
|---|---|
| `color_icons` | `true` |
| `default` | `true`（未知类型也给个默认图标） |
| `variant` | `dark` |

### COBOL 的定制

```lua
["cob"] = { icon = "󰒋", color = "#00a4e4", name = "Cobol" },
```

`.cob` / `.COB` / `.cbl` / `.CBL` 都指定了同一个图标和颜色（蓝色系），
所以 COBOL 文件在文件树里能一眼认出来。

### 使用方

| 插件 | 用在哪 |
|---|---|
| neo-tree | 文件树图标 |
| bufferline | 标签图标 |
| heirline | 状态栏文件图标 |

## 动手练习

1. 打开 Neo-tree，看不同文件类型的图标。
2. 打开一个 `.cob` 文件，确认它在树里是蓝色 COBOL 图标。
3. 看 bufferline 标签上的图标。
4. 确认状态栏里的文件名旁也有图标。

**验收**：COBOL 文件有专属图标，各处显示一致。

## 注意事项

- **需要 Nerd Font**。字体不对时全是方块。这是最常见的「图标坏了」原因。
- **`variant = "dark"`** 与深色主题匹配；换浅色主题可考虑 `light`。
- **它是纯数据插件**，没有命令和按键。
- 自定义图标通过 `override_by_extension` / `set_icon_by_filetype` 做。

## 查快捷键和帮助

```vim
:help nvim-web-devicons
```
