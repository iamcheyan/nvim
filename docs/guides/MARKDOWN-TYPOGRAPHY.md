# Neovim Markdown Typography — Blue Palette

This adds a Typora-like reading surface for `FileType=markdown` while keeping the
configured global Blue colorscheme as the source of the accent colors and leaving
COBOL, shell, Lua, SQL, and other buffers unchanged.

## Design

The Markdown page uses warm paper (`#faf9f5`) and book-text ink (`#303030`) for
long-form reading. Blue's active cursor-line accent (`#005faf`), deep navy
background identity (`#000087`), and cyan UI accent (`#008787`) carry into heading
hierarchy, links, list markers, and quote rules. H1 through H6 descend in size and
weight through color, bold and italic emphasis.

Inline code uses a soft warm-gray chip (`#ebe8df`) and muted red text. Fenced code
keeps a dark Blue-night-like panel (`#202536`) with pale text, so code remains
visually distinct from prose. Quotes use a quiet left marker and italic gray text;
links are underlined; list and task markers use Blue cyan and a restrained green
for completed items. Tables use normal readable text and soft separators.

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
