# 文件类型与语法高亮

> 为什么打开 `.cob` 文件没有高亮？为什么缩进规则不一样？都跟 filetype 有关。

## filetype 是什么

Neovim 给每个 buffer 打一个「文件类型」标签，比如 `lua`、`python`、`markdown`、`cobol`。

这个标签决定：

- 用什么语法高亮
- 用什么缩进规则
- 加载哪些 `after/ftplugin/` 里的设置
- 启用哪些插件（很多插件按 `ft` 懒加载）

`:set filetype?` 查看当前 buffer 的类型。

## 怎么确定文件类型

三个阶段：

**1. 按扩展名或文件名**

Neovim 内置一张表：`.lua` → `lua`，`.py` → `python`，`Makefile` → `make`。

**2. 按内容识别**

比如 shebang 行 `#!/usr/bin/env python3` 会被识别成 `python`。

**3. 用户手动指定**

```lua
vim.filetype.add({ extension = { dat = "text", cob = "cobol" } })
```

这份配置就这么给 `.dat` / `.lst` / `.ctl` 指定了 `text`，让 position-ruler 能接管。

## 为什么 COBOL 要手动映射

因为 Neovim 内置表里没有 `.cob`。这份配置显式加了：

```lua
vim.filetype.add({
  pattern = {
    [".*%.[cC][oO][bB]"] = "cobol",
    [".*%.[cC][bB][lL]"] = "cobol",
    [".*%.[cC][oO][bB][oO][lL]"] = "cobol",
    [".*%.[cC][pP][yY]"] = "cobol",
  },
})
```

用的是 `pattern`（正则）而不是 `extension`，因为要**大小写不敏感**——`ACCOUNT.COB` 也得识别。

`.cpy`（copybook）也算 `cobol`，这样在 copybook 里也能用 cobol.nvim 的功能。

## 高亮的两个层次

**语法高亮**（syntax）：正则驱动，按关键词着色。

**Treesitter**：按语法树着色，嵌套结构能正确处理。

两者的差别：

```cobol
IF A = 1
   IF B = 2
      DISPLAY "X"
   END-IF
END-IF
```

正则高亮只认得「这行有 IF」，嵌套层次分不清。Treesitter 知道哪个 `END-IF` 配哪个 `IF`。

**COBOL 没有 Treesitter parser**，所以用的是正则高亮 + cobol.nvim 自己的结构识别。

## after/ftplugin：按文件类型设选项

`after/ftplugin/<filetype>.lua` 里的代码只在该类型 buffer 生效。

这份配置的例子：

```lua
-- after/ftplugin/css.lua
vim.opt_local.expandtab = true
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2
```

CSS、HTML、JSON、YAML、TypeScript 都是 2 空格缩进；Python 是 4。

**`opt_local` 是关键**——只影响当前 buffer，不会污染全局。

## 按 ft 懒加载插件

很多插件只在特定文件类型加载：

```lua
{ "OXY2DEV/markview.nvim", ft = { "markdown", "quarto" } }
```

打开 markdown 才加载，不拖慢启动。

这是插件配置里 `ft` 字段的作用。

## 常见问题

| 现象 | 原因 | 检查 |
|---|---|---|
| 没高亮 | filetype 没识别 | `:set filetype?` |
| 高亮但不准 | 用的是正则而不是 Treesitter | `:checkhealth treesitter` |
| 缩进不对 | `after/ftplugin/` 没有该类型 | `:verbose set shiftwidth?` |
| 插件没生效 | `ft` 字段不匹配 | `:Lazy` 看加载状态 |
| COBOL 没功能 | `.cob` 未映射 | 检查 `vim.filetype.add` |

**排查顺序**：先 `:set filetype?` 确认类型对，再查其它。

## 强制指定类型

临时改：

```vim
:set filetype=python
```

或者在文件里加 modeline：

```vim
# vim: set ft=python :
```

modeline 会被 Neovim 读取。出于安全考虑，某些模式默认关闭。

## 下一步

- [04 LSP 是什么](04-lsp.html)
- [05 Treesitter 与正则高亮](05-treesitter.html)
