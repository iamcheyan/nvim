# Treesitter 与正则高亮

> 为什么有的语言折叠准确、有的只能按缩进？区别在于有没有语法树。

## 两代技术

| 代 | 技术 | 原理 |
|---|---|---|
| 旧 | 正则高亮（syntax） | 按行匹配关键词 |
| 新 | Treesitter | 解析出语法树，按节点着色 |

## 正则高亮的问题

```cobol
DISPLAY "IF THIS IS A STRING"
IF A = 1
```

正则看到第二行有 `IF`，正确高亮。但第一行的 `IF` 在字符串里，正则**分不清**——
它只看「这行有没有 IF 这个词」。

嵌套更明显：

```cobol
IF A = 1
   IF B = 2
      DISPLAY "X"
   END-IF
END-IF
```

正则不知道哪个 `END-IF` 配哪个 `IF`。所以折叠、文本对象、结构跳转都做不对。

## Treesitter 的做法

Treesitter 把源码解析成一棵树：

```
if_statement
├── condition: (relation)
├── if_statement
│   ├── condition: (relation)
│   └── body: (display_statement)
└── else_clause
```

有了这棵树：

- **高亮**：按节点类型着色，字符串里的 `IF` 不会被当关键词
- **折叠**：按节点范围折叠，`END-IF` 和 `IF` 天然配对
- **文本对象**：`af` 选整个函数，`if` 选函数体
- **结构跳转**：`%` 在配对的起止之间跳

## parser 是什么

Treesitter 本身只是框架，每种语言需要单独的 **parser**（语法定义），编译成动态库。

装 parser：

```vim
:TSInstall lua
:TSInstall python
:TSInstall markdown
```

parser 和 Neovim 版本绑定（ABI 版本）。**升级 Neovim 后可能需要重装 parser。**

这份配置固定用 nvim-treesitter 的 `main` 分支，它要求：

| 项目 | 要求 |
|---|---|
| Neovim | ≥ 0.12 |
| Tree-sitter CLI | ≥ 0.26.1 |

在 0.10 上 `main` 完全不可用，表现为高亮全灭。

## COBOL 为什么没有 parser

有 `tree-sitter-cobol` 项目，但：

- 没进 nvim-treesitter 的官方列表
- 需要自己编译
- 这份配置没有采用

所以 COBOL 的折叠由 `cobol.nvim` 自己实现（按 Division / Section / Paragraph 的文本规则），
文本对象在 COBOL 里被主动禁用（`mini.ai` 里显式返回空表，避免报错）。

**这是配置里反复出现的模式：COBOL 走自己的实现，其它语言走 Treesitter。**

## 怎么知道有没有 parser

```vim
:checkhealth treesitter
```

或者：

```vim
:InspectTree
```

有语法树就说明 parser 在。没有会报错。

## 增量解析

Treesitter 的 parser 是**增量**的：改一行只需要重新解析受影响的节点，不是整个文件。

所以大文件里编辑也不卡。这是它比传统全量解析好的地方。

## 和 LSP 的分工

容易混。区别：

| | Treesitter | LSP |
|---|---|---|
| 粒度 | 语法结构 | 语义 |
| 需要 server | 否（本地 parser） | 是 |
| 跨文件 | 否 | 是 |
| 例子 | 折叠、文本对象、高亮 | 跳定义、引用、重命名 |

简单说：**Treesitter 懂语法，LSP 懂语义**。

一个 `foo()` 调用，Treesitter 知道它是一个函数调用节点；LSP 知道 `foo` 定义在哪个文件的第几行。

## 配置里的实际使用

| 用途 | 谁在用 |
|---|---|
| 高亮 | nvim-treesitter |
| 折叠 | nvim-ufo（provider 是 treesitter 优先） |
| 文本对象 | nvim-treesitter-textobjects、mini.ai |
| 结构跳转 | 同上 |
| 大纲 | aerial（backend 含 treesitter） |

## 常见问题

| 现象 | 原因 |
|---|---|
| 高亮全没了 | Neovim 版本低于 parser 的 ABI |
| 某个语言没高亮 | 该 parser 没装 |
| 折叠不准 | 没有 parser，退回按缩进 |
| `:InspectTree` 报错 | parser 缺失 |
| 升级 Neovim 后出问题 | parser 需要重装 |

## 下一步

- [06 折叠机制](06-folding.html)
- [插件手册：nvim-treesitter](../plugins/nvim-treesitter.html)
- [Treesitter 参考文档](../reference/treesitter.html)
