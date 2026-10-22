-- Training aid that discourages inefficient key repetition. Disabled by default.
return {
  {
    "m4xshen/hardtime.nvim",
    cmd = { "Hardtime" },
    opts = {
      enabled = false,
      disable_mouse = false,
      max_time = 1000,
      max_count = 3,
      allow_different_key = true,
      resetting_keys = { ["1"] = true, ["2"] = true },
      hint = true,
      notification = false,
    },
  },
}
