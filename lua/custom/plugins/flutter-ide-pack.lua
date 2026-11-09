-- IDE pack: Flutter tooling plus JetBrains-ish quality-of-life plugins
local function gh(repo) return 'https://github.com/' .. repo end

-- Flutter/Dart: hot reload, outline, devices, DAP
-- nvim-dap and nvim-dap-ui are installed by kickstart.plugins.debug
vim.pack.add {
  gh 'nvim-lua/plenary.nvim',
  gh 'neovim/nvim-lspconfig',
  gh 'mfussenegger/nvim-dap',
  gh 'rcarriga/nvim-dap-ui',
  gh 'akinsho/flutter-tools.nvim',
}

require('flutter-tools').setup {
  widget_guides = { enabled = true },
  dev_log = { open_cmd = '10split' },
  lsp = {
    on_attach = function(_, bufnr)
      local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { buffer = bufnr, desc = desc }) end
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

-- Problems panel (like IntelliJ’s “Problems” / “Inspection Results”)
vim.pack.add { gh 'folke/trouble.nvim' }
require('trouble').setup {}
vim.keymap.set('n', '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', { desc = 'Diagnostics (workspace)' })
vim.keymap.set('n', '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', { desc = 'Diagnostics (file)' })
vim.keymap.set('n', '<leader>xq', '<cmd>Trouble quickfix toggle<cr>', { desc = 'Quickfix' })
vim.keymap.set('n', 'gR', '<cmd>Trouble lsp toggle focus=false win.position=right<cr>', { desc = 'LSP references' })

-- Toggle terminal (tool windows)
vim.pack.add { { src = gh 'akinsho/toggleterm.nvim', version = vim.version.range '*' } }
require('toggleterm').setup { direction = 'horizontal', size = 12 }
vim.keymap.set('n', '<leader>t', '<cmd>ToggleTerm<cr>', { desc = 'Toggle terminal' })

-- Tasks runner (great with your Makefile targets)
vim.pack.add { gh 'stevearc/overseer.nvim' }
require('overseer').setup {}

-- Tests (run nearest/file; show output & summary)
--  vim.pack.add {
--    gh 'nvim-lua/plenary.nvim',
--    gh 'antoinemadec/FixCursorHold.nvim',
--    gh 'nvim-neotest/nvim-nio',
--    gh 'nvim-neotest/neotest',
--    gh 'sidlatau/neotest-dart', -- Flutter/Dart adapter
--  }
--  local neotest = require 'neotest'
--  neotest.setup {
--    adapters = {
--      require 'neotest-dart' { command = 'flutter' }, -- or "dart"
--    },
--  }
--  vim.keymap.set('n', '<leader>tn', function() neotest.run.run() end, { desc = 'Test nearest' })
--  vim.keymap.set('n', '<leader>tf', function() neotest.run.run(vim.fn.expand '%') end, { desc = 'Test file' })
--  vim.keymap.set('n', '<leader>to', function() neotest.output.open { enter = true } end, { desc = 'Test output' })
--  vim.keymap.set('n', '<leader>ts', function() neotest.summary.toggle() end, { desc = 'Test summary' })

-- Small JetBrains-ish quality-of-life
-- (todo-comments.nvim is now set up in init.lua)
vim.pack.add {
  { src = gh 'kylechui/nvim-surround', version = vim.version.range '*' }, -- Surround text objects (like IntelliJ's "surround with")
  gh 'ray-x/lsp_signature.nvim', -- Parameter hints while you type
}
require('nvim-surround').setup {}
require('lsp_signature').setup {}
