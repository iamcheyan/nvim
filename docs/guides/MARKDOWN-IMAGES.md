# Neovim Markdown 图片预览与粘贴

本文说明当前配置如何在 Markdown 缓冲区中预览图片，以及如何把剪贴板图片归档到文档旁的 `assets/` 并插入 Markdown 引用。实现由两个插件和一段自定义 Lua 配置共同完成：Markview 负责 Markdown 语法的可视化呈现，Snacks image 负责文档图片的内联/浮动显示，`config.markdown_image_paste` 负责图片文件的保存和引用生成。

## 能力总览

| 操作 | 实现 | 结果 |
| --- | --- | --- |
| 打开 Markdown | `OXY2DEV/markview.nvim` | 标题、列表、代码块等 Markdown 元素以预览样式显示 |
| 预览文档引用的图片 | `folke/snacks.nvim` 的 `image.doc` | 支持内联和浮动图片预览，图片目录包含 `assets/` 等 |
| 在 Markdown 中粘贴图片路径 | 自定义 `vim.paste` 包装及 `config.markdown_image_paste` | 将现存图片复制到文档的 `assets/`，把路径改成 `![](assets/...)` |
| 粘贴剪贴板中的图片像素 | `<leader>p` / `<leader>pi` 或 `:PasteImage` | 从 Wayland/X11 读取原始图片字节、保存到 `assets/` 并插入引用 |
| 把当前行中的图片路径归档 | `<leader>ci` 或 `:ConvertImageUnderCursor` | 复制图片到 `assets/`，并在当前行替换为相对引用 |

具体按键受 `mapleader` 影响；当前 leader 是空格。

## 打开 Markdown 图片预览

### Markdown 语法预览：Markview

插件规格位于 `lua/plugins/markview.lua`：

- 使用 `OXY2DEV/markview.nvim`。
- `lazy = false` 保证插件规格不延迟到后续事件才安装/配置；同时保留 `ft` 文件类型范围，适用于 Markdown、MDX、Quarto 和 R Markdown。
- `preview.enable = true` 启用预览；`preview.filetypes` 明确列出支持的文件类型；`icon_provider = "internal"` 使用插件自带图标提供器。
- `<leader>um` 映射到 `:Markview`，用于切换 Markview 预览。

打开 Markdown 文件后，Markview 将编辑器中的 Markdown 标记转换成适合阅读的呈现，例如标题层级、列表标记、引用、代码块和表格。配色及 Markdown 窗口的隔离处理由 `config.markdown_typography` 管理；这与图片文件解码/绘制是不同层次。

### 文档图片预览：Snacks image

`lua/plugins/snacks.lua` 的 `image` 选项启用图片功能，并配置 `doc`：

```lua
image = {
  enabled = true,
  doc = {
    inline = true,
    float = true,
    max_width = 80,
    max_height = 40,
  },
  img_dirs = { "assets", "img", "images", "static", "media", "attachments" },
}
```

Snacks image 读取文档中的 Markdown 图片引用，并按文档相对目录和 `img_dirs` 配置寻找资源。这里把 `assets` 列入搜索目录，因此由下方粘贴功能生成的 `![](assets/image-....png)` 可以被预览。`inline` 和 `float` 同时开启；尺寸上限为 80 列、40 行。实际显示还依赖 Snacks image 后端支持的终端/图形环境和图片解码依赖。预览未出现时，先检查引用路径确实存在，再检查当前终端是否支持 Snacks 所用的图片协议及相应依赖。

## 图片粘贴与归档

核心实现位于 `lua/config/markdown_image_paste.lua`，由 `lua/config/lazy.lua` 在 Lazy 插件管理器初始化后调用 `require("config.markdown_image_paste").setup()`。

### 目标目录和文件命名

`save_image_to_assets(source_path, bufnr)` 以目标 Markdown 缓冲区文件所在目录作为文档目录；若缓冲区尚未命名，则使用 Neovim 当前工作目录。它在该目录下创建 `assets/`（等同于 `mkdir -p`），把图像复制进去，然后返回相对于文档目录的 `assets/<文件名>`。

文件名采用 `image-YYYYMMDD-HHMMSS.<扩展名>`。若同一秒已存在同名文件，则依次尝试 `image-YYYYMMDD-HHMMSS-1.<扩展名>`、`-2` 等，避免覆盖已有图片。图片扩展名从源路径提取并转为小写；原始剪贴板读取识别 PNG、JPEG 和 WebP MIME 类型。

路径检测 `is_image_file()` 支持普通路径、包在同类引号中的路径，以及 `file://` URI；会展开 `~/`，只接受受支持的图像扩展名，并使用文件系统 `stat` 确认目标确实是普通文件。因此普通文字、无效路径或不存在的图片不会被转换。

### 两种剪贴板载荷

粘贴逻辑先处理系统剪贴板寄存器中的图片路径，再尝试剪贴板里的原始图片字节：

