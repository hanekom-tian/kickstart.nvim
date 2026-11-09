-----------------------------------------------------------------------
-- Generic mapping helper
-----------------------------------------------------------------------
-- mode: "n", "v", "x", "i", etc.
-- lhs:  key you press (left-hand side)
-- rhs:  command/keys Neovim executes (right-hand side)
-- opts: extra options (optional)
local function map(mode, lhs, rhs, opts)
  -- Default behavior:
  --   noremap = true  → non-recursive (do NOT re-apply other mappings)
  --   silent  = true  → don't show the command in the command line
  local options = { noremap = true, silent = true }

  -- If the caller passed extra options, merge them in
  if opts then options = vim.tbl_extend('force', options, opts) end

  -- This is the actual Neovim API for defining keymaps in Lua
  vim.keymap.set(mode, lhs, rhs, options)
end

-----------------------------------------------------------------------
-- NON-RECURSIVE HELPERS (like :nnoremap, :vnoremap, :xnoremap)
-- These all keep noremap = true, so the RHS is taken literally.
-- Any other mappings you have will NOT be applied to the resulting keys.
-----------------------------------------------------------------------

-- Normal mode, non-recursive (equivalent to :nnoremap)
local function nnoremap(lhs, rhs, opts) map('n', lhs, rhs, opts) end

-- Visual mode, non-recursive (equivalent to :vnoremap)
local function vnoremap(lhs, rhs, opts) map('v', lhs, rhs, opts) end

-- Visual + Select mode, non-recursive (equivalent to :xnoremap)
local function xnoremap(lhs, rhs, opts) map('x', lhs, rhs, opts) end

-----------------------------------------------------------------------
-- RECURSIVE HELPER (like :nmap)
-- This one explicitly sets noremap = false.
-- That means the RHS CAN trigger other mappings you’ve defined.
-----------------------------------------------------------------------

local function nmap(lhs, rhs, opts)
  opts = opts or {}
  opts.noremap = false -- allow recursion
  map('n', lhs, rhs, opts)
end

-----------------------------------------------------------------------
-- EXAMPLE MAPPINGS USING THESE HELPERS
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- 1. "Greatest remap ever"
--    Visual <leader>p → paste over selection WITHOUT overwriting your yank
--
--    What it sends:
--      "_dP
--    Explanation:
--      "_d  → delete selection into the black-hole register (discard)
--      P    → paste BEFORE cursor from the default register
--
--    Result:
--      - You replace the selection with what you last yanked
--      - Your original yank is preserved (can paste it again later)
--    If <leader> is <Space>, the key is:  (visual) Space + p
-----------------------------------------------------------------------
xnoremap('<leader>p', '"_dP')

-----------------------------------------------------------------------
-- 2. "Next greatest remap ever" (system clipboard yanks)
--
--    <leader>y in normal/visual mode → yank to system clipboard ("+)
--
--    Examples (if <leader> = <Space>):
--      Normal:   <Space> y y  → copy current line to OS clipboard
--      Visual:   select text, <Space> y  → copy selection to OS clipboard
--      Normal:   <Space> Y    → copy WHOLE line to OS clipboard
-----------------------------------------------------------------------

-- Normal mode: <leader>y{motion} yanks {motion} into system clipboard
nnoremap('<leader>y', '"+y')

-- Visual mode: <leader>y yanks selection into system clipboard
vnoremap('<leader>y', '"+y')

-- Normal mode: <leader>Y yanks WHOLE line into system clipboard
-- Uses nmap (recursive) just to mimic Vim's :nmap behavior.
nmap('<leader>Y', '"+Y')

-----------------------------------------------------------------------
-- 3. Delete without clobbering your yank
--
--    <leader>d{motion} or visual <leader>d → delete into black-hole register
--    So the deletion does NOT replace what you have in your default register.
--
--    Examples (if <leader> = <Space>):
--      Normal:   <Space> d w → delete a word, keep previous yank
--      Visual:   select text, <Space> d → delete selection, keep previous yank
-----------------------------------------------------------------------

-- Normal mode: delete to black-hole register
nnoremap('<leader>d', '"_d')

-- Visual mode: delete selection to black-hole register
vnoremap('<leader>d', '"_d')

-----------------------------------------------------------------------
-- 4. Example to show the difference between nnoremap and nmap
-----------------------------------------------------------------------
-- Say we want:
--   j → move down one *display* line (wrapped line) instead of one real line.
--   gj → move 5 lines down.
--
-- With NON-RECURSIVE mappings:
--   - pressing j → becomes gj
--   - Neovim does NOT re-interpret gj as another mapping
--
-- Uncomment to test:
-- nnoremap("j", "gj")    -- j uses gj movement
-- nnoremap("gj", "5j")   -- gj uses 5j, but j does NOT get this second mapping
--
-- With RECURSIVE mappings:
--   - pressing j → gj (from first map)
--   - then gj is remapped again to 5j (second map)
--   - so j effectively becomes 5j
--
-- Uncomment to test:
-- nmap("j", "gj")        -- j becomes gj
-- nmap("gj", "5j")       -- gj becomes 5j, and j chains into this too
-----------------------------------------------------------------------
