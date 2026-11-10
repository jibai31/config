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
}