1. **剪贴板里是图片文件路径**：依次读取系统寄存器 `+`、`*`，检查内容中是否存在一个或多个可访问的图片文件路径。每张图片复制到文档的 `assets/`，再把对应路径替换为 `![](assets/生成的文件名)`。有意不读取 unnamed register `"`，避免误把之前编辑/复制过的旧路径再次归档。
2. **剪贴板里是图片像素数据**：如果寄存器路径没有转换成功，则探测系统剪贴板原始数据。Linux Wayland 使用 `wl-paste --list-types` 查 MIME，再按 PNG、JPEG、WebP 顺序读取支持的类型；如果当前 `WAYLAND_DISPLAY` 不存在或指向已失效 socket，会在 `XDG_RUNTIME_DIR`（缺省为 `/run/user/<uid>`）下扫描有效的 `wayland-N` socket 并修正环境变量。Wayland 路径不可用时，若有 `xclip`，则查询 X11 clipboard targets 并尝试相同 MIME 类型。取出的字节先写入带正确扩展名的临时文件，再复制到 Markdown 的 `assets/`；临时文件随后删除。

从寄存器读取路径时会清理前后空白、包裹引号和 `file://`，并且处理末尾换行。系统命令的输出通过临时文件大小检查，避免把空结果当成图像。

### 自动转换路径的入口

`setup()` 保存原生 `vim.paste` 函数，并安装包装器。只有当前缓冲区 `filetype == "markdown"` 时，包装器才会逐行检查粘贴文本；找到已有图片文件路径时，先复制图片并将路径替换成 Markdown 图片语法，再把修改后的行交给原生粘贴。普通文本、其他文件类型和没有可转换图片路径的输入直接交给原生粘贴函数，保留原来的粘贴行为。逐行检查也支持一次粘贴多张图片。

Markdown 文件类型的 `FileType` 自动命令建立缓冲区局部快捷键：

- `<leader>p` 与 `<leader>pi`：调用 `paste_image()`。这是 Markdown buffer-local 映射，会在 Markdown 文件中使用图片粘贴行为。
- `<leader>ci`：调用 `convert_image_under_cursor()`，只转换光标所在行的现存图片文件路径。

另有两个全局用户命令：

- `:PasteImage`：从系统剪贴板读取图片路径或原始图像数据并插入 Markdown 引用。
- `:ConvertImageUnderCursor`：转换光标所在行的图片路径。

`paste_image()` 在当前行为空白时用引用替换该行；当前行已有内容时则在其后插入新行。路径转换入口则只替换图片路径 token，保留行中其他文字。每次成功处理会显示通知；无法找到图片时显示警告，保存失败则显示错误。

## 从粘贴到预览的数据流

```text
系统剪贴板
  ├─ + / * 中的图片文件路径 ──检查扩展名与文件存在性──复制到文档目录/assets
  └─ 原始图像 MIME 数据 ──wl-paste 或 xclip──临时文件──复制到 assets
                                                   │
                                                   ▼
                                   插入 ![](assets/image-时间戳.png)
                                                   │
                                  Markview 呈现 Markdown 结构
                                  Snacks image 解析并显示引用图片
```

这里“自动粘贴到 assets”指图片文件字节被复制进文档旁 `assets/`，Markdown buffer 里插入的是相对链接文本；Neovim 不会把二进制图片内容直接嵌入 `.md` 文件。

## 相关改动的演进

实现可从这些提交追溯：

- `d5e184d`：加入 `markdown_image_paste.lua`、图片归档测试、Markview Markdown 预览及 Snacks 图片配置。
- `e85162b`：增加失效 Wayland socket 检测与重选；增加对 PNG、JPEG、WebP MIME 数据的探测；将剪贴板图片读取改为插入多行安全的缓冲区 API。
- `f856a38`：修复 smart-paste 面对嵌入换行时将多行内容传给 `nvim_buf_set_lines` 的问题，并规范化 CR/LF 行分割。
- `35fbd19`：添加近期 Neovim 配置截图；它不改变上述图片处理流程。

## 回归检查

仓库中的 `tests/markdown_image_paste_spec.lua` 覆盖：

- 存在的 PNG、带引号路径和 `file://` 路径识别，以及不存在路径/普通文字拒绝。
- `assets/image-*.png` 的生成及拷贝后文件存在且非空。
- 从寄存器路径粘贴后生成 Markdown 图片语法（包括末尾换行）。
- 当前行图片路径转换和一段文本中多张图片路径同时转换。
- 不从 unnamed register `"` 读取旧图片路径。

运行：

```sh
nvim --headless -u NONE -l tests/markdown_image_paste_spec.lua
```

此 spec 测试路径处理及归档/链接逻辑；它不模拟实际 Wayland/X11 桌面剪贴板，也不证明当前终端图形协议能显示图像。Markview 的 Markdown 渲染和 Snacks image 的实际图片显示应在目标 Neovim UI 与终端环境中分别观察。
