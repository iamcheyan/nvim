local M = {}
local cache = {}
local hidden = {
  ['neo-tree']=true, NvimTree=true, aerial=true, help=true, lazy=true, mason=true,
  Trouble=true, snacks_layout_box=true, qf=true, csv=true, tsv=true, text=true,
  txt=true,
  checkhealth=true, man=true, dropbar_menu=true, dropbar_menu_fzf=true, local_popup_menu=true,
}
local structural = {}
for kind in ([[class_definition function_definition async_function_definition type_alias_statement
  class_declaration interface_declaration type_alias_declaration enum_declaration enum_assignment
  method_definition public_field_definition property_signature function_declaration
  constructor_declaration method_declaration field_declaration record_declaration type_spec
  class module method singleton_method mod_item struct_item enum_item trait_item impl_item
  class_specifier struct_specifier enum_specifier document element cte
  paragraph section program_id_division identification_division environment_division data_division
  procedure_division if_statement case_statement]]):gmatch('%S+') do structural[kind] = true end

local function text(node, buf)
  return node and vim.treesitter.get_node_text(node, buf):gsub('%s+', ' '):sub(1, 100) or ''
end
local function descendant(node, kind)
  if node:type() == kind then return node end
  for child in node:iter_children() do
    if type(child) == 'userdata' then
      local found = descendant(child, kind)
      if found then return found end
    end
  end
end
local assignment_kinds = {
  assignment = true, field_declaration = true, public_field_definition = true,
  property_signature = true, pair = true, block_mapping_pair = true,
}

local function role(node, buf)
  local kind = node:type()
  if kind == 'document' then return 'module', '' end
  if kind == 'section' then return 'module', '󰉫' end
  if kind == 'element' then return 'class', '󰅴' end
  if kind == 'cte' then return 'module', '󰆼' end
  if kind:find('class') then return 'class', '󰌗' end
  if kind == 'pair' or kind == 'block_mapping_pair' then return 'field', '󰌋' end
  if kind == 'object' then return 'module', '󰌋' end
  if kind:find('struct') or kind:find('interface') or kind:find('enum') or kind:find('record') then return 'class', '󰠱' end
  if kind:find('function') or kind:find('method') or kind:find('paragraph') then
    local parent = node:parent()
    if parent and parent:type() == 'decorated_definition' then return 'property', '󰅪' end
    if kind == 'method_declaration' or kind == 'method_definition' then return 'function', '󰆧' end
    local scope = parent
    while scope and not scope:type():find('class') and not scope:type():find('struct') do scope = scope:parent() end
    if scope then return 'function', '󰆧' end
    return 'function', '󰊕'
  end
  if assignment_kinds[kind] then return 'field', '󰅪' end
  return 'symbol', '󰅩'
end
local selected

local function inside_structural(node)
  local parent = node:parent()
  while parent do
    if selected(parent) then return true end
    parent = parent:parent()
  end
  return false
end

selected = function(node)
  if not node:named() then return false end
  local kind = node:type()
  if kind == 'document' then return true end
  if kind == 'object' then return node:parent() ~= nil and node:parent():type() == 'pair' end
  if structural[kind] then return true end
  return assignment_kinds[kind] == true and inside_structural(node)
