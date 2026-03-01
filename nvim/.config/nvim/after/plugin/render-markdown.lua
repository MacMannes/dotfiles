require("render-markdown").setup({
    html = {
        comment = {
            text = function(ctx)
                return ctx.text:match("^<!%-%-%s*(.-)%s*%-%->$")
            end,
        },
    },
})
