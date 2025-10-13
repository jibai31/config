return {
  "folke/tokyonight.nvim",
  opts = {
    on_colors = function(colors)
      colors.border = "#7aa2f7" -- Custom border color
    end,
    on_highlights = function(highlights, colors)
      highlights.FloatBorder = { fg = colors.border }
      highlights.TelescopeBorder = { fg = colors.border }
    end,
  },
}
