-- Local Blue-coordinated reading palette for Markdown windows only.
-- Global Blue and all non-Markdown buffers retain their existing highlights.
local M = {}

local palette = {
  paper = "#faf9f5",
  ink = "#303030",
  muted = "#686b78",
  blue = "#005faf", -- Blue's active cursor-line accent
  blue_dark = "#000087", -- Blue's background identity, used sparingly
  cyan = "#008787", -- Blue's sign/border accent
  violet = "#805080",
  rule = "#d8d6cf",
  code_bg = "#202536",
  code_fg = "#e4e7ed",
  inline_bg = "#ebe8df",
  red = "#a43f45",
  green = "#477356",
}

local window_groups = {
  MdTypographyNormal = { fg = palette.ink, bg = palette.paper },
  MdTypographyNormalNC = { fg = palette.ink, bg = palette.paper },
  MdTypographySignColumn = { fg = palette.cyan, bg = palette.paper },
  MdTypographyFoldColumn = { fg = palette.cyan, bg = palette.paper },
  MdTypographyLineNr = { fg = palette.muted, bg = palette.paper },
  MdTypographyCursorLineNr = { fg = palette.blue, bg = palette.paper, bold = true },
  MdTypographyCursorLine = { bg = "#eeece5" },
  MdTypographyColorColumn = { bg = "#f1efe8" },
  MdTypographyEndOfBuffer = { fg = palette.paper, bg = palette.paper },
  MdTypographyWinSeparator = { fg = palette.rule, bg = palette.paper },
  MdTypographyStatusLine = { fg = palette.ink, bg = "#eeece5" },
  MdTypographyStatusLineNC = { fg = palette.muted, bg = palette.paper },
}

local syntax_groups = {
  markdownH1 = { fg = palette.blue_dark, bold = true },
  markdownH2 = { fg = palette.blue, bold = true },
  markdownH3 = { fg = palette.violet, bold = true },
  markdownH4 = { fg = palette.ink, bold = true },
  markdownH5 = { fg = palette.ink, italic = true },
  markdownH6 = { fg = palette.muted, italic = true },
  markdownCode = { fg = palette.code_fg, bg = palette.code_bg },
  markdownCodeBlock = { fg = palette.code_fg, bg = palette.code_bg },
  markdownCodeDelimiter = { fg = palette.cyan, bg = palette.code_bg },
  markdownBlockquote = { fg = palette.muted, italic = true },
  markdownBlockquoteDelimiter = { fg = palette.cyan, bold = true },
  markdownListMarker = { fg = palette.cyan, bold = true },
  markdownUrl = { fg = palette.cyan, underline = true },
  markdownLinkText = { fg = palette.blue, underline = true },
  markdownBold = { fg = palette.ink, bold = true },
  markdownItalic = { fg = palette.ink, italic = true },
  markdownStrike = { fg = palette.muted, strikethrough = true },
  markdownRule = { fg = palette.rule },
  markdownTable = { fg = palette.ink },
  markdownTableDelimiter = { fg = palette.rule },
  MarkviewHeading1 = { fg = palette.blue_dark, bold = true },
  MarkviewHeading2 = { fg = palette.blue, bold = true },
  MarkviewHeading3 = { fg = palette.violet, bold = true },
  MarkviewHeading1Sign = { fg = palette.cyan },
  MarkviewHeading2Sign = { fg = palette.cyan },
  MarkviewHeading3Sign = { fg = palette.violet },
  MarkviewHeading4Sign = { fg = palette.ink },
  MarkviewHeading5Sign = { fg = palette.muted },
  MarkviewHeading6Sign = { fg = palette.muted },
  MarkviewCodeFg = { fg = palette.code_fg },
  MarkviewCodeInfo = { fg = palette.cyan, bg = palette.code_bg },
  MarkviewInlineCode = { fg = palette.red, bg = palette.inline_bg },
  MarkviewCode = { fg = palette.code_fg, bg = palette.code_bg },
  MarkviewQuote = { fg = palette.muted, italic = true },
  MarkviewListItemMinus = { fg = palette.cyan, bold = true },
  MarkviewListItemPlus = { fg = palette.green, bold = true },
  MarkviewListItemStar = { fg = palette.cyan, bold = true },
  MarkviewCheckboxChecked = { fg = palette.green, bold = true },
  MarkviewCheckboxUnchecked = { fg = palette.cyan },
  MarkviewCheckboxPending = { fg = palette.blue, bold = true },
  MarkviewCheckboxProgress = { fg = palette.blue, bold = true },
  MarkviewCheckboxCancelled = { fg = palette.muted, strikethrough = true },
  MarkviewCheckboxStriked = { fg = palette.muted, strikethrough = true },
  MarkviewBlockQuoteDefault = { fg = palette.muted, italic = true },
  MarkviewBlockQuoteNote = { fg = palette.blue, italic = true },
  MarkviewBlockQuoteOk = { fg = palette.green, italic = true },
  MarkviewBlockQuoteWarn = { fg = palette.violet, italic = true },
  MarkviewBlockQuoteError = { fg = palette.red, italic = true },
  MarkviewBlockQuoteSpecial = { fg = palette.cyan, italic = true },
  MarkviewTableHeader = { fg = palette.blue_dark, bg = "#eeece5", bold = true },
  MarkviewTableBorder = { fg = palette.rule },
  MarkviewTableAlignLeft = { fg = palette.blue },
  MarkviewTableAlignRight = { fg = palette.blue },
  MarkviewTableAlignCenter = { fg = palette.blue },
}

