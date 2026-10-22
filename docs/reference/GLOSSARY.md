# 术语对照

> Vim 的术语和常见中文译法不一致，容易对不上。这一页用于对照。

## 核心概念

| 英文 | 大陆常用 | 台湾常用 | 说明 |
|---|---|---|---|
| buffer | 缓冲区 | 緩衝區 | 文件在内存里的副本 |
| window | 窗口 | 視窗 | 看 buffer 的视口 |
| tab page | 标签页 | 分頁 | 一组 window 的布局 |
| register | 寄存器 | 暫存器 | 存复制/删除内容的地方 |
| mode | 模式 | 模式 | 普通/插入/可视 |
| mapping | 映射 | 對應 | 键位绑定 |
| leader | 前缀键 | 前置鍵 | 自定义键的统一前缀 |

## 操作

| 英文 | 中文 | 说明 |
|---|---|---|
| yank | 复制 / 拽 | `y` |
| put / paste | 粘贴 | `p` |
| delete | 删除 | `d` |
| change | 修改 | `c` |
| operator | 操作符 | `d` `c` `y` 等 |
| motion | 动作 | 移动命令 |
| text object | 文本对象 | `iw` `i(` 等 |
| count | 计数 | 前面的数字 |

## 界面元素

| 英文 | 中文 |
|---|---|
| statusline | 状态栏 |
| tabline | 标签栏 |
| winbar | 窗口栏 |
| cmdline | 命令行 |
| sign column | 标记列 / 符号列 |
| gutter | 边栏（行号 + 标记列） |
| floating window | 浮窗 |
| popup menu | 弹出菜单 |
| quickfix | 快速修复列表（不译） |
| location list | 位置列表 |

## 功能

| 英文 | 中文 | 说明 |
|---|---|---|
| fold | 折叠 |
| indent | 缩进 |
| highlight | 高亮 |
| completion | 补全 |
| diagnostic | 诊断 |
| session | 会话 |
| autocmd | 自动命令 |
| snippet | 代码片段 |

## 插件生态

| 英文 | 中文 / 说明 |
|---|---|
| picker | 选择器（模糊查找界面） |
| fuzzy finder | 模糊查找 |
| LSP | 语言服务器协议（不译） |
| Treesitter | 语法树解析器（不译） |
| parser | 解析器 |
| formatter | 格式化工具 |
| linter | 静态检查工具 |
| dependency | 依赖 |

## 繁体教程里的对应词

如果读台湾或香港的资料，会遇到这些：

| 繁体用词 | 大陆用词 |
|---|---|
| 游標 | 光标 |
| 檔案 | 文件 |
| 字元 | 字符 |
| 緩衝區 | 缓冲区 |
| 暫存器 | 寄存器 |
| 對應 | 映射 |
| 設定 | 设置 |
| 預設 | 默认 |
| 搜尋 | 搜索 |
| 取代 | 替换 |
| 剪貼 | 剪切/粘贴 |
| 視窗 | 窗口 |
| 分頁 | 标签页 |

## 日语资料里的对应词

如果读日文资料：

| 日文 | 中文 |
|---|---|
| カーソル | 光标 |
| ファイル | 文件 |
| 文字 | 字符 |
| バッファ | 缓冲区 |
| レジスタ | 寄存器 |
| マッピング | 映射 |
| 設定 | 设置 |
| 検索 | 搜索 |
| 置換 | 替换 |
| 折りたたみ | 折叠 |
| 補完 | 补全 |
| 画面分割 | 分屏 |
| タブ | 标签页 |

## 那些不该翻译的

这些在中文技术写作里通常保留英文：

| 词 | 原因 |
|---|---|
| buffer / window / tab | 翻译后反而混淆（尤其 tab 不等于标签页） |
| leader | 是配置里的概念名 |
| quickfix / location list | Vim 专有功能名 |
| LSP / Treesitter | 专有技术名 |
| Neovim / Vim | 产品名 |
| VimScript / Lua | 语言名 |

## 一个提醒

**「标签页」这个译法有歧义。**

- 浏览器里的「标签页」= 一个文档
- Vim 里的 tab page = 一组窗口布局

所以本站统一用 **tab page** 或「tab」，不译成「标签页」，避免和 bufferline 的文件标签混淆。

## 下一步

- [01 架构：buffer、window、tab](../wiki/01-architecture.html)
- [02 命令与 Ex 历史](commands.html)
