-- Standalone VimQuest plugin.
return {
  "iamcheyan/VimQuest",
  name = "VimQuest.nvim",
  cmd = {
    "VimQuestStart",
    "VimQuestStop",
    "VimQuestNext",
    "VimQuestPrev",
    "VimQuestNextRound",
    "VimQuestRestart",
    "VimQuestTasks",
    "VimQuestList",
    "VimQuestCheck",
    "VimQuestHint",
    "VimQuestStats",
    "VimQuestWords",
    "VimQuestSelectDictionary",
  },
  config = function()
    require("vimquest").setup()
  end,
}