local markview_overrides = {
  MarkviewHeading1 = { fg = palette.blue_dark, bg = palette.paper, bold = true },
  MarkviewHeading2 = { fg = palette.blue, bg = palette.paper, bold = true },
  MarkviewHeading3 = { fg = palette.violet, bg = palette.paper, bold = true },
  MarkviewHeading4 = { fg = palette.ink, bg = palette.paper, bold = true },
  MarkviewHeading5 = { fg = palette.ink, bg = palette.paper, italic = true },
  MarkviewHeading6 = { fg = palette.muted, bg = palette.paper, italic = true },
  MarkviewHeading1Sign = { fg = palette.cyan, bg = palette.paper },
  MarkviewHeading2Sign = { fg = palette.cyan, bg = palette.paper },
  MarkviewHeading3Sign = { fg = palette.violet, bg = palette.paper },
  MarkviewHeading4Sign = { fg = palette.ink, bg = palette.paper },
  MarkviewHeading5Sign = { fg = palette.muted, bg = palette.paper },
  MarkviewHeading6Sign = { fg = palette.muted, bg = palette.paper },
  MarkviewCode = { fg = palette.code_fg, bg = palette.code_bg },
  MarkviewCodeFg = { fg = palette.code_fg, bg = palette.code_bg },
  MarkviewCodeInfo = { fg = palette.cyan, bg = palette.code_bg },
  MarkviewInlineCode = { fg = palette.red, bg = palette.inline_bg },
  MarkviewTableHeader = { fg = palette.blue_dark, bg = "#eeece5", bold = true },
}

local treesitter_groups = {
  ["@markup.heading"] = { fg = palette.blue, bold = true },
  ["@markup.heading.1"] = { fg = palette.blue_dark, bold = true },
  ["@markup.heading.2"] = { fg = palette.blue, bold = true },
  ["@markup.heading.3"] = { fg = palette.violet, bold = true },
  ["@markup.heading.4"] = { fg = palette.ink, bold = true },
  ["@markup.heading.5"] = { fg = palette.ink, italic = true },
  ["@markup.heading.6"] = { fg = palette.muted, italic = true },
  ["@markup.heading.1.marker"] = { fg = palette.cyan, bold = true },
  ["@markup.heading.2.marker"] = { fg = palette.cyan },
  ["@markup.heading.3.marker"] = { fg = palette.violet },
  ["@markup.heading.marker"] = { fg = palette.cyan },
  ["@markup.strong"] = { fg = palette.ink, bold = true },
  ["@markup.italic"] = { fg = palette.ink, italic = true },
  ["@markup.strikethrough"] = { fg = palette.muted, strikethrough = true },
  ["@markup.link"] = { fg = palette.blue, underline = true },
  ["@markup.link.url"] = { fg = palette.cyan, underline = true },
  ["@markup.link.label"] = { fg = palette.blue, underline = true },
  ["@markup.list"] = { fg = palette.cyan, bold = true },
  ["@markup.list.checked"] = { fg = palette.green, bold = true },
  ["@markup.list.unchecked"] = { fg = palette.cyan },
  ["@markup.quote"] = { fg = palette.muted, italic = true },
  ["@markup.quote.marker"] = { fg = palette.cyan, bold = true },
  ["@markup.raw"] = { fg = palette.red, bg = palette.inline_bg },
  ["@markup.raw.block"] = { fg = palette.code_fg, bg = palette.code_bg },
  ["@markup.raw.inline"] = { fg = palette.red, bg = palette.inline_bg },
  ["@markup.math"] = { fg = palette.violet },
}

