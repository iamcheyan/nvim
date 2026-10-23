local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.runtimepath:prepend(root)
local created, tree_created = 0, 0
package.loaded["config.file_actions"] = { new_file = function() created = created + 1 end }
package.loaded["config.popup_menu"] = { open = function() end }
package.loaded["neo-tree.sources.manager"] = { get_state_for_window = function() end }
local context = require("config.context_menu")
context.setup()
vim.api.nvim_exec_autocmds("MenuPopup", {})
context.run("new_file")
assert(created == 1, "editor New File must use the shared file action")
context.open_buffer(vim.api.nvim_get_current_buf())
context.run("new_file")
assert(created == 2, "file-strip New File must use the same shared file action")
local state = {
  winid = vim.api.nvim_get_current_win(),
  tree = { get_node = function() return { type = "directory", path = vim.fn.getcwd() } end },
}
package.loaded["neo-tree.sources.filesystem.commands"] = {
  add = function(target) assert(target == state); tree_created = tree_created + 1 end,
}
context.open_neo(state, 1)
context.run("new_file")
assert(tree_created == 1 and created == 2, "tree creation must preserve the selected node's directory semantics")
vim.wait(10)
print("context_menu_file_actions_spec: OK")
