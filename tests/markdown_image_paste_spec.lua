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

-- 6. unnamed register safety: ensure paste_image does NOT use register '"'
vim.fn.setreg("+", "")
vim.fn.setreg("*", "")
vim.fn.setreg('"', sample_img)
local pasted_empty = mip.paste_image()
assert(pasted_empty == false, "must not fall back to register quote")

vim.fn.delete(sample_img)
vim.fn.delete(sample_img2)
vim.fn.delete(tmp_dir, "rf")
print("markdown_image_paste_spec: OK")
vim.cmd("qa!")
