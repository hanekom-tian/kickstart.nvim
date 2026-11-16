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
  -- Run/attach through nvim-dap (breakpoints, dap-ui). flutter-tools registers
  -- the `flutter debug-adapter` and the launch + attach configurations itself;
  -- overriding them with `dart debug_adapter` breaks running Flutter apps and
  -- leaves FlutterAttach without an attach configuration.
  debugger = { enabled = true },
}

-- `flutter debug-adapter` only passes `toolArgs` (not `args`) to `flutter attach`,
-- so FlutterAttach's `-d <device>` was dropped. With several devices `flutter
-- attach` then fails and flutter-tools falls back to *launching* a new app.
require('dap').listeners.on_config['flutter-attach-args'] = function(config)
  if config.type ~= 'dart' or config.request ~= 'attach' or not config.args then return config end
  config = vim.deepcopy(config)
  config.toolArgs = vim.list_extend(config.toolArgs or {}, config.args)
  config.args = nil
  return config
end

-- Attach to an app started elsewhere (terminal, another editor): pick the device first
local function flutter_attach()
  vim.system({ 'flutter', 'devices', '--machine' }, { text = true }, function(res)
    local ok, devices = pcall(vim.json.decode, res.stdout:match '%[.*%]' or '')
    vim.schedule(function()
      if not ok or #devices == 0 then return vim.notify('No Flutter devices found', vim.log.levels.WARN) end
      vim.ui.select(devices, {
        prompt = 'Attach to app on device',
        format_item = function(d) return ('%s (%s)'):format(d.name, d.id) end,
      }, function(d)
        if d then vim.cmd('FlutterAttach -d ' .. d.id) end
      end)
    end)
  end)
end

-- Widget select mode (FlutterInspectWidget, or DevTools' "Select widget"):
-- tapping a widget in the simulator/emulator jumps to the code that builds it.
-- The Dart debug adapter forwards the inspector's `navigate` events as
-- `dart.toolEvent`; flutter-tools doesn't handle them for running apps.
require('dap').listeners.after['event_dart.toolEvent']['flutter-navigate'] = function(_, body)
  if not body or body.kind ~= 'navigate' or not body.data then return end
  local uri = body.data.fileUri or body.data.uri
  if not uri or not uri:match '^file:' then return end
  local line = math.max((body.data.line or 1) - 1, 0)
  local col = math.max((body.data.column or 1) - 1, 0)
  local pos = { line = line, character = col }
  vim.schedule(function() vim.lsp.util.show_document({ uri = uri, range = { start = pos, ['end'] = pos } }, 'utf-16', { focus = true }) end)
end

-- Flutter keys (<leader>f is Format)
require('which-key').add { { '<leader>F', group = '[F]lutter' } }
vim.keymap.set('n', '<leader>Fr', '<cmd>FlutterRun<cr>', { desc = 'Flutter: Run' })
vim.keymap.set('n', '<leader>Fa', flutter_attach, { desc = 'Flutter: Attach to running app' })
vim.keymap.set('n', '<leader>Fh', '<cmd>FlutterReload<cr>', { desc = 'Flutter: Hot reload' })
vim.keymap.set('n', '<leader>FR', '<cmd>FlutterRestart<cr>', { desc = 'Flutter: Hot restart' })
vim.keymap.set('n', '<leader>Fq', '<cmd>FlutterQuit<cr>', { desc = 'Flutter: Quit app' })
vim.keymap.set('n', '<leader>Fd', '<cmd>FlutterDevices<cr>', { desc = 'Flutter: Devices' })
vim.keymap.set('n', '<leader>Fe', '<cmd>FlutterEmulators<cr>', { desc = 'Flutter: Emulators' })
vim.keymap.set('n', '<leader>Fi', '<cmd>FlutterInspectWidget<cr>', { desc = 'Flutter: Select widget on device' })
vim.keymap.set('n', '<leader>Ft', '<cmd>FlutterOpenDevTools<cr>', { desc = 'Flutter: Open DevTools (widget tree, network)' })
vim.keymap.set('n', '<leader>Fo', '<cmd>FlutterOutlineToggle<cr>', { desc = 'Flutter: Widget outline' })
vim.keymap.set('n', '<leader>Fl', '<cmd>FlutterLogToggle<cr>', { desc = 'Flutter: Toggle log' })
vim.keymap.set('n', '<leader>Fc', '<cmd>FlutterCommands<cr>', { desc = 'Flutter: All commands' })

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
