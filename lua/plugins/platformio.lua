return {
  "anurag3301/nvim-platformio.lua",

  cond = function()
    -- local platformioRootDir = vim.fs.root(vim.fn.getcwd(), { 'platformio.ini' }) -- cwd and parents
    local platformioRootDir = (vim.fn.filereadable("platformio.ini") == 1) and vim.fn.getcwd() or nil
    if platformioRootDir then
      -- if platformio.ini file exist in cwd, enable plugin to install plugin (if not istalled) and load it.
      vim.g.platformioRootDir = platformioRootDir
    elseif (vim.uv or vim.loop).fs_stat(vim.fn.stdpath("data") .. "/lazy/nvim-platformio.lua") == nil then
      -- if nvim-platformio not installed, enable plugin to install it first time
      vim.g.platformioRootDir = vim.fn.getcwd()
    else -- if nvim-platformio.lua installed but disabled, create Pioinit command
      vim.api.nvim_create_user_command("Pioinit", function() --available only if no platformio.ini and .pio in cwd
        vim.api.nvim_create_autocmd("User", {
          pattern = { "LazyRestore", "LazyLoad" },
          once = true,
          callback = function(args)
            if args.match == "LazyRestore" then
              require("lazy").load({ plugins = { "nvim-platformio.lua" } })
            elseif args.match == "LazyLoad" then
              local pio_install_status = require("platformio.utils").pio_install_check()
              if not pio_install_status then
                return
              end
              vim.notify("PlatformIO loaded", vim.log.levels.INFO, { title = "PlatformIO" })
              require("platformio").setup(vim.g.pioConfig)
              vim.cmd("Pioinit")
            end
          end,
        })
        vim.g.platformioRootDir = vim.fn.getcwd()
        require("lazy").restore({ plguins = { "nvim-platformio.lua" }, show = false })
      end, {})
    end
    return vim.g.platformioRootDir ~= nil
  end,

  config = function()
    vim.g.pioConfig = {
      lsp = "clangd", -- value: clangd | ccls
      clangd_source = "compiledb", -- value: ccls | compiledb, For detailed explation check :help platformio-clangd_source
      picker_backend = "auto", -- value: auto | telescope | snacks | mini_pick | ui_select
      menu_key = "<leader>\\",
      debug = false, -- enable debug messages
    }

    local ok, platformio = pcall(require, "platformio")
    if not ok then
      vim.notify("Failed to load PlatformIO plugin", vim.log.levels.ERROR)
      return
    end

    platformio.setup(vim.g.pioConfig)
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
}
