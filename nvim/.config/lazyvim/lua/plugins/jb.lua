return {
    "nickkadutskyi/jb.nvim",
    lazy = false,
    priority = 1000,
    opts = {
        transparent = false,
        snacks = {
            explorer = {
                -- Enable folke/snacks.nvim styling for explorer
                enabled = true,
            },
        },
    },
    init = function()
        -- Set custom highlights for line numbers
        vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#7a7e85", bold = false })
        vim.api.nvim_set_hl(0, "LineNr", { fg = "#ce8e6d", bold = true })
        vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#7a7e85", bold = false })

        -- Colors for NeoTest
        vim.api.nvim_set_hl(0, "NeotestAdapterName", { fg = "#ce8e6d", bold = true })
        vim.api.nvim_set_hl(0, "NeotestDir", { fg = "#b6b7be" })
        vim.api.nvim_set_hl(0, "NeotestFile", { fg = "#57a8f5" })
        vim.api.nvim_set_hl(0, "NeotestNamespace", { fg = "#c87dba" })
        vim.api.nvim_set_hl(0, "NeotestSkipped", { fg = "#57a8f5" })
        vim.api.nvim_set_hl(0, "NeotestPassed", { fg = "#57965c" })
        vim.api.nvim_set_hl(0, "NeotestFailed", { fg = "#db5c5c" })

        -- Package-info color
        vim.api.nvim_set_hl(0, "PackageInfoOutdatedVersion", { fg = "#d19a66", bold = false })

        vim.api.nvim_set_hl(0, "FoldColumn", { bg = "" })
        vim.api.nvim_set_hl(0, "CursorLine", { bg = "#43454a" })
        vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#858a94", bg = "#2c2d31" })
        vim.api.nvim_set_hl(0, "SnacksPickerBorder", { fg = "#393b40" })
        vim.api.nvim_set_hl(0, "SnacksPickerBorderPreview", { fg = "#0000ff" })
        vim.api.nvim_set_hl(0, "SnacksPickerInputBorder", { fg = "#393b40", bg = "#2c2d31" })
        vim.api.nvim_set_hl(0, "SnacksPickerPrompt", { fg = "#79797a" })
        vim.api.nvim_set_hl(0, "SnacksIndent", { fg = "#323438" })
        vim.api.nvim_set_hl(0, "SnacksIndentScope", { fg = "#65676f" })
        vim.api.nvim_set_hl(0, "SnacksIndentChunk", { fg = "#65676f" })
        vim.api.nvim_set_hl(0, "SnacksPickerList", { fg = "#02afff", bg = "#2b2d30" })
        vim.api.nvim_set_hl(0, "MsgArea", { fg = "#95979e" })
        vim.api.nvim_set_hl(0, "NoiceFormatProgressDone", { bg = "#1e1f21" })
        vim.api.nvim_set_hl(0, "NoiceFormatProgressTodo", { bg = "#1e1f21" })
        vim.api.nvim_set_hl(0, "WinBar", { bg = "#2b2d30", fg = "#f0f0ea" })
        vim.api.nvim_set_hl(0, "WinBarNC", { bg = "#2b2d30", fg = "#f0f0ea" })
        vim.api.nvim_set_hl(0, "DiagnosticHint", { fg = "#c29e49" })
        vim.api.nvim_set_hl(0, "MacMannes", { bg = "#0000ff", fg = "#fffc79" })
    end,
}