local original_treesitter_groups
local palette_active = false

local function set_highlights(ns, source)
  for name, spec in pairs(source) do
    vim.api.nvim_set_hl(ns, name, spec)
  end
end

local function apply_namespace(win)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  local ns = vim.api.nvim_create_namespace("MarkdownTypographyBlue:" .. tostring(win))
  set_highlights(ns, window_groups)
  set_highlights(ns, syntax_groups)
  vim.api.nvim_win_set_hl_ns(win, ns)
end

local function is_markdown(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "markdown"
end

local function snapshot_treesitter_groups()
  local snapshot = {}
  for name in pairs(treesitter_groups) do
    local ok, spec = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    snapshot[name] = ok and vim.deepcopy(spec) or {}
  end
  return snapshot
end

local function apply_treesitter_groups()
  for name, spec in pairs(treesitter_groups) do
    vim.api.nvim_set_hl(0, name, spec)
  end
end

local function apply_to_markdown_windows(buf)
  if not palette_active then
    original_treesitter_groups = snapshot_treesitter_groups()
    palette_active = true
  end
  apply_treesitter_groups()
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.api.nvim_win_is_valid(win) then
      apply_namespace(win)
      vim.wo[win].winhighlight = table.concat({
        "Normal:MdTypographyNormal",
        "NormalNC:MdTypographyNormalNC",
        "SignColumn:MdTypographySignColumn",
        "FoldColumn:MdTypographyFoldColumn",
        "LineNr:MdTypographyLineNr",
        "CursorLineNr:MdTypographyCursorLineNr",
        "CursorLine:MdTypographyCursorLine",
        "ColorColumn:MdTypographyColorColumn",
        "EndOfBuffer:MdTypographyEndOfBuffer",
        "WinSeparator:MdTypographyWinSeparator",
        "StatusLine:MdTypographyStatusLine",
        "StatusLineNC:MdTypographyStatusLineNC",
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

local function restore_window(win)
  if not vim.api.nvim_win_is_valid(win) or is_markdown(vim.api.nvim_win_get_buf(win)) then
    return
  end
  vim.api.nvim_win_set_hl_ns(win, 0)
  vim.wo[win].winhighlight = ""
  if palette_active and not any_markdown_window() then
    vim.schedule(function()
      if any_markdown_window() then
        return
      end
      for name, spec in pairs(original_treesitter_groups or {}) do
        vim.api.nvim_set_hl(0, name, spec)
      end
      palette_active = false
      original_treesitter_groups = nil
    end)
  end
end

function M.palette()
  return palette
end

local function apply_markview_palette()
  if not package.loaded["markview.highlights"] then
    return
  end
  local groups = require("markview.highlights").groups
  local colors = {
    "#686b78",
    palette.blue_dark,
    palette.blue,
    palette.violet,
    palette.green,
    palette.cyan,
    palette.red,
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
  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
    group = group,
    callback = function(args)
      local buf = args.buf > 0 and args.buf or vim.api.nvim_get_current_buf()
      if is_markdown(buf) then
        apply_to_markdown_windows(buf)
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
        apply_global_markdown_surface()
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
