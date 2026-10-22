# position-ruler.nvim

> 私有插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

定长记录文件（`.dat`、`.lst`、`.ctl`）和 CSV 里，**第几列**才是关键信息。
普通编辑器只显示行号，你得靠数格子。position-ruler 在窗口顶部画一把字符标尺，
再给当前列画一条竖线，位置一眼可见。

这是为 COBOL 的定长记录场景做的：第 17 课那个 200 字节账户主文件就是典型用例。

## 在当前配置里怎么用

插件在 `text` 和 `csv` 文件类型上自动启用。配置额外把三个扩展名映射成 `text`：

```lua
vim.filetype.add({ extension = { dat = "text", lst = "text", ctl = "text" } })
```

所以 `.dat` 文件一打开就有标尺，不需要手动开。

| 命令 | 作用 |
|---|---|
| `:PositionJump 89` | 跳到第 89 列 |
| `:PositionRange 1 10` | 查看第 1–10 列范围 |
| `:PositionRulerToggle` | 开关标尺 |
| `:PositionRulerEnable` / `:PositionRulerDisable` | 显式启用 / 停用 |

### 配置项

| 选项 | 值 | 含义 |
|---|---|---|
| `enabled` | `true` | 默认开启 |
| `ruler` | `true` | 显示顶部标尺 |
| `show_position` | `true` | 显示当前位置 |
| `cursorcolumn` | `true` | 显示光标所在列 |
| `max_file_size` | 100 MB | 超过则不画标尺 |
| `copy_to_clipboard` | `false` | 不自动复制列号 |

## 动手练习

1. 打开课程里的定长文件：
   ```sh
   cd ~/development/cobol
   nvim lessons/17_fixed-length-files/account-master-200.dat
   ```
2. 确认顶部出现列标尺，且光标列有竖线。
3. 执行 `:PositionJump 11`，光标应落到第 11 列（账户 ID 起点）。
4. 执行 `:PositionRange 1 10`，查看前 10 列的内容。
5. `:PositionRulerToggle` 关掉，再开一次。
6. 打开一个 `.cob` 文件，确认标尺**不出现**（COBOL 用的是 cobol.nvim 的列标尺）。

**验收**：`.dat` 有标尺且能跳列，`.cob` 不出现标尺。

## 注意事项

- **和 cobol.nvim 的列标尺不是一回事**。COBOL 文件用 `cobol.nvim` 的 7/8/12/73 列标尺，
  普通数据文件用这个。两者不会同时出现，因为按 filetype 分流。
- **超过 100 MB 不画标尺**，避免频繁重绘拖慢滚动。
- **`.dat` 映射成 `text` 是全局的**。如果某个 `.dat` 其实是二进制，
  打开会显示成乱码——这时用 `:e ++bin` 而不是改映射。
- 标尺不改变文本内容，`y` 复制到的仍是原始字符。

## 查快捷键和帮助

```vim
:help position-ruler
:PositionRulerToggle
```

相关：[COBOL 章节](cobol.html)（列规则与固定格式）、[按键速查](../keys.html)。
