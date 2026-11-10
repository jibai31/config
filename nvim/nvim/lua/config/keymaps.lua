-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
-- " Helpers
-- """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

map("n", ":=", ":!", { desc = "Cmdline - Easier on Mac" })
map("n", ",so", ":!so %<CR>", { desc = "Source current file (reload vim config)" })

-- """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
-- " IA
-- """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

map("n", "<Space>ww", ":Codeium Chat", { desc = "Launch Windsurf Chat" })

-- """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
-- " File
-- """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

map("n", "s", ":w<CR>", { desc = "Save file" })
map("n", "<Space>rf", function()
  require("snacks").rename.rename_file()
end, { desc = "Rename current file" })

-- """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
-- " Search & code navigation
-- """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

map("n", "vv", "viw<Space>sw", { remap = true, desc = "Search selected text" })
map("n", "K", ":lua vim.diagnostic.open_float()<CR>", { desc = "Show diagnostics for the current cursor position" })

map("n", "<Space>fm", function()
  require("telescope.builtin").find_files({ search_dirs = { "app/models" }, prompt_title = "Find Models" })
end, { desc = "Find Model" })

map("n", "<Space>fd", function()
  require("telescope.builtin").find_files({ search_dirs = { vim.fn.expand("%:p:h") }, prompt_title = "Find Files" })
end, { desc = "Find Files (Current File Dir)" })

map("n", "<Space>fs", function()
  require("telescope.builtin").find_files({ search_dirs = { "spec/" }, prompt_title = "Find Models" })
end, { desc = "Find Spec" })

map("n", "<Space>fr", function()
  local routes = vim.fn.systemlist("rails routes")

  require("telescope.pickers")
    .new({}, {
      prompt_title = "Rails Routes",
      finder = require("telescope.finders").new_table({
        results = routes,
      }),
      sorter = require("telescope.sorters").get_substr_matcher(),
      previewer = false,
    })
    :find()
end, { desc = "Search Rails Routes" })

-- """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
-- " Quickfix list (eg, search results)
-- """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

-- Ctrl-q to send search results to quickfix
-- Alt-q to send SELECTED search results to quickfix (Tab to select)
map("n", "<Space>j", ":cnext<CR>", { desc = "Next quickfix item" })
map("n", "<Space>k", ":cprev<CR>", { desc = "Previous quickfix item" })

-- """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
-- " Play with buffers, windows and tables
-- "   BUFFER: a file loaded in memory
-- "   WINDOW: different splits of the screen to view the opened buffers
-- "   TAB:    whole new set of splits to view still the same opened buffers
-- """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

-- H/L          navigate between buffers (:bnext / :bprevious)
-- <Space>,     show the opened buffers
-- <C-h>/<C-l>  navigate between views (<C-w>w / <C-w>k)
-- gt & gT      navigate between tabs

-- Function to close all buffers not visible in windows
local function close_hidden_buffers()
  local visible_buffers = {}

  -- Get all visible buffers from all windows
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    visible_buffers[buf] = true
  end

  -- Close all buffers that are not visible
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    -- if vim.api.nvim_buf_is_loaded(buf) and not visible_buffers[buf] then
    if vim.bo[buf].buflisted and not visible_buffers[buf] then
      -- Only close if it's a normal buffer (not special buffers like terminals)
      local buftype = vim.bo[buf].buftype
      if buftype == "" then
        vim.api.nvim_buf_delete(buf, { force = false })
      end
    end
  end
end

map("n", "ù", "*")
map("n", "zz", "za", { desc = "Toggle fold" })
map("n", "<Enter>", "z.", { desc = "Center screen on cursor" })
map("n", "-", "<C-w>-", { desc = "Decrease height" })
map("n", "+", "<C-w>+", { desc = "Increase height" })
map("n", "_", "<C-w>_", { desc = "Max out height" })
map("n", "=", "<C-w>=", { desc = "Equally high and wide" })
map("n", "|", ":vsp<CR>", { desc = "Split vertically" })
map("n", "<Tab>", "<C-w>w", { desc = "Switch to next window" })
map("n", "<S-Tab>", "<C-w>k", { desc = "Switch to prev window" })
map("n", "<F3>", close_hidden_buffers, { desc = "Close all buffers not visible in windows", silent = true })
map("n", "<Space><F3>", "<Space>bo", { desc = "Delete other buffers", silent = true })
map("n", "<F4>", ":q!<CR>", { desc = "Close window" })
map("n", "<Space><F4>", ":bp<BAR>bd#<CR>", { desc = "Close buffer" })
map("n", "<F5>", ":%bd|e#|bd#<CR>", { desc = "Delete all buffers except current" })
map("n", "<BS>", "<C-o>", { desc = "Back to previous location" })
map("n", "<Cmd-h>", "H", { desc = "Display left buffer" })

-- DEBUG HELP
-- List all opened windows:
-- :lua for _, win in ipairs(vim.api.nvim_list_wins()) do local buf = vim.api.nvim_win_get_buf(win); print(string.format("Win %d -> Buf %d: %s (config: %s)", win, buf, vim.api.nvim_buf_get_name(buf), vim.inspect(vim.api.nvim_win_get_config(win)))) end

-- """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
-- " Tests
-- """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

vim.g.last_rspec_cmd = nil

-- map("n", ",tt", "<CMD>split | terminal<CR> | bin/rspec %<CR>", { desc = "Run current test" })
-- map("n", ",tr", ":w<cr>:!bin/rspec % --tag ~js<CR>", { desc = "Run current test file" })
-- map("n", ",te", ":w<cr>:!bin/rspec % --format documentation --tag ~js<CR>", { desc = "Test with documentation" })

map("n", ",tT", function()
  local current_file = vim.fn.expand("%")
  local cmd = "rspec " .. current_file

  vim.g.last_rspec_cmd = cmd

  vim.cmd("split") -- OR smaller terminal with: vim.cmd("botright 15split")
  vim.cmd("terminal " .. cmd)
  vim.cmd("startinsert")
end, { desc = "Run test file" })

map("n", ",tt", function()
  local current_file = vim.fn.expand("%")
  local current_line = vim.fn.line(".")
  local cmd = "rspec " .. current_file .. ":" .. current_line

  vim.g.last_rspec_cmd = cmd

  vim.cmd("split") -- OR smaller terminal with: vim.cmd("botright 15split")
  vim.cmd("terminal " .. cmd)
  vim.cmd("startinsert")
end, { desc = "Run current test" })

map("n", ",tr", function()
  local cmd
  if vim.g.last_rspec_cmd then
    cmd = vim.g.last_rspec_cmd
  else
    local current_file = vim.fn.expand("%")
    local current_line = vim.fn.line(".")
    cmd = "rspec " .. current_file .. ":" .. current_line

    vim.g.last_rspec_cmd = cmd
  end

  vim.cmd("split")
  vim.cmd("terminal " .. cmd)
  vim.cmd("startinsert")
end, { desc = "Rerun last test" })

-- """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
-- " Git
-- """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

-- map("n", "<Space>gc", function()
--   local commit = vim.fn.systemlist(
--     "git log -1 --pretty=format:%H " .. vim.fn.expand("%") .. " -L " .. vim.fn.line(".") .. ",+1:" .. vim.fn.expand("%")
--   )[1]
--   if commit then
--     vim.fn.system("gh browse " .. commit)
--   end
-- end, { desc = "Open commit for current line in GitHub" })

map("n", "<Space>gc", function()
  -- require("gitsigns").blame_line({ full = true })
  -- Or use this for direct GitHub opening:
  local file = vim.fn.expand("%")
  local line = vim.fn.line(".")
  local commit = vim.fn.systemlist("git log -n 1 --pretty=format:%H -L " .. line .. "," .. line .. ":" .. file)[1]

  if commit and commit ~= "" then
    vim.cmd("!gh browse " .. commit)
  else
    vim.notify("No commit found for current line", vim.log.levels.WARN)
  end
end, { desc = "Open commit in GitHub" })

-- """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
-- " Terminal
-- """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

map("n", "<F2>", "<CMD>split | terminal<CR>", { desc = "Open Terminal" })

-- """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
-- " File shortcuts
-- """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

map("n", ",vl", ":tabe ~/.config/nvim/lua/config/lazy.lua<CR>")
map("n", ",vi", ":tabe ~/.config/nvim/lua/config/keymaps.lua<CR>")
map("n", ",vo", ":tabe ~/.config/nvim/lua/config/options.lua<CR>")
map("n", ",va", ":tabe ~/.config/nvim/lua/config/autocmds.lua<CR>")
map("n", ",vr", ":tabe ~/.config/nvim/lua/plugins/rails.lua<CR>")
map("n", ",vn", ":tabe ~/.config/nvim/lua/plugins/neotest.lua<CR>")
map("n", ",vs", function()
  require("telescope.builtin").find_files({ search_dirs = { "~/.claude/" }, prompt_title = "Find Claude" })
end)
map("n", ",ee", ":tabe ~/.espanso.yml<CR>")
map("n", ",zz", ":tabe ~/.zshrc<CR>")
map("n", ",ab", ":tabe app/models/ability.rb<CR>")
map("n", ",ev", ":tabe .env<CR>")
map("n", ",gm", ":tabe Gemfile<CR>")
map("n", ",rt", ":tabe config/routes.rb<CR>")
map("n", ",sc", ":tabe config/schedule.rb<cr>")
map("n", ",sk", ":tabe db/structure.sql<cr>")
map("n", ",dn", ":tabe ~/Dropbox/Rails/rails-freelance-neocamino.txt<cr>")

map("n", ",lm", function()
  local last_migration = vim.fn.system("ls -t db/migrate/*.rb 2>/dev/null | head -1"):gsub("%s+$", "")
  if last_migration ~= "" then
    vim.cmd("edit " .. last_migration)
  else
    vim.notify("No migration files found", vim.log.levels.WARN)
  end
end, { desc = "Open last Rails migration" })
