return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "olimorris/neotest-rspec",
    },
    opts = {
      adapters = {
        require("neotest-rspec")({
          rspec_cmd = function()
            return { "bundle", "exec", "rspec" }
          end,
          root_files = { "Gemfile", ".rspec", ".gitignore" },
          filter_dirs = { ".git", "node_modules" },
        }),
      },
    },
  },
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui", -- Optional but recommended
      "theHamsta/nvim-dap-virtual-text", -- Optional
    },
  },
  {
    "suketa/nvim-dap-ruby", -- Ruby DAP adapter
  },
}
