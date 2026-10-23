return {
  {
    "rebelot/heirline.nvim",
    lazy = true,
    event = "VeryLazy",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    opts = function()
      local gap = { provider = "  " }
      local pad = { provider = " " }
      local function caps_locked()
        return _G._heirline_caps_lock_on == true
      end
      local function mode_surface()
        return caps_locked() and "FreshStatusLineCaps" or "FreshStatusLineAccent"
      end
      -- Resolve colors from the adapted StatusLine group so the actual bottom bar,
      -- not the separate WinBar surface, controls every statusline segment.
      local statusline_colors = setmetatable({}, {
        __index = function(_, key)
          local statusline = vim.api.nvim_get_hl(0, { name = "StatusLine", link = false })
          local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
          local fg, bg = statusline.fg or normal.fg, statusline.bg or normal.bg
          if key == "bg" then return bg end
          if key == "press_bg" then
            return vim.api.nvim_get_hl(0, { name = "FreshStatusLineAccent", link = false }).bg or bg
          end
          if key == "on_accent" then
            return vim.api.nvim_get_hl(0, { name = "FreshStatusLineAccent", link = false }).fg or fg
          end
          if key == "text" then return fg end
          if key == "accent" then
            return vim.api.nvim_get_hl(0, { name = "FreshStatusLineAccent", link = false }).fg or fg
          end
          if key == "warning" then
            return vim.api.nvim_get_hl(0, { name = "FreshStatusLineWarning", link = false }).fg or fg
          end
          if key == "git_text" then
            return vim.api.nvim_get_hl(0, { name = "FreshStatusLineGit", link = false }).fg or fg
          end
        end,
      })
      local function pad_segment(component)
        table.insert(component, 1, pad)
        table.insert(component, pad)
        return component
      end
      local function click_feedback(self, normal)
        if not self or not self._pressed then return normal end
        local accent = vim.api.nvim_get_hl(0, { name = "FreshStatusLineAccent", link = false })
        return { fg = accent.fg or "#ffffff", bg = accent.bg or statusline_colors.bg, bold = false }
      end

      local mode_names = {
        n = "NORMAL",
        no = "N-PENDING",
        nov = "N-PENDING",
        noV = "N-PENDING",
        ["no\22"] = "N-PENDING",
        niI = "NORMAL",
        niR = "NORMAL",
        niV = "NORMAL",
        nt = "NORMAL",
        v = "VISUAL",
        vs = "VISUAL",
        V = "V-LINE",
        Vs = "V-LINE",
        ["\22"] = "V-BLOCK",
        ["\22s"] = "V-BLOCK",
        s = "SELECT",
        S = "S-LINE",
        ["\19"] = "S-BLOCK",
        i = "INSERT",
        ic = "INSERT",
        ix = "INSERT",
        R = "REPLACE",
        Rc = "REPLACE",
        Rx = "REPLACE",
        Rv = "V-REPLACE",
        Rvc = "V-REPLACE",
        Rvx = "V-REPLACE",
        c = "COMMAND",
        cv = "EX",
        r = "PROMPT",
        rm = "MORE",
        ["r?"] = "CONFIRM",
        ["!"] = "SHELL",
        t = "TERMINAL",
      }

      local function get_venv_name()
        local venv = vim.env.VIRTUAL_ENV
        if venv and venv ~= "" then
          return vim.fn.fnamemodify(venv, ":t")
        end
        local conda = vim.env.CONDA_DEFAULT_ENV
        if conda and conda ~= "" then
          return conda
        end
        return nil
      end

      local menu = require("config.statusline.menu")
      local get_active_editor_win = menu.active_editor_win
      local open_statusline_menu = menu.open

      local Mode = {
        init = function(self)
          self.mode = vim.fn.mode(1)
        end,
        on_click = {
          callback = function(self, _, _, button)
            if button ~= "l" then return end
            open_statusline_menu("mode", {
              {
                icon = "󰌌",
                label = "Show All Keymaps (:WhichKey)",
                action = function()
                  pcall(function() require("which-key").show() end)
                end,
              },
              {
                icon = "󰍉",
                label = "Find Files (<leader><space>)",
                action = function()
                  pcall(function() require("snacks").picker.files() end)
                end,
              },
              {
                icon = "󰊄",
                label = "Search Text in Project (<leader>sg)",
                action = function()
                  pcall(function() require("snacks").picker.grep() end)
                end,
              },
              {
                icon = "󰙅",
                label = "Project Explorer (<leader>e)",
                action = function()
                  pcall(function() require("neo-tree.command").execute({ toggle = true }) end)
                end,
              },
              {
                icon = "󱐋",
                label = "Plugin Manager (:Lazy)",
                action = function()
                  vim.cmd("Lazy")
                end,
              },
              {
                icon = "󰑐",
                label = "Reload Configuration (<leader>uR)",
                action = function()
                  require("config.reload").menu()
                end,
              },
            }, "heirline_mode_menu")
          end,
          name = "heirline_mode_menu",
        },
        hl = function(self)
          if _G._active_statusline_menu == "mode" then
            return click_feedback({ _pressed = true }, mode_surface())
          end
          return click_feedback(self, mode_surface())
        end,
        {
          provider = " ",
          hl = function(self)
            if _G._active_statusline_menu == "mode" then
              return click_feedback({ _pressed = true }, mode_surface())
            end
            return click_feedback(self, mode_surface())
          end,
        },
        {
          provider = function(self)
            return (mode_names[self.mode] or self.mode)
          end,
          hl = function(self)
            if _G._active_statusline_menu == "mode" then
              return click_feedback({ _pressed = true }, mode_surface())
            end
            return click_feedback(self, mode_surface())
          end,
        },
      }


      local GitBranch = {
        init = function(self)
          self.gs = vim.b.gitsigns_status_dict
        end,
        on_click = {
          callback = function(self, _, _, button)
            if button ~= "l" then return end
            open_statusline_menu("git", {
              {
                icon = "󰊢",
                label = "Open Diffview Workspace (<leader>gd)",
                action = function()
                  vim.cmd("DiffviewOpen")
                end,
              },
              {
                icon = "󰋚",
                label = "Current File Diff History (<leader>gD)",
                action = function()
                  vim.cmd("DiffviewFileHistory %")
                end,
              },
              {
                icon = "󰜘",
                label = "Branch Commit History (<leader>gV)",
                action = function()
                  vim.cmd("DiffviewFileHistory")
                end,
              },
              {
                icon = "",
                label = "Open Lazygit Terminal (<leader>gg)",
                action = function()
                  pcall(function() require("snacks").lazygit() end)
                end,
              },
              { separator = true },
              {
                icon = "󰈈",
                label = "Toggle Line Blame (<leader>ub)",
                action = function()
                  pcall(function() require("gitsigns").toggle_current_line_blame() end)
                end,
              },
              {
                icon = "󰍉",
                label = "Preview Hunk at Cursor (<leader>gp)",
                action = function()
                  pcall(function() require("gitsigns").preview_hunk() end)
                end,
              },
              {
                icon = "󰜺",
                label = "Reset Hunk at Cursor (<leader>gr)",
                action = function()
                  pcall(function() require("gitsigns").reset_hunk() end)
                end,
              },
            }, "heirline_git_menu")
          end,
          name = "heirline_git_menu",
        },
        hl = function(self)
          if _G._active_statusline_menu == "git" then
            return "Pmenu"
          end
          return click_feedback(self, "FreshStatusLineGit")
        end,
        {
          provider = function(self)
            local head = self.gs and self.gs.head or ""
            return " " .. (head == "" and "-" or head)
          end,
          hl = function(self)
            if _G._active_statusline_menu == "git" then return { fg = statusline_colors.text, bold = false } end
            if self._pressed then return click_feedback(self) end
            return { fg = statusline_colors.git_text, bold = false }
          end,
        },
        {
          provider = function(self)
            local count = (self.gs and self.gs.added) or 0
            return " +" .. count
          end,
          hl = function(self)
            if _G._active_statusline_menu == "git" then return { fg = statusline_colors.text } end
            if self._pressed then return click_feedback(self) end
            return { fg = statusline_colors.git_text }
          end,
        },
        {
          provider = function(self)
            local count = (self.gs and self.gs.changed) or 0
            return " ~" .. count
          end,
          hl = function(self)
            if _G._active_statusline_menu == "git" then return { fg = statusline_colors.text } end
            if self._pressed then return click_feedback(self) end
            return { fg = statusline_colors.git_text }
          end,
        },
        {
          provider = function(self)
            local count = (self.gs and self.gs.removed) or 0
            return " -" .. count
          end,
          hl = function(self)
            if _G._active_statusline_menu == "git" then return { fg = statusline_colors.text } end
            if self._pressed then return click_feedback(self) end
            return { fg = statusline_colors.git_text }
          end,
        },
      }

      local function truncate_middle(value, max_width)
        if vim.fn.strdisplaywidth(value) <= max_width then return value end
        if max_width <= 1 then return "…" end
        local chars = vim.fn.strchars(value)
        local keep = max_width - 1
        local left = math.floor(keep / 2)
        local right = keep - left
        return vim.fn.strcharpart(value, 0, left) .. "…" .. vim.fn.strcharpart(value, chars - right, right)
      end

      local function compact_path(path, max_width)
        if vim.fn.strdisplaywidth(path) <= max_width then
          return vim.fn.fnamemodify(path, ":h") .. "/", vim.fn.fnamemodify(path, ":t")
        end
        local parts = {}
        for part in path:gmatch("[^/]+") do
          parts[#parts + 1] = part
        end
        local filename = parts[#parts] or path
        local display_file = filename
        if vim.fn.strdisplaywidth(display_file) > max_width - 2 then
          display_file = truncate_middle(display_file, max_width - 1)
          return "", display_file
        end

        local display_dir = "…/"
        for index = #parts - 1, 1, -1 do
          local candidate = "…/" .. table.concat(parts, "/", index, #parts - 1) .. "/"
          if vim.fn.strdisplaywidth(candidate .. display_file) > max_width then break end
          display_dir = candidate
        end
        return display_dir, display_file
      end

      local FileName = {
        update = { "BufEnter", "WinEnter", "VimResized", "WinResized" },
        init = function(self)
          local winid = get_active_editor_win()
          local bufnr = vim.api.nvim_win_get_buf(winid)
          local name = vim.api.nvim_buf_get_name(bufnr)
          local path = name == "" and "[No Name]" or vim.fn.fnamemodify(name, ":p")
          self.current_path = path

          local icon = "󰈔"
          local icon_color = statusline_colors.text
          if name ~= "" then
            local devicons = require("nvim-web-devicons")
            local fname = vim.fn.fnamemodify(name, ":t")
            local ext = vim.fn.fnamemodify(name, ":e")
            local ic = devicons.get_icon_color(fname, ext, { default = true })
            if ic then
              icon = ic
            end
            -- Reserve room for the git block on the left and the metadata blocks
            -- on the right.  When space gets tight, compact_path drops leading
            -- directories first and keeps the filename visible.
            local path_width = math.max(8, vim.o.columns - 100)
            self.dir, self.display_file = compact_path(path, path_width)
            self.file = fname
          else
            self.dir = ""
            self.file = "[No Name]"
            self.display_file = self.file
          end
          self.icon = icon
          self.icon_color = icon_color

          self.is_modified = vim.bo[bufnr].modified
          self.is_readonly = vim.bo[bufnr].readonly or not vim.bo[bufnr].modifiable
          self.is_new = (
            name ~= ""
            and vim.bo[bufnr].buftype == ""
            and vim.fn.filereadable(name) == 0
            and vim.fn.isdirectory(name) == 0
          )
        end,
        on_click = {
          callback = function(self, _, nclicks, button)
            if button ~= "l" then return end
            local path = self.current_path
            if not path or path == "" or path == "[No Name]" then return end
            local fname = self.file or vim.fn.fnamemodify(path, ":t")
            local rel_path = vim.fn.fnamemodify(path, ":.")

            if nclicks and nclicks >= 2 then
              vim.fn.setreg("+", path)
              vim.notify("Copied full path: " .. path, vim.log.levels.INFO)
              return
            end

            open_statusline_menu("file", {
              {
                icon = "󰅍",
                label = "Copy Relative Path",
                action = function()
                  vim.fn.setreg("+", rel_path)
                  vim.notify("Copied: " .. rel_path, vim.log.levels.INFO)
                end,
              },
              {
                icon = "󰅎",
                label = "Copy Absolute Path",
                action = function()
                  vim.fn.setreg("+", path)
                  vim.notify("Copied: " .. path, vim.log.levels.INFO)
                end,
              },
              {
                icon = "󰈤",
                label = "Copy Filename Only",
                action = function()
                  vim.fn.setreg("+", fname)
                  vim.notify("Copied: " .. fname, vim.log.levels.INFO)
                end,
              },
              { separator = true },
              {
                icon = "󰉖",
                label = "Open Directory in Ranger",
                action = function()
                  if vim.fn.executable("ranger") ~= 1 then
                    vim.notify("Ranger is not installed", vim.log.levels.WARN)
                    return
                  end
                  local dir = vim.fn.isdirectory(path) == 1 and path or vim.fn.fnamemodify(path, ":h")
                  require("snacks").terminal({ "ranger" }, { cwd = dir })
                end,
              },
              {
                icon = "󰙅",
                label = "Reveal in Neo-tree (<leader>e)",
                action = function()
                  pcall(function()
                    require("neo-tree.command").execute({ toggle = false, reveal = true })
                  end)
                end,
              },
              {
                icon = "󰋚",
                label = "View File History (Diffview)",
                action = function()
                  vim.cmd("DiffviewFileHistory %")
                end,
              },
              {
                icon = "󰑕",
                label = "Rename File (Snacks)",
                action = function()
                  pcall(function()
                    require("snacks").rename.rename_file()
                  end)
                end,
              },
            }, "heirline_file_actions")
          end,
          name = "heirline_file_actions",
        },
        hl = function(self)
          if _G._active_statusline_menu == "file" then
            return "Pmenu"
          end
          return click_feedback(self)
        end,
        {
          provider = function(self)
            return self.icon .. " "
          end,
          hl = function(self)
            if _G._active_statusline_menu == "file" then return { fg = statusline_colors.text, bold = false } end
            if self._pressed then return click_feedback(self) end
            return { fg = self.icon_color }
          end,
        },
        {
          provider = function(self)
            return self.dir
          end,
          hl = function(self)
            if _G._active_statusline_menu == "file" then return { fg = statusline_colors.text } end
            if self._pressed then return click_feedback(self) end
            return { fg = statusline_colors.text }
          end,
        },
        {
          provider = function(self)
            return self.display_file or self.file
          end,
          hl = function(self)
            if _G._active_statusline_menu == "file" then return { fg = statusline_colors.text, bold = false } end
            if self._pressed then return click_feedback(self) end
            return { fg = statusline_colors.text, bold = false }
          end,
        },
        {
          condition = function(self)
            return self.is_modified
          end,
          provider = " [+] ",
          hl = function(self)
            if _G._active_statusline_menu == "file" then return "Pmenu" end
            if self._pressed then return click_feedback(self, vim.g.colors_name == "blue" and "FreshStatusLineWarning" or nil) end
            return { fg = statusline_colors.warning, bold = false }
          end,
        },
        {
          condition = function(self)
            return self.is_readonly
          end,
          provider = " [RO] ",
          hl = function(self)
            if _G._active_statusline_menu == "file" then return { fg = statusline_colors.text, bold = false } end
            if self._pressed then return click_feedback(self) end
            return { fg = statusline_colors.text, bold = false }
          end,
        },
        {
          condition = function(self)
            return self.is_new
          end,
          provider = " [New] ",
          hl = function(self)
            if _G._active_statusline_menu == "file" then return "Pmenu" end
            if self._pressed then return click_feedback(self, vim.g.colors_name == "blue" and "FreshStatusLineAccent" or nil) end
            if vim.g.colors_name == "blue" then return "FreshStatusLineAccent" end
            return { fg = statusline_colors.accent, bold = false }
          end,
        },
      }

      local LspName = {
        update = { "BufEnter", "FileType", "LspAttach", "LspDetach" },
        init = function(self)
          local winid = get_active_editor_win()
          local bufnr = vim.api.nvim_win_get_buf(winid)
          local ft = vim.bo[bufnr].filetype
          local names = { sh = "Shell", text = "Text", javascriptreact = "JSX", typescriptreact = "TSX", vim = "Vimscript" }
          self.filetype = names[ft] or (ft == "" and "Text" or (ft:sub(1, 1):upper() .. ft:sub(2)))
          self.active = #vim.lsp.get_clients({ bufnr = bufnr }) > 0
        end,
        on_click = {
          callback = function(self, _, _, button)
            if button ~= "l" then return end
            open_statusline_menu("lsp", {
              {
                icon = "󰒋",
                label = "LSP Information (:LspInfo)",
                action = function()
                  vim.cmd("LspInfo")
                end,
              },
              {
                icon = "󰏓",
                label = "Package Manager (:Mason)",
                action = function()
                  vim.cmd("Mason")
                end,
              },
              {
                icon = "󰘦",
                label = "Document Symbols (<leader>cs)",
                action = function()
                  require("config.sidebar_tabs").toggle_symbols()
                end,
              },
              { separator = true },
              {
                icon = "󰌵",
                label = "Code Actions (<leader>ca)",
                action = function()
                  pcall(vim.lsp.buf.code_action)
                end,
              },
              {
                icon = "󰉿",
                label = "Format Buffer (<leader>fo)",
                action = function()
                  pcall(function()
                    vim.lsp.buf.format({ async = true })
                  end)
                end,
              },
              {
                icon = "󰑓",
                label = "Restart LSP Server (:LspRestart)",
                action = function()
                  vim.cmd("LspRestart")
                end,
              },
            }, "heirline_lsp_menu")
          end,
          name = "heirline_lsp_menu",
        },
        hl = function(self)
          if _G._active_statusline_menu == "lsp" then
            return click_feedback({ _pressed = true }, "FreshStatusLineWarning")
          end
          return click_feedback(self, "FreshStatusLineWarning")
        end,
        {
          provider = "󰒋 ",
          hl = function(self)
            if _G._active_statusline_menu == "lsp" then
              return click_feedback({ _pressed = true }, "FreshStatusLineWarning")
            end
            if self._pressed then return click_feedback(self, "FreshStatusLineWarning") end
            return { fg = "#ffffff" }
          end,
        },
        {
          provider = function(self)
            return self.filetype
          end,
          hl = function(self)
            if _G._active_statusline_menu == "lsp" then
              return click_feedback({ _pressed = true }, "FreshStatusLineWarning")
            end
            if self._pressed then return click_feedback(self, "FreshStatusLineWarning") end
            return { fg = "#ffffff", bold = false }
          end,
        },
      }

      local function open_choice_menu(kind, name, icon, choices)
        local entries = {}
        for _, choice in ipairs(choices) do
          entries[#entries + 1] = { icon = icon, label = choice.label, action = choice.action }
        end
        open_statusline_menu(kind, entries, name)
      end

      local FileFormat = {
        provider = function()
          local bufnr = vim.api.nvim_win_get_buf(get_active_editor_win())
          local value = ({ unix = "LF", dos = "CRLF", mac = "CR" })[vim.bo[bufnr].fileformat] or "LF"
          return " " .. value .. " "
        end,
        on_click = {
          callback = function(_, _, _, button)
            if button ~= "l" then return end
            open_choice_menu("fileformat", "heirline_fileformat_menu", "󰌒", {
              { label = "Line Format: Unix (LF)", action = function() vim.bo.fileformat = "unix" end },
              { label = "Line Format: Windows (CRLF)", action = function() vim.bo.fileformat = "dos" end },
              { label = "Line Format: Mac Classic (CR)", action = function() vim.bo.fileformat = "mac" end },
            })
          end,
          name = "heirline_fileformat_menu",
        },
        hl = function(self)
          if _G._active_statusline_menu == "fileformat" then return "FreshStatusLineAccent" end
          if self._pressed then return click_feedback(self) end
          return { fg = statusline_colors.text }
        end,
      }

      local Encoding = {
        update = { "BufEnter", "FileType", "OptionSet", "BufWritePost" },
        provider = function()
          local bufnr = vim.api.nvim_win_get_buf(get_active_editor_win())
          local enc = vim.bo[bufnr].fileencoding ~= "" and vim.bo[bufnr].fileencoding or vim.o.encoding
          return " " .. string.upper(enc) .. " "
        end,
        on_click = {
          callback = function(_, _, _, button)
            if button ~= "l" then return end
            open_statusline_menu("encoding", {
              { icon = "󰉿", label = "Set Encoding: UTF-8", action = function() vim.bo.fileencoding = "utf-8" end },
              { icon = "󰉿", label = "Set Encoding: GB18030 / GBK", action = function() vim.bo.fileencoding = "gb18030" end },
              { icon = "󰉿", label = "Set Encoding: Shift-JIS (CP932)", action = function() vim.bo.fileencoding = "cp932" end },
              { icon = "󰉿", label = "Set Encoding: EUC-JP", action = function() vim.bo.fileencoding = "euc-jp" end },
              { icon = "󰉿", label = "Set Encoding: Latin-1 (ISO-8859-1)", action = function() vim.bo.fileencoding = "latin1" end },
              { icon = "󰉿", label = "Set Encoding: UTF-16LE", action = function() vim.bo.fileencoding = "utf-16le" end },
              { separator = true },
              { icon = "󰑓", label = "Reload as: UTF-8 (:e ++enc=utf-8)", action = function() vim.cmd("edit ++enc=utf-8") end },
              { icon = "󰑓", label = "Reload as: Shift-JIS (:e ++enc=cp932)", action = function() vim.cmd("edit ++enc=cp932") end },
              { icon = "󰑓", label = "Reload as: GB18030 (:e ++enc=gb18030)", action = function() vim.cmd("edit ++enc=gb18030") end },
              { icon = "󰑓", label = "Reload as: EUC-JP (:e ++enc=euc-jp)", action = function() vim.cmd("edit ++enc=euc-jp") end },
            }, "heirline_encoding_menu")
          end,
          name = "heirline_encoding_menu",
        },
        hl = function(self)
          if _G._active_statusline_menu == "encoding" then return "FreshStatusLineAccent" end
          if self._pressed then return click_feedback(self) end
          return { fg = statusline_colors.text }
        end,
      }

      local FileMeta = {
        hl = function(self)
          return { fg = statusline_colors.text, bold = false }
        end,
        FileFormat,
        Encoding,
      }

      local Venv = {
        hl = "FreshStatusLineAccent",
        condition = function()
          return get_venv_name() ~= nil
        end,
        {
          provider = "󱔎 ",
          hl = { fg = statusline_colors.warning },
        },
        {
          provider = function()
            return get_venv_name()
          end,
          hl = { fg = statusline_colors.accent, bold = false },
        },
      }

      local RemainingPercent = {
        on_click = {
          callback = function(self, _, _, button)
            if button ~= "l" then return end
            open_statusline_menu("nav", {
              {
                icon = "󰎤",
                label = "Go to Line Number...",
                action = function()
                  vim.ui.input({ prompt = "Enter line number: " }, function(input)
                    if input and tonumber(input) then
                      vim.cmd("normal! " .. input .. "G")
                    end
                  end)
                end,
              },
              {
                icon = "󰜲",
                label = "Jump to Top of File (gg)",
                action = function()
                  vim.cmd("normal! gg")
                end,
              },
              {
                icon = "󰜮",
                label = "Jump to Bottom of File (G)",
                action = function()
                  vim.cmd("normal! G")
                end,
              },
              {
                icon = "󰆤",
                label = "Center Screen on Cursor (zz)",
                action = function()
                  vim.cmd("normal! zz")
                end,
              },
            }, "heirline_nav_menu")
          end,
          name = "heirline_nav_menu",
        },
        hl = function(self)
          if _G._active_statusline_menu == "nav" then
            return "Pmenu"
          end
          return click_feedback(self, "FreshStatusLineNeutral")
        end,
        {
          provider = "󰦨 ",
          hl = function(self)
            if _G._active_statusline_menu == "nav" then return { fg = statusline_colors.text } end
            if self._pressed then return click_feedback(self, "FreshStatusLineNeutral") end
            return { fg = statusline_colors.text }
          end,
        },
        {
          provider = function()
            local winid = get_active_editor_win()
            local bufnr = vim.api.nvim_win_get_buf(winid)
            local total = vim.api.nvim_buf_line_count(bufnr)
            if total <= 1 then
              return "0%"
            end
            local current = vim.api.nvim_win_get_cursor(winid)[1]
            local remain = math.floor(((total - current) / total) * 100 + 0.5)
            return remain .. "%"
          end,
          hl = function(self)
            if _G._active_statusline_menu == "nav" then return { fg = statusline_colors.text, bold = false } end
            if self._pressed then return click_feedback(self, "FreshStatusLineNeutral") end
            return { fg = statusline_colors.text, bold = false }
          end,
        },
      }

      local Align = { provider = "%=" }
      local hidden_filetypes = {
        ["neo-tree"] = true,
        ["NvimTree"] = true,
        ["aerial"] = true,
        ["help"] = true,
        ["lazy"] = true,
        ["mason"] = true,
        ["Trouble"] = true,
        ["snacks_layout_box"] = true,
        ["qf"] = true,
        ["csv"] = true,
        ["tsv"] = true,
        ["text"] = true,
        ["txt"] = true,
        ["plaintex"] = true,
        ["log"] = true,
        ["gitcommit"] = true,
        ["gitrebase"] = true,
        ["diff"] = true,
        ["checkhealth"] = true,
        ["man"] = true,
      }


      -- Join the right-side color blocks edge to edge; the padding lives inside
      -- each block so its background stays continuous.
      local CapsState = {
        hl = mode_surface,
        pad,
        {
          provider = function()
            if _G._heirline_caps_lock_on == nil then return "CAPS ?" end
            return caps_locked() and "CAPS ON" or "CAPS OFF"
          end,
        },
        pad,
      }
      pad_segment(GitBranch)
      pad_segment(FileName)
      pad_segment(Venv)
      pad_segment(LspName)
      pad_segment(RemainingPercent)
      pad_segment(Mode)
      -- Heirline does not track mouse presses. Keep our own short pulse and
      -- invalidate cached components so the first mouse-down redraws immediately.
      local function invalidate(component)
        component._win_cache = nil
        for _, child in ipairs(component) do invalidate(child) end
      end
      local function interactive(component)
        if component.on_click then
          local callback = component.on_click.callback
          local normal_hl = component.hl
          local menu_id = ({
            heirline_mode_menu = "mode", heirline_git_menu = "git",
            heirline_file_actions = "file", heirline_lsp_menu = "lsp",
            heirline_fileformat_menu = "fileformat", heirline_encoding_menu = "encoding",
            heirline_nav_menu = "nav", heirline_position_menu = "position",
          })[component.on_click.name]
          component.hl = function(self)
            local pressed = self._pressed
            self._pressed = nil
            local normal = normal_hl
            if type(normal_hl) == "function" then normal = normal_hl(self) end
            self._pressed = pressed
            if self._pressed or (menu_id and _G._active_statusline_menu == menu_id) then
              local style = click_feedback({ _pressed = true }, normal)
              style.force = true
              return style
            end
            return normal
          end
          component.on_click.update = true
          component.on_click.callback = function(self, ...)
            self._pressed = true
            self._press_generation = (self._press_generation or 0) + 1
            local generation = self._press_generation
            local function redraw()
              local heirline = require("heirline")
              if heirline.statusline then invalidate(heirline.statusline) end
              vim.cmd("redrawstatus")
            end
            redraw()
            vim.defer_fn(function()
              if self._press_generation == generation then
                self._pressed = nil
                redraw()
              end
            end, 220)
            return callback(self, ...)
          end
        end
        for _, child in ipairs(component) do interactive(child) end
      end
      for _, component in ipairs({ GitBranch, FileName, FileFormat, Encoding, LspName, RemainingPercent, Mode }) do
        interactive(component)
      end
      local PositionInfo = require("config.statusline.position").new(statusline_colors)
      interactive(PositionInfo)

      local RightInfo = {
        PositionInfo,
        Venv,
        FileMeta,
        LspName,
        RemainingPercent,
        CapsState,
        Mode,
      }


      return {
        statusline = {
          hl = function()
            return { fg = statusline_colors.text, bg = statusline_colors.bg, bold = false }
          end,
          GitBranch,
          FileName,
          Align,
          RightInfo,
        },
      }
    end,
    config = function(_, opts)
      vim.o.laststatus = 3
      require("heirline").setup(opts)
      require("config.bar_feedback").on_redraw = function()
        local function clear(component)
          if not component then return end
          component._win_cache = nil
          for _, child in ipairs(component) do clear(child) end
        end
        clear(require("heirline").statusline)
        vim.cmd("redrawstatus")
      end

      require("config.caps_lock").start()

      -- 解决切换主题后状态栏失去颜色的问题：
      -- 当执行 :colorscheme 时，Vim 会清空所有高亮组 (hi clear)。
      -- 监听 ColorScheme 事件，自动调用 heirline.utils.on_colorscheme 重建高亮并重绘状态栏。
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("HeirlineReloadOnColorscheme", { clear = true }),
        callback = function()
          local ok, utils = pcall(require, "heirline.utils")
          if ok and utils.on_colorscheme then
            utils.on_colorscheme()
          end
          pcall(vim.cmd, "redrawstatus")
        end,
      })
    end,
  },
}
