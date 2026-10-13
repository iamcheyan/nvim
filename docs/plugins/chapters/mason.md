# mason.nvim

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

在 Neovim 内安装和管理语言服务器、格式化器、调试器等外部工具。

## 在当前配置里怎么用

运行 `:Mason` 或 `<leader>cm` 打开界面；搜索包名，Enter 查看详情，`i` 安装、`X` 卸载、`U` 更新（以界面底部提示为准）。当前配置管理 basedpyright、lua_ls，以及 shfmt、stylua、ruff、shellcheck。ruff 为 Python 格式化服务；shellcheck 供 nvim-lint 检查 Shell 脚本。

## 动手练习

运行 `:Mason`，搜索 `lua-language-server`、`stylua`、`ruff` 和 `shellcheck`，查看安装状态。命令行也可用 `ruff check file.py` 和 `shellcheck file.sh` 检查文件；先不要卸载，练习按 Esc 退出并用 `:Mason` 再打开。

## 注意事项

Mason 安装的是外部可执行程序；配置会在启动后自动补装上述工具，已经安装的包不会重复处理。确认项目和机器需要后再卸载已有包。

## 查快捷键和帮助

在 Neovim 里用 `:verbose nmap <按键>` 查看最终映射和定义来源；按 `<leader>` 后稍等可看 which-key 提示。可用命令可用 `:command <前缀>` 查询。
