# lazy.nvim

> 管理器 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

插件管理器负责：安装、更新、锁定版本、按需加载。
lazy.nvim 的核心能力是**懒加载**——插件只在真正需要时才加载，缩短启动时间。

这份配置用它管理 40 个插件规格。

## 在当前配置里怎么用

| 命令 | 作用 |
|---|---|
| `:Lazy` | 打开管理界面 |
| `:Lazy sync` | 安装缺失 + 更新（等价于 install + update） |
| `:Lazy update` | 只更新 |
| `:Lazy install` | 只装缺失的 |
| `:Lazy clean` | 清理不再需要的插件 |
| `:Lazy profile` | 看启动耗时分布 |
| `:Lazy log` | 查看变更历史 |
| `:Lazy health` | 健康检查 |

### 懒加载策略

配置里用到的触发方式：

| 字段 | 含义 | 例子 |
|---|---|---|
| `lazy = false` | 启动即加载 | multicursor、bufferline |
| `event` | 事件触发 | `BufReadPost`、`VeryLazy` |
| `ft` | filetype 触发 | markview、batch |
| `cmd` | 命令触发 | `:GrugFar`、`:Mason` |
| `keys` | 按键触发 | 大多数插件 |

`multicursor` 特意用 `lazy = false`：`<C-S-n>` 这类带修饰键的映射
在懒加载回放时不可靠，首次按下会没反应。

### 锁文件

`lazy-lock.json` 记录每个插件的实际 revision，**被 `.gitignore` 忽略**，
是机器本地文件。想复现某台机器的状态就保留它；想试最新上游就删掉再 sync。

## 动手练习

1. `:Lazy` 打开界面，看插件列表和加载状态。
2. 切到 `Profile` 标签，看哪些插件拖慢了启动。
3. `:Lazy sync`，观察安装/更新。
4. 在界面里按 `?` 看完整按键。
5. `:Lazy clean` 清理无用插件，注意确认提示。

**验收**：能看清单个插件的加载方式，并能安全地 sync。

## 注意事项

- **`:Lazy sync` 会改工作树之外的东西**（插件目录），但不改配置仓库。
- **锁文件不进版本库**是有意的：不同机器允许有不同插件版本。
- **开发自有插件**时用 `dev` 配置指向本地 checkout，
  见 README 的「独立插件与本地开发」一节。
- 某些插件必须 `lazy = false`（如需在启动时就注册按键的），
  改成懒加载会导致按键首次无响应。

## 查快捷键和帮助

```vim
:help lazy.nvim
:Lazy
```
