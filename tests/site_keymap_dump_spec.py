"""The generated Lua keymap exporter must produce a readable TSV file."""
from pathlib import Path
import os
import runpy
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='nvim-keymap-dump-') as temp:
    script = Path(temp) / 'dump.lua'
    output = Path(temp) / 'keys.tsv'
    script.write_text("vim.g.mapleader = ' '\n" + runpy.run_path(str(root / 'site/build.py'))['DUMP_LUA'])
    result = subprocess.run(
        ['nvim', '--headless', '-u', 'NONE', '-l', str(script)],
        env={**os.environ, 'NVIM_DUMP_CONFIG': str(root), 'KEYMAP_DUMP': str(output)},
        capture_output=True, text=True, timeout=15,
    )
    assert result.returncode == 0, result.stderr
    rows = [line.split('\t') for line in output.read_text().splitlines()]
    assert rows and all(len(row) == 3 for row in rows), 'export must use real TSV delimiters'
    assert any(row[0].startswith('<leader>') for row in rows), 'configured keys missing'
print('site_keymap_dump_spec: OK')
