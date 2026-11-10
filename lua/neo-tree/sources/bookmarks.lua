-- Resolves `neo-tree.sources.bookmarks` to the config module so neo-tree can
-- load the custom source through its normal `require` path.
return require("config.neotree_bookmarks")
