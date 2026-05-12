---@diagnostic disable: missing-fields

-- ==============================================================================
-- 1. GLOBALS & OPTIONS
-- ==============================================================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

-- General
opt.showmode = false
opt.termguicolors = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.undofile = true
opt.inccommand = "split"

-- UI & Display
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.wrap = true
opt.breakindent = true
opt.hlsearch = true

-- Formatting
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.textwidth = 80

-- ==============================================================================
-- 2. GENERAL KEYMAPS
-- ==============================================================================
local map = vim.keymap.set

-- Clear search & escape
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("i", "Hh", "<Esc>", { desc = "Exit insert mode" })
map("v", "Hh", "<Esc>", { desc = "Exit visual mode" })

-- Tabs & Buffers
map("n", "<leader>n", "<cmd>tabnew<CR>", { desc = "New Tab" })
map("n", "<leader>xt", "<cmd>tabclose<CR>", { desc = "Close Tab" })
map("n", "<leader>xb", "<cmd>bdelete<CR>", { desc = "Close Buffer" })

-- ==============================================================================
-- 3. DIAGNOSTICS CONFIGURATION
-- ==============================================================================
-- Customize diagnostic signs
local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

-- Configure diagnostic virtual text and floats
vim.diagnostic.config({
    virtual_text = {
        prefix = '●', -- Could be '■', '▎', 'x'
        source = "if_many", -- Or "always"
    },
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
        source = true,
        border = "rounded", -- Gives hover windows a nice border
        header = "",
        prefix = "",
    },
})

-- ==============================================================================
-- 4. PLUGINS & CONFIGURATIONS
-- ==============================================================================
local pack_add = vim.pack.add

-- Theme
pack_add({ "https://github.com/shaunsingh/nord.nvim" })
vim.cmd.colorscheme("nord")

-- Mini Suite
pack_add({ { src = "https://github.com/nvim-mini/mini.nvim", version = "stable" } })
require("mini.bracketed").setup()
require("mini.surround").setup()
require("mini.cursorword").setup()
require("mini.pairs").setup()
require("mini.move").setup()
require("mini.jump").setup()
require("mini.jump2d").setup()
require("mini.hipatterns").setup()
require("mini.git").setup()
require("mini.diff").setup()

