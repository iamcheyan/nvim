-- Window-local native Delek colorscheme application for Markdown windows.
-- The global Blue colorscheme and all non-Markdown windows/controls remain unchanged.
local M = {}

local delek = require("config.delek_palette")

local palette = {
  paper = "#ffffff",
  ink = "#000000",
  cursor = "#000000",
  cursor_fg = "#ffffff",
  cursor_line = "#e4e4e4",
  visual = "#d0d0d0",
  line_nr = "#a52a2a",
  blue = "#0000ff",
  dark_blue = "#00008b",
  cyan = "#008b8b",
  magenta = "#cd00cd",
  blue_dark = "#cd00cd", -- delek Title / H1 alias
  pink = "#ff1493",
  green = "#00cd00",
  dark_green = "#008700",
  red = "#ee0000",
  slate = "#6a5acd",
  border = "#bcbcbc",
  code_bg = "#f4f4f4",
  code_fg = "#000000",
  inline_bg = "#e8e8e8",
}

-- Target groups for winhighlight compatibility
local window_groups = {
  Normal = delek["Normal"] or { fg = 0, bg = 16777215, ctermfg = 16, ctermbg = 231 },
  NormalNC = delek["Normal"] or { fg = 0, bg = 16777215, ctermfg = 16, ctermbg = 231 },
  Cursor = delek["Cursor"] or { fg = 16777215, bg = 0, ctermfg = 231, ctermbg = 16 },
  lCursor = delek["lCursor"] or { fg = 0, bg = 52480, ctermfg = 16, ctermbg = 40 },
  CursorLine = delek["CursorLine"] or { bg = 15000804, ctermbg = 254 },
  CursorLineNr = delek["CursorLineNr"] or { fg = 10824234, bold = true, ctermfg = 124 },
  LineNr = delek["LineNr"] or { fg = 10824234, ctermfg = 124 },
  SignColumn = { fg = 35723, bg = 16777215, ctermfg = 30, ctermbg = 231 },
  FoldColumn = delek["FoldColumn"] or { fg = 18, bg = 16777215 },
  Folded = delek["Folded"] or { fg = 18, bg = 15000804, ctermfg = 18, ctermbg = 254 },
  Visual = delek["Visual"] or { fg = 0, bg = 13684944, ctermfg = 16, ctermbg = 252 },
  Search = delek["Search"] or { fg = 16777215, bg = 13435085, ctermfg = 231, ctermbg = 164 },
  IncSearch = delek["IncSearch"] or { fg = 52480, reverse = true, ctermfg = 40 },
  MatchParen = delek["MatchParen"] or { fg = 16777215, bg = 16716947, bold = true },
  EndOfBuffer = { fg = 16777215, bg = 16777215, ctermfg = 231, ctermbg = 231 },
  WinSeparator = { fg = 12369084, bg = 16777215 },
  StatusLine = { fg = 0, bg = 15000804 },
  StatusLineNC = { fg = 12369084, bg = 16777215 },
  CursorColumn = delek["CursorColumn"] or { bg = 15000804, ctermbg = 254 },
  WinBar = delek["WinBar"] or { fg = 0, bg = 16777215, bold = true },
  WinBarNC = delek["WinBarNC"] or { fg = 8947848, bg = 16777215, bold = true },
  ContextlineText = delek["WinBar"] or { fg = 0, bg = 16777215 },
  ContextlineActiveMenu = delek["WinBar"] or { fg = 0, bg = 16777215, bold = true },
  ContextlineErrorBadge = { fg = 13382451, bg = 16777215, bold = true },
  ContextlineWarningBadge = { fg = 13408512, bg = 16777215, bold = true },
  SnacksStatusColumnMark = { fg = 34560, bg = 16777215 },
  SnacksStatusColumnSign = { fg = 35723, bg = 16777215 },
  MdTypographyNormal = delek["Normal"] or { fg = 0, bg = 16777215, ctermfg = 16, ctermbg = 231 },
  MdTypographyNormalNC = delek["Normal"] or { fg = 0, bg = 16777215, ctermfg = 16, ctermbg = 231 },
  MdTypographyCursor = delek["Cursor"] or { fg = 16777215, bg = 0, ctermfg = 231, ctermbg = 16 },
  MdTypographyCursorLine = delek["CursorLine"] or { bg = 15000804, ctermbg = 254 },
  MdTypographyCursorLineNr = delek["CursorLineNr"] or { fg = 10824234, bold = true, ctermfg = 124 },
  MdTypographyCursorColumn = delek["CursorColumn"] or { bg = 15000804, ctermbg = 254 },
  MdTypographyLineNr = delek["LineNr"] or { fg = 10824234, ctermfg = 124 },
  MdTypographySignColumn = { fg = 35723, bg = 16777215, ctermfg = 30, ctermbg = 231 },
  MdTypographyFoldColumn = delek["FoldColumn"] or { fg = 18, bg = 16777215 },
  MdTypographyColorColumn = { fg = 0, bg = 15000804, ctermfg = 16, ctermbg = 254 },
  MdTypographyEndOfBuffer = { fg = 16777215, bg = 16777215, ctermfg = 231, ctermbg = 231 },
  MdTypographyWinSeparator = { fg = 12369084, bg = 16777215 },
  MdTypographyStatusLine = { fg = 0, bg = 15000804 },
  MdTypographyStatusLineNC = { fg = 12369084, bg = 16777215 },
  MdTypographyWinBar = delek["WinBar"] or { fg = 0, bg = 16777215, bold = true },
  MdTypographyWinBarNC = delek["WinBarNC"] or { fg = 8947848, bg = 16777215, bold = true },
  MdTypographyContextlineText = delek["WinBar"] or { fg = 0, bg = 16777215 },
  MdTypographyContextlineActiveMenu = delek["WinBar"] or { fg = 0, bg = 16777215, bold = true },
  MdTypographyContextlineErrorBadge = { fg = 13382451, bg = 16777215, bold = true },
  MdTypographyContextlineWarningBadge = { fg = 13408512, bg = 16777215, bold = true },
  MdTypographyVisual = delek["Visual"] or { fg = 0, bg = 13684944, ctermfg = 16, ctermbg = 252 },
}

