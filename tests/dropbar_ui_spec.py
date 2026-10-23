"""Run: python3 tests/dropbar_ui_spec.py (uses the real config and an attached UI)."""
from pathlib import Path
import time
import os
import json
import pynvim

root = Path(__file__).resolve().parents[1]
argv = ['nvim', '--embed']
if os.environ.get('NVIM_PLUGIN_DEV_ROOT'):
    source = Path(os.environ['NVIM_PLUGIN_DEV_ROOT'])/'cobol.nvim/lua/cobol/dropbar.lua'
    argv += ['--cmd', 'lua package.preload["cobol.dropbar"]=function() return dofile(' + json.dumps(str(source)) + ') end']
nvim = pynvim.attach('child', argv=argv)
try:
    nvim.ui_attach(140, 40, rgb=True)
    nvim.exec_lua("require('auto-session.config').enabled=false")
    # The sidebar restore scheduled by VeryLazy can still reopen Neo-tree after
    # this point. Let it settle, then start from a clean layout; otherwise the
    # sidebar changes the winbar budget and split widths.
    nvim.exec_lua("vim.wait(400)")
    nvim.exec_lua("pcall(function() require('neo-tree.command').execute({action='close'}) end)")
    nvim.command('silent! only')
    nvim.command('lcd ' + nvim.funcs.fnameescape(str(root/'tests/fixtures/context')))
    def screen():
        time.sleep(0.15)
        nvim.command('redraw')
        return nvim.exec_lua('''local rows = {}
          for row=1,vim.o.lines do
            local cells={}
            for col=1,vim.o.columns do cells[#cells+1]=vim.fn.screenstring(row,col) end
            rows[#rows+1]=table.concat(cells)
          end
          return rows''')
    def open_file(relative):
        nvim.command('edit ' + nvim.funcs.fnameescape(str(root/'tests/fixtures/context'/relative)))
    def check_bar(label):
        rows = screen()
        # Bufferline is optional and loads asynchronously; find the bar row
        # instead of assuming it is always the first screen line.
        bar = next((r for r in rows[:3] if label in r), None)
        assert bar, f'Visible winbar missing {label}: {rows[:3]!r}'
        assert bar.startswith(' ') and not bar.startswith('  '), f'Winbar needs one cell of left padding: {bar!r}'
    for _ in range(3):
        open_file('examples/python/night_report.py')
        nvim.current.window.cursor = (4, 10)
        nvim.input('j')
        check_bar('NightReport')
        open_file('src/cobol/NIGHTSETTLE.COB')
        nvim.current.window.cursor = (13, 15)
        nvim.input('j')
        check_bar('PROCEDURE DIVISION')
        assert '󰌗' in screen()[1]
    nvim.command('vsplit ' + nvim.funcs.fnameescape(str(root/'tests/fixtures/context/examples/python/night_report.py')))
    nvim.current.window.cursor = (4, 10)
    nvim.input('j')
    rows = screen()
    assert 'NightReport' in rows[1] and 'IF WS-STATUS' in rows[1], rows[1]
    nvim.command('wincmd w')
    nvim.input('k')
    rows = screen()
    assert 'NightReport' in rows[1] and 'IF WS-STATUS' in rows[1], rows[1]
    nvim.command('silent! only')
    nvim.command('lcd ' + nvim.funcs.fnameescape(str(root/'tests/fixtures/context')))
    open_file('examples/python/night_report.py')
    nvim.current.window.cursor = (4, 10)
    nvim.input('j')
    check_bar('NightReport')
    # The input pipeline must update symbols while editing, before leaving Insert.
    nvim.current.window.cursor = (3, 6)
    nvim.input('cwEditedReport')
    time.sleep(0.15)
    assert 'EditedReport' in screen()[1], screen()[1]
    nvim.input('\x1b')
    nvim.command('set nomodified')
    print('dropbar_ui_spec: OK (switches, splits, left alignment, icons, Insert updates)')
finally:
    try:
        nvim.command('qa!')
    except (EOFError, OSError):
        pass