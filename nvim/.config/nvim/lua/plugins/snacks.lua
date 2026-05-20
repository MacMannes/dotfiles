return {
    "snacks.nvim",
    opts = {
        indent = { enabled = true },
        scroll = { enabled = false },
        lazygit = { configure = false },
        picker = {
            sources = {
                explorer = {
                    win = {
                        list = {
                            keys = {
                                ["."] = "toggle_hidden",
                            },
                        },
                    },
                },
                files = {
                    hidden = true,
                    ignored = false,
                },
                grep = {
                    hidden = true,
                    ignored = false,
                },
            },
        },
    },
    keys = {
        -- stylua: ignore start
        { "<leader><leader>", function() Snacks.picker.buffers() end,                desc = "Find existing buffers" },
        { "<D-e>",            function() Snacks.explorer() end,                      desc = "File Explorer", },
        { "<D-o>",            function() Snacks.picker.files({ hidden = true }) end, desc = "Find Files" },
        { "<D-w>",            function() Snacks.bufdelete() end,                     desc = "Delete Buffer" },
        { "z=",               function() Snacks.picker.spelling() end,               desc = "spelling suggestions" },


        {
            "<leader>fp",
            function()
                Snacks.picker.projects(
                    {
                        dev = { "~/Develop/NS/Backend/",
                            "~/Develop/NS/Cloud/",
                            "~/Develop/NS/Dojo/",
                            "~/Develop/NS/Serverless/",
                            "~/Develop/NS/Web/",
                            "~/Develop/MacMannes/Backend/",
                            "~/Develop/MacMannes/Cloud/",
                            "~/Develop/MacMannes/Embedded/",
                            "~/Develop/MacMannes/Serverless/",
                            "~/Develop/MacMannes/HomeAutomation/",

                        },
                        patterns = { ".git", "package.json", "gradlew" },
                    })
            end,
            desc = "Projects",
        },

        --stylua: ignore end
    },
}