-- Lualine (Isolated Scope)
pack_add({ "https://github.com/nvim-lualine/lualine.nvim" })
do
    local lualine = require("lualine")
    local colors = {
        bg = "#3b4252",
        fg = "#D8DEE9",
        yellow = "#EBCB8B",
        cyan = "#8FBCBB",
        darkblue = "#5E81AC",
        green = "#A3BE8C",
        orange = "#D08770",
        violet = "#B48EAD",
        magenta = "#B48EAD",
        blue = "#81A1C1",
        red = "#BF616A",
    }
    local conditions = {
        buffer_not_empty = function() return vim.fn.empty(vim.fn.expand("%:t")) ~= 1 end,
        hide_in_width = function() return vim.fn.winwidth(0) > 80 end,
        check_git_workspace = function()
            local filepath = vim.fn.expand("%:p:h")
            local gitdir = vim.fn.finddir(".git", filepath .. ";")
            return gitdir and #gitdir > 0 and #gitdir < #filepath
        end,
    }

    local config = {
        options = {
            component_separators = "",
            section_separators = "",
            theme = {
                normal = { c = { fg = colors.fg, bg = colors.bg } },
                inactive = { c = { fg = colors.fg, bg = colors.bg } },
            },
        },
        sections = { lualine_a = {}, lualine_b = {}, lualine_y = {}, lualine_z = {}, lualine_c = {}, lualine_x = {} },
        inactive_sections = { lualine_a = {}, lualine_b = {}, lualine_y = {}, lualine_z = {}, lualine_c = {}, lualine_x = {} },
    }

    local function ins_left(component) table.insert(config.sections.lualine_c, component) end
    local function ins_right(component) table.insert(config.sections.lualine_x, component) end

    ins_left { function() return "▊" end, color = { fg = colors.blue }, padding = { left = 0, right = 1 } }
    ins_left {
        function() return "" end,
        color = function()
            local mode_color = {
                n = colors.red,
                i = colors.green,
                v = colors.blue,
                [" "] = colors.blue,
                V = colors.blue,
                c = colors.magenta,
                no = colors.red,
                s = colors.orange,
                S = colors.orange,
                ic = colors.yellow,
                R = colors.violet,
                Rv = colors.violet,
                cv = colors.red,
                ce = colors.red,
                r = colors.cyan,
                rm = colors.cyan,
                ["r?"] = colors.cyan,
                ["!"] = colors.red,
                t = colors.red,
            }
            return { fg = mode_color[vim.fn.mode()] }
        end,
        padding = { right = 1 },
    }
    ins_left { "filesize", cond = conditions.buffer_not_empty }
    ins_left { "filename", cond = conditions.buffer_not_empty, color = { fg = colors.magenta, gui = "bold" } }
    ins_left { "location" }
    ins_left { "progress", color = { fg = colors.fg, gui = "bold" } }
    ins_left {
        "diagnostics", sources = { "nvim_diagnostic" },
        symbols = { error = " ", warn = " ", info = " " },
        diagnostics_color = { error = { fg = colors.red }, warn = { fg = colors.yellow }, info = { fg = colors.cyan } },
    }
    ins_left { function() return "%=" end }
    ins_left {
        function()
            local msg = "No Active Lsp"
            local buf_ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })
            local clients = vim.lsp.get_clients()
            if next(clients) == nil then return msg end
            for _, client in ipairs(clients) do
                local filetypes = client.config.filetypes
                if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then return client.name end
            end
            return msg
        end,
        icon = " LSP:", color = { fg = colors.fg, gui = "bold" },
    }

    ins_right { "o:encoding", fmt = string.upper, cond = conditions.hide_in_width, color = { fg = colors.green, gui = "bold" } }
    ins_right { "fileformat", fmt = string.upper, icons_enabled = false, color = { fg = colors.green, gui = "bold" } }
    ins_right { "branch", icon = "", color = { fg = colors.violet, gui = "bold" } }
    ins_right {
        "diff", symbols = { added = " ", modified = "󰝤 ", removed = " " },
        diff_color = { added = { fg = colors.green }, modified = { fg = colors.orange }, removed = { fg = colors.red } },
        cond = conditions.hide_in_width,
    }
    ins_right { function() return "▊" end, color = { fg = colors.blue }, padding = { left = 1 } }

    lualine.setup(config)
end

-- Snacks
pack_add({ "https://github.com/folke/snacks.nvim" })
require("snacks").setup({
    indent = { enabled = true },
    input = { enabled = true },
    notifier = { enabled = true },
    zen = { enabled = true },
    terminal = { enabled = true },
    explorer = { enabled = true },
    image = { enabled = true },
})
map("n", "<leader>t", function() Snacks.terminal.toggle() end, { desc = "Toggle Terminal" })
map("n", "<leader>z", function() Snacks.zen() end, { desc = "Toggle Zen Mode" })
map("n", "<leader>e", function() Snacks.explorer() end, { desc = "Toggle Explorer" })

-- Treesitter
pack_add({ "https://github.com/nvim-treesitter/nvim-treesitter" }, { confirm = false })
require("nvim-treesitter.config").setup({
    auto_install = true,
})

-- Blink (Completion)
pack_add({
    "https://github.com/saghen/blink.lib",
    "https://github.com/saghen/blink.cmp"
}, { confirm = false })

require("blink.cmp").setup({
    completion = {
        menu = {
            -- "single" gives sharp, clean, minimalistic edges instead of rounded
            border = "single",

            -- Adds a slight transparency to the menu for a more atmospheric feel
            -- (requires termguicolors to be set, and a terminal that supports transparency)
            winblend = 10,

            draw = {
                -- Cleans up the visual clutter by organizing columns neatly
                columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
            }
        },
        documentation = {
            auto_show = true,
            window = {
                border = "single",
                winblend = 10,
            }
        }
    },

    signature = {
        enabled = true,
        window = {
            border = "single",
            winblend = 10,
        }
    },


    keymap = { preset = "super-tab" },
    fuzzy = { implementation = "lua" },
})

-- LSP Configuration
pack_add({
    "https://github.com/neovim/nvim-lspconfig",
    "https://github.com/mason-org/mason.nvim",
    "https://github.com/mason-org/mason-lspconfig.nvim",
    "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim"
}, { confirm = false })

local lsp_servers = {
    lua_ls = { Lua = { workspace = { library = vim.api.nvim_get_runtime_file("lua", true) } } },
    ty = {},
    ruff = {},
    clangd = {},
    zls = {},
}

