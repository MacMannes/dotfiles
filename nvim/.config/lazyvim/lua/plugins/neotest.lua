return {
    { "marilari88/neotest-vitest" },
    {
        "nvim-neotest/neotest",
        opts = {
            adapters = {
                ["neotest-vitest"] = {
                    filter_dir = function(name, rel_path, root)
                        return name ~= "node_modules" and name ~= "integration-tests"
                    end,
                },
            },
        },
    },
}
