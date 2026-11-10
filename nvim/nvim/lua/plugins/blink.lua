return {

  -- Autocomplete -> DISABLE
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "super-tab",
      },
      completion = {
        accept = { auto_brackets = { enabled = false } },
        trigger = {
          show_on_keyword = false, -- Don't show automatically on typing
        },
      },
      snippets = {
        expand = function() end, -- Disable snippet expansion
      },
      sources = {
        providers = {
          snippets = { enabled = false }, -- Disable snippet source
        },
      },
    },
  },
}
