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

- Format Lua: `stylua .` (check only: `stylua --check .`; Mason installs it at `~/.local/share/nvim/mason/bin/stylua`). Config in `.stylua.toml`: 2-space indent, 160 cols, single quotes preferred, no call parentheses (`require 'foo'`, `setup { ... }`), simple statements collapsed onto one line.
- Headless load check: `nvim --headless "+qa"` (surfaces startup errors; on a fresh machine this also installs every plugin, which can take several minutes).
- Plugins (built-in `vim.pack`, no lazy.nvim): inspect with `:lua vim.pack.update(nil, { offline = true })`, update with `:lua vim.pack.update()` (`:write` in the confirmation buffer applies). Installed under `~/.local/share/nvim/site/pack/core/opt/`; versions pinned in the tracked `nvim-pack-lock.json`.
- Mason tools: `:MasonToolsUpdate` (headless: `nvim --headless +MasonToolsUpdateSync +qa`). Treesitter parsers: `:TSUpdate`.
- Health: `:checkhealth kickstart` (defined in `lua/kickstart/health.lua`).

## Architecture

The config tracks upstream kickstart, which uses Neovim 0.12's built-in `vim.pack`: plugins load eagerly, in order, as `vim.pack.add { ... }` followed by `require(...).setup {}`. There are no lazy specs, `keys =`, or `opts =` tables.

- `init.lua` — upstream kickstart split into numbered `do ... end` sections (options, keymaps, vim.pack build hooks, UI, telescope, LSP, conform, blink.cmp, treesitter, optional modules). Local `gh(repo)` helper expands GitHub URLs. User changes are applied inline on top of upstream; keep them minimal so upstream merges stay easy.
  - Section 2 requires `lua/extensions/` (`extensions.filetypes`, `extensions.keymaps`) for non-plugin user customizations.
  - Section 10 requires the optional kickstart modules from `lua/kickstart/plugins/` (debug, indent_line, lint, autopairs; kickstart's neo-tree is replaced by the user's own) and then `require 'custom.plugins'`.
- `lua/custom/plugins/*.lua` — the user's own plugins, loaded by `lua/custom/plugins/init.lua` in **unspecified order**; anything order-dependent must live in one file. Contains neo-tree (`neo-tree-file-explorer.lua`), tmux-navigator, and an "IDE pack" (flutter-tools, trouble, toggleterm, overseer, nvim-surround, lsp_signature). flutter-tools relies on nvim-dap/dap-ui from `kickstart.plugins.debug`, which loads earlier.
- `lua/extensions/` — plain Lua run at startup (custom keymap helpers like `nnoremap`/`xnoremap`, extra filetype detection).
- Icons come from `mini.icons` with `MiniIcons.mock_nvim_web_devicons()`, so plugins that want nvim-web-devicons work without installing it.

### Updating from upstream

`upstream` remote is `https://github.com/nvim-lua/kickstart.nvim`. Merge `upstream/master` on a feature branch; conflicts are usually limited to `init.lua`. User customizations in `init.lua` worth preserving: nerd font on, `<C-hjkl>` split maps commented out (tmux-navigator owns them), extensions requires, telescope `find_files` showing hidden/ignored files, `rust_analyzer` server, mini.statusline overrides hiding sections in neo-tree/special buffers, conform format-on-save inverted to "everything except c/cpp", and the enabled kickstart modules + `custom.plugins` loader.

### Adding things

- New LSP server: add to the `servers` table in `init.lua` (Section 6); mason-tool-installer installs it and the loop calls `vim.lsp.config` + `vim.lsp.enable`. Extra non-LSP tools go in the `vim.list_extend(ensure_installed, {...})` list.
- New formatter: `formatters_by_ft` in the conform setup in `init.lua` (format-on-save is on except for c/cpp).
- New linter: `lint.linters_by_ft` in `lua/kickstart/plugins/lint.lua`.
- Treesitter: parsers are auto-installed on `FileType` for any language nvim-treesitter supports; the `parsers` list only pre-installs.
- New plugin: prefer a new file in `lua/custom/plugins/` over editing `init.lua`. Plugins that need a build step go in the `PackChanged` autocmd in Section 3.

### Gotchas

- Leader is `<Space>`; `vim.g.have_nerd_font = true`.
- Keymap overlap to watch for: `<leader>t` is ToggleTerm but is also the prefix for `<leader>th` (inlay hints) and gitsigns' `<leader>tb`/`<leader>tw`, so it waits for `timeoutlen` before it runs; `<leader>d`/`<leader>p`/`<leader>y` are remapped in `extensions/keymaps.lua`; flutter-tools sets its own buffer-local `gd`/`gr`/`<leader>rn`/`<leader>ca`.
- `kickstart.plugins.debug` asks mason-nvim-dap to install `delve`, which needs Go; without Go it retries (and logs) on every startup.
