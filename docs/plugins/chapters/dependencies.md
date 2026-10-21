# 依赖库

> 依赖 · [回到插件目录](../PLUGINS.md)

这四个不是给你直接用的插件。它们是别的插件依赖的库，装好后由上层插件调用，
没有按键、没有命令、也不需要配置。列在这里是为了让你在 `:Lazy` 里看到一个不认识的
名字时能查到它是什么。

| 库 | 谁在依赖 | 换成别的会怎样 |
|---|---|---|
| **plenary.nvim** | diffview、neo-tree、部分测试 | 上层插件直接加载失败 |
| **nui.nvim** | noice.nvim、各类浮窗菜单 | 浮层渲染不出来 |
| **promise-async** | nvim-ufo | 折叠功能整体不可用 |
| **nvim-web-devicons** | bufferline、heirline、neo-tree、snacks | 图标全部消失，退回纯文字 |

调 JSON 解析、异步调度、路径处理、弹窗布局、文件图标——都是重复造轮子的事，
交给这几个库比每个插件各写一份更省事。它们本身不产生用户可见行为。

## 出了问题时怎么判断

**症状**：启动报 `module 'plenary' not found` 之类的错误，或某个插件功能整块失效。

**先查是否装上了**：

```vim
:Lazy
```

搜索库名，看状态是不是 loaded。lazy.nvim 会自动解析依赖，正常情况下不需要手动装。

**不要做的事**：

- 不要单独 `:Lazy disable` 这些库。上层插件会在下次加载时直接报错。
- 不要在配置里手动 `require("plenary")`、`require("nui")`。它们是给插件用的 API，
  不是用户接口。
- 不要因为「没用过」就删掉。判断依据是**有没有插件依赖它**，不是你有没有直接调过。

## nvim-web-devicons 的例外

这一个有实际可见效果，值得单独说：它决定文件图标长什么样。这份配置对 COBOL
做了定制：

```lua
["cob"] = { icon = "󰒋", color = "#00a4e4", name = "Cobol" },
```

`.cob` / `.COB` / `.cbl` / `.CBL` 都是同一个蓝色图标，所以在文件树和标签栏里
一眼能认出 COBOL 文件。

**图标显示成方块**是最常见的现象，原因是终端字体不是 Nerd Font，与库本身无关。
换字体即可，不用改配置。

## 查快捷键和帮助

这几个库没有用户命令。要查它们的 API：

```vim
:help plenary
:help nui
:help promise-async
:help nvim-web-devicons
```

如果只是想知道「这个插件为什么在这儿」，看它上层插件的章节更直接：
[nvim-ufo](nvim-ufo.html)、[bufferline](bufferline.nvim.html)、[neo-tree](neo-tree.nvim.html)。
