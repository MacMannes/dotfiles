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
      -- Mason installs kotlin-lsp into a versioned subdirectory; find it dynamically
      local mason_kotlin_base = vim.fn.expand("$MASON/packages/kotlin-lsp")
      local kotlin_lsp_dir = mason_kotlin_base
      if vim.fn.isdirectory(mason_kotlin_base .. "/lib") ~= 1 then
        -- Find the versioned subdirectory (e.g. kotlin-server-x.y.z)
        local handle = vim.loop.fs_scandir(mason_kotlin_base)
        if handle then
          while true do
            local name, ftype = vim.loop.fs_scandir_next(handle)
            if not name then break end
            if ftype == "directory" and name:match("^kotlin%-server") then
              kotlin_lsp_dir = mason_kotlin_base .. "/" .. name
              break
            end
          end
        end
      end
      vim.env.KOTLIN_LSP_DIR = kotlin_lsp_dir

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
