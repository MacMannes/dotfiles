-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.cmd("set splitright")

vim.opt.listchars = {
    tab = "» ",
    trail = "·",
    nbsp = "␣",
    extends = "…",
}

vim.g.snacks_animate = false
vim.g.lazyvim_ts_lsp = "tsgo"

-- Show CWD and file name in title of terminal app
vim.o.title = true
vim.o.titlelen = 0

local last_filename = ""

local function update_title()
    local pwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
    local filename = vim.fn.expand("%:t") -- Get the current file name

    if filename ~= "" then
        last_filename = filename -- Update cache only when a valid filename exists
    end

    if last_filename == "" then
        vim.o.titlestring = "lazyvim - " .. pwd
    else
        vim.o.titlestring = "lazyvim - " .. pwd .. " - " .. last_filename
    end
end

-- Set the title initially
update_title()

-- Auto-update title on relevant events
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "BufWritePost", "CursorHold" }, {
    pattern = "*",
    callback = update_title,
})

-- Save the terminal's title on the terminal's own title-stack when Neovim
-- starts, and pop it back off when Neovim exits. Supported by Ghostty,
-- iTerm2, kitty, WezTerm and xterm (compiled with title-stack support).
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        io.write("\27[22;0t")
    end,
})

vim.api.nvim_create_autocmd("VimLeave", {
    callback = function()
        io.write("\27[23;0t")
    end,
})

-- Spell checking
vim.o.spell = true
vim.o.spelllang = "en_us,nl"
vim.o.spelloptions = "camel"

vim.o.mousemodel = "popup_setpos"

-- Disable automatic system clipboard sync
vim.opt.clipboard = ""
