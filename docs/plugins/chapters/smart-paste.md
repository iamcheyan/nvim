# smart-paste.nvim

> 私有插件 · [回到插件目录](../PLUGINS.md) · 相关配置：[`lua/plugins/smart-paste.lua`](../../../lua/plugins/smart-paste.lua)

---

## 它解决什么问题

从网页文档、代码审查工具或其他编辑器复制一段代码粘贴进 Neovim，传统的粘贴体验往往伴随着诸多痛点：

1. **缩进错乱地狱**：
   - 复制的代码可能顶格（第 0 列），粘贴进深层函数时需要一行行手动补充缩进；
   - 复制的代码可能带着外层 8 个空格，粘贴到浅层块时缩进又过深；
   - 粗暴的自动缩进（如 `gg=G` 或只对齐首行）会破坏代码块内部精细的相对层级（例如字典、嵌套循环、链式调用）。
2. **多余空行与孤儿空行（Stray Blank Lines）**：
   - 剪贴板工具（如 Linux Wayland 下的 `wl-copy`）向行式寄存器传递数据时末尾经常携带换行，粘贴时导致下方多空出一行；
   - 在一个刚用 `o` 开出的空行或代码块占位行上按 `p`，传统行级粘贴会在上下插入新行，从而把原本的空白行留作孤儿空行；
   - 在只有一行的文件上 `dd` 剪切后按 `p`，产生莫名其妙的空行错位。
3. **输入路径割裂**：
   - 很多配置中，键盘快捷键（如 `<C-v>`）做了智能处理，但日常高频的 `p` / `P` 以及终端鼠标粘贴（Bracketed Paste）走的又是另一套逻辑，行为极不一致。

`smart-paste.nvim` 提供了一套**全入口统一、保持块内相对层级、感知代码语法作用域、且彻底消灭多余空行**的现代化智能粘贴解决方案。

---

## 按键与场景一览

配置将所有粘贴入口在底层收拢至同一套智能引擎：

| 模式 | 按键 | 行为与优势 |
|---|---|---|
| **Normal** | `p` | 在当前行之后智能粘贴（根据语法块/上下文自动平移缩进，支持 `.` 点重复） |
| **Normal** | `P` | 在当前行之前智能粘贴（向前恢复代码，自动对齐目标缩进层级） |
| **Normal** | `<leader>p` | 块级智能粘贴系统剪贴板（与 `p` 逻辑完全同构） |
| **Normal** | `<C-v>` | 现代编辑器惯用的粘贴快捷键（与 `p` 逻辑完全同构） |
| **Visual** | `p` / `P` / `<C-v>` | 用剪贴板内容替换选区并智能重排对齐，保持原剪贴板内容不被覆盖 |
| **Insert** | `<C-v>` | 插入模式智能粘贴（单行原样插入，多行代码按当前光标列自动对齐） |
| **终端直通** | 右键 / `Cmd+V` / 终端粘贴 | 通过 `vim.paste` 全局钩子拦截 Bracketed Paste，同样享受缩进平移 |

---

## 核心架构设计

整个智能粘贴系统由五个核心机制协同构建：

```
                    ┌──────────────────────────────────────────────┐
                    │                   输入来源                   │
                    │  • Normal: p / P / <C-v> / <leader>p         │
                    │  • Visual: p / P / <C-v>                     │
                    │  • Terminal Bracketed Paste (vim.paste)      │
                    └──────────────────────┬───────────────────────┘
                                           │
                                           ▼
                    ┌──────────────────────────────────────────────┐
                    │           1. 数据提取与规范化清洗            │
                    │  • flatten_lines: 统一 CR/LF 换行分割        │
                    │  • strip_trailing_blank_lines: 剥离尾随空行  │
                    │  • 首行前缀还原 (TextYankPost 元数据缓存)    │
                    └──────────────────────┬───────────────────────┘
                                           │
                                           ▼
                    ┌──────────────────────────────────────────────┐
                    │           2. 目标缩进智能解析                │
                    │  • 空白行检测 (current_line:match('^%s*$'))  │
                    │  • 作用域开启/闭合探测 (heuristics.is_scope) │
                    │  • Treesitter / indentexpr / 启发式融合      │
                    └──────────────────────┬───────────────────────┘
                                           │
                                           ▼
                    ┌──────────────────────────────────────────────┐
                    │           3. 相对平移算法 (align)            │
                    │  • 计算源块最小非空缩进: source_indent       │
                    │  • 平移增量: delta = target - source         │
                    │  • 整块等距平移，保留所有内部嵌套层级        │
                    └──────────────────────┬───────────────────────┘
                                           │
                                           ▼
                    ┌──────────────────────────────────────────────┐
                    │           4. 零多余空行落盘输出              │
                    │  • 当前为空白行 ──► nvim_buf_set_lines 替换  │
                    │  • 当前为代码行 ──► nvim_put('l', after) 插入│
                    └──────────────────────────────────────────────┘
```

