# batch.nvim

> 私有插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

Windows Batch（`.bat` / `.cmd`）没有 LSP，语法高亮和结构导航都弱。
`batch.nvim` 提供标签导航、基础诊断和折叠。

绑定方式是 `ft = { "dosbatch" }`——**只在 Batch 文件上加载**，不影响其它语言。

## 在当前配置里怎么用

```lua
opts = {
  enable_diagnostics = true,
  enable_folding = true,
  enable_statusline = true,
  map_keys = false,   -- 不自动绑按键
}
```

`map_keys = false` 是刻意的：Batch 的按键容易和 Vim 原生冲突，
所以**不自动绑定**，需要时用命令或 Aerial 访问。

| 能力 | 状态 |
|---|---|
| 诊断 | 开启 |
| 折叠 | 开启 |
| 状态栏集成 | 开启 |
| 按键映射 | **关闭** |

### 与 contextline 的关系

它依赖 `contextline.nvim`，所以状态栏的结构上下文（标签层次）由后者提供。

## 动手练习

1. 创建一个 `.bat` 文件，写几个 `:label` 和 `goto :label`。
2. 确认文件被识别为 `dosbatch`（`:set ft?`）。
3. 打开 Aerial 大纲，确认能列出标签。
4. 用 `za` 折叠一个代码块，确认折叠生效。
5. 故意写一个不存在的标签跳转，看是否有诊断。

**验收**：标签能被大纲识别，折叠可用，诊断有反馈。

## 注意事项

- **`map_keys = false`**：没有默认按键，用命令或大纲访问。
- **只对 `dosbatch` filetype 生效**。`.bat` 扩展名要能被识别成这个 filetype。
- **诊断来自插件自身规则**，不是编译器。真正的验证要在 `cmd.exe` 里跑。
- 折叠不依赖 Treesitter（Batch 也没有 parser）。

## 查快捷键和帮助

```vim
:help batch.nvim
:Lazy
```
