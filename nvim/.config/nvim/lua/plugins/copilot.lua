return {
    {
        "zbirenbaum/copilot.lua",
        opts = {
            filetypes = {
                conf = false,
                dosini = false,
                systemd = false,
                hyperlang = false,
            },
        },
    },
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        dependencies = {
            "zbirenbaum/copilot.lua",
        },
        opts = {},
        keys = {
            { "<leader>aa", "<cmd>CopilotChatToggle<cr>", desc = "Toggle Copilot Chat" },
            { "<leader>aq", function()
                local input = vim.fn.input("Quick Chat: ")
                if input ~= "" then
                    require("CopilotChat").ask(input, { selection = require("CopilotChat.select").visual })
                end
            end, mode = { "n", "v" }, desc = "Quick Chat" },
        },
    },
}
