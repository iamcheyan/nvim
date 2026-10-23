"""Verify selected Neo-tree rows stay continuous through expander padding."""
import time
import pynvim

nvim = pynvim.attach('child', argv=['nvim', '--embed'])
try:
    nvim.ui_attach(140, 40, rgb=True)
    time.sleep(1)
    nvim.command('lcd ' + nvim.funcs.getcwd())
    nvim.command('Neotree filesystem reveal=false')
    time.sleep(1)
    win = nvim.exec_lua('return require("neo-tree.sources.manager").get_state("filesystem").winid')
    assert win, 'Neo-tree did not open'
    row = nvim.exec_lua('''local win = ...
      local state = require("neo-tree.sources.manager").get_state("filesystem")
      local node, line = state.tree:get_node(vim.fn.getcwd() .. "/config")
      if not node then return nil end
      vim.api.nvim_set_current_win(win)
      vim.api.nvim_win_set_cursor(win, {line, 0})
      return line''', win)
    assert row, 'Expected config directory row was not rendered'
    time.sleep(.2)
    nvim.command('redraw')
    result = nvim.exec_lua('''local win, row = ...
      local pos = vim.api.nvim_win_get_position(win)
      local screen_row = pos[1] + row + 1
      local first_col = pos[2] + 2
      local cells = {}
      for col = 1, 5 do
        local attr = vim.fn.screenattr(screen_row, first_col + col - 1)
        cells[#cells + 1] = {
          char = vim.fn.screenstring(screen_row, first_col + col - 1),
          fg = vim.fn.synIDattr(attr, "fg#"),
        }
      end
      return cells''', win, row)
    groups = nvim.exec_lua('''local r = {}
      for _, name in ipairs({ "NeoTreeExpander", "NeoTreeIndentMarker", "NeoTreeDimText" }) do
        r[name] = vim.api.nvim_get_hl(0, { name = name, link = false })
      end
      return r''')
    for name, attrs in groups.items():
        assert 'bg' not in attrs, f'{name} must not mask the selected row: {attrs!r}'
    print(f'neo_tree_selection_highlight_spec: OK {result!r}')
finally:
    try:
        nvim.command('qa!')
    except (EOFError, OSError):
        pass
