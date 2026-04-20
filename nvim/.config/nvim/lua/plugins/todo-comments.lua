return {
    "folke/todo-comments.nvim",
    opts = {
        -- Add lowercase and mixed-case aliases for each keyword.
        -- The highlight.lua source hardcodes \C (case-sensitive) in its regex,
        -- so case-insensitive matching via patterns is not possible without patching.
        keywords = {
            FIX = { alt = { "FIXME", "BUG", "FIXIT", "ISSUE", "fix", "fixme", "bug", "Fix", "Fixme" } },
            TODO = { alt = { "todo", "Todo" } },
            WARN = { alt = { "WARNING", "XXX", "warn", "warning", "Warn", "Warning" } },
            PERF = { alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE", "perf", "optim", "Perf" } },
        },
    },
}
