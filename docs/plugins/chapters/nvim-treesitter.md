# nvim-treesitter

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

正则高亮只认得「这行有关键字」，Treesitter 认得「这个结构到哪结束」。
差别体现在折叠、文本对象、结构跳转能不能做对。

这份配置固定用 **`main` 分支**，这带来一个硬性前提：**Neovim 0.12+ 与 ABI-15 parser**。
在 0.10 上 `main` 整体不可用，表现为高亮全灭。

## 在当前配置里怎么用

| 能力 | 说明 |
|---|---|
| 语法高亮 | 打开对应文件自动启用 |
| 折叠范围 | 交给 nvim-ufo 使用 |
| 文本对象 | 配合 nvim-treesitter-textobjects |
| 增量选择 | 按语法节点逐步扩大选区 |

### 命令

```vim
:InspectTree        " 查看当前 buffer 的语法树
:TSBufEnable highlight
:TSBufDisable highlight
:checkhealth treesitter
```

`:InspectTree` 是排查「为什么这里没高亮」的第一站：语法树里没有节点，
说明 parser 没装或版本不对。

### 分支与版本约束

`main` 分支的关键约束（也是这份配置最容易踩的坑）：

| 项目 | 要求 |
|---|---|
| Neovim | ≥ 0.12 |
| nvim-treesitter | `main` |
| nvim-treesitter-textobjects | `main`（必须配对） |
| Tree-sitter CLI | 0.26.1+（编译 grammar 时需要） |

历史背景：曾经为 0.10 机器把分支钉在 `master`，该方案已废弃，
因为 `master` 被上游归档了。

## 动手练习

1. 打开一个 Lua 文件，`:InspectTree` 看语法树结构。
2. 在一个函数体内按 `vaf` / `vif`，确认按语法节点选择。
3. `:checkhealth treesitter`，确认没有版本告警。
4. 打开一个没有 parser 的文件类型，观察高亮缺失，再用 `:TSInstall` 装。
5. 按 `za` 折叠一个函数，确认折叠边界对齐语法结构而不是缩进。

**验收**：折叠和文本对象都按语法结构工作，`:checkhealth` 无告警。

## 注意事项

- **Neovim 版本是硬门槛**。升级前不要拉 `main`，否则高亮整体失效。
- **COBOL 没有 Treesitter parser**，所以 COBOL 的折叠由 `cobol.nvim` 自己实现，
  文本对象在 COBOL 里被 mini.ai 主动返回空——这是防错，不是缺功能。
- **parser 是编译产物**，和 Neovim ABI 绑定。升级 Neovim 后可能需要重装 parser。
- **`:TSUpdate` 后最好重启**，热更新的 parser 有时不生效。

## 查快捷键和帮助

```vim
:help treesitter
:help treesitter-folding
```

详见 [Treesitter 参考文档](../reference/treesitter.html)。
