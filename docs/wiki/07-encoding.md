# 编码与换行符

> 「为什么中文是乱码」「为什么文件末尾多了 ^M」——两个最老的问题，原因都在这一层。

## 两个独立的东西

| | 决定什么 | 例子 |
|---|---|---|
| **编码** | 字节怎么解释成字符 | UTF-8、GBK、Big5、Shift_JIS |
| **换行符** | 行怎么分隔 | LF（Unix）、CRLF（Windows）、CR（老 Mac） |

它们是**独立**的。一个文件可以是「UTF-8 + CRLF」，也可以是「GBK + LF」。

## Neovim 的三个相关选项

| 选项 | 含义 |
|---|---|
| `encoding` | Neovim 内部用什么编码（**永远是 utf-8，不要改**） |
| `fileencoding` | 当前文件是什么编码 |
| `fileencodings` | 打开文件时按什么顺序尝试 |

**别碰 `encoding`。** Neovim 内部统一 UTF-8。要改的是 `fileencoding`。

## 打开乱码文件

```
:e ++enc=big5 文件名
```

`++enc=` 强制按指定编码重新读取。

常见编码名：

| 名称 | 用什么 |
|---|---|
| `utf-8` | 现代默认 |
| `gbk` / `gb18030` | 简体中文（Windows） |
| `big5` | 繁体中文（台湾） |
| `shift_jis` / `cp932` | 日文（Windows） |
| `euc-jp` | 日文（Unix） |
| `latin1` | 西欧 |

**先试 `gb18030`**——它是 GBK 的超集，兼容性最好。

## 保存成别的编码

```
:set fileencoding=gbk
:w
```

会按 gbk 写回文件。

**警告**：转成 gbk 后，某些字符（比如 emoji、生僻字）会无法表示，Neovim 会报错或替换成 `?`。

## `fileencodings` 的顺序

打开文件时，Neovim 按这个列表依次尝试，第一个成功的就用：

```lua
vim.o.fileencodings = "ucs-bom,utf-8,gb18030,big5,latin1"
```

| 项 | 含义 |
|---|---|
| `ucs-bom` | 带 BOM 的 UTF-8 |
| `utf-8` | 无 BOM 的 UTF-8 |
| `gb18030` | 中文兼容 |
| `latin1` | 兜底（任何字节序列都能「成功」） |

**`latin1` 必须放最后**——它对任何字节都能解读成功，放前面就永远轮不到别的。

## BOM 问题

BOM（Byte Order Mark）是文件开头的三个字节 `EF BB BF`，用来标记「这是 UTF-8」。

Windows 上的某些工具会加，Unix 工具通常不加。

**问题**：加了 BOM 的文件，第一行的第一个字符会被当成 BOM 的一部分。脚本会报「command not found」。

处理：

```vim
:set nobomb    " 保存时去掉
:set bomb      " 保存时加上
```

## 换行符

| 格式 | 字节 | 哪里用 |
|---|---|---|
| LF | `\n` | Unix、Linux、macOS |
| CRLF | `\r\n` | Windows |
| CR | `\r` | 老 Mac（已淘汰） |

Neovim 里看 `fileformat`：

```vim
:set fileformat?
```

| 值 | 含义 |
|---|---|
| `unix` | LF |
| `dos` | CRLF |
| `mac` | CR |

看到 `^M` 就是 CRLF 在 Unix 环境里显示出来了。

## 转换换行符

```vim
:set fileformat=unix
:w
```

或者不改设置，直接转换所有行：

```vim
:%s/\r$//e
```

删掉每行末尾的 `\r`。

## 这份配置的相关处理

配置里有个 `<leader>fu` 的 dos2unix 映射——把当前文件的 CRLF 转成 LF。

对 COBOL 定长文件特别重要：**多一个 `\r` 会让每条记录多一个字节**，
按固定长度解析时全部错位。

课程第 17 课那个 200 字节的账户主文件，如果被 Windows 工具处理过，
每条记录会变成 201 字节。

## 常见问题

| 现象 | 原因 | 处理 |
|---|---|---|
| 中文乱码 | 编码猜错 | `:e ++enc=gb18030` |
| 所有行尾有 `^M` | CRLF | `:set ff=unix` 然后保存 |
| 脚本第一行语法错误 | BOM | `:set nobomb` 保存 |
| 定长记录解析错位 | 多了 `\r` | 转成 unix 格式 |
| 保存后中文变问号 | 目标编码不支持该字符 | 保留 UTF-8 |
| 打开二进制文件一片乱码 | 它是二进制 | `:e ++bin` |

## 一个检查顺序

遇到编码问题，按这个顺序查：

1. `:set fileencoding?` —— 当前认为是什么编码
2. `:set fileformat?` —— 什么换行符
3. `:e ++enc=xxx` —— 换一个编码试试
4. `:set bomb?` —— 有没有 BOM
5. 用 `xxd` 或 `file` 命令直接看字节

```sh
file -i 文件名          # 猜编码
head -c 100 文件名 | xxd   # 看前 100 字节
```

## 下一步

- [按键速查](../keys.html)
- [插件手册：position-ruler](../plugins/position-ruler.html)（定长文件定位）
