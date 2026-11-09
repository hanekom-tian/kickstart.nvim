# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal Neovim config forked from [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim). Upstream commits are mixed into history; the user's own changes sit on top. Targets latest stable/nightly Neovim only.

## Git workflow

Follow git flow, with `claude` in the role of the develop branch:

- `claude` is the default base branch for all work.
- Never push to, commit to, or merge into `master`, `main`, or `develop`.
- Start each piece of work on a feature branch cut from `claude` (`git checkout claude && git checkout -b feature/<name>`).
- When the feature is done, merge it back into `claude` (`git checkout claude && git merge --no-ff feature/<name>`), then delete the feature branch.
- Use the git flow prefixes for other branch types too (`bugfix/`, `hotfix/`, `release/`), always cut from and merged back into `claude`.

## Commands

There is no build or test suite. Useful checks:

- Format Lua: `stylua .` (check only: `stylua --check .`). Config in `.stylua.toml`: 2-space indent, 160 cols, single quotes preferred, no call parentheses (`require 'foo'`, `setup { ... }`).
- Headless load check: `nvim --headless "+qa"` (surfaces startup errors); plugin sync: `nvim --headless "+Lazy! sync" +qa`.
- Health: `:checkhealth kickstart` (defined in `lua/kickstart/health.lua`).
- Inside Neovim: `:Lazy` (plugins), `:Mason` (LSP servers/tools), `:ConformInfo`.

## Architecture

- `init.lua` — the monolithic kickstart file: options, basic keymaps/autocmds, lazy.nvim bootstrap, and the core plugin specs (telescope, LSP via mason + lspconfig, conform, blink.cmp, tokyonight, mini.nvim, treesitter). Heavily commented in kickstart style.
  - Before `require('lazy').setup`, it loads `lua/extensions/` (`extensions.filetypes`, `extensions.keymaps`) for non-plugin user customizations.
  - At the end of the spec list it requires optional kickstart modules from `lua/kickstart/plugins/` (debug, indent_line, lint, autopairs, gitsigns; neo-tree is commented out) and then `{ import = 'plugins' }`.
- `lua/plugins/*.lua` — the user's own plugin specs, auto-imported by lazy.nvim (this replaces kickstart's `lua/custom/plugins/`). Each file returns a spec or list of specs. Contains the user's neo-tree config (used instead of `kickstart.plugins.neo-tree`), tmux-navigator, and an "IDE pack" (flutter-tools, trouble, toggleterm, overseer, todo-comments, nvim-surround, lsp_signature).
- `lua/extensions/` — plain Lua run at startup (custom keymap helpers like `nnoremap`/`xnoremap`, extra filetype detection).

### Adding things

- New LSP server: add to the `servers` table in `init.lua`; mason-tool-installer installs it and the mason-lspconfig handler sets it up with blink.cmp capabilities. Extra non-LSP tools go in the `vim.list_extend(ensure_installed, {...})` list.
- New formatter: `formatters_by_ft` in the conform spec in `init.lua` (format-on-save is on except for c/cpp).
- New linter: `lint.linters_by_ft` in `lua/kickstart/plugins/lint.lua`.
- New treesitter parser: `ensure_installed` in the treesitter spec in `init.lua`. This uses the newer nvim-treesitter API (`require('nvim-treesitter').install(...)` + a `FileType` autocmd calling `vim.treesitter.start`), not the old `configs.setup { highlight = ... }` style — parsers not in that list won't get highlighting started.
- New plugin: prefer a new file in `lua/plugins/` over editing `init.lua`.

### Gotchas

- Leader is `<Space>`; `vim.g.have_nerd_font = true`.
- Keymap overlap to watch for: `<leader>t` is ToggleTerm but is also the prefix for `<leader>th` (inlay hints) and gitsigns' `<leader>tb`/`<leader>tD`, so it waits for `timeoutlen` before it runs, `<leader>d`/`<leader>p`/`<leader>y` are remapped in `extensions/keymaps.lua`, and flutter-tools sets its own buffer-local `gd`/`gr`/`<leader>rn`/`<leader>ca`.
- `lazy-lock.json` is gitignored (kickstart default), so plugin versions are not pinned in the repo.
