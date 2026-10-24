local function picker_flag_title(picker)
  local hidden = picker.opts.hidden and "ON" or "OFF"
  local ignored = picker.opts.ignored and "ON" or "OFF"
  local function state(value)
    return value == "ON" and "SnacksPickerToggleOn" or "SnacksPickerToggleOff"
  end
  return {
    { " " .. (picker.title or "Files") .. " ", "FloatTitle" },
    { "│", "FloatTitle" },
    { " Hidden ", "SnacksPickerFooterText" },
    { hidden, state(hidden) },
    { "  Ignored ", "SnacksPickerFooterText" },
    { ignored, state(ignored) },
    { " ", "FloatTitle" },
  }
end

local function picker_refresh_flags(picker)
  local win = picker.input and picker.input.win
  if win and win:valid() then
    win:set_title(picker_flag_title(picker), "center")
  end
end

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    keys = {
      { "<leader>fe", false },
      { "<leader>fE", false },
      { "<leader>e", false },
      { "<leader>E", false },
    },
    config = function(_, opts)
      local is_wsl = (vim.fn.has("wsl") == 1)
        or (vim.env.WSL_DISTRO_NAME ~= nil and vim.env.WSL_DISTRO_NAME ~= "")
        or (vim.env.WSL_INTEROP ~= nil and vim.env.WSL_INTEROP ~= "")
        or (function()
          local uname = vim.uv.os_uname()
          return uname and uname.release and (uname.release:lower():find("microsoft") ~= nil or uname.release:lower():find("wsl") ~= nil)
        end)()

      -- In WSL, terminal graphics protocols (Kitty/Sixel) typically fail or output
      -- raw escape sequences (garbled text). Disable image module on WSL.
      if is_wsl then
        opts = vim.tbl_deep_extend("force", opts or {}, {
          image = {
            enabled = false,
            doc = { inline = false, float = false },
          },
        })
      else
        -- Ensure remote image streaming (t="d") is active over SSH or on remote hosts.
        -- In tmux, SSH_CLIENT/SSH_CONNECTION can be missing from the pane environment when
        -- attaching to an existing session, which causes Snacks to fall back to local file path
        -- mode (t="f"), rendering blank placeholder images in local Kitty.
        -- Only an actual SSH session, or an explicit SNACKS_SSH=1, opts in.
        -- A hostname check treated every non-workstation tmux as remote.
        if vim.env.SNACKS_SSH == nil then
          if vim.env.SSH_CLIENT or vim.env.SSH_CONNECTION or vim.env.SSH_TTY then
            vim.env.SNACKS_SSH = "1"
          end
        end

        -- With extended-keys off, tmux answers Snacks' XTVERSION query itself.
        -- In Tailscale SSH or nested sessions, client_termname is often generic xterm-256color
        -- or tmux-256color. Default to Kitty capability for tmux sessions so image rendering
        -- is enabled without blocking on startup probes.
        if vim.env.SNACKS_KITTY == nil then
          if vim.env.TERM == "xterm-kitty" or vim.env.TERM_PROGRAM == "kitty" then
            vim.env.SNACKS_KITTY = "1"
          elseif vim.env.TMUX and vim.fn.executable("tmux") == 1 then
            local client = vim.fn.system({ "tmux", "display-message", "-p", "#{client_termname}" })
            if vim.v.shell_error == 0 and client:lower():find("kitty", 1, true) then
              vim.env.SNACKS_KITTY = "1"
            end
          end
        end
      end
      local picker_layout = opts.picker and opts.picker.layout and opts.picker.layout.layout
      if type(picker_layout) == "table" then
        picker_layout.min_width = math.min(120, math.max(40, vim.o.columns - 4))
      end
      require("snacks").setup(opts)
      vim.api.nvim_set_hl(0, "SnacksPickerToggleOn", { link = "DiagnosticOk" })
      vim.api.nvim_set_hl(0, "SnacksPickerToggleOff", { link = "Comment" })

      -- Work around an upstream snacks bug where ioctl(TIOCGWINSZ) in tmux/pty
      -- returns xpixel=0 and ypixel=0, which causes cell_width=0 and cell_height=0,
      -- resulting in division by zero and width=NaN, completely breaking image display.
      local image_terminal = require("snacks.image.terminal")
      local orig_size = image_terminal.size
      image_terminal.size = function()
        local s = orig_size()
        if not s or s.cell_width == 0 or s.cell_height == 0 or s.width == 0 or s.height == 0 then
          local dw, dh = 9, 18
          s = {
            width = vim.o.columns * dw,
            height = vim.o.lines * dh,
            columns = vim.o.columns,
            rows = vim.o.lines,
            cell_width = dw,
            cell_height = dh,
            scale = 1,
          }
        end
        return s
      end

      -- Work around an upstream grep transform crash when rg outputs a non-NUL line.
      local proc = require("snacks.picker.source.proc")
      local raw_proc = proc.proc
      proc.proc = function(picker_opts, ctx)
        if picker_opts and picker_opts.cmd == "rg" and type(picker_opts.transform) == "function" then
          local original_transform = picker_opts.transform
          picker_opts = vim.tbl_extend("force", {}, picker_opts)
          picker_opts.transform = function(item, transform_ctx)
            local ok, ret = pcall(original_transform, item, transform_ctx)
            if ok then
              return ret
            end
            local err = tostring(ret)
            if err:find("file_sep", 1, true) then
              return false
            end
            error(ret)
          end
        end
        return raw_proc(picker_opts, ctx)
      end

      -- Prioritize all opened files at the top of file pickers (<leader><space>),
      -- distinguishing the currently viewed file ([current]) and other open buffers ([open]).
      local function patch_files_picker()
        local ok, picker_mod = pcall(require, "snacks.picker")
        if not ok or not picker_mod or not picker_mod.pick then return end
        if picker_mod._files_picker_patched then return end
        picker_mod._files_picker_patched = true

        local raw_pick = picker_mod.pick
        picker_mod.pick = function(source, p_opts)
          if not p_opts and type(source) == "table" then
            p_opts, source = source, nil
          end
          p_opts = p_opts or {}
          local src = source or p_opts.source
          if src == "files" or src == "git_files" then
            local cur_win = vim.api.nvim_get_current_win()
            local cur_buf = vim.api.nvim_win_get_buf(cur_win)
            local cur_name = vim.api.nvim_buf_get_name(cur_buf)
            local is_normal_file = cur_name ~= ""
              and vim.bo[cur_buf].buftype == ""
              and vim.api.nvim_win_get_config(cur_win).relative == ""
            local cur_file = is_normal_file and vim.fs.normalize(cur_name) or nil
            local cwd = vim.fs.normalize(vim.uv.cwd() or ".")

            local open_buffers = {}
            for _, b in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
              if b.name and b.name ~= "" and vim.bo[b.bufnr].buftype == "" then
                local norm = vim.fs.normalize(b.name)
                local rel = (norm:sub(1, #cwd + 1) == (cwd .. "/")) and norm:sub(#cwd + 2) or nil
                local item_info = {
                  is_current = (norm == cur_file),
                  rel = rel,
                  lastused = b.lastused or 0,
                  bufnr = b.bufnr,
                }
                open_buffers[norm] = item_info
                if rel then
                  open_buffers[rel] = item_info
                end
              end
            end

            p_opts = vim.tbl_extend("force", {}, p_opts)

            local user_transform = p_opts.transform
            p_opts.transform = function(item, ctx)
              if user_transform then
                local t = user_transform(item, ctx)
                if t == false then return false end
                if type(t) == "table" then item = t end
              end
              local info = open_buffers[item.file] or (item._path and open_buffers[item._path])
              if info then
                if info.is_current then
                  item.is_current = true
                  item.filename_hl = "SnacksPickerCurrentFile"
                else
                  item.is_open = true
                end
                item.lastused = info.lastused
              end
            end

            p_opts.matcher = vim.tbl_extend("force", p_opts.matcher or {}, { sort_empty = true })

            local default_sort = Snacks.picker.config.sort(p_opts)
            p_opts.sort = function(a, b)
              local a_rank = a.is_current and 1 or (a.is_open and 2 or 3)
              local b_rank = b.is_current and 1 or (b.is_open and 2 or 3)
              if a_rank ~= b_rank then
                return a_rank < b_rank
              end
              if a.is_open and b.is_open then
                local a_used = a.lastused or 0
                local b_used = b.lastused or 0
                if a_used ~= b_used then
                  return a_used > b_used
                end
              end
              return default_sort(a, b)
            end

            local orig_format = p_opts.format or Snacks.picker.format.file
            local format_fn = type(orig_format) == "string" and (Snacks.picker.format[orig_format] or Snacks.picker.format.file) or orig_format
            p_opts.format = function(item, picker)
              local ret = format_fn(item, picker)
              if item.is_current then
                table.insert(ret, { " [current] ", "SnacksPickerCurrentBadge" })
              elseif item.is_open then
                table.insert(ret, { " [open] ", "SnacksPickerOpenBadge" })
              end
              return ret
            end
          end
          return raw_pick(source, p_opts)
        end
      end

      patch_files_picker()

      -- Center solid badge diagnostic signs by highlighting only the 1-cell glyph,
      -- leaving the trailing column as a standard gutter space instead of stretching
      -- the badge background into an awkward off-center 2-cell box.
      local statuscolumn = require("snacks.statuscolumn")
      local orig_statuscolumn_icon = statuscolumn.icon
      statuscolumn.icon = function(sign)
        if not sign then
          return "  "
        end
        if sign.type == "sign" and sign.texthl and sign.texthl:match("^DiagnosticSign") then
          local char = vim.fn.strcharpart(sign.text or "", 0, 1)
          if char ~= "" and char ~= " " then
            return "%#" .. sign.texthl .. "#" .. char .. "%* "
          end
        end
        return orig_statuscolumn_icon(sign)
      end
    end,
    opts = {
      explorer = { enabled = false },
      scroll = { enabled = false },
      indent = {
        enabled = true,
        char = "│",
        only_scope = false,
        only_current = false,
      },
      scope = {
        enabled = true,
        char = "│",
        underline = false,
      },
      animate = {
        enabled = false,
      },
      image = {
        enabled = true,
        doc = {
          inline = true,
          float = true,
          max_width = 80,
          max_height = 40,
        },
        img_dirs = { "assets", "img", "images", "static", "media", "attachments" },
      },
      statuscolumn = {
        enabled = true,
        left = { "mark", "sign" },
        right = { "fold", "git" },
        folds = {
          open = true, -- 显示已展开的代码折叠三角图标 
          git_hl = false,
        },
      },
      notifier = {
        icons = {
          error = "",
          warn = "",
          info = "",
          debug = "",
          trace = "",
        },
      },
      -- 1. 全局基础窗口配置
      win = { border = "single", backdrop = false },
      -- 2. 覆盖 Snacks 内置的所有标准样式
      lazygit = {
        configure = true,
        theme = {
          activeBorderColor = { fg = "UnifiedFloatBorder" },
          inactiveBorderColor = { fg = "UnifiedFloatBorder" },
          defaultFgColor = { fg = "Normal" },
          selectedLineBgColor = { bg = "SnacksPickerListCursorLine" },
        },
      },
      styles = {
        float = { border = "single", backdrop = false },
        notification = { border = "single", backdrop = false },
        input = { border = "single", backdrop = false },
        confirm = { border = "single", backdrop = false },
        lazygit = { border = "single", backdrop = false },
      },
      picker = {
        on_show = function(picker)
          -- The picker floats over the editor; hide its context winbar while
          -- open so the old buffer breadcrumb does not look like a stray bar.
          local win = picker.main
          if win and vim.api.nvim_win_is_valid(win) then
            picker._saved_main_winbar = vim.wo[win].winbar
            vim.w[win].dropbar_suspended = true
            vim.wo[win].winbar = ""
          end
          -- Snacks maps NormalFloat for the preview, but blank filler lines
          -- use Normal. Map that too so scrolling past document text never
          -- exposes the editor's blue background inside the picker.
          vim.defer_fn(function()
            if picker.closed then return end
            local preview = picker.preview and picker.preview.win and picker.preview.win.win
            if preview and vim.api.nvim_win_is_valid(preview) then
              local winhl = vim.wo[preview].winhighlight
              if not winhl:find("Normal:", 1, true) then
                vim.wo[preview].winhighlight = (winhl ~= "" and (winhl .. ",") or "")
                  .. "Normal:SnacksPickerPreview"
              end
            end
          end, 50)
          -- Keep the hidden/ignored toggle state visible in the input border.
          -- The toggle actions call find(), which refreshes titles.
          if not picker._flags_title_hooked and picker.input and picker.input.win and picker.input.win:valid() then
            picker._flags_title_hooked = true
            local update_titles = picker.update_titles
            picker.update_titles = function(self)
              update_titles(self)
              picker_refresh_flags(self)
            end
            picker_refresh_flags(picker)
          end
        end,
        on_close = function(picker)
          local win = picker.main
          if win and vim.api.nvim_win_is_valid(win) and picker._saved_main_winbar ~= nil then
            vim.w[win].dropbar_suspended = nil
            vim.wo[win].winbar = picker._saved_main_winbar
            picker._saved_main_winbar = nil
            local context = package.loaded["config.dropbar"]
            if context then
              context.sync(vim.api.nvim_win_get_buf(win), win)
            end
          end
        end,
        layout = {
          layout = {
            -- Show the editor directly behind the picker.
            backdrop = false,
            box = "horizontal",
            width = 0.85,
            min_width = 120,
            height = 0.8,
            border = "single",
            footer = {
              { " Alt+h ", "SnacksPickerFooterKey" },
              { "Toggle Hidden", "SnacksPickerFooterText" },
              { "  │  ", "SnacksPickerFooterSeparator" },
              { " Alt+i ", "SnacksPickerFooterKey" },
              { "Toggle Ignored", "SnacksPickerFooterText" },
              { "  │  ", "SnacksPickerFooterSeparator" },
              { " Enter ", "SnacksPickerFooterKey" },
              { "Open", "SnacksPickerFooterText" },
              { "  │  ", "SnacksPickerFooterSeparator" },
              { " Esc ", "SnacksPickerFooterKey" },
              { "Close", "SnacksPickerFooterText" },
            },
            footer_pos = "center",
            {
              box = "vertical",
              border = "none",
              { win = "input", height = 1, border = "single" },
              { win = "list", border = "none" },
            },
            { win = "preview", border = "left", width = 0.55 },
          },
        },
        win = {
          preview = {
            wo = { cursorcolumn = false },
          },
          input = {
            keys = {
              ["<a-h>"] = { "toggle_hidden", mode = { "i", "n" } },
              ["<c-h>"] = { "toggle_hidden", mode = { "i", "n" } },
              ["<a-i>"] = { "toggle_ignored", mode = { "i", "n" } },
            },
          },
        },
        sources = {
          files = {
            hidden = false,
          },
          grep = {
            args = { "--no-messages" },
          },
          git_grep = {
            args = { "--no-messages" },
          },
        },
      },
    },
  },
}
