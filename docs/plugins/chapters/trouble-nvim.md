# trouble.nvim

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

诊断、符号、引用和快速修复结果分散在不同窗口里，清理一遍告警需要在多个列表之间来回跳。Trouble 把这些条目集中到一个可折叠面板里：同一套移动键，同一种预览，关闭时回到原来的窗口。

它只负责展示。诊断本身来自 LSP、linter 或 `vim.diagnostic`，所以面板为空通常表示当前没有内容，而不是插件没工作。

## 在当前配置里怎么用

| 按键 | 面板内容 |
|---|---|
| `<leader>xx` | 全部诊断 |
| `<leader>xX` | 当前缓冲区的诊断 |
| `<leader>xs` | 文档符号（函数、类、变量） |
| `<leader>xr` | LSP 引用/定义 |
| `<leader>xL` | location list |
| `<leader>xt` | TODO 标记 |

`<leader>xl` 和 `<leader>xq` 仍然打开原生的 location list 和 quickfix 窗口；Trouble 接管的是上面几项。

### 面板内按键

| 按键 | 作用 |
|---|---|
| `<CR>` | 跳到条目位置 |
| `o` | 跳转并关闭面板 |
| `q` | 关闭面板 |
| `r` / `R` | 刷新一次 / 切换自动刷新 |
| `p` / `P` | 预览条目 / 切换自动预览 |
| `zc` / `za` / `zM` | 折叠当前 / 切换 / 全部折叠 |

面板默认在底部打开，高 12 行，打开后焦点直接进入面板，方便连续跳转；关闭后回到原窗口。

## 动手练习

1. 在没有真实告警的文件里造一条诊断：

   ```vim
   :lua vim.diagnostic.set(vim.api.nvim_create_namespace("demo"), 0, {{lnum=0, col=0, severity=vim.diagnostic.severity.ERROR, message="demo error"}})
   ```

2. 按 `<leader>xx`，确认面板里出现 `demo error`。
3. 用 `<CR>` 跳到该行，再按 `<leader>xx` 关闭面板。
4. 按 `<leader>xs`，确认当前文件的符号能列出来。
5. 清理演示诊断：

   ```vim
   :lua vim.diagnostic.reset(vim.api.nvim_create_namespace("demo"), 0)
   ```

**验收**：面板能打开、能跳转、关闭后回到编辑窗口；没有诊断时面板为空但不报错。

## 注意

- `<leader>xX` 只看当前缓冲区，适合边改边清；`<leader>xx` 覆盖整个工作区。
- Trouble 的预览复用 `auto_preview`，与 bqf 的预览是两套实现，不会互相接管。
