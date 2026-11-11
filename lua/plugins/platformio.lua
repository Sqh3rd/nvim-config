return {
  {
    "batoaqaa/nvim-pio",
    lazy = false,
    dependencies = {
      { "nvim-telescope/telescope.nvim" },
      { "nvim-telescope/telescope-ui-select.nvim" },
      { "nvim-lua/plenary.nvim" },
      { "folke/which-key.nvim" },
      { "mason-org/mason-lspconfig.nvim" },
    },
    config = function()
      require("nvimpio").setup({
        pio = {
          pio_runtime_dir = "~/.platformio",
          pio_storage_dir = "~/.platformio",
        },
        clangd = {
          support = true, -- Master switch for PlatformIO LSP logic
          install = false, -- Flags whether to auto-install missing clangd
          -- Configures attach integration behavior.
          -- Options:
          --   "attach+" -> Attach the LSP client AND inject default hotkeys.
          --   "attach"  -> Attach the LSP client only (no custom hotkeys).
          --   "none"    -> Do not attach to files at all.
          attach = "attach+",
        },
        menu_key = "<leader>\\", -- Local workspace menu activation mapping
        menu_name = "PlatformIO", -- Interactive dashboard selection label
      })
    end,
  },
  {
    "anurag3301/nvim-platformio.lua",

    cond = function()
      return false
      -- -- local platformioRootDir = vim.fs.root(vim.fn.getcwd(), { 'platformio.ini' }) -- cwd and parents
      -- local platformioRootDir = (vim.fn.filereadable("platformio.ini") == 1) and vim.fn.getcwd() or nil
      -- if platformioRootDir then
      --   -- if platformio.ini file exist in cwd, enable plugin to install plugin (if not istalled) and load it.
      --   vim.g.platformioRootDir = platformioRootDir
      -- elseif (vim.uv or vim.loop).fs_stat(vim.fn.stdpath("data") .. "/lazy/nvim-platformio.lua") == nil then
      --   -- if nvim-platformio not installed, enable plugin to install it first time
      --   vim.g.platformioRootDir = vim.fn.getcwd()
      -- else -- if nvim-platformio.lua installed but disabled, create Pioinit command
      --   vim.api.nvim_create_user_command("Pioinit", function() --available only if no platformio.ini and .pio in cwd
      --     vim.api.nvim_create_autocmd("User", {
      --       pattern = { "LazyRestore", "LazyLoad" },
      --       once = true,
      --       callback = function(args)
      --         if args.match == "LazyRestore" then
      --           require("lazy").load({ plugins = { "nvim-platformio.lua" } })
      --         elseif args.match == "LazyLoad" then
      --           local pio_install_status = require("platformio.utils").pio_install_check()
      --           if not pio_install_status then
      --             return
      --           end
      --           vim.notify("PlatformIO loaded", vim.log.levels.INFO, { title = "PlatformIO" })
      --           require("platformio").setup(vim.g.pioConfig)
      --           vim.cmd("Pioinit")
      --         end
      --       end,
      --     })
      --     vim.g.platformioRootDir = vim.fn.getcwd()
      --     require("lazy").restore({ plguins = { "nvim-platformio.lua" }, show = false })
      --   end, {})
      -- end
      -- return vim.g.platformioRootDir ~= nil
    end,

    cmd = {
      "Pioinit",
      "PioLSP",
      "Piorun",
      "Piocmdh",
      "Piocmdf",
      "Piolib",
      "Piomon",
      "Piolsserial",
      "Piodebug",
      "PioTermList",
    },

    -- Dependencies are lazy-loaded by default unless specified otherwise.
    dependencies = {
      { "akinsho/toggleterm.nvim" },
      { "nvim-lua/plenary.nvim" },
      { "folke/which-key.nvim" },
      { "nvim-treesitter/nvim-treesitter" },

      -- install picker based on your likeing, remove or ignore rest

      -- telescope
      { "nvim-telescope/telescope.nvim" },
      { "nvim-telescope/telescope-ui-select.nvim" },

      -- Snacks picker
      { "folke/snacks.nvim", opts = {
        picker = { enabled = true, ui_select = true },
      } },

      -- Mini.Pick
      { "nvim-mini/mini.pick" },
    },

    ft = {
      "c",
      "h",
      "cpp",
      "hpp",
      "ino",
    },

    config = function()
      vim.g.pioConfig = {
        lsp = "clangd", -- or "ccls"
        clangd_source = "compiledb",
        menu_key = "<leader>\\",
        debug = false,
      }

      local ok, platformio = pcall(require, "platformio")
      if not ok then
        vim.notify("Failed to load PlatformIO plugin", vim.log.levels.ERROR)
        return
      end

      platformio.setup(vim.g.pioConfig)

      -- Get all environments from platformio.ini
      local function get_envs()
        local fname = vim.fn.getcwd() .. "/platformio.ini"
        if vim.fn.filereadable(fname) ~= 1 then
          return {}
        end
        local envs = {}
        for _, line in ipairs(vim.fn.readfile(fname)) do
          local env = line:match("%[env:(.+)%]")
          if env then
            table.insert(envs, env)
          end
        end
        return envs
      end

      -- Clean unwanted flags from compile_commands.json
      local function clean_compile_commands()
        local fname = vim.fn.getcwd() .. "/compile_commands.json"
        if vim.fn.filereadable(fname) ~= 1 then
          return
        end

        local f = io.open(fname, "r")
        local data = f:read("*a")
        f:close()

        local ok, json = pcall(require, "dkjson")
        if not ok then
          return
        end
        local arr, _, err = json.decode(data)
        if err then
          vim.notify("Failed to parse compile_commands.json: " .. err, vim.log.levels.ERROR)
          return
        end

        local remove_flags = {
          "-mlongcalls",
          "-mlong-calls",
          "-fstrict-volatile-bitfields",
          "-fno-tree-switch-conversion",
        }

        for _, entry in ipairs(arr) do
          if entry.arguments then
            entry.arguments = vim.tbl_filter(function(a)
              for _, flag in ipairs(remove_flags) do
                if a == flag then
                  return false
                end
              end
              return true
            end, entry.arguments)
          end
        end

        f = io.open(fname, "w")
        f:write(json.encode(arr, { indent = true }))
        f:close()
      end

      -- Optional: generate minimal .clangd
      local function generate_clangd_file()
        local f = io.open(".clangd", "w")
        if not f then
          return
        end
        f:write("CompileFlags:\n")
        f:write("  Remove:\n")
        f:write("    - -mlongcalls\n")
        f:write("    - -mlong-calls\n")
        f:write("    - -fstrict-volatile-bitfields\n")
        f:write("    - -fno-tree-switch-conversion\n")
        f:write("Diagnostics:\n")
        f:write("  Suppress:\n")
        f:write("    - drv_unknown_argument\n")
        f:write("    - drv_unsupported_opt_for_target\n")
        f:write("    - pp_file_not_found\n")
        f:close()
      end

      -- Generate compile_commands.json for all environments
      local function generate_compiler()
        local envs = get_envs()
        if #envs == 0 then
          vim.notify("No PlatformIO environments found!", vim.log.levels.ERROR)
          return
        end

        for _, env in ipairs(envs) do
          vim.notify("Generating compile_commands.json for env: " .. env, vim.log.levels.INFO)
          local cmd = { "pio", "run", "-e", env, "-t", "compiledb" }
          vim.fn.system(cmd)
          clean_compile_commands()
        end

        generate_clangd_file()
        vim.cmd("LspRestart")
      end

      -- Auto-generate compile_commands.json and attach LSP on opening C/C++ files
      vim.api.nvim_create_autocmd("BufReadPost", {
        pattern = { "*.c", "*.cpp", "*.h", "*.hpp", "platformio.ini" },
        callback = generate_compiler,
      })

      -- Manual fallback command
      vim.api.nvim_create_user_command("PioLSP", generate_compiler, {
        desc = "Generate compile_commands.json, .clangd, and attach PlatformIO LSP",
      })

      -- Auto-generate immediately if platformio.ini exists
      if vim.fn.filereadable(vim.fn.getcwd() .. "/platformio.ini") == 1 then
        vim.defer_fn(generate_compiler, 100)
      end
    end,
  },
}
