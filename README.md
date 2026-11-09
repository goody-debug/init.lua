# Minimal Neovim 0.12 Configuration

A fast, lightweight Neovim (`v0.12+`) configuration built around Neovim's native APIs (`vim.pack` and `vim.lsp.config`) and **3 plugins**.

## Highlights

* **Zero External Plugin Manager:** Uses Neovim 0.12's built-in `vim.pack.add()` for cloning and updating packages natively.
* **Zero-Plugin LSP:** Language servers are configured and attached directly via `vim.lsp.config` and `vim.lsp.enable` without `nvim-lspconfig`.
* **Centered Floating UI:** Fuzzy pickers (`mini.pick`), the column-based file explorer (`mini.files`), and LSP hover/diagnostic windows open centered with rounded borders (`winborder = "rounded"`).
* **Swapfile-Free Persistence:** Swapfiles and backups are disabled in favor of persistent undo history (`undofile`)[cite: 1] and automatic view/fold restoration (`mkview` / `loadview`)[cite: 1].
* **Compact Autocompletion:** Native LSP completion via `mini.completion` constrained to a minimal, non-intrusive popup menu.

## Plugins
1. **[`echasnovski/mini.nvim`](https://github.com/echasnovski/mini.nvim)** — Clean Nord colorscheme, Autocomplete, and everything else.
2. **[`nvim-treesitter/nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter)** — Parser and query installer paired with Neovim's native `vim.treesitter` highlighting and folding engine.
3. **[`rafamadriz/friendly-snippets`](https://github.com/rafamadriz/friendly-snippets)**

## Directory Structure

```text
~/.config/nvim/
├── init.lua       # Core options, vim.pack, Nord theme, mini.nvim setup, custom statusline
└── lua/
    └── lang.lua   # Per-filetype indentation, Treesitter attach, native LSP configs & format-on-save
```

## Language Servers (`lua/lang.lua`)

Configured natively via `vim.lsp.config` with automatic format-on-save (`BufWritePre`) for supported servers:

* **Python:** `ty` (`ty server`)
* **Go:** `gopls`
* **Lua:** `lua-language-server` (`lua_ls`)

## Keybindings
use `<leader>?` for a `cheasheet`

## Maintenance Commands

* **Update plugins:** `:lua vim.pack.update()`
* **Install Treesitter parsers:** `:TSInstall go gomod gowork gotmpl`
* **Remove plugins:** `:lua vim.pack.del({"example.nvim"})`
