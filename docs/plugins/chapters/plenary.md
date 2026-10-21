# plenary.nvim

> 依赖 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

提供 Lua 通用工具：异步任务、路径操作、弹窗、测试框架。
很多插件依赖它，包括 Telescope 生态和本配置的测试。

**它不是给你直接用的插件。**

## 在当前配置里怎么用

没有按键、没有命令。由依赖它的插件自动拉取和使用。

### 一个会被感知到的用途：测试

配置仓库的 `tests/` 目录里有大量 `.lua` 回归测试，它们跑在 plenary 的测试框架上：

```sh
nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/"
```

改状态栏、侧栏、折叠这些有视觉回归的地方，改动后应该跑对应测试。

## 动手练习

1. `:Lazy` 里搜索 `plenary`，确认已安装。
2. 找一个测试文件（如 `tests/which_key_spec.lua`）看看它怎么写的。
3. 如果配置了测试入口，跑一个最小测试确认环境可用。

**验收**：能找到它存在，并知道测试依赖它。

## 注意事项

- **不要手动 `require("plenary")`**，按需 `require` 子模块。
- **不要单独禁用**，会让依赖它的插件失效。
- 测试需要 `tests/minimal_init.lua` 之类的干净环境，不要在完整配置里跑。

## 查快捷键和帮助

```vim
:help plenary
```
