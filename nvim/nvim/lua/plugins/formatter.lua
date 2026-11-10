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
  -- none-ls
  {
    "nvimtools/none-ls.nvim",
    opts = function(_, opts)
      local null_ls = require("null-ls")

      opts.sources = opts.sources or {}

      -- Remove default shfmt if it exists and add configured one
      table.insert(
        opts.sources,
        null_ls.builtins.formatting.shfmt.with({
          extra_args = { "-i", "2" },
        })
      )

      return opts
    end,
  },
}
