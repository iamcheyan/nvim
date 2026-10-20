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
        if vim.env.SNACKS_SSH == nil then
          if vim.env.SSH_CLIENT or vim.env.SSH_CONNECTION or vim.env.SSH_TTY then
            vim.env.SNACKS_SSH = "1"
          elseif vim.env.TMUX and vim.fn.executable("tmux") == 1 then
            local tmux_ssh = vim.fn.system({ "tmux", "show-environment", "-g", "SSH_CLIENT" })
            if vim.v.shell_error == 0 and not tmux_ssh:match("^%-") and tmux_ssh:find("=", 1, true) then
              vim.env.SNACKS_SSH = "1"
            elseif vim.fn.hostname() ~= "hx90" then
              -- Fallback for remote hosts (non-workstation)
              vim.env.SNACKS_SSH = "1"
            end
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
            if vim.v.shell_error == 0 and (client:lower():find("kitty", 1, true) or vim.trim(client) == "xterm-256color" or vim.trim(client) == "tmux-256color") then
              vim.env.SNACKS_KITTY = "1"
            end
          end
        end
      end
      require("snacks").setup(opts)

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
            return false
          end
        end
        return raw_proc(picker_opts, ctx)
      end
    end,
    opts = {
      explorer = { enabled = false },
      scroll = { enabled = false },
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
        end,
        on_close = function(picker)
          local win = picker.main
          if win and vim.api.nvim_win_is_valid(win) and picker._saved_main_winbar ~= nil then
            vim.wo[win].winbar = picker._saved_main_winbar
            picker._saved_main_winbar = nil
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
