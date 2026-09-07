return {
    -- Silence markdownlint line-length (MD013) & friends in markdown buffers,
    -- unless the project provides its own markdownlint config.
    {
        "mfussenegger/nvim-lint",
        opts = function()
            local linter = require("lint").linters["markdownlint-cli2"]
            if linter then
                local fallback = vim.fn.stdpath("config") .. "/global.markdownlint-cli2.yaml"
                linter.args = function()
                    local found = vim.fs.find({
                        ".markdownlint-cli2.jsonc",
                        ".markdownlint-cli2.yaml",
                        ".markdownlint-cli2.cjs",
                        ".markdownlint.json",
                        ".markdownlint.jsonc",
                        ".markdownlint.yaml",
                        ".markdownlint.yml",
                    }, { upward = true, path = vim.fn.expand("%:p:h") })[1]
                    if found then
                        return { "-" }
                    end
                    return { "--config", fallback, "-" }
                end
            end
        end,
    },
}