-- Markview styling harmonized with delek clean paper
local markview_overrides = {
  MarkviewHeading1 = { fg = palette.magenta, bg = palette.paper, bold = true },
  MarkviewHeading2 = { fg = palette.blue, bg = palette.paper, bold = true },
  MarkviewHeading3 = { fg = palette.cyan, bg = palette.paper, bold = true },
  MarkviewHeading4 = { fg = palette.pink, bg = palette.paper, bold = true },
  MarkviewHeading5 = { fg = palette.dark_green, bg = palette.paper, bold = true },
  MarkviewHeading6 = { fg = palette.line_nr, bg = palette.paper, bold = true, italic = true },
  MarkviewHeading1Sign = { fg = palette.magenta, bg = palette.paper },
  MarkviewHeading2Sign = { fg = palette.blue, bg = palette.paper },
  MarkviewHeading3Sign = { fg = palette.cyan, bg = palette.paper },
  MarkviewHeading4Sign = { fg = palette.pink, bg = palette.paper },
  MarkviewHeading5Sign = { fg = palette.dark_green, bg = palette.paper },
  MarkviewHeading6Sign = { fg = palette.line_nr, bg = palette.paper },
  MarkviewCode = { fg = palette.code_fg, bg = palette.code_bg },
  MarkviewCodeFg = { fg = palette.code_fg, bg = palette.code_bg },
  MarkviewCodeInfo = { fg = palette.cyan, bg = palette.code_bg },
  MarkviewInlineCode = { fg = palette.dark_green, bg = palette.inline_bg },
  MarkviewTableHeader = { fg = palette.blue, bg = palette.cursor_line, bold = true },
}

local original_treesitter_groups
local palette_active = false

local function resolve_window_groups()
  local resolved = vim.deepcopy(window_groups)
  local winbar = vim.api.nvim_get_hl(0, { name = "WinBar", link = false })
  local winbar_nc = vim.api.nvim_get_hl(0, { name = "WinBarNC", link = false })
  if not winbar.bg then winbar = vim.deepcopy(delek["WinBar"] or window_groups.WinBar) end
  if not winbar_nc.bg then winbar_nc = vim.deepcopy(delek["WinBarNC"] or window_groups.WinBarNC) end

  resolved.WinBar = vim.deepcopy(winbar)
  resolved.WinBarNC = vim.deepcopy(winbar_nc)
  resolved.ContextlineText = vim.deepcopy(winbar)
  resolved.ContextlineActiveMenu = vim.deepcopy(winbar)
  resolved.MdTypographyWinBar = vim.deepcopy(winbar)
  resolved.MdTypographyWinBarNC = vim.deepcopy(winbar_nc)
  resolved.MdTypographyContextlineText = vim.deepcopy(winbar)
  resolved.MdTypographyContextlineActiveMenu = vim.deepcopy(winbar)
  for _, name in ipairs({ "ContextlineErrorBadge", "ContextlineWarningBadge" }) do
    resolved[name].bg = winbar.bg
    resolved["MdTypography" .. name].bg = winbar.bg
  end
  return resolved
end

