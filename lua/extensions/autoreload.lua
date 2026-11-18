-----------------------------------------------------------------------
-- Keep buffers in sync with files changed outside Neovim (Claude, git, ...)
-----------------------------------------------------------------------
-- The file on disk is the source of truth: changed files are reloaded
-- without the "W12: file and buffer both changed" prompt. Unsaved edits are
-- not lost; the reload is an undo step (see 'undoreload'), so `u` brings
-- them back.

vim.o.autoread = true

local group = vim.api.nvim_create_augroup('extensions-autoreload', { clear = true })

-- Cheap fallback checks for when the file watcher misses something.
-- (FocusGained only fires in tmux with `set -g focus-events on`.)
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI', 'TermLeave' }, {
  group = group,
  callback = function()
    if vim.fn.getcmdwintype() == '' then vim.cmd 'silent! checktime' end
  end,
})

-- Reload instead of prompting, even when the buffer has unsaved changes.
vim.api.nvim_create_autocmd('FileChangedShell', {
  group = group,
  callback = function(args)
    local reason = vim.v.fcs_reason
    if reason == 'deleted' then
      vim.v.fcs_choice = ''
      vim.notify(('%s was deleted on disk'):format(vim.fn.fnamemodify(args.file, ':~:.')), vim.log.levels.WARN)
    elseif reason == 'conflict' or reason == 'changed' then
      vim.b[args.buf].autoreload_had_changes = vim.bo[args.buf].modified
      vim.v.fcs_choice = 'reload'
    else
      vim.v.fcs_choice = ''
    end
  end,
})

vim.api.nvim_create_autocmd('FileChangedShellPost', {
  group = group,
  callback = function(args)
    if not vim.b[args.buf].autoreload_had_changes then return end
    vim.b[args.buf].autoreload_had_changes = nil
    vim.notify(
      ('%s changed on disk and was reloaded; press u to get your unsaved edits back'):format(vim.fn.fnamemodify(args.file, ':~:.')),
      vim.log.levels.WARN
    )
  end,
})

-----------------------------------------------------------------------
-- File watcher: reload as soon as a file changes, not on the next event
-----------------------------------------------------------------------
local watchers = {} -- bufnr -> uv_fs_event_t

local function unwatch(buf)
  if watchers[buf] then
    watchers[buf]:stop()
    watchers[buf]:close()
    watchers[buf] = nil
  end
end

local function watch(buf)
  unwatch(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= '' then return end
  local path = vim.api.nvim_buf_get_name(buf)
  if path == '' or not vim.uv.fs_stat(path) then return end

  local w = vim.uv.new_fs_event()
  if not w then return end
  watchers[buf] = w
  w:start(path, {}, function(err)
    if err then return end
    -- Editors and tools often replace files (write temp + rename), which
    -- leaves the watcher on the old inode, so re-arm it after every event.
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(buf) then return unwatch(buf) end
      -- checktime can't reload while in the command line or cmdwin; the
      -- BufEnter/CursorHold checks will pick it up afterwards.
      if vim.fn.mode() ~= 'c' and vim.fn.getcmdwintype() == '' then vim.cmd('silent! checktime ' .. buf) end
      watch(buf)
    end)
  end)
end

vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost', 'BufFilePost' }, {
  group = group,
  callback = function(args) watch(args.buf) end,
})

vim.api.nvim_create_autocmd({ 'BufUnload', 'BufWipeout' }, {
  group = group,
  callback = function(args) unwatch(args.buf) end,
})
