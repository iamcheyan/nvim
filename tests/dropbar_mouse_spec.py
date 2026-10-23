"""Exercise actual mouse press/release against the configured dropbar menus."""
from pathlib import Path
import tempfile
import time
import os
import json
import pynvim

with tempfile.TemporaryDirectory(prefix='nvim-dropbar-mouse-') as temp:
    project = Path(temp)
    (project/'src/nested').mkdir(parents=True)
    (project/'src/first.py').write_text('class First:\n    def run(self):\n        return 1\n\n    def other(self):\n        return 2\n')
    (project/'src/second.py').write_text('class Second:\n    pass\n')
    (project/'src/nested/third.py').write_text('class Third:\n    pass\n')
    (project/'src/sample.cob').write_text('       IDENTIFICATION DIVISION.\n       PROGRAM-ID. MOUSE-TEST.\n       PROCEDURE DIVISION.\n       RUN-PARA.\n           IF A > 1\n               DISPLAY "X"\n           END-IF.\n')
    argv=['nvim','--embed']
    if os.environ.get('NVIM_PLUGIN_DEV_ROOT'):
        source=Path(os.environ['NVIM_PLUGIN_DEV_ROOT'])/'cobol.nvim/lua/cobol/dropbar.lua'
        argv += ['--cmd','lua package.preload["cobol.dropbar"]=function() return dofile('+json.dumps(str(source))+') end']
    nvim = pynvim.attach('child', argv=argv)
    try:
        nvim.ui_attach(180, 45, rgb=True)
        nvim.exec_lua("require('auto-session.config').enabled=false")
        # A restored Neo-tree changes the window widths and click coordinates.
        # Wait for the deferred sidebar restore before closing it.
        nvim.exec_lua("vim.wait(400)")
        nvim.exec_lua("pcall(function() require('neo-tree.command').execute({action='close'}) end)")
        nvim.command('silent! only')
        nvim.command('lcd ' + nvim.funcs.fnameescape(temp))
        nvim.command('edit src/first.py')
        nvim.current.window.cursor=(3,10)
        nvim.input('h')
        time.sleep(.2)
        nvim.command('redraw')
        theme_icons=nvim.exec_lua('''local b=require('dropbar.utils.bar').get_current()
          local wb=vim.api.nvim_get_hl(0,{name='WinBar',link=false})
          local fg=wb.fg or vim.api.nvim_get_hl(0,{name='Normal',link=false}).fg
          for _,s in ipairs(b.components) do
            if s.data and s.data.path and vim.api.nvim_get_hl(0,{name=s.icon_hl,link=false}).fg~=fg then return false end
          end
          return true''')
        assert theme_icons, 'Path icons must follow the WinBar foreground'
        nvim.exec_lua("vim.v.errmsg=''")
        def click(row, col):
            # v:errmsg can carry unrelated errors from file-open autocommands;
            # assert only on errors produced by this click.
            nvim.exec_lua("vim.v.errmsg=''")
            nvim.api.input_mouse('left','press','',0,row,col)
            nvim.api.input_mouse('left','release','',0,row,col)
            time.sleep(.15)
            assert not nvim.eval('v:errmsg'), nvim.eval('v:errmsg')
        def component(label):
            return nvim.exec_lua('''local b=require('dropbar.utils.bar').get_current();local col=b.padding.left
              for _,s in ipairs(b.components) do
                local label=...
                if s.name:find(label,1,true) or (label=='[' and s.name=='' and s:cat(true):find('[',1,true)) then return {col=col,win=b.win,name=s.name} end
                col=col+s:displaywidth()+b.separator:displaywidth()
              end''',label)
        def click_bar(label):
            item=component(label)
            assert item, 'Missing path/code component: '+label
            pos=nvim.api.win_get_position(item['win'])
            click(pos[0],pos[1]+item['col']+1)
            menu=nvim.exec_lua("local m=require('config.dropbar_mouse').get_current(); return m and {win=m.win,prev=m.prev_win,col=m._win_configs.col} or nil")
            assert menu, 'Menu vanished after clicking '+label
            assert menu['prev']==item['win'], 'Menu anchored to wrong source window'
            assert menu['col']==item['col'], (menu,item)
            return menu
        def click_entry(label, arrow=False):
            target=nvim.exec_lua('''local m=require('config.dropbar_mouse').get_current()
              for i,e in ipairs(m.entries) do
                if e.components[2].name:find(...,1,true) then
                  return {win=m.win,row=i-vim.api.nvim_win_call(m.win,function() return vim.fn.line("w0") end),arrow=e.padding.left,
                    name=e.padding.left+e.components[1]:displaywidth()+e.separator:displaywidth()}
                end
              end''',label)
            assert target, 'Missing menu entry '+label
            pos=nvim.api.win_get_position(target['win'])
            click(pos[0]+1+target['row'], pos[1]+1+target['arrow' if arrow else 'name']+(0 if arrow else 1))
        def hover_entry(label):
            target=nvim.exec_lua('''local m=require('config.dropbar_mouse').get_current()
              for i,e in ipairs(m.entries) do
                if e.components[2].name:find(...,1,true) then
                  return {win=m.win,row=i-vim.api.nvim_win_call(m.win,function() return vim.fn.line("w0") end),
                    col=e.padding.left+e.components[1]:displaywidth()+e.separator:displaywidth()+2}
                end
              end''',label)
            assert target, 'Missing hover entry '+label
            pos=nvim.api.win_get_position(target['win'])
            nvim.api.input_mouse('move','', '',0,pos[0]+1+target['row'],pos[1]+target['col'])
            time.sleep(.1)
            return nvim.exec_lua('''local m=require('config.dropbar_mouse').get_current(); local hl={};
              for _,id in ipairs(vim.api.nvim_get_namespaces()) do
                local ns=vim.api.nvim_get_namespaces()[id]
                if ns then hl[#hl+1]={name=ns,id=id,marks=vim.api.nvim_buf_get_extmarks(m.buf,id,{0,0},{-1,-1},{details=true})} end
              end
              return {selected=m.selected,highlights=hl}''')
        # A refresh queued by the last edit must not delete a newly opened menu.
        nvim.exec_lua("vim.api.nvim_exec_autocmds('TextChanged',{buffer=0}); vim.api.nvim_exec_autocmds('TextChanged',{buffer=0})")
        click_bar('run')
        assert nvim.current.buffer.options['filetype']=='python', 'Mouse menu stole document focus'
        assert nvim.current.window.cursor[0]==3, 'Mouse menu moved document cursor'
        doc_cursor=nvim.current.window.cursor
        before=nvim.exec_lua("local m=require('config.dropbar_mouse').get_current(); return m.selected")
        hover_entry('other')
        assert nvim.exec_lua("return require('config.dropbar_mouse').get_current().selected")==2, 'Hover must immediately activate the pointed menu item'
        assert nvim.exec_lua("return vim.o.mousemoveevent"), 'Mouse hover events must be enabled while a dropbar menu is open'
        hover_highlight=nvim.exec_lua('''local m=require('config.dropbar_mouse').get_current();
          local groups={'DropBarMenuHoverEntry','DropBarMenuHoverSymbol','DropBarMenuHoverIcon'}
          for _,group in ipairs(groups) do
            local ns=vim.api.nvim_create_namespace(group)
            local marks=vim.api.nvim_buf_get_extmarks(m.buf,ns,{m.selected-1,0},{m.selected-1,-1},{details=true})
            for _,mark in ipairs(marks) do
              if mark[4].hl_group==group then return true end
            end
          end
          return false''')
        assert hover_highlight, 'Hovering a menu item must activate its hover highlight'
        nvim.input('<Down>')
        time.sleep(.1)
        assert nvim.exec_lua("return require('config.dropbar_mouse').get_current().selected")==min(2,before+1)
        nvim.input('<Up>')
        time.sleep(.1)
        assert nvim.current.window.cursor==doc_cursor, 'Menu arrow keys moved the document cursor'
        nvim.input('<End><CR>')
        time.sleep(.15)
        assert nvim.current.window.cursor[0]==5, 'Code click did not jump to other()'
        opened=click_bar('first.py')
        # A list that fits in the popup must never scroll into empty rows.
        pos=nvim.api.win_get_position(opened['win'])
        editor_cursor=nvim.current.window.cursor
        for _ in range(12):
            nvim.api.input_mouse('wheel','down','',0,pos[0]+2,pos[1]+5)
            time.sleep(.02)
        assert nvim.funcs.getwininfo(opened['win'])[0]['topline']==1, 'Short menu scrolled past its content'
        assert nvim.current.window.cursor==editor_cursor, 'Wheel over a menu must not scroll the editor'
        for direction in ('right','left'):
            for _ in range(15):
                nvim.api.input_mouse('wheel',direction,'',0,pos[0]+2,pos[1]+5)
                time.sleep(.02)
            leftcol=nvim.exec_lua("return vim.api.nvim_win_call(...,function() return vim.fn.winsaveview().leftcol end)",opened['win'])
            assert leftcol==0, ('Menu scrolled horizontally',direction,leftcol)
        menu_icons=nvim.exec_lua('''local m=require('config.dropbar_mouse').get_current()
          for _,e in ipairs(m.entries) do
            local s=e.components[2]
            if vim.api.nvim_get_hl(0,{name=s.icon_hl,link=false}).fg~=vim.api.nvim_get_hl(0,{name='FreshMenu',link=false}).fg then return false end
          end
          return true''')
        assert menu_icons, 'File menu icons must match unified menu foreground'
        source_buf=nvim.api.win_get_buf(opened['prev'])
        assert Path(nvim.api.buf_get_name(source_buf))==project/'src/first.py', 'Opening a file menu replaced the source editor with a preview'
        border=nvim.api.win_get_config(opened['win']).get('border')
        declared=nvim.exec_lua("return require('config.dropbar_mouse').get_current()._win_configs.border")
        assert declared is not None, 'Global float wrapper added a border after native menu geometry was calculated'
        click_entry('second.py')
        assert Path(nvim.current.buffer.name).name=='second.py', 'File menu did not switch files'
        click_bar('src')
        click_entry('src')
        assert Path(nvim.current.buffer.name).name != 'src', 'Directory name opened a directory buffer'
        # Re-clicking a parent while its child is open must keep both the
        # editor focus and the parent window alive (menu.lua:315 regression).
        nvim.exec_lua("""local root=require('config.dropbar_mouse').get_current():root()
          for _,e in ipairs(root.entries) do
            if vim.trim(e.components[2].name)=='src' then
              root:click_at({e.idx,e.padding.left},nil,1,'l')
              break
            end
          end
          assert(root.win and vim.api.nvim_win_is_valid(root.win),'parent menu was closed')
          assert(vim.bo.filetype~='dropbar_menu','submenu close stole document focus')""")
        click_entry('nested')
        geometry=nvim.exec_lua("""local m=require('config.dropbar_mouse').get_current()
          local p=m.prev_menu
          return {actual=m._win_configs.row,expected=p.clicked_at[1]-vim.api.nvim_win_call(p.win,function() return vim.fn.line('w0') end)}""")
        assert geometry['actual']==geometry['expected'], ('Submenu not aligned to parent row',geometry)
        source_cursor=nvim.current.window.cursor
        nvim.input('<Left>')
        time.sleep(.1)
        assert nvim.exec_lua("return require('config.dropbar_mouse').get_current().prev_menu~=nil")
        nvim.input('<Right>')
        time.sleep(.1)
        assert nvim.current.window.cursor==source_cursor, 'Expanding/collapsing moved document cursor'
        click_entry('third.py')
        assert Path(nvim.current.buffer.name).name=='third.py', 'Nested directory menu did not switch files'
        # Clicking the winbar of an inactive split must anchor to that split.
        source_win=nvim.current.window.handle
        nvim.command('vsplit src/first.py')
        time.sleep(.15)
        item=nvim.exec_lua('''local b=require('dropbar.utils.bar').get({win=...});local col=b.padding.left
          for _,s in ipairs(b.components) do
            if s.name=='third.py' then return {col=col,win=b.win} end
            col=col+s:displaywidth()+b.separator:displaywidth()
          end''',source_win)
        assert item, 'Inactive split lost its file breadcrumb'
        pos=nvim.api.win_get_position(source_win)
        click(pos[0],pos[1]+item['col']+1)
        menu=nvim.exec_lua("local m=require('config.dropbar_mouse').get_current();return m and {prev=m.prev_win,col=m._win_configs.col}")
        assert menu and menu['prev']==source_win and menu['col']==item['col'], (menu,item)
        active_win=nvim.current.window.handle
        active_cursor=nvim.current.window.cursor
        nvim.input('<Down><Up>')
        time.sleep(.1)
        assert nvim.current.window.handle==active_win and nvim.current.window.cursor==active_cursor
        nvim.input('\x1b')
        time.sleep(.15)
        assert nvim.exec_lua("return require('config.dropbar_mouse').get_current()==nil"), 'Esc did not close inactive-split menu'
        nvim.command('silent! only')
        nvim.command('edit src/sample.cob')
        nvim.current.window.cursor=(6,18)
        nvim.input('h')
        time.sleep(.15)
        click_bar('[')
        click_entry('PROCEDURE DIVISION',arrow=True)
        click_entry('RUN-PARA')
        assert nvim.current.window.cursor[0]==4, 'COBOL hierarchy did not jump to the paragraph'
        # Scroll a long native file menu and click an item in its visible rows.
        for index in range(30):
            (project/f'src/scroll{index:02}.py').write_text('pass\n')
        nvim.command('edit src/first.py')
        time.sleep(.15)
        opened=click_bar('first.py')
        assert nvim.exec_lua("return require('dropbar.configs').opts.menu.scrollbar.enable == false"), 'Menu scrollbar must be disabled'
        pos=nvim.api.win_get_position(opened['win'])
        editor_cursor=nvim.current.window.cursor
        first_top=nvim.funcs.getwininfo(opened['win'])[0]['topline']
        nvim.api.input_mouse('wheel','down','',0,pos[0]+2,pos[1]+5)
        time.sleep(.1)
        down_top=nvim.funcs.getwininfo(opened['win'])[0]['topline']
        assert down_top>first_top, ('Wheel down did not scroll the menu',first_top,down_top)
        assert nvim.current.window.cursor==editor_cursor, 'Wheel over a menu must not scroll the editor'
        nvim.api.input_mouse('wheel','up','',0,pos[0]+2,pos[1]+5)
        time.sleep(.1)
        assert nvim.funcs.getwininfo(opened['win'])[0]['topline']==first_top, 'Wheel up did not restore the menu position'
        for _ in range(35):
            nvim.api.input_mouse('wheel','down','',0,pos[0]+2,pos[1]+5)
            time.sleep(.02)
        info=nvim.funcs.getwininfo(opened['win'])[0]
        count=nvim.api.buf_line_count(nvim.api.win_get_buf(opened['win']))
        last_top=max(1,count-nvim.api.win_get_height(opened['win'])+1)
        assert info['topline']==last_top, ('Menu scrolled past its content',info['topline'],last_top)
        assert nvim.exec_lua("return require('config.dropbar_mouse').get_current().scrollbar == nil"), 'Menu created scrollbar windows'
        for _ in range(35):
            nvim.api.input_mouse('wheel','up','',0,pos[0]+2,pos[1]+5)
            time.sleep(.02)
        assert nvim.funcs.getwininfo(opened['win'])[0]['topline']==1
        target=nvim.exec_lua('''local m=require('config.dropbar_mouse').get_current()
          for i,e in ipairs(m.entries) do if vim.trim(e.components[2].name)=='scroll20.py' then return i end end''')
        assert target
        for _ in range(30):
            info=nvim.funcs.getwininfo(opened['win'])[0]
            if info['topline']<=target<=info['botline']: break
            pos=nvim.api.win_get_position(opened['win'])
            nvim.api.input_mouse('wheel','down','',0,pos[0]+2,pos[1]+5)
            time.sleep(.03)
        click_entry('scroll20.py')
        assert Path(nvim.current.buffer.name).name=='scroll20.py', 'Scrolled file menu click hit the wrong row'
        assert not nvim.eval('v:errmsg'), nvim.eval('v:errmsg')
        print('dropbar_mouse_spec: OK (position, persistence, code jumps, file and nested directory clicks)')
    finally:
        try: nvim.command('qa!')
        except (EOFError,OSError): pass
