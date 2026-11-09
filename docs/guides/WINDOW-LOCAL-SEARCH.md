# 分屏独立浏览与窗口级独立搜索

在 Neovim 中，使用分屏（`:vsplit` / `:split`）在左右打开同一个文件是常用的多部位对照手段。但 Vim 原生设计中，搜索高亮与搜索寄存器属于全局共享状态，导致分屏多开同一文件时产生视觉串扰。本配置提供了窗口级的搜索状态隔离与焦点视觉隔离机制。

---

## 痛点与需求

| 原生行为 | 带来的问题 | 本配置行为 |
|---|---|---|
| **全局 `hlsearch`** | 左边搜索关键词 A，右边窗口也会把 A 全部高亮，无法左右分别搜索 A 和 B 进行对照 | **窗口局部高亮**：左边搜 A 全亮 A，右边搜 B 全亮 B，两边同时高亮且互不干扰 |
| **全局 `@/` 寄存器** | 在右边按 `n` / `N` 会受左边最新搜索影响 | **状态自动恢复**：切回左边按 `n` 搜 A，切回右边按 `n` 搜 B |
| **全局 `cursorline`** | 非活动窗口依然显示横向光标行背景，左右两边都在同一行显示粗条 | **焦点感知光标行**：仅当前活动窗口显示光标行，非活动侧自动隐藏 |
| **双边相对行号** | 非活动窗口显示相对当前光标的差值，不易阅读真实行号 | **绝对行号回退**：活动侧显示相对行号（方便跳转），非活动侧显示绝对行号 |

---

## 核心实现原理

实现代码位于 [lua/config/win_search.lua](lua/config/win_search.lua) 与 [lua/config/autocmds.lua](lua/config/autocmds.lua)。

### 1. 窗口级独立高亮（`matchadd` 机制）

- 禁用全局搜索高亮：`vim.opt.hlsearch = false`，阻止 Neovim 底层 C 渲染器跨窗口广播高亮。
- 监听 `CmdlineLeave` 事件：当用户通过 `/` 或 `?` 确认搜索时，通过 Vim 窗口专属的 `matchadd` 接口将高亮挂载到当前窗口句柄：
  ```lua
  vim.fn.matchadd("Search", pattern, 10, -1, { window = win })
  ```
- 由于 `matchadd` 具有严格的窗口作用域（Window Scope），Window 1 仅渲染 Pattern A，Window 2 仅渲染 Pattern B，从而实现了在同一屏幕上**左右并存、互不干扰的高亮对比**。

### 2. 窗口搜索寄存器与底部提示联动（`w:win_search_pattern`）

- 每个窗口在 `vim.w[win].win_search_pattern` 中维护自己专属的检索词。
- 监听 `WinEnter` / `BufEnter` / `FocusGained` 事件：当鼠标点击或光标切换到某个分屏时：
  1. 自动将该窗口记忆的检索词同步回 Neovim 搜索寄存器 `@/`。
  2. 立即重算该窗口当前的匹配数，并自动刷新底部命令行的搜索提示（如 `/node [2/4]`），**无需按 `n` 即可立即跟随焦点自动切换**。
  3. 若进入的窗口未进行过搜索，则自动清空底部搜索提示，避免显示其他窗口的残留关键词。
- 配合 [lua/config/keymaps-defaults.lua](lua/config/keymaps-defaults.lua) 中增强的 `n` / `N` 映射，确保每次跳转前窗口状态均已对齐，实现在不同窗口内按 `n` 独立跳转各自关键词的效果。

### 3. 取词与取消搜索的独立性

- **取消高亮（`<Esc>`）**：在当前窗口按下 <kbd>Esc</kbd> 仅调用 `M.clear(current_win)` 清除当前窗口的高亮，另一侧分屏的高亮完整保留。
- **取词搜索（`*` / `#` / `g*` / `g#`）**：在 [lua/plugins/dev-visual.lua](lua/plugins/dev-visual.lua) 中拦截对应按键，取词后同样通过 `M.set` 仅挂载到当前活跃窗口。
- **重绘与清空（`<leader>ur`）**：同步清理当前窗口的局部高亮标记。

### 4. 焦点感知的光标行与行号管理