---

## 关键技术实现深度剖析

### 1. 块内相对缩进平移算法（Block Relative Rebasing）

平移的核心原则是：**不能只看第一行，也不能让所有行缩进变得相同**。

```lua
local function align(lines, target, bufnr)
  lines = vim.deepcopy(lines)

  -- 1. 恢复字符级复制丢失的首行前缀空白（见下节）
  if last_yank and vim.deep_equal(lines, last_yank.lines) then
    lines[1] = last_yank.prefix .. lines[1]
  end

  -- 2. 寻找整块代码的“浅层基准”（Shallowest Nonblank Line）
  -- 外部复制的代码第一行可能处于内层，必须以全块非空行的最小缩进作为 baseline
  local source = math.huge
  for _, line in ipairs(lines) do
    if line:match("%S") then
      source = math.min(source, vim.fn.strdisplaywidth(line:match("^%s*") or ""))
    end
  end
  if source == math.huge then source = 0 end

  -- 3. 全局应用 delta = target - source
  return indent_mod.apply_delta(lines, target - source, bufnr)
end
```

**示例效果**：
源文本（从网页复制代码，外层带 8 格缩进）：
```python
        class Calculator:
            def add(self, a, b):
                return a + b
```
若当前光标位于 4 格缩进的模块内，`source = 8`，`target = 4`，`delta = -4`。平移后：
```python
    class Calculator:
        def add(self, a, b):
            return a + b
```
`class` 准确对齐 4 格，方法准确对齐 8 格，内部 `return` 准确对齐 12 格。

---

### 2. 字符级复制首行前缀补偿（Prefix Recovery）

**痛点**：在 Vim 中使用字符式可视模式（`v`）选中多行代码时，选区通常从第一行的第一个非空字符开始，导致剪贴板中的首行**丢失了行首空白**，但第 2 行以后却保留了完整的原始缩进。如果直接计算，第一行缩进为 0，导致第二行被错误平移到极深的位置。

**解决方案**：
监听 `TextYankPost` 事件，在复制发生的瞬间记录光标起点的行首空白：
```lua
local last_yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("SmartPasteSourceIndent", { clear = true }),
  callback = function()
    local event = vim.v.event
    if event.operator ~= "y" or event.regtype ~= "v" or #event.regcontents < 2 then return end
    local start = vim.api.nvim_buf_get_mark(0, "[")
    local source = vim.api.nvim_buf_get_lines(0, start[1] - 1, start[1], false)[1] or ""
    local prefix = source:sub(1, start[2])
    if prefix:match("^%s*$") then
      last_yank = { lines = vim.deepcopy(event.regcontents), prefix = prefix }
    end
  end,
})
```
粘贴时只要检测到内容与 `last_yank` 匹配，立即将缺失的 `prefix` 补回第一行，再进行等距平移。

---

### 3. 零多余空行机制（Zero-Stray-Line Mechanism）

针对用户痛点“`dd` 之后按 `p` 多出一个空行”，系统实现了两重保障：

#### 保障 A：末尾空换行剥离
```lua
local function strip_trailing_blank_lines(lines)
  if type(lines) ~= "table" then return {} end
  local result = vim.deepcopy(lines)
  while #result > 1 and result[#result] == "" do
    table.remove(result)
  end
  return result
end
```
无论是 Wayland `wl-paste` 返回的 `\n\n` 还是字符分割产生的尾随空串，都会被清洗干净。

