-- The + and * registers are backed by an in-memory stub so this spec never depends
-- on a live X11/Wayland clipboard being present.
local clipboard_store = { ["+"] = "", ["*"] = "" }
vim.g.clipboard = {
  name = "markdown-image-paste-spec",
  copy = {
    ["+"] = function(lines) clipboard_store["+"] = table.concat(lines, "\n") end,
    ["*"] = function(lines) clipboard_store["*"] = table.concat(lines, "\n") end,
  },
  paste = {
    ["+"] = function() return { clipboard_store["+"] } end,
    ["*"] = function() return { clipboard_store["*"] } end,
  },
}
-- A provider chosen at startup (for example "wl-copy") is already cached, so the
-- provider must be re-initialized for the stub above to take effect.
vim.g.loaded_clipboard_provider = nil
assert(vim.fn["provider#clipboard#Executable"]() == "markdown-image-paste-spec",
  "the in-memory clipboard stub must be the active provider")
vim.g.loaded_clipboard_provider = 2
assert(vim.fn.has("clipboard") == 1, "the clipboard provider must be usable")

local mip = require("config.markdown_image_paste")
mip.setup()

-- Create temporary test images
local sample_img = vim.fn.tempname() .. ".png"
local f = io.open(sample_img, "wb")
if f then
  f:write("\137PNG\r\n\26\n\0\0\0\rIHDR\0\0\0\1\0\0\0\1\8\6\0\0\0\31\21\196\137\0\0\0\nIDATx\156c\0\1\0\0\5\0\1\13\n-\180\0\0\0\0IEND\174B`\130")
  f:close()
end

local sample_img2 = vim.fn.tempname() .. ".png"
local f2 = io.open(sample_img2, "wb")
if f2 then
  f2:write("\137PNG\r\n\26\n\0\0\0\rIHDR\0\0\0\1\0\0\0\1\8\6\0\0\0\31\21\196\137\0\0\0\nIDATx\156c\0\1\0\0\5\0\1\13\n-\180\0\0\0\0IEND\174B`\130")
  f2:close()
end

-- 1. is_image_file detection
assert(mip.is_image_file(sample_img) == true, "must recognize existing png file")
assert(mip.is_image_file('"' .. sample_img .. '"') == true, "must recognize quoted path")
assert(mip.is_image_file("file://" .. sample_img) == true, "must recognize file:// URI")
assert(mip.is_image_file("/tmp/nonexistent-1234567.png") == false, "must reject nonexistent file")
assert(mip.is_image_file("regular text without image") == false, "must reject plain text")

-- 2. save_image_to_assets
local tmp_dir = vim.fn.tempname()
vim.fn.mkdir(tmp_dir, "p")
local md_file = tmp_dir .. "/doc.md"
vim.cmd("edit " .. md_file)
local bufnr = vim.fn.bufnr(md_file)
vim.api.nvim_win_set_buf(0, bufnr)
vim.bo[bufnr].filetype = "markdown"

local rel_path, err = mip.save_image_to_assets(sample_img)
assert(rel_path and rel_path:match("^assets/image%-%d+%-%d+%.png$"), "must generate assets/image-*.png")
assert(err == nil, "save should succeed without error")

local full_assets_path = tmp_dir .. "/" .. rel_path
local stat = vim.uv.fs_stat(full_assets_path)
assert(stat and stat.type == "file" and stat.size > 0, "target image in assets/ must exist with content")

-- 3. paste_image integration (with trailing newline test)
vim.fn.setreg("+", sample_img .. "\n")
local pasted = mip.paste_image()
assert(pasted == true, "paste_image should succeed")
local line = vim.api.nvim_get_current_line()
assert(line:match("^%!%[%]%(assets/image%-%d+.*%.png%)$"),
  "line must contain markdown image syntax: " .. line)

-- 4. convert_image_under_cursor integration
vim.api.nvim_set_current_line("Here is an image: " .. sample_img .. " on this line")
local converted = mip.convert_image_under_cursor()
assert(converted == true, "convert_image_under_cursor should succeed")
local converted_line = vim.api.nvim_get_current_line()
assert(converted_line:find("assets/image-", 1, true) ~= nil, "converted line must reference assets directory")
assert(converted_line:find(sample_img, 1, true) == nil, "converted line must replace sample path")

-- 5. vim.paste hook with multiple images
vim.api.nvim_set_current_line("")
vim.paste({ sample_img .. " " .. sample_img2 }, -1)
local multi_line = vim.api.nvim_get_current_line()
local count = 0
for _ in multi_line:gmatch("%!%[%]%(assets/image%-[^%)]+%)") do
  count = count + 1
