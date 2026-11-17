-- Review git changes: side-by-side diffs with a file panel, branch and file history
vim.pack.add { 'https://github.com/sindrets/diffview.nvim' }

require('diffview').setup {}

require('which-key').add { { '<leader>g', group = '[G]it review' } }

vim.keymap.set('n', '<leader>gd', '<Cmd>DiffviewOpen<CR>', { desc = 'Git: [d]iff uncommitted changes' })
vim.keymap.set('n', '<leader>gh', '<Cmd>DiffviewFileHistory %<CR>', { desc = 'Git: [h]istory of current file' })
vim.keymap.set('n', '<leader>gH', '<Cmd>DiffviewFileHistory<CR>', { desc = 'Git: [H]istory of repo (commit log)' })
vim.keymap.set('n', '<leader>gq', '<Cmd>DiffviewClose<CR>', { desc = 'Git: [q]uit diff view' })

-- Review a branch: show only what the branch itself changes, i.e.
-- `git diff <base>...<branch>`, where base is the branch it was cut from.

local function git(args)
  local out = vim.fn.systemlist(vim.list_extend({ 'git' }, args))
  if vim.v.shell_error ~= 0 then return nil end
  return out
end

local function local_branches() return git { 'for-each-ref', '--format=%(refname:short)', 'refs/heads/' } end

-- The branch `branch` was created from, according to the (local) reflogs:
-- `git branch B A` logs "Created from A"; `git checkout -b B` logs "Created
-- from HEAD", so look up the checkout that created it in HEAD's reflog.
local function created_from(branch, branches)
  local log = git { 'reflog', 'show', '--format=%gs', 'refs/heads/' .. branch }
  local from = log and log[#log] and log[#log]:match '^branch: Created from (.+)$'
  if from == 'HEAD' then
    from = nil
    local head = git { 'reflog', 'show', '--format=%gs', 'HEAD' } or {}
    for i = #head, 1, -1 do -- oldest first
      from = head[i]:match('^checkout: moving from (.+) to ' .. vim.pesc(branch) .. '$')
      if from then break end
    end
  end
  return from and from ~= branch and vim.tbl_contains(branches, from) and from or nil
end

-- Without a reflog entry, guess: the other branch whose fork point
-- (merge-base) is the fewest commits behind `branch`. Skips branches that
-- were created from `branch` (its children in a stack) and branches that
-- already contain it (e.g. it was merged in). Siblings cut from the same
-- commit tie with the parent; prefer a branch still at the fork point, then
-- a mainline branch.
local mainline = { claude = 1, main = 2, master = 3, develop = 4 }

local function guess_base(branch, branches)
  local from = created_from(branch, branches)
  if from then return from end
  local best, best_key
  for _, other in ipairs(branches) do
    local fork = other ~= branch and created_from(other, branches) ~= branch and git { 'merge-base', other, branch }
    fork = fork and fork[1]
    local count = fork and tonumber((git { 'rev-list', '--count', fork .. '..' .. branch } or {})[1])
    if count and count > 0 then
      local at_fork = (git { 'rev-parse', other } or {})[1] == fork and 0 or 1
      local key = { count, at_fork, mainline[other] or math.huge }
      local better = not best_key
      for i = 1, #key do
        if better or key[i] ~= best_key[i] then
          better = better or key[i] < best_key[i]
          break
        end
      end
      if better then
        best, best_key = other, key
      end
    end
  end
  return best
end

local function review(base, branch) vim.cmd(('DiffviewOpen %s...%s'):format(base, branch)) end

local function pick_branch(prompt, branches, on_choice)
  vim.ui.select(branches, { prompt = prompt }, function(choice)
    if choice then on_choice(choice) end
  end)
end

vim.keymap.set('n', '<leader>gb', function()
  local branches = local_branches()
  if not branches then return vim.notify('Not in a git repository', vim.log.levels.WARN) end
  pick_branch('Review branch (against the branch it was cut from)', branches, function(branch)
    local base = guess_base(branch, branches)
    if not base then return vim.notify(('No base branch found for %s; use <leader>gB'):format(branch), vim.log.levels.WARN) end
    vim.notify(('Reviewing %s against %s'):format(branch, base))
    review(base, branch)
  end)
end, { desc = 'Git: review [b]ranch against its parent' })

vim.keymap.set('n', '<leader>gB', function()
  local branches = local_branches()
  if not branches then return vim.notify('Not in a git repository', vim.log.levels.WARN) end
  pick_branch('Review branch', branches, function(branch)
    local others = vim.tbl_filter(function(b) return b ~= branch end, branches)
    pick_branch(('Compare %s against'):format(branch), others, function(base) review(base, branch) end)
  end)
end, { desc = 'Git: review [B]ranch against a chosen base' })