local function register_global_aliases(groups)
  for name, spec in pairs(groups) do
    if name:find("^MdTypography") then
      vim.api.nvim_set_hl(0, name, spec)
    end
  end
end

local function apply_namespace(win)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  local groups = resolve_window_groups()
  register_global_aliases(groups)
  local ns = vim.api.nvim_create_namespace("MarkdownTypographyDelek:" .. tostring(win))
  -- Apply all native delek highlight groups into the window-local namespace
  for name, spec in pairs(delek) do
    vim.api.nvim_set_hl(ns, name, spec)
  end
  -- Apply window-local surface overrides
  for name, spec in pairs(groups) do
    vim.api.nvim_set_hl(ns, name, spec)
  end
  -- Apply Markview paper-background overrides
  for name, spec in pairs(markview_overrides) do
    vim.api.nvim_set_hl(ns, name, spec)
  end
  vim.api.nvim_win_set_hl_ns(win, ns)
end

local function is_markdown(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "markdown"
end

local function snapshot_treesitter_groups()
  local snapshot = {}
  local keys = {
    "@markup.heading.1",
    "@markup.raw.block",
    "@markup.raw.inline",
  }
  for _, name in ipairs(keys) do
    local ok, spec = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    snapshot[name] = ok and vim.deepcopy(spec) or {}
  end
  return snapshot
end

local function apply_treesitter_groups()
  vim.api.nvim_set_hl(0, "@markup.heading.1", { fg = palette.magenta, bold = true })
  vim.api.nvim_set_hl(0, "@markup.raw.block", { fg = palette.code_fg, bg = palette.code_bg })
  vim.api.nvim_set_hl(0, "@markup.raw.inline", { fg = palette.dark_green, bg = palette.inline_bg })
end

local function apply_to_markdown_windows(buf)
  if not palette_active then
    original_treesitter_groups = snapshot_treesitter_groups()
    palette_active = true
  end
  apply_treesitter_groups()
  if vim.api.nvim_buf_is_valid(buf) then
    vim.b[buf].snacks_statuscolumn_left = false
  end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.api.nvim_win_is_valid(win) then
      apply_namespace(win)
      -- Markdown windows drop the vertical cursor guide; the horizontal
      -- cursorline stays. cursorcolumn is global-local and nvim_win_set_buf
      -- resets it, so the override is re-asserted by the autocmds in
      -- M.setup() rather than set once here.
      vim.wo[win].winhighlight = table.concat({
        "Normal:MdTypographyNormal",
        "NormalNC:MdTypographyNormalNC",
        "Cursor:MdTypographyCursor",
        "CursorLine:MdTypographyCursorLine",
        "CursorLineNr:MdTypographyCursorLineNr",
        "CursorColumn:MdTypographyCursorColumn",
        "LineNr:MdTypographyLineNr",
        "SignColumn:MdTypographySignColumn",
        "FoldColumn:MdTypographyFoldColumn",
        "ColorColumn:MdTypographyColorColumn",
        "EndOfBuffer:MdTypographyEndOfBuffer",
        "WinSeparator:MdTypographyWinSeparator",
        "StatusLine:MdTypographyStatusLine",
        "StatusLineNC:MdTypographyStatusLineNC",
        "WinBar:MdTypographyWinBar",
        "WinBarNC:MdTypographyWinBarNC",
        "ContextlineText:MdTypographyContextlineText",
        "ContextlineActiveMenu:MdTypographyContextlineActiveMenu",
        "ContextlineErrorBadge:MdTypographyContextlineErrorBadge",
        "ContextlineWarningBadge:MdTypographyContextlineWarningBadge",
        "Visual:MdTypographyVisual",
      }, ",")
    end
  end
end

local function any_markdown_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if is_markdown(vim.api.nvim_win_get_buf(win)) then
      return true
    end
  end
  return false
end

local function restore_treesitter()
  if palette_active and not any_markdown_window() then
    for name, spec in pairs(original_treesitter_groups or {}) do
      vim.api.nvim_set_hl(0, name, spec)
    end
    palette_active = false
    original_treesitter_groups = nil
  end
end

local saved_cursorcolumn = {}

local function restore_window(win)
  if not vim.api.nvim_win_is_valid(win) or is_markdown(vim.api.nvim_win_get_buf(win)) then
    return
  end
  local prev = saved_cursorcolumn[win]
  if prev == nil then
    prev = vim.o.cursorcolumn
  end
  saved_cursorcolumn[win] = nil
  vim.api.nvim_set_option_value("cursorcolumn", prev, { scope = "local", win = win })
  vim.api.nvim_win_set_hl_ns(win, 0)
  vim.wo[win].winhighlight = ""
  restore_treesitter()
  vim.schedule(restore_treesitter)
end

function M.palette()
  return palette
end

function M.refresh()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and is_markdown(vim.api.nvim_win_get_buf(win)) then
      apply_namespace(win)
    end
  end
end

local function apply_markview_palette()
  if not package.loaded["markview.highlights"] then
    return
  end
  local groups = require("markview.highlights").groups
  local colors = {
    palette.border,     -- 0
    palette.magenta,    -- 1 (delek Title)
    palette.blue,       -- 2 (delek Statement)
    palette.cyan,       -- 3 (delek Identifier)
    palette.pink,       -- 4 (delek Special)
    palette.dark_green, -- 5 (delek Constant)
    palette.line_nr,    -- 6 (delek LineNr)
  }
  for level = 0, 6 do
    local n = level
    local color = colors[level + 1]
    groups[tostring(level)] = function()
      return {
        { group_name = string.format("MarkviewPalette%d", n), value = { fg = color, bg = palette.paper } },
        { group_name = string.format("MarkviewPalette%dSign", n), value = { fg = color, bg = palette.paper } },
        { group_name = string.format("MarkviewPalette%dFg", n), value = { fg = color } },
        { group_name = string.format("MarkviewPalette%dBg", n), value = { bg = palette.paper } },
      }
    end
  end
  for level = 0, 6 do
    for _, suffix in ipairs({ "", "Sign", "Fg", "Bg" }) do
      vim.api.nvim_set_hl(0, string.format("MarkviewPalette%d%s", level, suffix), {})
    end
  end
  require("markview.highlights").setup()
  for name, spec in pairs(markview_overrides) do
    vim.api.nvim_set_hl(0, name, spec)
  end
end

function M.setup()
  if M._ready then
    if vim.bo.filetype == "markdown" then
      apply_to_markdown_windows(vim.api.nvim_get_current_buf())
    end
    return
  end
  M._ready = true
  local group = vim.api.nvim_create_augroup("MarkdownTypographyBlue", { clear = true })
  local colorscheme_group = vim.api.nvim_create_augroup("MarkdownTypographyBlueMarkview", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = colorscheme_group,
    callback = function()
      if (vim.g.colors_name or ""):lower() == "blue" then
        apply_markview_palette()
      end
    end,
  })
  local current_ns = vim.api.nvim_get_hl_ns({ winid = vim.api.nvim_get_current_win() })
  if current_ns <= 0 then
    original_treesitter_groups = snapshot_treesitter_groups()
    palette_active = false
  else
    palette_active = true
  end
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "markdown",
    callback = function(args)
      apply_to_markdown_windows(args.buf)
    end,
  })
  -- cursorcolumn is window-local but global-initialized, and entering a buffer
  -- resets it. Re-assert "off" for Markdown windows on every entry so the
  -- vertical cursor guide stays hidden there without touching other windows.
  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "FileType" }, {
    group = group,
    callback = function()
      local win = vim.api.nvim_get_current_win()
      if not vim.api.nvim_win_is_valid(win) then
        return
      end
      if is_markdown(vim.api.nvim_win_get_buf(win)) then
        if saved_cursorcolumn[win] == nil then
          saved_cursorcolumn[win] = vim.wo[win].cursorcolumn
        end
        vim.api.nvim_set_option_value("cursorcolumn", false, { scope = "local", win = win })
      end
    end,
  })
  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
    group = group,
    callback = function(args)
      local win = vim.api.nvim_get_current_win()
      local buf = (vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win)) or args.buf
      if is_markdown(buf) then
        apply_to_markdown_windows(buf)
      else
        restore_window(win)
      end
    end,
  })
  vim.api.nvim_create_autocmd({ "BufWinLeave", "WinClosed" }, {
    group = group,
    callback = function(args)
      local buf = args.buf or vim.api.nvim_get_current_buf()
      local win = vim.api.nvim_get_current_win()
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) ~= buf then
          restore_window(win)
        else
          for _, candidate in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_is_valid(candidate) and vim.api.nvim_win_get_buf(candidate) ~= buf then
              restore_window(candidate)
            end
          end
        end
      end)
    end,
  })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      local markdown_open = false
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if is_markdown(vim.api.nvim_win_get_buf(win)) then
          markdown_open = true
          break
        end
      end
      if vim.bo.filetype == "markdown" then
        apply_markview_palette()
      end
      if markdown_open then
        palette_active = false
        original_treesitter_groups = nil
        vim.schedule(function()
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            if is_markdown(buf) then
              apply_to_markdown_windows(buf)
            end
          end
        end)
      end
    end,
  })
  if vim.bo.filetype == "markdown" then
    apply_to_markdown_windows(vim.api.nvim_get_current_buf())
  end
end

return M
