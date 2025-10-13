return {
  -- Conform (formatter)
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        javascript = { "prettier" },
        yaml = { "prettierd" },
        json = { "prettier" },
      },
    },
  },
}
