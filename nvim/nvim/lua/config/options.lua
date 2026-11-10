-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.winbar = "%m %f"
vim.opt.textwidth = 117
vim.opt.colorcolumn = "+1"
vim.opt.sidescroll = 0
vim.opt.sidescrolloff = 0

vim.g.loaded_matchparen = 1

vim.g.lazyvim_check_order = false
vim.g.lazyvim_ruby_lsp = "ruby_lsp"
vim.g.lazyvim_ruby_formatter = "rubocop"

vim.g.rails_no_migrations = 1
vim.g.rails_no_migration_prompt = 1
vim.g.rails_migration_check = 0

vim.g.codeium_idle_delay = 200

-- Assume the /g flag on :s substitutions to replace all matches in a line
vim.opt.gdefault = true

-- Show trailing spaces
vim.opt.list = true
vim.opt.listchars = { trail = " " }

-- Reduce how often match-like plugins fire (perfs)
vim.opt.updatetime = 500
