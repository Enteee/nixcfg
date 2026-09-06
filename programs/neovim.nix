{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # 26.05 default. None of the plugins below use the Ruby or Python3
    # remote-plugin providers, so drop them from the closure.
    withRuby = false;
    withPython3 = false;

    # Language servers enabled in initLua below. Without these on PATH every
    # buffer spawns four servers that fail to start.
    extraPackages = with pkgs; [
      nil           # nix
      pyright       # python
      clang-tools   # clangd
      rust-analyzer # rust
    ];

    plugins = with pkgs.vimPlugins; [
      # file explorer
      nvim-tree-lua
      nvim-web-devicons

      # fuzzy finder
      telescope-nvim
      plenary-nvim

      # LSP
      nvim-lspconfig

      # completion
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      luasnip
      cmp_luasnip

      # syntax highlighting
      nvim-treesitter.withAllGrammars

      # git integration
      gitsigns-nvim

      # statusline
      lualine-nvim

      # language specific
      rust-vim
    ];

    initLua = ''
      -- Leader key
      vim.g.mapleader = " "

      -- Line numbers
      vim.opt.number = true
      vim.opt.relativenumber = true

      -- Tabs and indentation
      vim.opt.expandtab = true
      vim.opt.shiftwidth = 2
      vim.opt.tabstop = 4
      vim.opt.softtabstop = 2

      -- Show whitespace characters
      vim.opt.list = true
      vim.opt.listchars = { eol = "$", tab = ">-", trail = "~", extends = ">", precedes = "<" }

      -- Max line length indicator
      vim.opt.colorcolumn = "80"

      -- Use system clipboard
      vim.opt.clipboard = "unnamed,unnamedplus"

      -- No auto-indenting
      vim.opt.cindent = false
      vim.opt.smartindent = false
      vim.opt.autoindent = false

      -- Insert literal tab with shift+tab
      vim.keymap.set("i", "<S-Tab>", "<C-V><Tab>")

      -- Telescope
      local telescope = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", telescope.find_files)
      vim.keymap.set("n", "<leader>fg", telescope.live_grep)
      vim.keymap.set("n", "<leader>fb", telescope.buffers)

      -- Nvim-tree
      require("nvim-tree").setup()
      vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { silent = true })

      -- Gitsigns
      require("gitsigns").setup()

      -- Lualine
      require("lualine").setup({
        options = { theme = "auto" },
      })

      -- Treesitter. The main-branch rewrite dropped nvim-treesitter.configs,
      -- so highlighting is started per buffer instead. Grammars come from
      -- withAllGrammars; pcall keeps filetypes without a parser quiet.
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })

      -- LSP. nvim-lspconfig 2.x ships lsp/<server>.lua definitions that
      -- Neovim's built-in vim.lsp.config consumes directly; the old
      -- require("lspconfig") framework is deprecated and is removed in 3.0.
      vim.lsp.config("*", {
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
      })
      vim.lsp.enable({
        "nil_ls",        -- nix
        "pyright",       -- python
        "clangd",        -- c/c++
        "rust_analyzer", -- rust
      })

      -- LSP keybindings
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local opts = { buffer = ev.buf }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts)
        end,
      })

      -- Completion
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
    '';
  };
}
