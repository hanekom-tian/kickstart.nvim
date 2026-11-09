-- File explorer (project view)
-- Icons come from mini.icons (mocking nvim-web-devicons), see init.lua
vim.pack.add {
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = 'v3.x' },
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
}

vim.keymap.set('n', '\\', '<Cmd>Neotree reveal<CR>', { desc = 'NeoTree reveal', silent = true })

require('neo-tree').setup {
  close_if_last_window = true,
  filesystem = {
    follow_current_file = { enabled = true },
    -- this controls hidden / dotfiles
    filtered_items = {
      visible = true, -- show the filtered items in the tree
      show_hidden_count = true,
      hide_dotfiles = false, -- do NOT hide “.git”, “.env”, etc.
      hide_gitignored = false, -- do NOT hide files ignored by git
      hide_by_name = {}, -- you can still hide things explicitly here
      never_show = {}, -- and *never* show these if you want
    },
    window = {
      mappings = {
        ['\\'] = 'close_window',
      },
    },
  },
  event_handlers = {
    {
      event = 'file_opened',
      handler = function()
        -- close all Neo-tree windows when a file is opened
        require('neo-tree.command').execute { action = 'close' }
      end,
    },
  },
}

-- Toggle the sidebar (open if closed, close if open)
vim.keymap.set('n', '<leader>e', '<Cmd>Neotree toggle<CR>', { desc = 'Toggle Neo-tree' })

-- Auto-open Neo-tree ONLY when starting `nvim` with no file args
if vim.fn.argc() == 0 then
  vim.api.nvim_create_autocmd('VimEnter', {
    group = vim.api.nvim_create_augroup('OpenNeoTreeOnEmpty', { clear = true }),
    callback = function()
      -- only if we're still on the empty, unnamed buffer
      if vim.fn.bufname() == '' and vim.bo.filetype == '' then
        require('neo-tree.command').execute {
          source = 'filesystem',
          position = 'left',
          toggle = true,
        }
      end
    end,
  })
end
