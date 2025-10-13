return {
  "Exafunction/windsurf.vim",
  event = "BufEnter",
  config = function()
    -- Accept suggestion
    vim.keymap.set("i", "<C-g>", function()
      return vim.fn["codeium#Accept"]()
    end, { expr = true })

    -- Clear current suggestion
    vim.keymap.set("i", "<C-x>", function()
      return vim.fn["codeium#Clear"]()
    end, { expr = true })

    -- Next suggestion
    vim.keymap.set("i", "<M-]>", function()
      return vim.fn["codeium#CycleCompletions"](1)
    end, { expr = true })

    -- Previous suggestion
    vim.keymap.set("i", "<M-[>", function()
      return vim.fn["codeium#CycleCompletions"](-1)
    end, { expr = true })
  end,
}
