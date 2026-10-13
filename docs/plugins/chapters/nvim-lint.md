# nvim-lint（ShellCheck）

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

在编辑 Shell 脚本时调用外部检查器。本配置用 nvim-lint 在打开、保存和离开插入模式时对 `sh`、`bash` 文件运行 ShellCheck。

## 在当前配置里怎么用

打开或修改 Shell 脚本会自动触发检查。ShellCheck 二进制由 Mason 安装；也可以在终端运行 `shellcheck script.sh` 检查文件，或运行 `shellcheck -s bash script.sh` 指定 Bash 语法。

## 动手练习

打开一个 Bash 文件后保存，确认检查器可执行：运行 `:!shellcheck %` 查看 ShellCheck 输出。也可以临时写一个未加引号的变量展开再保存，观察 ShellCheck 给出的建议。

## 注意事项

本配置全局关闭了 Neovim 诊断显示，所以自动检查不会在编辑区显示诊断标记。命令行检查仍可直接查看完整结果；若希望自动检查结果显示在编辑器里，需要启用诊断显示。

## 查快捷键和帮助

运行 `:Mason` 查看 `shellcheck` 安装状态；`:help lint` 查看 nvim-lint 的配置帮助。