#### 保障 B：空白行占位原地替换（In-place Line Replacement）
原生 Vim 的 `nvim_put(..., 'l', after)` 遇到空白行时，只会在上方或下方追加新行，原本的空白行被完整保留。配置改为：**若当前行是空白行，直接原地替换**：
```lua
if current_line:match("^%s*$") then
  -- 原地替换当前空白行，彻底杜绝孤儿空行
  vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, final_lines)
  vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
else
  -- 处于有效代码行时，按 after/before 插入
  vim.api.nvim_put(final_lines, "l", after, false)
end
```

---

### 4. 语法作用域感知与目标缩进解析

在确定要粘贴的目标缩进 `target` 时，系统不仅检测光标所在行，还具备上下文作用域推断能力：

```lua
local function resolve_target_indent(bufnr, row, after, current_line)
  -- 1. 空白行直接使用该行在当前语法树下的标准缩进
  if current_line:match("^%s*$") then
    return indent_mod.get_target_indent(bufnr, row)
  end

  local current_indent = vim.fn.strdisplaywidth(current_line:match("^(%s*)") or "")
  local sw = vim.bo[bufnr].shiftwidth > 0 and vim.bo[bufnr].shiftwidth or vim.bo[bufnr].tabstop

  -- 2. 向下粘贴 (p) 且当前行为作用域开启者（如 if、function、for、while、{）
  if after then
    if heuristics.is_scope_opener(current_line, bufnr) then
      return current_indent + sw
    end
    return current_indent
  end

  -- 3. 向上粘贴 (P) 且当前行为作用域闭合者（如 end、}、elif）
  if not after and heuristics.is_scope_closer(current_line, bufnr) then
    return current_indent + sw
  end

  return current_indent
end
```

---

### 5. 操作符函数与点重复支持（Dot-Repeat via `operatorfunc`）

为了让自定义粘贴像原生 Vim 动作一样支持 `.` 重复，引擎采用了标准表达式映射 + `operatorfunc` 架构：

```lua
local op_state = {}

function _G.__smart_paste_do_op(_motion)
  execute_smart_paste(op_state.reg, op_state.count, op_state.after)
end

local function trigger_smart_paste(after)
  op_state = {
    reg = vim.v.register,
    count = vim.v.count1,
    after = after,
  }
  vim.go.operatorfunc = "v:lua.__smart_paste_do_op"
  return "g@l"
end

vim.keymap.set("n", "p", function() return trigger_smart_paste(true) end, { expr = true, desc = "Smart paste after" })
vim.keymap.set("n", "P", function() return trigger_smart_paste(false) end, { expr = true, desc = "Smart paste before" })
```

---

## 动手验证

在任意 Lua 或 Python 文件中进行以下测试，体验新引擎的平滑度：

1. **外部浏览器代码测试**：
   - 从 GitHub 或网页复制一段无缩进（顶格）的函数；
   - 在一个缩进深达 4 格的函数内部，光标停留在有效代码行上按 `p`；
   - 验证：整段代码自动平移到 4 格缩进，函数体自动缩进到 8 格，与外层结构无缝嵌合。
2. **`dd` 剪切原地恢复测试**：
   - 光标处于任意代码行，按 `dd` 剪切；
   - 立即按大写 `P`；
   - 验证：代码行原样恢复在原位置，**上下绝无任何多余空行**。
3. **空行原地占位测试**：
   - 按 `o` 新开一行空白行并按 `<Esc>` 退出；
   - 直接按 `p` 或 `<C-v>`；
   - 验证：粘贴内容直接替换该空白行，首行严格对齐当前层级，上方不会残留原本按 `o` 留下的空行。
4. **点重复测试**：
   - 在目标位置按 `p` 粘贴，然后移动光标到另一个位置按 `.`；
   - 验证：在新位置再次触发相同内容的智能缩进粘贴。

---

## 常见疑问

### 为什么块可视模式要用 `<C-q>`？
配置将普通模式、插入模式和可视模式的 `<C-v>` 全部统一分配给了智能粘贴。因此，原本 Neovim 的视觉块模式（Visual-Block）转由 `<C-q>` 接管（在大部分终端和 GUI 下均可无冲突直通）。

### 如何完全禁用智能缩进进行字面粘贴？
如果确实需要将某段文字原汁原味、不经过任何缩进对齐地粘入，可使用寄存器显式指定原生操作，或执行：
```vim
:put "
```
或在可视模式下按 `"+P`。
