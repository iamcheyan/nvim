# nvim-treesitter-textobjects

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

`ciw` 只能按「词」选。但你想的是「改掉这个函数体」「选中这个 if 块」。
textobjects 把这些结构变成可以配合操作符的文本对象。

它必须和 nvim-treesitter **同分支**（都用 `main`），否则查询文件对不上。

## 在当前配置里怎么用

| 对象 | 按键 | 作用 |
|---|---|---|
| 函数 | `af` / `if` | 整个函数 / 函数体 |
| 类 | `ac` / `ic` | 整个类 / 类体 |
| 块、条件、循环 | `ab`/`ib`、`ao`/`io`、`al`/`il` | 外层 / 内层 |
| 参数 | `aa` / `ia` | 参数列表 |
| 跳转 | `]f` / `[f` 等 | 下一个 / 上一个同类结构 |

配合操作符使用：`daf` 删整个函数，`cif` 改函数体，`vaf` 选中后按 `y` 复制。

### 与 mini.ai 的分工

这是配置里容易混的一点：

- **textobjects** 提供 `af` / `if` 这类固定名字的对象，来自 Treesitter 查询。
- **mini.ai** 提供可自定义的对象（`cia`、`ciq`、`g` 等），也能用 Treesitter。

两者有重叠。在 **COBOL 里 mini.ai 的 Treesitter 对象会主动返回空**，
因为 COBOL 没有 parser；此时这些对象不发生作用而不是报错。

## 动手练习

1. 在 Lua 文件里把光标放进一个函数，按 `vaf`，确认选中整个函数。
2. `daf` 删掉它，然后 `u` 撤销。
3. `]f` 跳到下一个函数。
4. 在一个 if 块里按 `vib` / `vab`，体会内层与外层。
5. 打开 COBOL 文件试 `vaf`，确认**不报错，也不选中函数**。

**验收**：普通语言里对象按语法生效；COBOL 里安静地不生效。

## 注意事项

- **分支必须配对**。treesitter 和 textobjects 都用 `main`，混用会加载失败。
- **没有 parser 就没有对象**。这不是插件坏了，是语法树不存在。
- **COBOL 的行为是刻意设计的**。mini.ai 里显式返回空，避免在 COBOL 里抛错。
- 对象名（`af`、`ib`）取决于查询文件，不同语言支持程度不同。

## 查快捷键和帮助

```vim
:help treesitter-textobjects
```