end
local function name(node, buf)
  local kind = node:type()
  if kind == 'document' then return '' end
  if kind == 'object' then
    local parent = node:parent()
    if parent and parent:type() == 'pair' then
      local key = parent:field('key')[1]
      return key and text(key:named_child(0) or key, buf) or ''
    end
    return ''
  end
  if kind == 'block_mapping_pair' then
    local key = node:field('key')[1]
    return key and text(key, buf) or text(node, buf)
  end
  if kind:find('heading') then
    local heading = descendant(node, 'inline') or descendant(node, 'heading_content')
    if heading then return text(heading, buf) end
  end
  if kind == 'section' then
    local heading = descendant(node, 'atx_heading') or descendant(node, 'setext_heading')
    local content = heading and descendant(heading, 'inline')
    return content and text(content, buf) or ''
  end
  local candidate
  if kind:find('function') or kind:find('method') then
    candidate = node:field('name')[1] or descendant(node, 'property_identifier') or descendant(node, 'identifier')
    if candidate and kind == 'method_declaration' then
      local receiver = node:field('receiver')[1]
      local receiver_type = receiver and descendant(receiver, 'type_identifier')
      if receiver_type then return '(' .. text(receiver_type, buf) .. ').' .. text(candidate, buf) end
    end
  elseif kind:find('class') or kind:find('struct') or kind:find('interface')
    or kind:find('enum') or kind:find('record') then
    candidate = node:field('name')[1] or descendant(node, 'type_identifier') or descendant(node, 'identifier')
  elseif kind == 'cte' then
    local name = descendant(node, 'identifier')
    if name then return text(name, buf) end
  elseif kind == 'element' then
    local tag = descendant(node, 'tag_name')
    if not tag then return text(node, buf) end
    local label = text(tag, buf)
    for child in node:iter_children() do
      if child:type() == 'start_tag' then
        for attr in child:iter_children() do
          if attr:type() == 'attribute' then
            local name = descendant(attr, 'attribute_name')
            local value = descendant(attr, 'attribute_value')
            if name and value then
              local key = text(name, buf)
              if key == 'id' then return label .. '#' .. text(value, buf) end
              if key == 'class' then return label .. '.' .. text(value, buf) end
            end
          end
        end
      end
    end
    return label
  elseif kind == 'pair' then
    local key = node:field('key')[1]
    candidate = key and key:named_child(0) or key
  elseif kind == 'object' then
    local parent = node:parent()
    local key = parent and parent:field('key')[1]
    candidate = key and key:named_child(0) or key
  else
    candidate = node:field('key')[1] or descendant(node, 'string_content')
      or descendant(node, 'name') or descendant(node, 'property_identifier')
      or descendant(node, 'identifier') or descendant(node, 'type_identifier')
  end
  if candidate then return text(candidate, buf) end
  return text(node, buf):match('^[^\n{}]+') or node:type()
