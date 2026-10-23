"""Verify the file picker shows its hidden/ignored toggle state.
Run: python3 tests/snacks_picker_flags_spec.py (uses the real config and an attached UI)."""
from pathlib import Path
import time
import pynvim

root = Path(__file__).resolve().parents[1]
nvim = pynvim.attach('child', argv=['nvim', '--embed'])
try:
    nvim.ui_attach(140, 40, rgb=True)
    nvim.exec_lua("require('auto-session.config').enabled=false")
    nvim.exec_lua("vim.wait(400)")
    nvim.exec_lua("pcall(function() require('neo-tree.command').execute({action='close'}) end)")
    nvim.command('silent! only')
    nvim.command('lcd ' + nvim.funcs.fnameescape(str(root)))
    nvim.exec_lua("require('snacks').picker.pick('files')")
    nvim.exec_lua('''
      vim.wait(1000, function()
        return #require('snacks.picker.core.picker').get({}) > 0
      end)
    ''')
    time.sleep(0.2)
    nvim.command('redraw')

    def title_text():
        return nvim.exec_lua('''
          local p = require('snacks.picker.core.picker').get({})[1]
          assert(p and p.input and p.input.win, 'file picker is not open')
          local t = p.input.win.opts.title
          assert(type(t) == 'table', 'picker title is not set')
          local out = {}
          for _, chunk in ipairs(t) do out[#out + 1] = chunk[1] end
          return table.concat(out)
        ''')

    def toggle(action):
        nvim.exec_lua('''
          local p = require('snacks.picker.core.picker').get({})[1]
          assert(p, 'file picker is not open')
          p:action(...)
        ''', action)
        time.sleep(0.2)
        nvim.command('redraw')

    initial = title_text()
    assert 'Hidden OFF' in initial, initial
    assert 'Ignored OFF' in initial, initial
    toggle('toggle_hidden')
    hidden = title_text()
    assert 'Hidden ON' in hidden and 'Ignored OFF' in hidden, hidden
    toggle('toggle_ignored')
    both = title_text()
    assert 'Hidden ON' in both and 'Ignored ON' in both, both
    toggle('toggle_hidden')
    ignored_only = title_text()
    assert 'Hidden OFF' in ignored_only and 'Ignored ON' in ignored_only, ignored_only
    print('snacks_picker_flags_spec: OK')
finally:
    try:
        nvim.command('qa!')
    except (EOFError, OSError):
        pass
