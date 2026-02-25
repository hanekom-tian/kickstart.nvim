-- lua/custom/plugins/ide-pack.lua
return {
  -- Flutter/Dart: hot reload, outline, devices, DAP
  {
    'akinsho/flutter-tools.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'neovim/nvim-lspconfig',
      'mfussenegger/nvim-dap',
      'rcarriga/nvim-dap-ui',
    },
    config = function()
      require('flutter-tools').setup {
        widget_guides = { enabled = true },
        dev_log = { open_cmd = '10split' },
        lsp = {
          on_attach = function(_, bufnr)
            local map = function(lhs, rhs, desc)
              vim.keymap.set('n', lhs, rhs, { buffer = bufnr, desc = desc })
            end
            map('gd', vim.lsp.buf.definition, 'Go to definition')
            map('gr', vim.lsp.buf.references, 'References')
            map('<leader>rn', vim.lsp.buf.rename, 'Rename symbol')
            map('<leader>ca', vim.lsp.buf.code_action, 'Code action')
          end,
        },
        debugger = {
          enabled = true,
          run_via_dap = true,
          register_configurations = function(_)
            local dap = require 'dap'
            dap.adapters.dart = { type = 'executable', command = 'dart', args = { 'debug_adapter' } }
            dap.configurations.dart = {
              {
                type = 'dart',
                request = 'launch',
                name = 'Launch main.dart',
                program = '${workspaceFolder}/lib/main.dart',
                cwd = '${workspaceFolder}',
              },
            }
            require('dapui').setup()
          end,
        },
      }
      -- Handy Flutter keys
      --      vim.keymap.set('n', '<leader>fr', ':FlutterReload<CR>', { desc = 'Flutter: Hot reload' })
      --      vim.keymap.set('n', '<leader>fR', ':FlutterRestart<CR>', { desc = 'Flutter: Hot restart' })
      --      vim.keymap.set('n', '<leader>fd', ':FlutterDevices<CR>', { desc = 'Flutter: Devices' })
      --      vim.keymap.set('n', '<leader>fe', ':FlutterEmulators<CR>', { desc = 'Flutter: Emulators' })
      --      vim.keymap.set('n', '<leader>fo', ':FlutterOutlineToggle<CR>', { desc = 'Flutter: Outline' })
      --      vim.keymap.set('n', '<leader>fx', ':FlutterQuit<CR>', { desc = 'Flutter: Quit app' })
    end,
  },

  -- Problems panel (like IntelliJ’s “Problems” / “Inspection Results”)
  {
    'folke/trouble.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {},
    keys = {
      { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Diagnostics (workspace)' },
      { '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', desc = 'Diagnostics (file)' },
      { '<leader>xq', '<cmd>Trouble quickfix toggle<cr>', desc = 'Quickfix' },
      { 'gR', '<cmd>Trouble lsp toggle focus=false win.position=right<cr>', desc = 'LSP references' },
    },
  },

  -- Toggle terminal (tool windows)
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    opts = { direction = 'horizontal', size = 12 },
    keys = {
      { '<leader>t', '<cmd>ToggleTerm<cr>', desc = 'Toggle terminal' },
    },
  },

  -- Tasks runner (great with your Makefile targets)
  { 'stevearc/overseer.nvim', opts = {} },

  -- Tests (run nearest/file; show output & summary)
  --  {
  --    'nvim-neotest/neotest',
  --    dependencies = {
  --      'nvim-lua/plenary.nvim',
  --      'antoinemadec/FixCursorHold.nvim',
  --      'sidlatau/neotest-dart', -- Flutter/Dart adapter
  --    },
  --    config = function()
  --      local neotest = require 'neotest'
  --      neotest.setup {
  --        adapters = {
  --          require 'neotest-dart' { command = 'flutter' }, -- or "dart"
  --        },
  --      }
  --      vim.keymap.set('n', '<leader>tn', function()
  --        neotest.run.run()
  --      end, { desc = 'Test nearest' })
  --      vim.keymap.set('n', '<leader>tf', function()
  --        neotest.run.run(vim.fn.expand '%')
  --      end, { desc = 'Test file' })
  --      vim.keymap.set('n', '<leader>to', function()
  --        neotest.output.open { enter = true }
  --      end, { desc = 'Test output' })
  --      vim.keymap.set('n', '<leader>ts', function()
  --        neotest.summary.toggle()
  --      end, { desc = 'Test summary' })
  --    end,
  --  },

  -- Small JetBrains-ish quality-of-life
  { 'folke/todo-comments.nvim', dependencies = { 'nvim-lua/plenary.nvim' }, opts = {} }, -- TODO/FIXME highlights
  { 'kylechui/nvim-surround', version = '*', config = true }, -- Surround text objects (like IntelliJ's "surround with")
  { 'ray-x/lsp_signature.nvim', opts = {} }, -- Parameter hints while you type
}
