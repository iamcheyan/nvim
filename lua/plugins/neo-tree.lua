local function project_root()
  local buf = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = buf })
  for _, c in ipairs(clients) do
    if c.config.root_dir then
      return c.config.root_dir
    end
  end
  return vim.fs.root(buf, { ".git", "lua" }) or vim.uv.cwd()
end

return {
  -- 配置 neo-tree
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      {
        "<leader>fe",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = project_root() })
        end,
        desc = "Explorer NeoTree (Root Dir)",
      },
      {
        "<leader>fE",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
        end,
        desc = "Explorer NeoTree (cwd)",
      },
      { "<leader>e", "<leader>fE", desc = "Explorer NeoTree (cwd)", remap = true },
      {
        "<leader>ge",
        function()
          require("neo-tree.command").execute({ source = "git_status", toggle = true })
        end,
        desc = "Git Explorer",
      },
      {
        "<leader>be",
        function()
          require("neo-tree.command").execute({ source = "buffers", toggle = true })
        end,
        desc = "Buffer Explorer",
      },
    },
    opts = {
      enable_diagnostics = false,
      sources = { "filesystem", "buffers", "git_status" },
      event_handlers = {
        {
          event = "neo_tree_window_after_open",
          handler = function(args) require("config.sidebar_tabs").on_tree_open(args) end,
        },
        {
          event = "neo_tree_buffer_enter",
          handler = function()
            -- The tree has no signs, folds, or status column; remove editing-window gutters.
            vim.wo.foldcolumn = "0"
            vim.wo.signcolumn = "no"
            vim.wo.statuscolumn = ""
            vim.wo.winfixwidth = true
          end,
        },
      },
      source_selector = {
        winbar = false,
        -- Rendered in bufferline's sidebar offset by config.sidebar_tabs.
        statusline = false,
        separator = "",
        content_layout = "center",
        sources = {
          { source = "filesystem", display_name = "󰉓 File" },
          { source = "buffers", display_name = "󰈚 Bufs" },
          { source = "git_status", display_name = "󰊢 Git" },
        },
      },
      use_popups_for_input = false,
      open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
      -- Keep the tree compact below the source tabs in the tabline.
      hide_root_node = true,
      -- With the root node hidden, drop its indent level too: every row shifts
      -- one level to the left. Nothing is clipped by this -- the indent
      -- component only substitutes the expander glyph inside the indent, and
      -- this config leaves `expander_collapsed`/`expander_expanded` empty.
      retain_hidden_root_indent = false,
      -- 全局默认缩进配置（用于 filesystem）
      default_component_configs = {
        indent = {
          indent_size = 2,
          padding = 0,
          with_markers = true,
          indent_marker = "│",
          last_indent_marker = "└",
          highlight = "NeoTreeIndentMarker",
          with_expanders = true,
          expander_collapsed = "",
          expander_expanded = "",
          expander_highlight = "NeoTreeExpander",
        },
        git_status = {
          symbols = {
            unstaged = "",
            staged = "",
          },
        },
      },
      filesystem = {
        bind_to_cwd = false,
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
      },
      git_status = {
        window = {
          position = "left",
          width = 32,
          mappings = {
            ["A"] = "git_add_all",
            ["gu"] = "git_unstage_file",
            ["ga"] = "git_add_file",
            ["gr"] = "git_revert_file",
            ["gc"] = "git_commit",
            ["gp"] = "git_push",
            ["gg"] = "git_commit_and_push",
          },
        },
        -- 使用自定义渲染器，覆盖缩进配置
        renderers = {
          root = {
            { "text", { "  ", highlight = "NeoTreeRootName" } },
            { "name", zindex = 10 },
          },
          directory = {
            { "indent", with_markers = false, indent_size = 0 },
            { "icon" },
            { "current_filter" },
            { "name" },
            { "symlink_target" },
          },
          file = {
            { "indent", with_markers = false, indent_size = 0 },
            { "icon" },
            { "name", use_git_status_colors = true },
            { "symlink_target" },
          },
        },
      },
      buffers = {
        window = {
          position = "left",
          width = 32,
        },
        -- 使用自定义渲染器，覆盖缩进配置
        renderers = {
          root = {
            { "text", { "  ", highlight = "NeoTreeRootName" } },
            { "name", zindex = 10 },
          },
          directory = {
            { "indent", with_markers = false, indent_size = 0 },
            { "icon" },
            { "name" },
          },
          file = {
            { "indent", with_markers = false, indent_size = 0 },
            { "icon" },
            { "name", use_git_status_colors = true },
          },
        },
      },
      window = {
        position = "left",
        width = 32,
        mappings = {
          ["<"] = function() require("config.sidebar_tabs").cycle(-1) end,
          [">"] = function() require("config.sidebar_tabs").cycle(1) end,
          ["l"] = "open",
          ["h"] = "close_node",
          ["<space>"] = "none",
        },
      },
    },
    config = function(_, opts)
      -- Fix upstream Neo-tree re-entrancy bug in renderer.position.restore where
      -- focus_node -> expand_to_node -> render_tree -> restore causes infinite recursion / stack overflow.
      local renderer = require("neo-tree.ui.renderer")
      local orig_restore = renderer.position.restore
      renderer.position.restore = function(state)
        if state and state.position and state.position.node_id then
          local node_id = state.position.node_id
          state.position.node_id = nil
          if state.position.topline and state.position.lnum then
            pcall(vim.api.nvim_win_call, state.winid, function()
              vim.fn.winrestview({ topline = state.position.topline, lnum = state.position.lnum })
            end)
          end
          local log = require("neo-tree.log")
          log.debug("Focusing on node_id:", node_id)
          renderer.focus_node(state, node_id, true)
          renderer.position.restore_selection(state)
          renderer.position.clear(state)
          return
        end
        return orig_restore(state)
      end

      -- Guard nui.utils.render_lines against strings containing newlines passed to nvim_buf_set_lines
      local ok_nui, nui_utils = pcall(require, "nui.utils")
      if ok_nui and nui_utils and nui_utils.render_lines then
        local orig_render_lines = nui_utils.render_lines
        nui_utils.render_lines = function(lines, bufnr, ns_id, linenr_start, linenr_end, byte_start, byte_end)
          local orig_buf_set_lines = vim.api.nvim_buf_set_lines
          local orig_buf_set_text = vim.api.nvim_buf_set_text
          local function sanitize(arr)
            for i, s in ipairs(arr) do
              if type(s) == "string" and s:find("[\r\n]") then
                arr[i] = s:gsub("\r", ""):gsub("\n", " ")
              end
            end
            return arr
          end

          vim.api.nvim_buf_set_lines = function(b, s, e, strict, replacement)
            return orig_buf_set_lines(b, s, e, strict, sanitize(replacement))
          end
          vim.api.nvim_buf_set_text = function(b, sr, sc, er, ec, replacement)
            return orig_buf_set_text(b, sr, sc, er, ec, sanitize(replacement))
          end

          local ok, res = pcall(orig_render_lines, lines, bufnr, ns_id, linenr_start, linenr_end, byte_start, byte_end)
          vim.api.nvim_buf_set_lines = orig_buf_set_lines
          vim.api.nvim_buf_set_text = orig_buf_set_text
          if not ok then
            error(res)
          end
          return res
        end
      end

      require("neo-tree").setup(opts)
    end,
  },
}
