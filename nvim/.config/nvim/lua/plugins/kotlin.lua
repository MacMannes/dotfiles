return {
  -- Kotlin DAP debugging
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      "mason-org/mason.nvim",
    },
    opts = function()
      local dap = require("dap")

      dap.adapters.kotlin = {
        type = "executable",
        command = vim.fn.stdpath("data") .. "/mason/bin/kotlin-debug-adapter",
      }

      dap.configurations.kotlin = {
        {
          type = "kotlin",
          request = "launch",
          name = "Launch Kotlin (main class)",
          projectRoot = "${workspaceFolder}",
          mainClass = function()
            return vim.fn.input("Main class (e.g. com.example.MainKt): ")
          end,
        },
        {
          type = "kotlin",
          request = "attach",
          name = "Attach to JVM (port 5005)",
          hostName = "localhost",
          port = 5005,
          timeout = 10000,
          projectRoot = "${workspaceFolder}",
        },
      }
    end,
  },

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

  -- Ensure kotlin tools are installed via Mason
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "kotlin-lsp", "kotlin-debug-adapter" } },
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
