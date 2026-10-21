# nvim-lint

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

LSP 管语法和类型，但 Shell 脚本的最佳实践、Python 的风格问题需要专门工具。
nvim-lint 在**保存时**调用这些外部 linter，把结果送进 Neovim 的诊断系统。

## 在当前配置里怎么用

绑定的 filetype 与工具：

| filetype | linter |
|---|---|
| `sh` | `shellcheck` |
| `bash` | `shellcheck` |
| `python` | `ruff` |

触发时机是 `BufWritePost`——**只有保存时才检查**，编辑过程中不打扰。

结果通过标准诊断接口显示，所以：

| 按键 | 作用 |
|---|---|
| `]d` / `[d` | 下一个 / 上一个诊断 |
| `<C-w>d` | 浮窗显示当前诊断 |

### 与 conform 的分工

| 工具 | 角色 |
|---|---|
| conform | 格式化（改代码布局） |
| nvim-lint | 检查（报告问题） |
| shellcheck | 实际执行检查的程序 |

一个管格式，一个管错误，不冲突。所以 Shell 脚本保存时可能同时被 `shfmt` 重排、
被 `shellcheck` 挑毛病，两者互不干扰。

## 动手练习

1. 写一个 `.sh` 文件，故意引用未定义变量：`echo $UNDEFINED_VAR`。
2. 保存，确认出现诊断。
3. `]d` 跳到该诊断，`<C-w>d` 看详情。
4. 修正后保存，确认诊断消失。
5. 对一个 `.cob` 文件保存，确认**没有** lint 诊断（COBOL 不在列表里）。

**验收**：Shell 和 Python 保存时被检查，其它语言不受影响。

## 注意事项

- **只支持列表里的 filetype**。COBOL 的检查走 `cobc`，由 `cobol.nvim` 负责。
- **需要外部程序实际存在**。没装 `shellcheck` 时没有诊断，也不报错。
- **只在保存时触发**。想立刻检查可以手动 `:lua require("lint").try_lint()`。
- **诊断来自多个源**。LSP 和 lint 的结果会合并显示，
  看来源要在诊断浮窗里确认。

## 查快捷键和帮助

```vim
:help nvim-lint
:checkhealth
```
