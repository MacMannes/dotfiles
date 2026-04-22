return {
  {
    "AlexandrosAlexiou/kotlin.nvim",
    ft = { "kotlin" },
    dependencies = {
      "mason.nvim",
      "mason-lspconfig.nvim",
    },
    config = function()
      require("kotlin").setup({
        root_markers = {
          "gradlew",
          ".git",
          "mvnw",
          "settings.gradle",
          "settings.gradle.kts",
        },
        jvm_args = {
          "-Xmx8g",
        },
        inlay_hints = {
          enabled = true,
        },
      })
    end,
  },

  -- Ensure kotlin-lsp is installed via Mason
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "kotlin-lsp" } },
  },

  -- Disable LazyVim's automatic kotlin_lsp setup (kotlin.nvim handles it as kotlin_ls)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_lsp = { enabled = false },
      },
    },
  },

  -- Ensure treesitter has Kotlin parser
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "kotlin" } },
  },
}
