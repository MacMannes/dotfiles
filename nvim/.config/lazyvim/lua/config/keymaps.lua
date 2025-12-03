-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Yank whole line
vim.keymap.set("n", "Y", "yy")

-- Copy / Paste from system clipboard
vim.keymap.set("v", "<leader>y", '"+y', { desc = "Copy to system clipboard" })
vim.keymap.set("v", "<D-c>", '"+y', { desc = "Copy to system clipboard" })
vim.keymap.set("n", "<leader>p", '"+p', { desc = "Paste from system clipboard" })

-- Comments
vim.keymap.set("v", "<D-/>", function()
    vim.cmd.norm("gc")
end)
vim.keymap.set("n", "<D-/>", function()
    vim.cmd.norm("gcc")
end)

-- Next diagnostic
vim.keymap.set("n", "<F2>", function()
    vim.cmd.norm("]d")
end)

-- Save file
vim.keymap.set("n", "<D-s>", "<cmd>w<CR>", { silent = true })

vim.keymap.set("n", "<leader>rn", "<leader>cr", { remap = true, desc = "[R]e[N]ame" })

-- Debugging
local dap = require("dap")

vim.keymap.set("n", "<a-CR>", vim.lsp.buf.code_action, { desc = "[C]ode [A]ction" }) -- Alt + Enter

vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Continue" })
vim.keymap.set("n", "<F8>", dap.toggle_breakpoint, { desc = "Debug: Toggle breakpoint" })
vim.keymap.set("n", "<F9>", dap.step_over, { desc = "Debug: Step over" })
vim.keymap.set("n", "<S-F9>", dap.step_into, { desc = "Debug: Step into" })
vim.keymap.set("n", "<F7>", dap.step_out, { desc = "Debug: Step out" })
vim.keymap.set("n", "<F12>", dap.terminate, { desc = "Debug: Quit" })

-- Visual selection remappings

-- Shift + Arrow for Visual Line Mode and move into that direction
vim.keymap.set("n", "<S-Down>", "Vj", { noremap = true, silent = true })
vim.keymap.set("n", "<S-Up>", "Vk", { noremap = true, silent = true })
vim.keymap.set("n", "<S-Left>", "vbh", { noremap = true, silent = true })
vim.keymap.set("n", "<S-Right>", "vbl", { noremap = true, silent = true })

-- When in Visual mode, make Shift+Arrow keys behave as regular Arrow keys
vim.keymap.set("v", "<S-Down>", "j", { noremap = true, silent = true })
vim.keymap.set("v", "<S-Up>", "k", { noremap = true, silent = true })
vim.keymap.set("v", "<S-Left>", "h", { noremap = true, silent = true })
vim.keymap.set("v", "<S-Right>", "l", { noremap = true, silent = true })

-- Move highlighted Code
vim.keymap.set("n", "<A-Down>", ":m .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "<A-Up>", ":m .-2<CR>==", { desc = "Move line up" })
vim.keymap.set("i", "<A-Down>", "<Esc>:m .+1<CR>==gi", { desc = "Move line down" })
vim.keymap.set("i", "<A-Up>", "<Esc>:m .-2<CR>==gi", { desc = "Move line up" })
vim.keymap.set("v", "<A-Down>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "<A-Up>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
