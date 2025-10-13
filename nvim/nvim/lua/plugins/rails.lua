return {
  -- vim-rails
  {
    "tpope/vim-rails",
    ft = { "ruby", "haml", "slim" }, -- Load for these filetypes
  },

  -- vim-endwise
  {
    "tpope/vim-endwise",
    ft = { "ruby" },
  },

  -- vim-surround
  {
    "tpope/vim-surround",
    -- cs[delimiter1][delimiter2] will change delimiters around cursor (eg, cs"')
    -- yss[delimiter] will wrap the entire line with delimiter
    -- ds[delimiter] will remove the delimiter
    -- Also works with visual mode on multiple lines: V (for visual mode) S<div> will wrap the lines with <div>
  },

  -- Autocomplete -> DISABLE
  {
    "saghen/blink.cmp",
    opts = {
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

  -- Copilot (loaded by default in LazyVim) -> DISABLE
  {
    "github/copilot.vim",
    enabled = false,
  },
  {
    "zbirenbaum/copilot.lua",
    enabled = false,
  },
  {
    "zbirenbaum/copilot-cmp",
    enabled = false,
  },

  -- add more treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "ruby",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      },
    },
  },
}
