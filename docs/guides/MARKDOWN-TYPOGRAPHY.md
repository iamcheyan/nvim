# Neovim Markdown Typography — Delek Light Palette

This adds a clean, comfortable reading surface for `FileType=markdown` inspired
by the classic `delek` theme while keeping the configured global Blue colorscheme
for all controls, sidebars, and non-Markdown buffers.

## Design

The Markdown page uses pure white (`#ffffff`) and deep black ink (`#000000`) for
crisp, effortless document editing. Window highlights, cursors, line numbers,
search highlights, and headings follow `delek`:
- Cursor: black block on white paper (`#000000` / `#ffffff`)
- Line numbers: `delek` brown (`#a52a2a`)
- Cursor line: subtle soft gray (`#e4e4e4`)
- Selection: light gray (`#d0d0d0`)
- Search: magenta/white (`#cd00cd` / `#ffffff`)
- Headings: magenta (`#cd00cd`), blue (`#0000ff`), cyan (`#008b8b`), pink (`#ff1493`), green (`#008700`), brown (`#a52a2a`)
- Blockquotes: italic comment red (`#ee0000`)
- Links: blue with underline (`#0000ff`)
- Inline code: fresh green constant (`#008700`) on subtle gray (`#e8e8e8`)
- Fenced code block: clean light panel (`#f4f4f4`) with dark text

## Files and activation

- `lua/config/markdown_typography.lua` defines the palette, Treesitter captures,
  legacy Markdown syntax groups, Markview highlight groups, and the per-window
  lifecycle.
- `lua/config/lazy.lua` loads the module as part of the normal config.
- A `FileType=markdown` autocmd installs a window-local highlight namespace and
  `winhighlight` mappings. `BufWinEnter` and `WinEnter` restore it when reopening
  or switching among Markdown windows.
- `BufWinLeave` and `WinClosed` clear the local namespace when a window stops
  showing Markdown. The original Blue syntax groups are restored after the last
  Markdown window closes or switches away.
- Treesitter headings, inline code, fenced code, quotes, lists, links, task lists,
  tables and emphasis receive explicit captures. Existing `nvim-treesitter` and
  `markview.nvim` integrations are reused; no rendering plugin was added.

The highlight namespace is attached with `nvim_win_set_hl_ns`, while
`winhighlight` maps editor UI surfaces to names in that namespace. This keeps the
paper background and UI accents local to Markdown windows. Markdown syntax
captures are global Neovim groups, so the module snapshots their Blue definitions
and restores them when no Markdown window remains. Window-local colors do not
rewrite the buffer or modify the active global colorscheme.

## Example

```markdown
# COBOL

## REDEFINES

> 同じメモリを別の形式で参照します

`MOVE CUSTOMER TO OUTPUT`

- item1
- [x] completed item

| Field | Meaning |
|:--|:--|
| NAME | customer name |
```

This should read like a document: a clear navy H1, Blue H2, a quiet italic quote,
a warm inline-code chip, indented list markers, and a dark fenced-code surface
when a block is present.

## Verify

Run the isolated Blue palette and lifecycle regression:

```sh
nvim --headless -u NONE -i NONE -l tests/markdown_typography_spec.lua
```

It checks warm paper and ink in the Markdown window namespace, Treesitter
heading/code captures, Markdown enter/leave cleanup, multi-window behavior, and
that global Blue `Normal`, `Statement`, and heading highlights survive unchanged
for non-Markdown buffers.
