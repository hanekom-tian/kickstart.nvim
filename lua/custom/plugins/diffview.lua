-- Review git changes: side-by-side diffs with a file panel, branch and file history
vim.pack.add { 'https://github.com/sindrets/diffview.nvim' }

require('diffview').setup {}

require('which-key').add { { '<leader>g', group = '[G]it review' } }

vim.keymap.set('n', '<leader>gd', '<Cmd>DiffviewOpen<CR>', { desc = 'Git: [d]iff uncommitted changes' })
vim.keymap.set('n', '<leader>gh', '<Cmd>DiffviewFileHistory %<CR>', { desc = 'Git: [h]istory of current file' })
vim.keymap.set('n', '<leader>gH', '<Cmd>DiffviewFileHistory<CR>', { desc = 'Git: [H]istory of repo (commit log)' })
vim.keymap.set('n', '<leader>gq', '<Cmd>DiffviewClose<CR>', { desc = 'Git: [q]uit diff view' })

-- Review a branch against `claude` (the git flow develop branch): only what
-- the branch itself changes, i.e. `git diff claude...<branch>`
vim.keymap.set('n', '<leader>gb', function()
  local branches = vim.fn.systemlist { 'git', 'for-each-ref', '--format=%(refname:short)', 'refs/heads/' }
  if vim.v.shell_error ~= 0 then return vim.notify('Not in a git repository', vim.log.levels.WARN) end
  branches = vim.tbl_filter(function(b) return b ~= 'claude' end, branches)
  vim.ui.select(branches, { prompt = 'Review branch against claude' }, function(branch)
    if branch then vim.cmd('DiffviewOpen claude...' .. branch) end
  end)
end, { desc = 'Git: review [b]ranch against claude' })
