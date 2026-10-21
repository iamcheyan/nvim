# cobol.nvim

> 私有插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

COBOL 的编辑难点不在语法，在**列**。第 7 列是注释指示符、8–11 是 Area A、
12–72 是 Area B、73 以后被忽略。通用编辑器不认识这套规则，也不会算记录布局。

`cobol.nvim` 把这些做成编辑器能力：列标尺、结构导航、PIC 布局估算、
GnuCOBOL 诊断接入。它是这份配置里唯一针对单一语言深度定制的插件。

## 在当前配置里怎么用

| 按键 | 作用 |
|---|---|
| `g7` `g8` `g12` `g73` | 跳到固定格式的关键列 |
| `gd` | 跳到段落定义（COBOL buffer 内） |
| `gf` | 打开 Copybook |
| `K` | 预览 Copybook |
| `<leader>cL` | 计算记录布局 |
| `<leader>cK` | 立即运行 GnuCOBOL 检查 |
| `<leader>cO` | 格式化保留字大小写 |
| `<leader>c=` | 按 COBOL 缩进重排整个缓冲 |
| `<leader>cc` | 切换 Smart CAPS |
| `<leader>ch` | 查看十六进制 / EBCDIC / COMP-3 |
| `<leader>cg` | 开关列标尺 |

`<leader>cr` 只做 LSP 重命名，`<leader>cl` 只做 LSP 信息，`<leader>uc` 只切换 conceal。插件自己仍会在 FileType 时登记 `<leader>cr` / `<leader>cl`，`options.lua` 在下一轮调度里删掉并改到 `<leader>cL` / `<leader>cK`。

### 三个容易误解的点

1. **记录布局是 `<leader>cL`**，对应 `:CobolCalcRecord`。不要用 `<leader>cr`。
2. **`gd` 在 COBOL 里由本插件提供**，不是 LSP。`:verbose nmap gd` 可验证。
3. **折叠交给 nvim-ufo**。`folding.enable = false`，插件不再把窗口改成自己的 `foldexpr`。COBOL 没有 Treesitter parser，所以折叠来自 UFO 的缩进提供者。普通模式 `<Tab>` 不再缩进，留给 `<C-i>` 跳转列表。

### 文件类型识别

```lua
[".*%.[cC][oO][bB]"] = "cobol"
```

`.cob`、`.cbl`、`.cobol`、`.cpy` 都会识别成 COBOL，且**大小写不敏感**——
`ACCOUNT.COB` 也能正确识别。

## 动手练习

1. 打开一个 `.cob` 文件，`g7` `g8` `g12` `g73` 逐个跳，观察列位置。
2. `<leader>cg` 开关列标尺。
3. 在一个 01 记录上 `<leader>cL`，看字段偏移和总长度。
4. 在 `COPY "xxx.CPY".` 上按 `gf` 打开 Copybook，`K` 预览。
5. 在段落名上 `gd`，`Ctrl-o` 返回。
6. `<leader>cK` 运行编译器检查，`<leader>cq` 打开 quickfix。

**验收**：列跳转准确，布局估算有数字，Copybook 能打开。

## 注意事项

- **布局估算是估算**。组级 `OCCURS` 不乘算子字段，大的 `REDEFINES`
  覆盖不扩大合计——所以不要把结果当 ABI 保证。
- **`cobc` 必须存在**。没有 GnuCOBOL 时 `<leader>cK` 无法检查。
- **固定格式与自由格式**由 `source_format` 决定，默认 `auto` 按文件内容判断。
- **Smart CAPS 默认关闭**，需要时 `<leader>cc` 打开。
- 完整文档在插件仓库：`README.zh-CN.md` 与 `:help cobol.nvim`。

## 查快捷键和帮助

```vim
:help cobol.nvim
:CobolCalcRecord
:CobolLint
```

COBOL 相关的编辑器工作流见 [COBOL 课程站](https://cobol.iamcheyan.com/)。
