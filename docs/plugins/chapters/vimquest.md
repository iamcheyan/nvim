# VimQuest.nvim

> 私有插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

代码里的标识符、注释、错误信息大多是英文。想练英语又不想离开编辑器——
VimQuest 把你的代码库变成词汇练习：扫描项目文件，注入词汇题（填空、同义替换），
在 Neovim 里做题。

**它的目的是练英语，不是写代码。** 装在配置里，但和日常开发解耦。

## 在当前配置里怎么用

全部通过命令操作，没有默认按键：

| 命令 | 作用 |
|---|---|
| `:VimQuestStart` | 开始一轮练习 |
| `:VimQuestStop` | 结束 |
| `:VimQuestNext` / `:VimQuestPrev` | 下一题 / 上一题 |
| `:VimQuestNextRound` | 下一轮 |
| `:VimQuestRestart` | 重来 |
| `:VimQuestTasks` | 查看任务列表 |
| `:VimQuestList` | 列出题目 |
| `:VimQuestCheck` | 检查答案 |
| `:VimQuestHint` | 提示 |
| `:VimQuestStats` | 学习统计 |
| `:VimQuestWords` | 单词表 |
| `:VimQuestSelectDictionary` | 选择词库 |

### 工作方式

1. 扫描项目，随机选代码文件。
2. 复制到临时会话目录。
3. 把词汇任务作为注释注入（填空、同义替换等）。
4. 在任务下方加 Prev/Next 跳转和 Vim 操作提示。

**原始文件不会被修改**——练习在副本上做。

## 动手练习

1. 在项目目录运行 `:VimQuestStart`。
2. 用 `:VimQuestNext` 浏览几道题，看题目怎么注入的。
3. 做一道题，`:VimQuestCheck` 检查。
4. 卡住用 `:VimQuestHint`。
5. `:VimQuestStats` 看统计，`:VimQuestStop` 结束。
6. 确认项目原文件没有被改动（`git status`）。

**验收**：能完成一轮练习，且工作树干净。

## 注意事项

- **练习在副本上做**，原文件不动。
- **需要项目里有足够的代码文件**，空目录没题可出。
- **英语水平与题目难度相关**，可用 `:VimQuestSelectDictionary` 换词库。
- 它不影响开发流程，随时可以不用。
- 书签和 VimQuest 的历史选择都用 Snacks picker 展示。

## 查快捷键和帮助

```vim
:help VimQuest
:VimQuestTasks
```
