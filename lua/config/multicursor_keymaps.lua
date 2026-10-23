local M = {}

-- Reapply mappings without rerunning mc.setup() or registering another layer.
function M.apply(mc)
  local map = require("config.reload").mapper("multicursor")
  for _, lhs in ipairs({ "<leader>n", "<leader>N" }) do
    for _, mode in ipairs({ "n", "x" }) do
      local old = vim.fn.maparg(lhs, mode, false, true)
      if old.desc == "Add cursor to next match" or old.desc == "Add cursor to previous match" then
        pcall(vim.keymap.del, mode, lhs)
      end
    end
  end
  map({ "n", "x" }, "<leader><up>", function() mc.lineSkipCursor(-1) end, { desc = "Add cursor on previous line" })
  map({ "n", "x" }, "<leader><down>", function() mc.lineSkipCursor(1) end, { desc = "Add cursor on next line" })
  map({ "n", "x" }, "<leader>mn", function() mc.matchAddCursor(1) end, { desc = "Add cursor to next match" })
  map({ "n", "x" }, "<leader>mN", function() mc.matchAddCursor(-1) end, { desc = "Add cursor to previous match" })
  map({ "n", "x" }, "<M-d>", function() mc.matchSkipCursor(1) end, { desc = "Skip next match" })
  map({ "n", "x" }, "<M-D>", function() mc.matchSkipCursor(-1) end, { desc = "Skip previous match" })
  map({ "n", "x" }, "<C-n>", function() mc.matchAddCursor(1) end, { desc = "Add cursor to next match" })
  map({ "n", "x" }, "<C-S-n>", mc.matchAllAddCursors, { desc = "Add cursor to every match" })
  map({ "n", "x" }, "ga", mc.addCursorOperator, { desc = "Add cursor with operator" })
  map("n", "<leader>A", mc.alignCursors, { desc = "Align cursors" })
  map("n", "<leader>gv", mc.restoreCursors, { desc = "Restore cursors" })
  map({ "n", "x" }, "<leader>mq", mc.toggleCursor, { desc = "Toggle multicursor mode" })
  map("n", "<c-leftmouse>", mc.handleMouse)
  map("n", "<c-leftdrag>", mc.handleMouseDrag)
  map("n", "<c-leftrelease>", mc.handleMouseRelease)
end

return M
