--[[

=====================================================================
==================== READ THIS BEFORE CONTINUING ====================
=====================================================================

Kickstart.nvim is *not* a distribution.

Kickstart.nvim is a template for your own configuration.
  The goal is that you can read every line of code, top-to-bottom, understand
  what your configuration is doing, and modify it to suit your needs.

  Once you've done that, you should start exploring, configuring and tinkering to
  explore Neovim!

  If you don't know anything about Lua, I recommend taking some time to read through
  a guide. One possible example:
  - https://learnxinyminutes.com/docs/lua/


  And then you can explore or search through `:help lua-guide`
  - https://neovim.io/doc/user/lua-guide.html


Kickstart Guide:

I have left several `:help X` comments throughout the init.lua
You should run that command and read that help section for more information.

In addition, I have some `NOTE:` items throughout the file.
These are for you, the reader to help understand what is happening. Feel free to delete
them once you know what you're doing, but they should serve as a guide for when you
are first encountering a few different constructs in your nvim config.

I hope you enjoy your Neovim journey,
- TJ

P.S. You can delete this when you're done too. It's your config now :)
--]]
-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- Install package manager
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

-- NOTE: Here is where you install your plugins.
--  You can configure plugins using the `config` key.
--
--  You can also configure plugins after the setup call,
--    as they will be available in your neovim runtime.
require('lazy').setup({
  -- NOTE: First, some plugins that don't require any configuration

  -- Git related plugins
  'tpope/vim-fugitive',

  -- Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',

  -- NOTE: This is where your plugins related to LSP can be installed.
  --  The configuration is done below. Search for lspconfig to find it below.
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    -- LSP Configuration & Plugins
    "mason-org/mason-lspconfig.nvim",
    opts = {},
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      'saghen/blink.lib',
      'saghen/blink.cmp',
      -- Useful status updates for LSP.
      { 'j-hui/fidget.nvim', opts = {} },
      { "neovim/nvim-lspconfig", opts = {},
        config = function()
          -- Brief aside: **What is LSP?**
          --
          -- LSP is an initialism you've probably heard, but might not understand what it is.
          --
          -- LSP stands for Language Server Protocol. It's a protocol that helps editors
          -- and language tooling communicate in a standardized fashion.
          --
          -- In general, you have a "server" which is some tool built to understand a particular
          -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
          -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
          -- processes that communicate with some "client" - in this case, Neovim!
          --
          -- LSP provides Neovim with features like:
          --  - Go to definition
          --  - Find references
          --  - Autocompletion
          --  - Symbol Search
          --  - and more!
          --
          -- Thus, Language Servers are external tools that must be installed separately from
          -- Neovim. This is where `mason` and related plugins come into play.
          --
          -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
          -- and elegantly composed help section, `:help lsp-vs-treesitter`

          --  This function gets run when an LSP attaches to a particular buffer.
          --    That is to say, every time a new file is opened that is associated with
          --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
          --    function will be executed to configure the current buffer
          vim.api.nvim_create_autocmd('LspAttach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
            callback = function(event)
              -- NOTE: Remember that Lua is a real programming language, and as such it is possible
              -- to define small helper and utility functions so you don't have to repeat yourself.
              --
              -- In this case, we create a function that lets us more easily define mappings specific
              -- for LSP related items. It sets the mode, buffer and description for us each time.
              local map = function(keys, func, desc, mode)
                mode = mode or 'n'
                vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
              end

              -- Rename the variable under your cursor.
              --  Most Language Servers support renaming across files, etc.
              map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

              -- Execute a code action, usually your cursor needs to be on top of an error
              -- or a suggestion from your LSP for this to activate.
              map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

              -- Find references for the word under your cursor.
              map('grr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

              -- Jump to the implementation of the word under your cursor.
              --  Useful when your language has ways of declaring types without an actual implementation.
              map('gri', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

              -- Jump to the definition of the word under your cursor.
              --  This is where a variable was first declared, or where a function is defined, etc.
              --  To jump back, press <C-t>.
              map('grd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

              -- WARN: This is not Goto Definition, this is Goto Declaration.
              --  For example, in C this would take you to the header.
              map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

              -- Fuzzy find all the symbols in your current document.
              --  Symbols are things like variables, functions, types, etc.
              map('gO', require('telescope.builtin').lsp_document_symbols, 'Open Document Symbols')

              -- Fuzzy find all the symbols in your current workspace.
              --  Similar to document symbols, except searches over your entire project.
              map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')

              -- Jump to the type of the word under your cursor.
              --  Useful when you're not sure what type a variable is and you want to see
              --  the definition of its *type*, not where it was *defined*.
              map('grt', require('telescope.builtin').lsp_type_definitions, '[G]oto [T]ype Definition')

              -- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
              ---@param client vim.lsp.Client
              ---@param method vim.lsp.protocol.Method
              ---@param bufnr? integer some lsp support methods only in specific files
              ---@return boolean
              local function client_supports_method(client, method, bufnr)
                if vim.fn.has 'nvim-0.11' == 1 then
                  return client:supports_method(method, bufnr)
                else
                  return client.supports_method(method, { bufnr = bufnr })
                end
              end

              -- The following two autocommands are used to highlight references of the
              -- word under your cursor when your cursor rests there for a little while.
              --    See `:help CursorHold` for information about when this is executed
              --
              -- When you move your cursor, the highlights will be cleared (the second autocommand).
              local client = vim.lsp.get_client_by_id(event.data.client_id)
              if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
                local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
                vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                  buffer = event.buf,
                  group = highlight_augroup,
                  callback = vim.lsp.buf.document_highlight,
                })

                vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
                  buffer = event.buf,
                  group = highlight_augroup,
                  callback = vim.lsp.buf.clear_references,
                })

                vim.api.nvim_create_autocmd('LspDetach', {
                  group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
                  callback = function(event2)
                    vim.lsp.buf.clear_references()
                    vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
                  end,
                })
              end

              -- The following code creates a keymap to toggle inlay hints in your
              -- code, if the language server you are using supports them
              --
              -- This may be unwanted, since they displace some of your code
              if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
                map('<leader>th', function()
                  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
                end, '[T]oggle Inlay [H]ints')
              end
            end,
          })

          -- Diagnostic Config
          -- See :help vim.diagnostic.Opts
          vim.diagnostic.config {
            severity_sort = true,
            float = { border = 'rounded', source = 'if_many' },
            underline = { severity = vim.diagnostic.severity.ERROR },
            signs = vim.g.have_nerd_font and {
              text = {
                [vim.diagnostic.severity.ERROR] = '󰅚 ',
                [vim.diagnostic.severity.WARN] = '󰀪 ',
                [vim.diagnostic.severity.INFO] = '󰋽 ',
                [vim.diagnostic.severity.HINT] = '󰌶 ',
              },
            } or {},
            virtual_text = {
              source = 'if_many',
              spacing = 2,
              format = function(diagnostic)
                local diagnostic_message = {
                  [vim.diagnostic.severity.ERROR] = diagnostic.message,
                  [vim.diagnostic.severity.WARN] = diagnostic.message,
                  [vim.diagnostic.severity.INFO] = diagnostic.message,
                  [vim.diagnostic.severity.HINT] = diagnostic.message,
                }
                return diagnostic_message[diagnostic.severity]
              end,
            },
          }

          -- LSP servers and clients are able to communicate to each other what features they support.
          --  By default, Neovim doesn't support everything that is in the LSP specification.
          --  When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
          --  So, we create new capabilities with blink.cmp, and then broadcast that to the servers.
          local capabilities = require('blink.cmp').get_lsp_capabilities()

          -- Enable the following language servers
          --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
          --
          --  Add any additional override configuration in the following tables. Available keys are:
          --  - cmd (table): Override the default command used to start the server
          --  - filetypes (table): Override the default list of associated filetypes for the server
          --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
          --  - settings (table): Override the default settings passed when initializing the server.
          --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
          local servers = {
            clangd = {},
            gopls = {},
            pyright = {},
            -- jdtls = {},
            -- rust_analyzer = {},
            -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
            --
            -- Some languages (like typescript) have entire language plugins that can be useful:
            --    https://github.com/pmizio/typescript-tools.nvim
            --
            -- But for many setups, the LSP (`ts_ls`) will work just fine
            -- ts_ls = {},
            --

            lua_ls = {
              -- cmd = { ... },
              -- filetypes = { ... },
              -- capabilities = {},
              settings = {
                Lua = {
                  completion = {
                    callSnippet = 'Replace',
                  },
                  -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
                  -- diagnostics = { disable = { 'missing-fields' } },
                },
              },
            },
          }

          -- Ensure the servers and tools above are installed
          --
          -- To check the current status of installed tools and/or manually install
          -- other tools, you can run
          --    :Mason
          --
          -- You can press `g?` for help in this menu.
          --
          -- `mason` had to be setup earlier: to configure its options see the
          -- `dependencies` table for `nvim-lspconfig` above.
          --
          -- You can add other tools here that you want Mason to install
          -- for you, so that they are available from within Neovim.
          local ensure_installed = vim.tbl_keys(servers or {})
          vim.list_extend(ensure_installed, {
            'stylua', -- Used to format Lua code
          })
          require('mason-tool-installer').setup { ensure_installed = ensure_installed }

          require('mason-lspconfig').setup {
            ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
            automatic_installation = false,
            handlers = {
              function(server_name)
                local server = servers[server_name] or {}
                -- This handles overriding only values explicitly passed
                -- by the server configuration above. Useful when disabling
                -- certain features of an LSP (for example, turning off formatting for ts_ls)
                server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
                require('lspconfig')[server_name].setup(server)
              end,
            },
          }
        end,
      },
    },
  },

  {
    -- Autocompletion
    'hrsh7th/nvim-cmp',
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',

      -- Adds LSP completion capabilities
      'hrsh7th/cmp-nvim-lsp',

      -- Adds a number of user-friendly snippets
      'rafamadriz/friendly-snippets',
    },
  },

  -- Useful plugin to show you pending keybinds.
  { 'folke/which-key.nvim', opts = {} },
  {
    -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      -- See `:help gitsigns.txt`
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      on_attach = function(bufnr)
        vim.keymap.set('n', '<leader>hp', require('gitsigns').preview_hunk, { buffer = bufnr, desc = 'Preview git hunk' })

        -- don't override the built-in and fugitive keymaps
        local gs = package.loaded.gitsigns
        vim.keymap.set({ 'n', 'v' }, ']c', function()
          if vim.wo.diff then
            return ']c'
          end
          vim.schedule(function()
            gs.next_hunk()
          end)
          return '<Ignore>'
        end, { expr = true, buffer = bufnr, desc = 'Jump to next hunk' })
        vim.keymap.set({ 'n', 'v' }, '[c', function()
          if vim.wo.diff then
            return '[c'
          end
          vim.schedule(function()
            gs.prev_hunk()
          end)
          return '<Ignore>'
        end, { expr = true, buffer = bufnr, desc = 'Jump to previous hunk' })
      end,
    },
  },

  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'catppuccin-mocha'
    end,
  },
  {
    -- Set lualine as statusline
    'nvim-lualine/lualine.nvim',
    -- See `:help lualine.txt`
    opts = {
      options = {
        icons_enabled = false,
        theme = 'catppuccin-mocha',
        component_separators = '|',
        section_separators = '',
      },
    },
  },

  {
    -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help ibl`
    main = 'ibl',
    opts = {},
  },

  -- "gc" to comment visual regions/lines
  { 'numToStr/Comment.nvim', opts = {} },

  -- Fuzzy Finder (files, lsp, etc)
  {
    'nvim-telescope/telescope.nvim',
    branch = 'master',
    dependencies = {
      'nvim-lua/plenary.nvim',
      -- Fuzzy Finder Algorithm which requires local dependencies to be built.
      -- Only load if `make` is available. Make sure you have the system
      -- requirements installed.
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        -- NOTE: If you are having trouble with this installation,
        --       refer to the README for telescope-fzf-native for more instructions.
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
    },
  },

  {
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    lazy = false,
  },
  -- NOTE: Next Step on Your Neovim Journey: Add/Configure additional "plugins" for kickstart
  --       These are some example plugins that I've included in the kickstart repository.
  --       Uncomment any of the lines below to enable them.
  -- require 'kickstart.plugins.autoformat',
  -- require 'kickstart.plugins.debug',

  -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --    You can use this folder to prevent any conflicts with this init.lua if you're interested in keeping
  --    up-to-date with whatever is in the kickstart repo.
  --    Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  --
  --    For additional information see: https://github.com/folke/lazy.nvim#-structuring-your-plugins
  { import = 'custom.plugins' },
}, {})

-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!

-- Set highlight on search
vim.o.hlsearch = false

-- Make line numbers default
vim.wo.number = true

-- Enable mouse mode
vim.o.mouse = 'a'

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = 'unnamedplus'

-- Enable break indent
vim.o.breakindent = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

vim.o.smarttab = true
vim.o.expandtab = true

vim.o.smartindent = true

vim.o.swapfile = false
vim.o.backup = false
vim.o.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.o.undofile = true

vim.o.scrolloff = 20

-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Exit terminal
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { silent = true })

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
require('telescope').setup {
  defaults = {
    mappings = {
      i = {
        ['<C-u>'] = false,
        ['<C-d>'] = false,
      },
    },
  },
}

-- Enable telescope fzf native, if installed
pcall(require('telescope').load_extension, 'fzf')

-- See `:help telescope.builtin`
vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles, { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', function()
  -- You can pass additional configuration to telescope to change theme, layout, etc.
  require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = '[/] Fuzzily search in current buffer' })

vim.keymap.set('n', '<leader>gf', require('telescope.builtin').git_files, { desc = 'Search [G]it [F]iles' })
vim.keymap.set('n', '<leader>sf', require('telescope.builtin').find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', require('telescope.builtin').resume, { desc = '[S]earch [R]esume' })


vim.keymap.set('n', '<leader><S-t>n', ':tabnew<CR>', { desc = '[T]ab [N]ew' })
vim.keymap.set('n', '<leader><S-t>c', ':tabclose<CR>', { desc = '[T]ab [C]lose' })
vim.keymap.set('n', '<leader><S-t>h', ':tabprevious<CR>', { desc = '[T]ab Previous' })
vim.keymap.set('n', '<leader><S-t>l', ':tabnext<CR>', { desc = '[T]ab Next' })

-- [[ Configure Autoformat ]]

-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter` (main branch API)
-- Defer Treesitter setup after first render to improve startup time of 'nvim {filename}'
vim.defer_fn(function()
  local ts = require 'nvim-treesitter'
  ts.setup {}

  -- Languages to install. markdown_inline is required for markdown highlighting.
  local ensure_installed = {
    'c', 'go', 'lua', 'python', 'javascript', 'typescript', 'vimdoc', 'vim', 'bash',
    'markdown', 'markdown_inline', 'query',
  }
  local installed = ts.get_installed()
  local missing = vim.tbl_filter(function(lang)
    return not vim.tbl_contains(installed, lang)
  end, ensure_installed)
  if #missing > 0 then
    ts.install(missing)
  end

  -- Enable highlighting and indentation per buffer; auto-install missing parsers
  local function attach(buf, filetype)
    local lang = vim.treesitter.language.get_lang(filetype)
    if not lang then
      return
    end

    local function start()
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      if not pcall(vim.treesitter.start, buf, lang) then
        return
      end
      vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end

    if vim.tbl_contains(ts.get_installed(), lang) then
      start()
    elseif vim.tbl_contains(ts.get_available(), lang) then
      ts.install({ lang }):await(start)
    end
  end

  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('kickstart-treesitter', { clear = true }),
    callback = function(args)
      attach(args.buf, args.match)
    end,
  })

  -- Buffers opened before this deferred setup ran (e.g. `nvim file.md`) already
  -- fired FileType, so attach to them now.
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= '' then
      attach(buf, vim.bo[buf].filetype)
    end
  end

  -- Treesitter textobjects (main branch API)
  require('nvim-treesitter-textobjects').setup {
    select = {
      lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
    },
    move = {
      set_jumps = true, -- whether to set jumps in the jumplist
    },
  }

  local select = require 'nvim-treesitter-textobjects.select'
  local move = require 'nvim-treesitter-textobjects.move'
  local swap = require 'nvim-treesitter-textobjects.swap'

  local function map_select(lhs, capture, desc)
    vim.keymap.set({ 'x', 'o' }, lhs, function()
      select.select_textobject(capture, 'textobjects')
    end, { desc = desc })
  end
  map_select('aa', '@parameter.outer', 'Select outer parameter')
  map_select('ia', '@parameter.inner', 'Select inner parameter')
  map_select('af', '@function.outer', 'Select outer function')
  map_select('if', '@function.inner', 'Select inner function')
  map_select('ac', '@class.outer', 'Select outer class')
  map_select('ic', '@class.inner', 'Select inner class')

  local function map_move(lhs, fn, capture, desc)
    vim.keymap.set({ 'n', 'x', 'o' }, lhs, function()
      fn(capture, 'textobjects')
    end, { desc = desc })
  end
  map_move(']m', move.goto_next_start, '@function.outer', 'Next function start')
  map_move(']]', move.goto_next_start, '@class.outer', 'Next class start')
  map_move(']M', move.goto_next_end, '@function.outer', 'Next function end')
  map_move('][', move.goto_next_end, '@class.outer', 'Next class end')
  map_move('[m', move.goto_previous_start, '@function.outer', 'Previous function start')
  map_move('[[', move.goto_previous_start, '@class.outer', 'Previous class start')
  map_move('[M', move.goto_previous_end, '@function.outer', 'Previous function end')
  map_move('[]', move.goto_previous_end, '@class.outer', 'Previous class end')

  vim.keymap.set('n', '<leader>a', function()
    swap.swap_next '@parameter.inner'
  end, { desc = 'Swap with next parameter' })
  vim.keymap.set('n', '<leader>A', function()
    swap.swap_previous '@parameter.inner'
  end, { desc = 'Swap with previous parameter' })

  -- Incremental selection was removed from the main branch; use a simple node-based
  -- expansion instead. <C-Space> grows the selection, <M-Space> shrinks it.
  local sel_stack = {}
  vim.keymap.set({ 'n', 'x' }, '<c-space>', function()
    local buf = vim.api.nvim_get_current_buf()
    local mode = vim.fn.mode()
    local node
    if mode == 'n' then
      sel_stack = {}
      node = vim.treesitter.get_node()
    else
      local top = sel_stack[#sel_stack]
      node = top and top:parent() or vim.treesitter.get_node()
    end
    if not node then
      return
    end
    table.insert(sel_stack, node)
    local sr, sc, er, ec = node:range()
    vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
    if mode == 'n' then
      vim.cmd 'normal! v'
    else
      vim.cmd 'normal! o'
      vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
      vim.cmd 'normal! o'
    end
    local last_line = vim.api.nvim_buf_line_count(buf)
    if er + 1 > last_line then
      er, ec = last_line - 1, #vim.api.nvim_buf_get_lines(buf, last_line - 1, last_line, true)[1]
    end
    vim.api.nvim_win_set_cursor(0, { er + 1, math.max(ec - 1, 0) })
    _ = buf
  end, { desc = 'Treesitter: expand selection' })
  vim.keymap.set('x', '<M-space>', function()
    if #sel_stack <= 1 then
      return
    end
    table.remove(sel_stack)
    local node = sel_stack[#sel_stack]
    local sr, sc, er, ec = node:range()
    vim.cmd 'normal! o'
    vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
    vim.cmd 'normal! o'
    vim.api.nvim_win_set_cursor(0, { er + 1, math.max(ec - 1, 0) })
  end, { desc = 'Treesitter: shrink selection' })
end, 0)

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- NERDTree keymaps
vim.keymap.set('n', '<C-n>', ':NERDTreeToggle<CR>', { desc = 'Explore the current directory' })

-- document existing key chains
require('which-key').add {
  { "<leader>c", group = "[C]ode" },
  { "<leader>c_", hidden = true },
  { "<leader>d", group = "[D]ocument" },
  { "<leader>d_", hidden = true },
  { "<leader>g", group = "[G]it" },
  { "<leader>g_", hidden = true },
  { "<leader>h", group = "More git" },
  { "<leader>h_", hidden = true },
  { "<leader>r", group = "[R]ename" },
  { "<leader>r_", hidden = true },
  { "<leader>s", group = "[S]earch" },
  { "<leader>s_", hidden = true },
  { "<leader>w", group = "[W]orkspace" },
  { "<leader>w_", hidden = true },
  { "<leader>t", group = "Res[t]" },
  { "<leader>t_", hidden = true },
  { "<leader>E", group = "[E]xecute" },
  { "<leader>E_", hidden = true },
}

require('mason').setup()

-- [[ Configure nvim-cmp ]]
-- See `:help cmp`
local cmp = require 'cmp'
local luasnip = require 'luasnip'
require('luasnip.loaders.from_vscode').lazy_load()
luasnip.config.setup {}

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete {},
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_locally_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  },
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et

