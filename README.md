# Minimal Neovim 0.12 Configuration

A fast, lightweight Neovim (`v0.12+`) configuration built around Neovim's native APIs (`vim.pack` and `vim.lsp.config`) and **4 plugins**.

## Highlights

* **Zero External Plugin Manager:** Uses Neovim 0.12's built-in `vim.pack.add()` for cloning and updating packages natively.
* **Zero-Plugin LSP:** Language servers are configured and attached directly via `vim.lsp.config` and `vim.lsp.enable` without `nvim-lspconfig`.
* **Centered Floating UI:** Fuzzy pickers (`mini.pick`), the column-based file explorer (`mini.files`), and LSP hover/diagnostic windows open centered with rounded borders (`winborder = "rounded"`).
* **Swapfile-Free Persistence:** Swapfiles and backups are disabled in favor of persistent undo history (`undofile`)[cite: 1] and automatic view/fold restoration (`mkview` / `loadview`)[cite: 1].
* **Compact Autocompletion:** Native LSP completion via `mini.completion` constrained to a minimal, non-intrusive popup menu.

## Plugins

1. **[`gbprod/nord.nvim`](https://github.com/gbprod/nord.nvim)** — Nord colorscheme with custom italic highlight rules[cite: 1].
2. **[`echasnovski/mini.nvim`](https://github.com/echasnovski/mini.nvim)** — Core editor modules:
   * `mini.pick` — Centered fuzzy finder for files, live ripgrep, buffers, and help tags.
   * `mini.files` — Centered column-based file explorer with live preview.
   * `mini.completion` — Lightweight LSP completion with compact popup dimensions.
   * `mini.notify` — Floating notifications and message history.
   * `mini.icons` — Filetype and UI icons.
   * `mini.comment`, `mini.pairs`, `mini.surround`, `mini.bufremove` — Text objects, auto-pairs, and layout-preserving buffer deletion.
3. **[`nvim-treesitter/nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter)** — Parser and query installer paired with Neovim's native `vim.treesitter` highlighting and folding engine[cite: 1].
4. **[`rafamadriz/friendly-snippets`](https://github.com/rafamadriz/friendly-snippets)**

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

The leader key is mapped to `<Space>`[cite: 1].

### General
| Mode | Key | Action |
| :--- | :--- | :--- |
| `i` | `jj` | Exit Insert mode[cite: 1] |
| `n` | `<Esc>` | Clear search highlights[cite: 1] |
| `n` | `<leader>x` | Delete current buffer without closing the window (`mini.bufremove`) |
| `n` | `<leader>h` | Show notification history (`mini.notify`) |
| `n`, `v` | `<leader>y` | Yank to system clipboard (`"+y`)[cite: 1] |
| `n`, `v` | `<leader>p` | Paste from system clipboard (`"+p`)[cite: 1] |

### Pickers & File Explorer
| Mode | Key | Action |
| :--- | :--- | :--- |
| `n` | `<leader>e` | Toggle centered file explorer (`mini.files`) |
| `n` | `<leader>ff` | Find files (`mini.pick`) |
| `n` | `<leader>fg` | Live grep across project (`mini.pick`) |
| `n` | `<leader>fb` | Switch open buffers (`mini.pick`) |
| `n` | `<leader>fh` | Search help tags (`mini.pick`) |

### Editing & Completion
| Mode | Key | Action |
| :--- | :--- | :--- |
| `i` | `<Tab>` / `<S-Tab>` | Cycle next / previous completion item |
| `i` | `<CR>` | Confirm selected completion item |
| `n` | `gcc` | Toggle line comment (`mini.comment`) |
| `v` | `gc` | Toggle selection comment (`mini.comment`) |
| `n` | `ys{motion}{char}` | Add surrounding characters (`mini.surround`) |
| `n` | `ds{char}` | Delete surrounding characters (`mini.surround`) |
| `n` | `cs{old}{new}` | Replace surrounding characters (`mini.surround`) |

### LSP (Active on Buffer Attach)
| Mode | Key | Action |
| :--- | :--- | :--- |
| `n` | `gd` | Go to definition |
| `n` | `gi` | Go to implementation[cite: 1] |
| `n` | `gr` | Find references |
| `n` | `K` | Show hover documentation |
| `n` | `<leader>rn` | Rename symbol |
| `n` | `<leader>ca` | Code actions |
| `n` | `<leader>f` | Format current buffer[cite: 1] |
| `n` | `<C-w>d` | Open line diagnostics float |

## Maintenance Commands

* **Update plugins:** `:lua vim.pack.update()`
* **Install Treesitter parsers:** `:TSInstall go gomod gowork gotmpl`