end
assert(count == 2, "multi-image paste must convert all paths: " .. multi_line)

-- 6. unnamed register safety: ensure paste_image does NOT use register '"'.
-- PATH points at an empty directory so this check cannot depend on the real system
-- clipboard or on a locally installed kitten.
-- Register contents are set while PATH is still intact: a clipboard provider that
-- was initialized at startup resolves its helper binary through PATH.
vim.fn.setreg("+", "")
vim.fn.setreg("*", "")
vim.fn.setreg('"', sample_img)
local register_test_bin = vim.fn.tempname()
vim.fn.mkdir(register_test_bin, "p")
local path_before_register_test = vim.env.PATH
vim.env.PATH = register_test_bin
local pasted_empty = mip.paste_image()
vim.env.PATH = path_before_register_test
assert(pasted_empty == false, "must not fall back to register quote")

-- 7. Simulate Kitty's OSC 5522 responses at the terminal boundary. Exercise the
-- full paste path, including binary chunks, asset creation, and failed reads.
local saved_send = vim.api.nvim_ui_send
local saved_uis = vim.api.nvim_list_uis
local saved_path = vim.env.PATH
local saved_tmux = vim.env.TMUX
local empty_bin = vim.fn.tempname()
local clip_dir = vim.fn.tempname()
vim.fn.mkdir(empty_bin, "p")
vim.fn.mkdir(clip_dir, "p")
vim.env.PATH = empty_bin -- no wl-paste or xclip
vim.env.TMUX = "tmux-test"
vim.fn.setreg("+", "")
vim.fn.setreg("*", "")
vim.api.nvim_list_uis = function() return { {} } end

local denied = false
local requested = {}
local image_bytes = "\137PNG\r\n\26\n\0\255image payload"
local function reply(status, id, mime, payload)
  local header = "\27]5522;type=read:status=" .. status .. ":id=" .. id
  if mime then header = header .. ":mime=" .. vim.base64.encode(mime) end
  vim.api.nvim_exec_autocmds("TermResponse", {
    data = { sequence = header .. (payload and ";" .. vim.base64.encode(payload) or "") },
  })
end

vim.api.nvim_ui_send = function(query)
  assert(query:sub(1, 7) == "\27Ptmux;", "tmux clipboard query must use passthrough")
  local id = assert(query:match(":id=([%w%-]+)"))
  local mime = vim.base64.decode(assert(query:match(";([%w+/=]+)\27\27\\\27\\$")))
  requested[#requested + 1] = mime
  vim.schedule(function()
    if mime == "." then
      reply("OK", id)
      reply("DATA", id, ".", "text/plain\nimage/png\n")
      reply("DONE", id)
    elseif denied then
      reply("OK", id)
      reply("DATA", id, mime, image_bytes:sub(1, 9))
      reply("EBUSY", id)
    else
      reply("OK", id)
      reply("DATA", id, mime, image_bytes:sub(1, 9))
      reply("DATA", id, mime, image_bytes:sub(10))
      reply("DONE", id)
    end
  end)
end

local clip_doc = clip_dir .. "/clip.md"
vim.cmd("edit " .. vim.fn.fnameescape(clip_doc))
vim.bo.filetype = "markdown"
vim.api.nvim_set_current_line("")
assert(mip.paste_image(), "Kitty image bytes must paste through tmux")
local archived = vim.api.nvim_get_current_line():match("^%!%[%]%((assets/image%-[%w%-]+%.png)%)$")
assert(archived, "pasted image must link to a PNG asset")
local image = assert(io.open(clip_dir .. "/" .. archived, "rb"))
assert(image:read("*a") == image_bytes, "clipboard image must be archived byte for byte")
image:close()
assert(vim.deep_equal(requested, { ".", "image/png" }), "paste must request only the chosen image type")

denied = true
vim.api.nvim_set_current_line("")
assert(not mip.paste_image(), "denied clipboard reads must not paste")
assert(vim.api.nvim_get_current_line() == "", "failed read must leave the buffer unchanged")
assert(#vim.fn.glob(clip_dir .. "/assets/*", false, true) == 1, "denied read must not create an asset")

vim.api.nvim_ui_send = saved_send
vim.api.nvim_list_uis = saved_uis
vim.env.PATH = saved_path
vim.env.TMUX = saved_tmux
vim.fn.delete(clip_dir, "rf")
vim.fn.delete(empty_bin, "rf")


vim.fn.delete(sample_img)
vim.fn.delete(sample_img2)
vim.fn.delete(tmp_dir, "rf")
vim.fn.delete(register_test_bin, "rf")
print("markdown_image_paste_spec: OK")
vim.cmd("qa!")