end
local function tree(buf)
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local ft = vim.bo[buf].filetype
  local lang = ({sh='bash', zsh='bash'})[ft] or vim.treesitter.language.get_lang(ft)
  if cache[buf] and cache[buf].tick == tick and cache[buf].lang == lang then return cache[buf].items end
  local ok, parser = pcall(vim.treesitter.get_parser, buf, lang)
  if not ok or not parser then return nil end
  local parsed = parser:parse()
  if not parsed[1] then return nil end
  local function visit(node, items)
    for child in node:iter_children() do
      local target = items
      local skip = child ~= nil and child:type() == 'object' and child:parent() ~= nil
        and child:parent():type() == 'pair'
      if child and selected(child) and not skip then
        local sr, sc, er, ec = child:range()
        local label, icon = role(child, buf)
        local item = {name=name(child, buf), kind=child:type(), label=label, icon=icon, children={},
          range={start={line=sr, character=sc}, ['end']={line=er, character=ec}}}
        items[#items+1] = item
        target = item.children
      end
      if child then visit(child, target) end
    end
  end
  local items = {}
  visit(parsed[1]:root(), items)
  cache[buf] = {tick=tick, lang=lang, items=items}
  return items
end

-- Lists stay lazy so native dropbar menus can traverse siblings and children
-- without copying cycles through symbol:merge().
local function symbols(items, buf, win)
  local result = {}
  for index, item in ipairs(items) do
    local symbol = require('dropbar.bar').dropbar_symbol_t:new(setmetatable({
      name=item.name, icon=(item.icon or '') .. ' ', buf=buf, win=win, range=item.range,
      data={kind=item.kind, label=item.label, text=item.name},
      name_hl='DropBarContextText', icon_hl='DropBarContextText',
    }, {__index=function(_, key)
      if key == 'siblings' then return symbols(items, buf, win) end
      if key == 'sibling_idx' then return index end
      if key == 'children' then return symbols(item.children or {}, buf, win) end
    end}))
    result[#result+1] = symbol
  end
  return result
end

local function contains(range, cursor)
  local row, col = cursor[1]-1, cursor[2]
  return (row > range.start.line or (row == range.start.line and col >= range.start.character))
    and (row < range['end'].line or (row == range['end'].line and col < range['end'].character))
end
function M.treesitter_symbols(buf, win, cursor)
  local items = tree(buf) or {}
  local chain = {}
  local function descend(level, depth)
    for index, item in ipairs(level) do
      if contains(item.range, cursor) and item.kind ~= 'paragraph' then
        local only_child = #item.children == 1 and item.children[1]
        local skip_self = (item.kind == 'document' and #item.children > 0
          and item.children[1].kind == 'block_mapping_pair')
          or (item.kind == 'section' and only_child and only_child.kind == 'section')
        if not skip_self then
          chain[depth] = symbols(level, buf, win)[index]
          for deeper = depth + 1, #chain do chain[deeper] = nil end
        end
        if #item.children > 0 then
          descend(item.children, skip_self and depth or depth + 1)
        end
      end
    end
  end
  descend(items, 1)
  return chain
end
function M.should_attach(buf, win)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then return false end
  local ft = vim.bo[buf].filetype
  return not hidden[ft] and vim.bo[buf].buflisted and vim.bo[buf].buftype == ''
end
function M.get_symbols(buf, win, cursor, layout)
  if not M.should_attach(buf, win) then return {} end
  local ft = vim.bo[buf].filetype
  local result
  if ft == 'cobol' or ft == 'cbl' or ft == 'cob' then
    result = require('cobol.dropbar').get_symbols(buf, win, cursor, layout)
  elseif ft == 'batch' or ft == 'dosbatch' then
    result = require('batch.dropbar').get_symbols(buf, win, cursor, layout)
  else
    -- The syntax tree reflects the current edit. Async document symbols can
    -- still describe the previous text and make names/icons flicker on replies.
    result = M.treesitter_symbols(buf, win, cursor)
    if #result == 0 then result = require('dropbar.sources.lsp').get_symbols(buf, win, cursor) end
  end
  if #result == 0 and ft ~= 'cobol' and ft ~= 'cbl' and ft ~= 'cob' then
    result = require('dropbar.sources.treesitter').get_symbols(buf, win, cursor)
  end
  if #result == 0 then
    result = {require('dropbar.bar').dropbar_symbol_t:new({
      name='(root)', icon='󰌗 ', buf=buf, win=win, on_click=false,
    })}
  end
  for _, symbol in ipairs(result) do
    symbol.name_hl, symbol.icon_hl = 'DropBarContextText', 'DropBarContextText'
  end
  if ft ~= 'cobol' and ft ~= 'cbl' and ft ~= 'cob' then
    for _, severity in ipairs({vim.diagnostic.severity.ERROR, vim.diagnostic.severity.WARN}) do
      local count = #vim.diagnostic.get(buf, {severity=severity})
      if count > 0 then
        result[#result+1] = require('dropbar.bar').dropbar_symbol_t:new({
          name=(severity == vim.diagnostic.severity.ERROR and '  ' or '  ') .. count .. ' ',
          icon='', name_hl=severity == vim.diagnostic.severity.ERROR and 'DropBarContextErrorBadge' or 'DropBarContextWarningBadge',
          data={diagnostic=true},
          on_click=function()
            vim.fn.setqflist({}, 'r', {title=severity == vim.diagnostic.severity.ERROR and 'Errors in current buffer' or 'Warnings in current buffer',
              items=vim.diagnostic.toqflist(vim.diagnostic.get(buf, {severity=severity}))})
            vim.cmd.copen()
          end,
        })
      end
    end
  end
  return result
end
-- Native name callbacks close the root menu and jump. Directory names should
-- instead use the indicator callback, preserving the parent menu and editor.
function M.path_menu(menu)
  for _, entry in ipairs(menu and menu.entries or {}) do
    for _, component in ipairs(entry.components) do
      component.name_hl, component.icon_hl = 'DropBarMenuText', 'DropBarMenuText'
    end
    local indicator, label = entry.components[1], entry.components[2]
    local path = label and label.data and label.data.path
    if path and vim.fn.isdirectory(path) == 1 then
      label.on_click = function()
        if type(indicator.on_click) == 'function' then indicator:on_click() end
      end
    end
  end
  if menu and menu.buf then menu:fill_buf() end
end
function M.sources()
  local left_width = 0
  return {
    {get_symbols=function(buf, win, cursor)
      local items = require('dropbar.sources.path').get_symbols(buf, win, cursor)
      local separator = require('dropbar.configs').opts.icons.ui.bar.separator
      local padding=require('dropbar.configs').opts.bar.padding
      left_width = padding.left + padding.right
      for _, symbol in ipairs(items) do
        left_width = left_width + symbol:displaywidth() + vim.fn.strdisplaywidth(separator)
      end
      return items
    end},
    {get_symbols=function(buf, win, cursor)
      return M.get_symbols(buf, win, cursor, {left_width=left_width})
    end},
  }
end

-- Anchor menus to their source symbol, including keyboard-opened menus and
-- inactive splits. The mouse may already be over another window when opened.
function M.menu_col(menu)
  if menu.prev_menu then
    return menu.prev_menu._win_configs.width + (menu.prev_menu.scrollbar and menu.prev_menu.scrollbar.background and 1 or 0)
  end
  local bar = require('dropbar.utils.bar').get({win=menu.prev_win})
  local col = bar and bar.padding.left or 0
  for _, symbol in ipairs(bar and bar.components or {}) do
    if symbol.menu == menu then return col end
    col = col + symbol:displaywidth() + bar.separator:displaywidth()
  end
  return 0
end
function M.menu_row(menu)
  local parent=menu.prev_menu
  if not parent then return 0 end
  local row=parent.clicked_at and parent.clicked_at[1] or 1
  local top=vim.api.nvim_win_call(parent.win,function() return vim.fn.line('w0') end)
  return row-top
end
function M.sync(buf, win)
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  win = win == 0 and vim.api.nvim_get_current_win() or win
  if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_buf(win) ~= buf then return end
  if vim.w[win].dropbar_suspended then return end
  -- Updating a source bar destroys its symbols and their open menus. Keep the
  -- displayed snapshot until navigation finishes, including preview cursors.
  local existing = require('dropbar.utils.bar').get({buf=buf, win=win})
  for _, symbol in ipairs(existing and existing.components or {}) do
    if symbol.menu and symbol.menu.is_opened then return end
  end
  if M.should_attach(buf, win) then
    require('dropbar.utils.bar').attach(buf, win)
    vim.api.nvim_win_call(win, function() _G.dropbar.bars[buf][win]:_update() end)
  elseif vim.wo[win].winbar == '%{%v:lua.dropbar()%}' then
    vim.wo[win].winbar = ''
    if package.loaded['position-ruler'] then require('position-ruler').refresh() end
  end
end
function M.highlights()
  local set=vim.api.nvim_set_hl
  for name, target in pairs({
    DropBarMenuNormalFloat='FreshMenu', DropBarMenuFloatBorder='FreshMenuBorder',
    DropBarMenuCurrentContext='FreshMenuSelected', DropBarMenuHoverEntry='FreshMenuSelected',
    DropBarMenuSbar='FreshMenu', DropBarMenuThumb='FreshMenuSelected',
    DropBarMenuHoverIcon='FreshMenuSelected', DropBarMenuHoverSymbol='FreshMenuSelected',
    dropbarIconUIIndicator='FreshMenu', DropBarIconUISeparatorMenu='FreshMenu',
    DropBarFzfMatch='FreshMenuSelected',
  }) do set(0,name,{link=target}) end
  for _,name in ipairs({'DropBarContextText','DropBarContextIcon','DropBarKindDir','DropBarKindFile',
    'DropBarKindDirNC','DropBarKindFileNC','DropBarIconUISeparator','DropBarIconUIIndicator',
    'DropBarHover','DropBarCurrentContext','DropBarCurrentContextIcon','DropBarCurrentContextName',
    '_DropBarIconHover','_DropBarHover','_DropBarIconCurrentContext','_DropBarCurrentContext'}) do
    set(0,name,{fg=0,ctermfg=0})
  end
  local menu_text=vim.api.nvim_get_hl(0,{name='FreshMenu',link=false})
  set(0,'DropBarMenuText',{fg=menu_text.fg,ctermfg=menu_text.ctermfg})
  set(0,'DropBarContextErrorBadge',{link='DiagnosticError'})
  set(0,'DropBarContextWarningBadge',{link='DiagnosticWarn'})
end
function M.setup()
  M.highlights()
  local group = vim.api.nvim_create_augroup('ConfiguredDropbar', {clear=true})
  vim.api.nvim_create_autocmd({'BufEnter', 'BufWinEnter', 'WinEnter', 'FileType', 'LspAttach', 'CursorMoved', 'CursorMovedI', 'TextChanged', 'TextChangedI', 'WinResized', 'VimResized', 'DirChanged'}, {
    group=group, callback=function(args)
      if args.event == 'WinResized' or args.event == 'VimResized' or args.event == 'DirChanged' then
        for _, win in ipairs(vim.api.nvim_list_wins()) do M.sync(vim.api.nvim_win_get_buf(win), win) end
      else
        for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do M.sync(args.buf, win) end
      end
    end,
  })
  vim.api.nvim_create_autocmd('ColorScheme', {group=group, callback=function() vim.schedule(M.highlights) end})
  vim.api.nvim_create_autocmd('BufDelete', {group=group, callback=function(args) cache[args.buf]=nil end})
  vim.api.nvim_create_autocmd('DiagnosticChanged', {group=group, callback=function(args)
    for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do M.sync(args.buf, win) end
  end})
  vim.api.nvim_create_user_command('DropbarContextMenu', function()
    local bar = require('dropbar.utils.bar').get_current()
    if bar then
      bar:_update()
      for i=#bar.components,1,-1 do
        local symbol = bar.components[i]
        if type(symbol.on_click) == 'function' and not (symbol.data and symbol.data.diagnostic) then
          symbol:on_click()
          break
        end
      end
    end
  end, {desc='Open dropbar hierarchy menu'})
end

return M
