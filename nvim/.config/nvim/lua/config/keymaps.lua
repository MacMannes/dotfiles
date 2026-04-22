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

-- Debug nearest Kotlin/Java test via Gradle --debug-jvm + DAP attach
vim.keymap.set("n", "<leader>tg", function()
    local lib = require("neotest.lib")
    local file_path = vim.api.nvim_buf_get_name(0)

    -- Find gradle root
    local root_dir = lib.files.match_root_pattern("gradlew")(file_path)
    if not root_dir then
        vim.notify("No gradlew found", vim.log.levels.ERROR)
        return
    end

    -- Determine subproject task
    local relative = file_path:sub(#root_dir + 2)
    local subproject_name = relative:match("^(.+)/src/")
    local gradle_task
    if subproject_name and subproject_name ~= "" then
        gradle_task = ":" .. subproject_name:gsub("/", ":") .. ":test"
    else
        gradle_task = ":test"
    end

    -- Get package name from file
    local package_name = ""
    for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, 20, false)) do
        local match = line:match("^%s*package%s+([%w%.]+)")
        if match then
            package_name = match
            break
        end
    end

    -- Get class name from filename
    local class_name = vim.fn.fnamemodify(file_path, ":t:r")
    local test_filter = package_name .. "." .. class_name

    -- Try to find the nearest test method using treesitter
    local ts_utils_ok, _ = pcall(require, "nvim-treesitter.ts_utils")
    if ts_utils_ok then
        local cursor_node = vim.treesitter.get_node()
        while cursor_node do
            local node_type = cursor_node:type()
            if node_type == "function_declaration" or node_type == "method_declaration" then
                local name_node = cursor_node:field("name")[1]
                if name_node then
                    local method_name = vim.treesitter.get_node_text(name_node, 0)
                    test_filter = test_filter .. "." .. method_name .. "*"
                end
                break
            end
            cursor_node = cursor_node:parent()
        end
    end

    local gradle_cmd = root_dir
        .. "/gradlew --project-dir "
        .. root_dir
        .. " "
        .. gradle_task
        .. " --tests '"
        .. test_filter
        .. "' --debug-jvm --rerun"

    vim.notify("Starting Gradle in debug mode...\n" .. gradle_cmd, vim.log.levels.INFO)

    -- Run gradle in background
    local attached = false
    vim.fn.jobstart(gradle_cmd, {
        stdout_buffered = false,
        stderr_buffered = false,
        on_stdout = function(_, data)
            for _, line in ipairs(data) do
                if not attached and line:match("Listening for transport") then
                    attached = true
                    vim.schedule(function()
                        vim.notify("JVM listening, attaching debugger...", vim.log.levels.INFO)
                        dap.run({
                            type = "kotlin",
                            request = "attach",
                            name = "Attach to Gradle test",
                            hostName = "localhost",
                            port = 5005,
                            timeout = 30000,
                            projectRoot = root_dir,
                        })
                    end)
                end
            end
        end,
        on_stderr = function(_, data)
            for _, line in ipairs(data) do
                if not attached and line:match("Listening for transport") then
                    attached = true
                    vim.schedule(function()
                        vim.notify("JVM listening, attaching debugger...", vim.log.levels.INFO)
                        dap.run({
                            type = "kotlin",
                            request = "attach",
                            name = "Attach to Gradle test",
                            hostName = "localhost",
                            port = 5005,
                            timeout = 30000,
                            projectRoot = root_dir,
                        })
                    end)
                end
            end
        end,
        on_exit = function(_, code)
            vim.schedule(function()
                if not attached then
                    vim.notify("Gradle exited (code " .. code .. ") before debugger could attach", vim.log.levels.WARN)
                end
            end)
        end,
    })
end, { desc = "Debug nearest test with Gradle --debug-jvm" })

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

-- Copy OpenCode file reference (@file#L<line>) to clipboard
vim.keymap.set("n", "<leader>ay", function()
    local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local ref = "@" .. path .. "#L" .. line
    vim.fn.setreg("+", ref)
    vim.notify("Copied: " .. ref)
end, { desc = "Copy OpenCode file reference" })

vim.keymap.set("v", "<leader>ay", function()
    local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
    local start_line = vim.fn.line("v")
    local end_line = vim.fn.line(".")
    if start_line > end_line then
        start_line, end_line = end_line, start_line
    end
    local ref
    if start_line == end_line then
        ref = "@" .. path .. "#L" .. start_line
    else
        ref = "@" .. path .. "#L" .. start_line .. "-" .. end_line
    end
    vim.schedule(function()
        vim.fn.setreg("+", ref)
        vim.notify("Copied: " .. ref)
    end)
end, { desc = "Copy OpenCode file reference (range)" })
