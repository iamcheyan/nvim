# vim-abolish

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

改命名风格（`userName` → `user_name` → `USER_NAME`）和批量替换单词的多种形态，手工做容易漏。Abolish 提供两类能力：光标下词的**命名风格转换**，以及能同时匹配多种形态的 `:Subvert`。

## 在当前配置里怎么用

不需要配置按键，插件自带 `cr` 前缀的转换：

| 按键 | 作用 |
|---|---|
| `crc` | 转成 camelCase |
| `crs` | 转成 snake_case |
| `crm` | 转成 MixedCase |
| `cru` | 转成 UPPER_SNAKE |
| `cr-` | 转成 dash-case |
| `cr.` | 转成 dot.case |
| `crt` | 转成 Title Case |

批量替换用 `:Subvert`：

```vim
:%Subvert/facilit{y,ies}/building{,s}/g
```

也可以 `:Abolish <旧词> <新词>` 建立缩写式替换。

## 动手练习

1. 把光标放在 `user_name` 上，按 `crc`，确认变成 `userName`。
2. 再按 `crm`，确认变成 `UserName`；按 `cru` 变成 `USER_NAME`。
3. 用 `:Subvert` 一次替换单复数两种形态。
4. 用 `u` 撤回，确认每次转换都能单独撤销。

**验收**：`cr` 系列在光标下即时转换；`:Subvert` 能覆盖多种词形。

## 注意

- 转换只作用于光标下的单词，不需要选中。
- `cr` 是插件自带的映射前缀，和 `<C-r>`（寄存器粘贴）无关，不要混淆。
