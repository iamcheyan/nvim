-- Context-aware indentation for internal and system-clipboard paste.
return {
  {
    "nemanjamalesija/smart-paste.nvim",
    lazy = false,
    config = function()
      local indent_mod = require("smart-paste.indent")
      local heuristics = require("smart-paste.heuristics")

      local function flatten_lines(raw_lines)
        if type(raw_lines) ~= "table" then return {} end
        local res = {}
        for _, item in ipairs(raw_lines) do
          local str = tostring(item):gsub("\r$", ""):gsub("\r\n", "\n")
          local parts = vim.split(str, "\n", { plain = true })
          for _, part in ipairs(parts) do
            table.insert(res, part)
          end
        end
        return res
      end

      local function strip_trailing_blank_lines(lines)
        if type(lines) ~= "table" then return {} end
        local result = vim.deepcopy(lines)
        while #result > 1 and result[#result] == "" do
          table.remove(result)
        end
        return result
      end

      local function clipboard_lines(reg)
        reg = (reg and reg ~= "") and reg or "+"
        local info = vim.fn.getreginfo(reg)
        local raw = info and info.regcontents
        if not raw or (type(raw) == "table" and #raw == 0) then
          local text = vim.fn.getreg(reg)
          if text and text ~= "" then
            raw = { text }
          end
        end
        if type(raw) ~= "table" or #raw == 0 then
          if reg ~= "+" then
            return clipboard_lines("+")
          end
          return nil, "v"
        end
        local lines = strip_trailing_blank_lines(flatten_lines(raw))
        local regtype = (info and info.regtype) or "v"
        return lines, regtype
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
        return indent_mod.apply_delta(lines, target - source, bufnr)
      end

      local function resolve_target_indent(bufnr, row, after, current_line)
        local line_count = vim.api.nvim_buf_line_count(bufnr)
        if line_count <= 0 then return 0 end

        if current_line:match("^%s*$") then
          return indent_mod.get_target_indent(bufnr, row)
        end

        local function row_indent(r)
          local l = vim.api.nvim_buf_get_lines(bufnr, r, r + 1, false)[1] or ""
          if l:match("^%s*$") then
            return indent_mod.get_target_indent(bufnr, r), l
          end
          return vim.fn.strdisplaywidth(l:match("^(%s*)") or ""), l
        end

        local current_indent = vim.fn.strdisplaywidth(current_line:match("^(%s*)") or "")
        local sw = vim.bo[bufnr].shiftwidth > 0 and vim.bo[bufnr].shiftwidth or vim.bo[bufnr].tabstop
        if after then
          local next_row = row + 1
          if next_row < line_count and heuristics.is_scope_opener(current_line, bufnr) then
            local next_indent, next_line = row_indent(next_row)
            if next_indent > current_indent then
              return next_indent
            elseif next_line:match("^%s*$") or (heuristics.is_scope_closer(next_line, bufnr) and next_indent <= current_indent) then
              return current_indent + sw
            else
              return current_indent
            end
          else
            return current_indent
          end
        else
          local prev_row = row - 1
          if prev_row >= 0 and heuristics.is_scope_closer(current_line, bufnr) then
            local prev_indent, prev_line = row_indent(prev_row)
            if prev_indent > current_indent then
              return prev_indent
            elseif prev_line:match("^%s*$") or (heuristics.is_scope_opener(prev_line, bufnr) and prev_indent <= current_indent) then
              return current_indent + sw
            else
              return current_indent
            end
          else
            return current_indent
          end
        end
      end

      local op_state = {}

      local function execute_smart_paste(reg, count, after)
        local lines, regtype = clipboard_lines(reg)
        if not lines or #lines == 0 then return end

        local bufnr = vim.api.nvim_get_current_buf()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local line_count = vim.api.nvim_buf_line_count(bufnr)
        local row = math.max(0, math.min(cursor[1] - 1, line_count - 1))
        local current_line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""

        local is_multiline = #lines > 1 or vim.startswith(regtype, "V")

        if is_multiline or current_line:match("^%s*$") then
          local target = resolve_target_indent(bufnr, row, after, current_line)
          local adjusted = flatten_lines(align(lines, target, bufnr))

          local final_lines = {}
          for _ = 1, count do
            for _, l in ipairs(adjusted) do
              table.insert(final_lines, l)
            end
          end

          if current_line:match("^%s*$") then
            vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, final_lines)
            vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
          else
            vim.api.nvim_put(final_lines, "l", after, false)
          end
        else
          local raw_keys = '"' .. reg .. tostring(count) .. (after and "p" or "P")
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(raw_keys, true, false, true), "n", false)
        end
      end

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

      -- Native bracketed paste hook (terminal paste via Ctrl-Shift-V / Cmd-V)
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

      local function paste_visual_clipboard()
        local mode = vim.fn.mode()
        local lines = clipboard_lines(vim.v.register)
        if not lines then return end

        if mode == "V" then
          vim.cmd.normal({ args = { "\27" }, bang = true })
          local first = vim.api.nvim_buf_get_mark(0, "<")[1]
          local last = vim.api.nvim_buf_get_mark(0, ">")[1]
          if first <= 0 or last <= 0 then return end
          if first > last then first, last = last, first end
          local bufnr = vim.api.nvim_get_current_buf()
          local row = first - 1
          local target = require("smart-paste.indent").get_target_indent(bufnr, row)
          local adjusted = flatten_lines(align(lines, target, bufnr))
          vim.api.nvim_buf_set_lines(bufnr, row, last, false, adjusted)
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
          local bufnr = vim.api.nvim_get_current_buf()
          local source = vim.api.nvim_buf_get_lines(bufnr, srow, srow + 1, false)[1] or ""
          local target = vim.fn.strdisplaywidth(source:match("^%s*") or "")
          local adjusted = align(lines, target, bufnr)
          local last_line = vim.api.nvim_buf_get_lines(bufnr, erow, erow + 1, false)[1] or ""
          local end_col = vim.str_byteindex(last_line, vim.str_utfindex(last_line, ecol) + 1)
          local before_selection = source:sub(1, scol)
          if before_selection:match("^%s*$") then
            scol = 0
          else
            adjusted[1] = adjusted[1]:gsub("^%s*", "")
          end
          adjusted = flatten_lines(adjusted)
          vim.api.nvim_buf_set_text(bufnr, srow, scol, erow, end_col, adjusted)
          vim.api.nvim_win_set_cursor(0, { srow + #adjusted, #adjusted[#adjusted] })
          return
        end
        -- Blockwise selections retain native replacement semantics.
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('gv"+P', true, false, true), "n", false)
      end

      require("smart-paste").paste_clipboard_visual = paste_visual_clipboard

      -- Unified keymaps: p, P, <C-v>, <leader>p use the same smart paste engine!
      vim.keymap.set("n", "p", function() return trigger_smart_paste(true) end, { expr = true, desc = "Smart paste after" })
      vim.keymap.set("n", "P", function() return trigger_smart_paste(false) end, { expr = true, desc = "Smart paste before" })
      vim.keymap.set("n", "<leader>p", function() return trigger_smart_paste(true) end, { expr = true, desc = "Smart paste block" })
      vim.keymap.set("n", "<C-v>", function() return trigger_smart_paste(true) end, { expr = true, desc = "Smart paste block" })

      vim.keymap.set("x", "p", paste_visual_clipboard, { desc = "Smart paste over selection" })
      vim.keymap.set("x", "P", paste_visual_clipboard, { desc = "Smart paste over selection" })
      vim.keymap.set("x", "<C-v>", paste_visual_clipboard, { desc = "Smart paste clipboard over selection" })
      vim.keymap.set("x", "<Plug>(smart-paste-clipboard-visual)", paste_visual_clipboard, { desc = "Smart paste clipboard over selection" })

      vim.keymap.set("i", "<Plug>(smart-paste-clipboard-insert)", function()
        local lines = clipboard_lines("+")
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
        local flat_adjusted = flatten_lines(adjusted)
        vim.api.nvim_buf_set_lines(bufnr, row - 1, row, false, flat_adjusted)
        vim.api.nvim_win_set_cursor(0, { row + #flat_adjusted - 1, #flat_adjusted[#flat_adjusted] - #suffix })
      end, { desc = "Smart paste system clipboard block" })
    end,
  },
}
