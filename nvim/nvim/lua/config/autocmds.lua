-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local augroup = vim.api.nvim_create_augroup -- Create/get autocommand group
local autocmd = vim.api.nvim_create_autocmd -- Create autocommand

-- Simple Tab for completion acceptance
autocmd("User", {
  pattern = "LazyVimConfigured",
  callback = function()
    local cmp = require("cmp")

    cmp.setup({
      -- mapping = {
      --   ["<Tab>"] = cmp.mapping.confirm({ select = true }),
      --   ["<CR>"] = cmp.mapping(function(fallback)
      --     fallback() -- Just insert a newline
      --   end),
      -- },
      mapping = {
        -- Tab: confirm cmp popup if visible, otherwise fall through to Codeium
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.confirm({ select = true })
          else
            fallback() -- lets Codeium's <Tab> mapping fire
          end
        end, { "i", "s" }),

        -- Enter: always just a newline, never confirms anything
        ["<CR>"] = cmp.mapping(function(fallback)
          fallback()
        end, { "i", "s" }),
      },
    })
  end,
})

-- Disable plugins inside Telescope
autocmd("FileType", {
  pattern = "TelescopePrompt",
  callback = function()
    vim.b.codeium_enabled = false
    vim.b.matchparen_disable = 1
  end,
})

-- Disable formatting for ERB files
autocmd("FileType", {
  pattern = { "eruby" },
  callback = function()
    vim.b.autoformat = false
  end,
})

-- Formatting for sh files
autocmd("FileType", {
  pattern = { "sh" },
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
  end,
})

-- Highlight trailing spaces in red (only in normal mode)
autocmd({ "BufWinEnter", "InsertLeave" }, {
  pattern = "*",
  callback = function()
    vim.cmd("match TrailingWhitespace /\\s\\+$/")
  end,
})

autocmd("InsertEnter", {
  pattern = "*",
  callback = function()
    vim.cmd("match none")
  end,
})

vim.cmd("highlight TrailingWhitespace ctermbg=red guibg=red")