require("mason").setup()
require("mason-lspconfig").setup()
require("mason-tool-installer").setup({
    ensure_installed = vim.tbl_keys(lsp_servers),
})

for server, config in pairs(lsp_servers) do
    vim.lsp.config(server, {
        settings = config,
        on_attach = function(_, bufnr)
            map("n", "grd", vim.lsp.buf.definition, { buffer = bufnr, desc = "LSP: Go to definition" })
            map("n", "grf", vim.lsp.buf.format, { buffer = bufnr, desc = "LSP: Format buffer" })
        end,
    })
end

-- Telescope (Fuzzy Finder)
pack_add({
    "https://github.com/nvim-lua/plenary.nvim",
    "https://github.com/nvim-tree/nvim-web-devicons",
    "https://github.com/nvim-telescope/telescope.nvim"
}, { confirm = false })
require("telescope").setup({})

local pickers = require("telescope.builtin")
map("n", "<leader>sp", pickers.builtin, { desc = "[S]earch Builtin [P]ickers" })
map("n", "<leader>sb", pickers.buffers, { desc = "[S]earch [B]uffers" })
map("n", "<leader>sf", pickers.find_files, { desc = "[S]earch [F]iles" })
map("n", "<leader>sw", pickers.grep_string, { desc = "[S]earch Current [W]ord" })
map("n", "<leader>sg", pickers.live_grep, { desc = "[S]earch by [G]rep" })
map("n", "<leader>sr", pickers.resume, { desc = "[S]earch [R]esume" })
map("n", "<leader>sh", pickers.help_tags, { desc = "[S]earch [H]elp" })
map("n", "<leader>sm", pickers.man_pages, { desc = "[S]earch [M]anuals" })
map("n", "gd", pickers.lsp_definitions, { desc = "Go to Definition" })
map("n", "gi", pickers.lsp_implementations, { desc = "Go to Implementation" })
map("n", "<leader>ss", pickers.lsp_document_symbols, { desc = "[S]erch [S]ymbols" })
map("n", "<leader>sk", pickers.lsp_dynamic_workspace_symbols, { desc = "[S]earch wor[K]space Symbols" })

-- Which-Key
pack_add({ "https://github.com/folke/which-key.nvim" }, { confirm = false })
require("which-key").setup({
    spec = {
        { "<leader>s", group = "[S]earch", icon = { icon = "", color = "green" } },
    }
})

-- Debugging & Godot
pack_add({
    "https://github.com/mfussenegger/nvim-dap",
    "https://github.com/rcarriga/nvim-dap-ui",
    "https://github.com/Mathijs-Bakker/godotdev.nvim"
})
require("godotdev").setup()

-- Garbage Day
pack_add({ "https://github.com/zeioth/garbage-day.nvim" })
require("garbage-day").setup({ opts = {} })

-- ==============================================================================
-- 5. UI
-- ==============================================================================
pack_add({
    { src = 'https://github.com/MunifTanjim/nui.nvim' },
    { src = 'https://github.com/folke/noice.nvim' },
})

require("noice").setup({
    lsp = {
        override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
        },
        hover = {
            enabled = true, -- Let noice handle standard LSP hover (the 'K' keybind)
            border = {
                style = "single"
            },
        },
        signature = {
            -- Disable noice's signature help so it doesn't clash with blink.cmp
            enabled = false,
        },
    },
    presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = true, -- Gives hover docs a nice border
    },
    views = {
        -- 1. The LSP Hover Window
        hover = {
            border = {
                style = "single",
            },
            win_options = {
                winblend = 10, -- Matches your blink.cmp setting
                -- Optional: You can also change the background color highlight group here
                -- winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
            },
        },

        -- 2. The Command Line Popup (when you type ':')
        cmdline_popup = {
            win_options = {
                winblend = 10,
            },
        },

        -- 3. General Popups (like when you get a long message or error)
        popup = {
            win_options = {
                winblend = 10,
            },
        },

        -- 4. The Mini View (the little notification box in the bottom right)
        mini = {
            win_options = {
                winblend = 10,
            },
        },
    },
})

-- Using your vim.pack.add setup
pack_add({
    { src = 'https://github.com/smjonas/inc-rename.nvim' }
})

require("inc_rename").setup()
-- Keymap
vim.keymap.set("n", "<leader>rn", function()
    return ":IncRename " .. vim.fn.expand("<cword>")
end, { expr = true, desc = "Rename" })
