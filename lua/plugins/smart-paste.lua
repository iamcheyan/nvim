-- Context-aware indentation for internal and system-clipboard paste.
return {
  {
    "nemanjamalesija/smart-paste.nvim",
    config = function()
      require("smart-paste").setup()

      -- External clipboard registers are often characterwise. Keep their
      -- relative indentation intact while rebasing the block to this line.
      local function clipboard_lines()
        local info = vim.fn.getreginfo("+")
        local lines = info and info.regcontents
        if type(lines) ~= "table" or #lines == 0 then return nil end
        lines = vim.deepcopy(lines)
        for i, line in ipairs(lines) do lines[i] = line:gsub("\r$", "") end
        if #lines > 1 and lines[#lines] == "" then table.remove(lines) end
        return lines
      end

      -- Characterwise yanks omit whitespace before the first selected byte.
      -- Remember that missing prefix instead of guessing from nested lines.
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

      local function align(lines, target, bufnr)
        local indent = require("smart-paste.indent")
        lines = vim.deepcopy(lines)
        if last_yank and vim.deep_equal(lines, last_yank.lines) then
          lines[1] = last_yank.prefix .. lines[1]
        elseif vim.bo[bufnr].filetype == "cobol" and lines[1]:match("^%S") then
          -- External characterwise copies have no yank metadata. A matching
          -- COBOL END-verb supplies the opener's original base indentation.
          local verb = lines[1]:match("^([%a%-]+)")
          if verb then
            for i = #lines, 2, -1 do
              local whitespace, ending = lines[i]:match("^(%s*)(END%-[%a%-]+)")
              if ending == "END-" .. verb:upper() then
                lines[1] = whitespace .. lines[1]
                break
              end
            end
          end
        end
        -- External clipboard text may start inside a nested block. Use the
        -- block's shallowest nonblank line as its baseline, not line one.
        local source = math.huge
        for _, line in ipairs(lines) do
          if line:match("%S") then
            source = math.min(source, vim.fn.strdisplaywidth(line:match("^%s*") or ""))
          end
        end
        if source == math.huge then source = 0 end
        return indent.apply_delta(lines, target - source, bufnr)
      end

      -- Terminal/GUI bracketed paste invokes vim.paste, not key mappings.
      -- Rebase the whole payload before the native handler inserts it.
      local native_paste = vim.paste
      local pending
      vim.paste = function(lines, phase)
        local mode = vim.api.nvim_get_mode().mode
        if vim.fn.getcmdtype() ~= "" or vim.bo.buftype == "terminal" then
          return native_paste(lines, phase)
        end
        if phase == 1 then pending = {} end
        if phase ~= -1 then
          pending = pending or {}
          if #pending == 0 then
            pending = vim.deepcopy(lines)
          elseif #lines > 0 then
            pending[#pending] = pending[#pending] .. lines[1]
            for i = 2, #lines do pending[#pending + 1] = lines[i] end
          end
          if phase ~= 3 then return true end
          lines, pending = pending, nil
        end
        if #lines > 1 and (mode:find("^i") or mode == "n") then
          local row, col = unpack(vim.api.nvim_win_get_cursor(0))
          local current = vim.api.nvim_get_current_line()
          local insertion = mode == "n" and math.min(col + 1, #current) or col
          local prefix = current:sub(1, insertion)
          if prefix:match("^%s*$") then
            local target = vim.fn.strdisplaywidth(prefix)
            if target == 0 and current:match("^%s*$") then
              target = require("smart-paste.indent").get_target_indent(0, row - 1)
            end
            lines = align(lines, target, vim.api.nvim_get_current_buf())
            -- The native handler retains the destination prefix on line one.
            lines[1] = require("smart-paste.indent").apply_delta(
              { lines[1] }, -vim.fn.strdisplaywidth(prefix), vim.api.nvim_get_current_buf()
            )[1]
          end
        end
        return native_paste(lines, -1)
      end

      local function paste_clipboard_block()
        local lines = clipboard_lines()
        if not lines then return end
        local bufnr = vim.api.nvim_get_current_buf()
        local row = vim.api.nvim_win_get_cursor(0)[1] - 1
        local target = require("smart-paste.indent").get_target_indent(bufnr, row)
        vim.api.nvim_put(align(lines, target, bufnr), "l", true, false)
      end

      local function paste_visual_clipboard()
        local mode = vim.fn.mode()
        if mode == "V" then
          local lines = clipboard_lines()
          if not lines then return end
          vim.cmd.normal({ args = { "\27" }, bang = true })
          local first = vim.api.nvim_buf_get_mark(0, "<")[1]
          local last = vim.api.nvim_buf_get_mark(0, ">")[1]
          if first <= 0 or last <= 0 then return end
          if first > last then first, last = last, first end
          local bufnr = vim.api.nvim_get_current_buf()
          local row = first - 1
          local target = require("smart-paste.indent").get_target_indent(bufnr, row)
          vim.api.nvim_buf_set_lines(bufnr, row, last, false, align(lines, target, bufnr))
          vim.api.nvim_win_set_cursor(0, { first, 0 })
          return
        end
        if mode == "v" then
          local anchor = vim.fn.getpos("v")
          local cursor = vim.api.nvim_win_get_cursor(0)
          local arow, acol = anchor[2] - 1, anchor[3] - 1
          local crow, ccol = cursor[1] - 1, cursor[2]
          local srow, scol, erow, ecol = arow, acol, crow, ccol
          if srow > erow or (srow == erow and scol > ecol) then
            srow, scol, erow, ecol = erow, ecol, srow, scol
          end
          vim.cmd.normal({ args = { "\27" }, bang = true })
          local lines = clipboard_lines()
          if not lines then return end
          local bufnr = vim.api.nvim_get_current_buf()
          local source = vim.api.nvim_buf_get_lines(bufnr, srow, srow + 1, false)[1] or ""
          local target = vim.fn.strdisplaywidth(source:match("^%s*") or "")
          local adjusted = align(lines, target, bufnr)
          local last_line = vim.api.nvim_buf_get_lines(bufnr, erow, erow + 1, false)[1] or ""
          local end_col = vim.str_byteindex(last_line, vim.str_utfindex(last_line, ecol) + 1)
          local before_selection = source:sub(1, scol)
          if before_selection:match("^%s*$") then
            -- Replace indentation too, so the first pasted row shares the
            -- same base column as every following row.
            scol = 0
          else
            adjusted[1] = adjusted[1]:gsub("^%s*", "")
          end
          vim.api.nvim_buf_set_text(bufnr, srow, scol, erow, end_col, adjusted)
          vim.api.nvim_win_set_cursor(0, { srow + #adjusted, #adjusted[#adjusted] })
          return
        end
        -- Blockwise selections retain native replacement semantics.
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('gv"+P', true, false, true), "n", false)
      end

      require("smart-paste").paste_clipboard_visual = paste_visual_clipboard
      vim.keymap.set("n", "<leader>p", paste_clipboard_block, { desc = "Smart paste system clipboard block" })
      vim.keymap.set("n", "<C-v>", paste_clipboard_block, { desc = "Smart paste system clipboard block" })
      vim.keymap.set("x", "<Plug>(smart-paste-clipboard-visual)", paste_visual_clipboard, {
        desc = "Smart paste clipboard over selection",
      })

      vim.keymap.set("i", "<Plug>(smart-paste-clipboard-insert)", function()
        local lines = clipboard_lines()
        if not lines then return end
        if #lines == 1 then
          vim.api.nvim_paste(lines[1], false, -1)
          return
        end
        local bufnr = vim.api.nvim_get_current_buf()
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        local current = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ""
        local prefix, suffix = current:sub(1, col), current:sub(col + 1)
        local adjusted
        if current:match("^%s*$") then
          local target = vim.fn.strdisplaywidth(current)
          if target == 0 then
            target = require("smart-paste.indent").get_target_indent(bufnr, row - 1)
          end
          adjusted = align(lines, target, bufnr)
        else
          local target = vim.fn.strdisplaywidth(prefix:match("^%s*") or "")
          adjusted = align(lines, target, bufnr)
          if prefix:match("^%s*$") then adjusted[1] = adjusted[1]:gsub("^%s*", "") end
          adjusted[1] = prefix .. adjusted[1]
          adjusted[#adjusted] = adjusted[#adjusted] .. suffix
        end
        vim.api.nvim_buf_set_lines(bufnr, row - 1, row, false, adjusted)
        vim.api.nvim_win_set_cursor(0, { row + #adjusted - 1, #adjusted[#adjusted] - #suffix })
      end, { desc = "Smart paste system clipboard block" })
    end,
  },
}
