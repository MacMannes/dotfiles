-- Override clangd cmd to add --query-driver, which makes clangd fetch system
-- includes from the actual cross-compiler instead of Apple's headers.
-- Without it, macOS <cmath> triggers "no member named acoshl in the global
-- namespace" on ESP32/Arduino projects.
--
-- The full cmd is copied from lazyvim/plugins/extras/lang/clangd.lua so the
-- array replacement (Lazy deep_extend doesn't merge arrays) keeps all flags.
return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                clangd = {
                    cmd = {
                        "clangd",
                        "--background-index",
                        "--clang-tidy",
                        "--header-insertion=iwyu",
                        "--completion-style=detailed",
                        "--function-arg-placeholders",
                        "--fallback-style=llvm",
                        "--query-driver="
                            .. "/Users/andre/.platformio/packages/toolchain-xtensa-esp32s3/bin/xtensa-esp32s3-elf-g++,"
                            .. "/Users/andre/.platformio/packages/toolchain-xtensa-esp32s3/bin/xtensa-esp32s3-elf-gcc,"
                            .. "/Users/andre/.platformio/packages/toolchain-riscv32-esp/bin/riscv32-esp-elf-g++,"
                            .. "/Users/andre/.platformio/packages/toolchain-riscv32-esp/bin/riscv32-esp-elf-gcc",
                    },
                },
            },
        },
    },
}
