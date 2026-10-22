-- Mouse menus use native dropbar entries without taking the editor's focus.
local M = {}
local root_menu, saved, source_buf, group
function M.get_current()
  local menu=root_menu
  while menu and menu.sub_menu and menu.sub_menu.is_opened do menu=menu.sub_menu end
  return menu
end
local function select(menu, row)
  if not menu or not menu.win or not vim.api.nvim_win_is_valid(menu.win) then return end
  row=math.max(1,math.min(#menu.entries,row))
  menu.selected=row
  vim.api.nvim_win_set_cursor(menu.win,{row,0})
  menu:update_current_context_hl(row)
  menu:update_hover_hl({row,0})
end
local function cleanup()
  if group then vim.api.nvim_del_augroup_by_id(group); group=nil end
  for _, entry in ipairs(saved or {}) do
    if vim.api.nvim_buf_is_valid(source_buf) then
      pcall(vim.keymap.del, entry.mode, entry.key, {buffer=source_buf})
      for _, map in ipairs(entry.maps) do vim.fn.mapset(entry.mode, false, map) end
    end
  end
  saved=nil
  root_menu=nil
end
local function bind(menu)
  root_menu=menu
  -- Clicking an inactive split's winbar keeps the currently active document
  -- focused. Temporary keys must belong to that document, not the anchor.
  source_buf=vim.api.nvim_get_current_buf()
  saved={}
  local function close() if root_menu then root_menu:close(false) end end
  local function move(delta)
    local current=M.get_current()
    if current then select(current,vim.api.nvim_win_get_cursor(current.win)[1]+delta) end
  end
  local function activate(component)
    local current=M.get_current()
    if not current then return end
    local row=vim.api.nvim_win_get_cursor(current.win)[1]
    local entry=current.entries[row]
    if entry then current:click_on(entry.components[component],nil,1,'l') end
  end
  local function click()
    local mouse=vim.fn.getmousepos()
    local target=require('dropbar.utils.menu').get({win=mouse.winid})
    if target then
      if mouse.line>=1 and mouse.line<=#target.entries and mouse.column>=1 then
        select(target,mouse.line)
        target:click_at({mouse.line,mouse.column-1},nil,1,'l')
      end
    else
      close()
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<LeftMouse>',true,false,true),'m',false)
    end
  end
  for _, mode in ipairs({'n','x','i'}) do
    for key, callback in pairs({['<LeftMouse>']=click, ['<Esc>']=function()
      close()
      if vim.fn.mode():sub(1,1)=='i' then vim.cmd.stopinsert() end
    end,
      ['<Up>']=function() move(-1) end, ['<Down>']=function() move(1) end,
      ['<Home>']=function() select(M.get_current(),1) end,
      ['<End>']=function() local m=M.get_current(); if m then select(m,#m.entries) end end,
      ['<CR>']=function() activate(2) end, ['<Right>']=function() activate(1) end,
      ['<Left>']=function() local m=M.get_current(); if m and m.prev_menu then m:close(false) else close() end end,
      ['<MouseMove>']=function()
        local mouse=vim.fn.getmousepos()
        local target=require('dropbar.utils.menu').get({win=mouse.winid})
        if target and mouse.line>=1 and mouse.line<=#target.entries then select(target,mouse.line) end
        require('dropbar.utils.menu').update_hover_hl(mouse)
      end}) do
      local maps={}
      for _, map in ipairs(vim.api.nvim_buf_get_keymap(source_buf,mode)) do
        if vim.api.nvim_replace_termcodes(map.lhs,true,false,true)==vim.api.nvim_replace_termcodes(key,true,false,true) then maps[#maps+1]=map end
      end
      saved[#saved+1]={mode=mode,key=key,maps=maps}
      vim.keymap.set(mode,key,callback,{buffer=source_buf,silent=true,nowait=true})
    end
  end
  group=vim.api.nvim_create_augroup('DropbarMouseLifetime',{clear=true})
  vim.api.nvim_create_autocmd({'BufLeave','WinLeave'}, {group=group,buffer=source_buf,callback=close})
end
function M.open(symbol)
  local parent=symbol.entry and symbol.entry.menu
  local items=parent and symbol.opts.children or symbol.opts.siblings
  if not items or #items==0 then return end
  if symbol.menu and symbol.menu.is_opened then symbol.menu:close(false); return end
  if not parent and root_menu then root_menu:close(false) end
  if symbol.menu then symbol.menu:del(); symbol.menu=nil end
  local native=require('dropbar.menu')
  local opts=require('dropbar.configs').opts
  local entries={}
  for _, item in ipairs(items) do
    local children=item.children
    local expandable=children and #children>0
    entries[#entries+1]=native.dropbar_menu_entry_t:new({components={
      item:merge({name='',icon=expandable and opts.icons.ui.menu.indicator or ' ',
        icon_hl='DropBarMenuText',name_hl='DropBarMenuText',on_click=expandable and M.open or false}),
      item:merge({name_hl='DropBarMenuText',icon_hl='DropBarMenuText',on_click=function(self)
        if item.data and item.data.path and vim.fn.isdirectory(item.data.path)==1 then
          M.open(self)
        else
          if root_menu then root_menu:close(false) end
          item:jump()
        end
      end}),
    }})
  end
  local menu=native.dropbar_menu_t:new({prev_win=parent and parent.win or symbol.bar.win,
    prev_buf=parent and parent.buf or symbol.buf, entries=entries,
    cursor=not parent and symbol.sibling_idx and {symbol.sibling_idx,0} or nil})
  symbol.menu=menu
  menu.open_win=function(self)
    self.is_opened=true
    self.win=vim.api.nvim_open_win(self.buf,false,self._win_configs)
    vim.wo[self.win].winhighlight='Normal:DropBarMenuNormalFloat,NormalFloat:DropBarMenuNormalFloat,FloatBorder:DropBarMenuFloatBorder'
    vim.wo[self.win].scrolloff=0
    vim.wo[self.win].sidescrolloff=0
    vim.wo[self.win].wrap=false
    vim.wo[self.win].winfixbuf=true
  end
  local native_close=menu.close
  menu.close=function(self,...)
    -- Native close focuses prev_win. In a mouse menu that steals editor
    -- focus, triggers WinLeave and destroys the parent during click_at().
    local prev_win=self.prev_win
    self.prev_win=nil
    native_close(self,...)
    self.prev_win=prev_win
    if self==root_menu then cleanup() end
  end
  menu:open()
  select(menu,menu.cursor and menu.cursor[1] or 1)
  if not parent then bind(menu) end
end
return M