在 [lua/config/autocmds.lua](lua/config/autocmds.lua) 中设置自动命令组 `SplitWindowFocus`：
- **活动窗口（`WinEnter`, `BufEnter`, `FocusGained`）**：
  - `cursorline = true`
  - 若启用了行号，则 `relativenumber = true`（便于进行 `5j`、`12k` 等相对跳行）。
- **非活动窗口（`WinLeave`, `BufLeave`, `FocusLost`）**：
  - `cursorline = false`（消除背景横线杂色）。
  - 若启用了行号，则 `relativenumber = false`（还原为常规绝对行号 `1, 2, 3...`，便于对照行数）。
- 过滤浮窗（`config.relative ~= ""`）与专用面板（`neo-tree`），不干扰辅助界面的自有样式。

### 5. 分屏极致紧凑贴合与留白消除

在保留每个窗口顶栏 Dropbar 面包屑导航的前提下，清除了所有多余的占位与空白缝隙：
- **消除中缝空白断层**：在 [lua/config/ui_highlights.lua](lua/config/ui_highlights.lua) 中修复 `WinSeparator` 与 `VertSplit` 的色彩设置，消除原本将前景色和背景色设为一致所产生的 1 列/1 行“虚空盲区”，呈现轻盈纤细的单像素物理分割线。
- **左右分屏直接贴合**：去除 `statuscolumn` 在行号左侧强行占位的空白 padding 并将 `foldcolumn` 设为 `0`，行号直接紧挨垂直中缝 `│` 展开，左右代码紧凑贴合。
- **上下分屏直接贴合**：上下两块代码区域通过精细单像素分界线 `─` 与下方分屏的面包屑顶栏直接无缝相接，不再有任何多余的空行。

### 6. 分屏分割线鼠标拖拽调整尺寸（[lua/config/split_mouse_drag.lua](lua/config/split_mouse_drag.lua)）

- **解除滚动条对分割线的误拦截**：在 [lua/config/scrollbar_scroll.lua](lua/config/scrollbar_scroll.lua) 中，原本使用 `mp.wincol >= width` 判断滚动条悬停，导致点击右侧外沿的垂直分割线 `│`（`mp.wincol == width + 1`, `mp.line == 0`）时被误判为点击左侧窗口滚动条并吞掉 `<LeftMouse>` / `<LeftDrag>` 事件。现已修正为严格匹配窗口内部滚动条列（`mp.wincol == width and mp.line > 0`），并在横向拖拽时自动让渡给分屏拖拽逻辑。
- **支持宽容边缘热区与双向拖拽**：新增 [lua/config/split_mouse_drag.lua](lua/config/split_mouse_drag.lua)，不仅支持直接按住 `│` 左右拖拽、按住 `─` 上下拖拽，还支持在分割线相邻 1 格边缘（左侧滚动条列或右侧首列行号、下方顶栏）按住并向垂直于分割线方向拖动时自动触发尺寸调整，完美兼容 Kitty + SSH + Tmux 环境与 `laststatus = 3`。

---

## 典型操作演示

1. 使用 `:vsplit` 将当前文件在左右两侧打开。
2. 在左侧分屏输入 `/foo<CR>`：
   - 左侧所有 `foo` 均被高亮。
   - 右侧分屏保持原本代码色彩，不会被高亮干扰。
3. 按 <kbd>Ctrl-w</kbd> <kbd>l</kbd> 切换到右侧分屏，输入 `/bar<CR>`：
   - 右侧所有 `bar` 被高亮。
   - 左侧所有 `foo` **依然保持高亮**！此时屏幕上可以直观比对 `foo` 与 `bar` 的分布与用法。
4. 在右侧按 <kbd>n</kbd>：仅在右侧窗口跳转下一个 `bar`。
5. 按 <kbd>Ctrl-w</kbd> <kbd>h</kbd> 切回左侧按 <kbd>n</kbd>：仅在左侧窗口跳转下一个 `foo`。
6. 在左侧按 <kbd>Esc</kbd>：清除左侧的 `foo` 高亮；右侧的 `bar` 高亮继续保留。

---

## 回归测试

相关行为由自动化测试保障：
- [tests/split_window_focus_spec.lua](tests/split_window_focus_spec.lua)：测试分屏间 `apple` 与 `banana` 的并行独立高亮、寄存器恢复、光标独立跳行及单独清除。
- 运行测试：
  ```bash
  nvim --headless -u NONE -c "lua dofile('tests/split_window_focus_spec.lua')" -c "qa!"
  ```
