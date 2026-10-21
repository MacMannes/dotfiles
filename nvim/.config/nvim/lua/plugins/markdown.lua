return {
    -- Silence markdownlint line-length (MD013) & friends in markdown buffers,
    -- unless the project provides its own markdownlint config.
    {
        "mfussenegger/nvim-lint",
        opts = function()
            local linter = require("lint").linters["markdownlint-cli2"]
            if linter then
                local fallback = vim.fn.stdpath("config") .. "/global.markdownlint-cli2.yaml"
                -- nvim-lint requires `args` to be a list (entries may be functions).
                local function config_path()
                    local found = vim.fs.find({
                        ".markdownlint-cli2.jsonc",
                        ".markdownlint-cli2.yaml",
                        ".markdownlint-cli2.cjs",
                        ".markdownlint.json",
                        ".markdownlint.jsonc",
                        ".markdownlint.yaml",
                        ".markdownlint.yml",
                    }, { upward = true, path = vim.fn.expand("%:p:h") })[1]
                    return found or fallback
                end
                linter.args = { "--config", config_path, "-" }
            end
        end,
    },
}
