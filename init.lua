-- Leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Base options
local opt = vim.opt
vim.cmd("filetype plugin indent on")
vim.cmd("syntax on")

opt.number = false
opt.cursorline = false
opt.expandtab = true
opt.tabstop = 4
opt.cmdheight = 0
opt.shiftwidth = 4
opt.softtabstop = 4
opt.autoindent = true
opt.smartindent = true
opt.ignorecase = true
opt.smartcase = true
opt.wrap = false
opt.incsearch = true
opt.hlsearch = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.splitbelow = true
opt.splitright = true
opt.showcmd = true
opt.wildmenu = true
opt.signcolumn = "yes"
opt.updatetime = 300
opt.hidden = true
opt.undofile = true
opt.undodir = vim.fn.expand("~/.config/nvim/undodir")
opt.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50"

-- Folds
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.fillchars = { fold = ' ' }
opt.foldtext = ""
opt.foldlevel = 99
opt.foldlevelstart = 99

-- Keymaps
local keymap = vim.keymap.set
keymap("n", "<Esc>", ":nohlsearch<CR><Esc>", { silent = true })
keymap("i", "jj", "<Esc>", { silent = true })
keymap("n", "<leader>x", ":bdelete!<CR>", { silent = true })
keymap({"n", "v"}, "<Leader>y", '"+y')
keymap({"n", "v"}, "<Leader>p", '"+p')

-- Diagnostics
vim.diagnostic.config({
  float = { border = "rounded", max_width = 80 },
  signs = false,
  underline = true,
})

-- Lazy bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins
require("lazy").setup({
  {
    'gbprod/nord.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('nord').setup({
        transparent = false,
        terminal_colors = true,
        styles = {
          comments = { italic = true },
          keywords = { italic = true },
          strings = { italic = true },
        },
      })
      
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
          local saga_normals = { 
            "SagaNormal", "HoverNormal", "RenameNormal", 
            "DiagnosticNormal", "DiagnosticShowNormal", 
            "ActionPreviewNormal", "CodeActionNormal",
            "NormalFloat" 
          }
          for _, group in ipairs(saga_normals) do
            vim.api.nvim_set_hl(0, group, { link = "Normal" })
          end
          
          local saga_borders = { 
            "SagaBorder", "HoverBorder", "RenameBorder", 
            "DiagnosticBorder", "DiagnosticShowBorder", 
            "ActionPreviewBorder", "CodeActionBorder",
            "FloatBorder" 
          }
          for _, group in ipairs(saga_borders) do
            local hl = vim.api.nvim_get_hl(0, { name = "FloatBorder", link = false })
            vim.api.nvim_set_hl(0, group, hl)
          end

          local italic_groups = {
            -- Comments/Strings
            "Comment", "String",
            "@comment", "@string",

            -- Keywords
            "Keyword", "Statement", "Conditional", "Repeat", "Exception", "Include",
            "@keyword", "@conditional", "@repeat", "@exception", "@include",
            "@keyword.conditional", "@keyword.repeat", "@keyword.exception", "@keyword.import",

            -- Constants
            "Boolean", "Constant",
            "@boolean", "@constant.builtin",

            -- Types/Classes
            "Type", "StorageClass", "Structure",
            "@type", "@type.builtin", "@type.qualifier", "@keyword.modifier", "@keyword.type",

            -- Variables
            "@variable.builtin",

            -- Macros/Functions
            "Macro",
            "@function.builtin", "@function.macro",

            -- Markup
            "markdownItalic", "@markup.italic",

            -- Tags
            "@tag", "@tag.attribute"
          }

          for _, group in ipairs(italic_groups) do
            local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
            hl.italic = true
            vim.api.nvim_set_hl(0, group, hl)
          end
        end
      })
      
      vim.cmd.colorscheme("nord")
    end
  },
  'tpope/vim-commentary',
  'tpope/vim-surround',
  { 'windwp/nvim-autopairs', config = true },
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require("nvim-tree").setup({
        view = {
          side = "right",
          width = 35,
        }
      })
      vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { silent = true })
    end
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 
        'nvimdev/lspsaga.nvim',
        config = function()
          require('lspsaga').setup({
            ui = { 
              border = 'rounded',
              scrollbar = false,
            },
            symbol_in_winbar = { enable = false },
            lightbulb = { enable = false }
          })
        end
      },
      {
        'nvim-treesitter/nvim-treesitter',
        config = function()
          vim.api.nvim_create_autocmd("FileType", {
            pattern = "odin",
            callback = function()
              vim.treesitter.start()
            end,
          })
        end
      },
      'nvim-tree/nvim-web-devicons',
    },
    config = function()
      local capabilities = require('blink.cmp').get_lsp_capabilities()
      
      vim.lsp.enable('ty')
      
      -- OLS configuration
      vim.lsp.config('ols', {
        cmd = { "ols" },
        filetypes = { "odin" },
        cmd_env = {
          OLS_BUILTIN_FOLDER = "/home/mudabir/.local/share/ols/builtin",
        },
        init_options = {
          enable_snippets = true,
          enable_auto_import = true,
          align_struct_fields = true,
          align_struct_values = true,
          align_trailing_comments = true,
          enable_semantic_tokens = true,
        },
      })
      vim.lsp.enable('ols')

      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(event)
          local bufopts = { noremap=true, silent=true, buffer=event.buf }
          vim.keymap.set('n', 'gd', '<cmd>Lspsaga goto_definition<CR>', bufopts)
          vim.keymap.set('n', 'gp', '<cmd>Lspsaga peek_definition<CR>', bufopts)
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
          vim.keymap.set('n', 'gr', '<cmd>Lspsaga finder<CR>', bufopts)
          vim.keymap.set('n', 'K', '<cmd>Lspsaga hover_doc<CR>', bufopts)
          vim.keymap.set('n', '<leader>rn', '<cmd>Lspsaga rename<CR>', bufopts)
          vim.keymap.set('n', '<leader>ca', '<cmd>Lspsaga code_action<CR>', bufopts)
          vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, bufopts)
          vim.keymap.set('n', '<C-w>d', '<cmd>Lspsaga show_line_diagnostics<CR>', bufopts)
        end,
      })
    end
  },
  {
    'saghen/blink.cmp',
    dependencies = 'rafamadriz/friendly-snippets',
    version = '*',
    build = 'cargo build --release',
    opts = {
      keymap = {
        preset = 'super-tab',
      },
      completion = {
        menu = {
          border = 'rounded',
          draw = { columns = { { "label" }, { "kind" } } }
        },
        documentation = { auto_show = false, window = { border = 'rounded' } }
      },
      sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
    }
  },
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'rcarriga/nvim-dap-ui',
      'nvim-neotest/nvim-nio',
    },
    config = function()
      local dap = require('dap')
      local dapui = require('dapui')
      
      dapui.setup()

      dap.adapters.codelldb = {
        type = 'server',
        port = "${port}",
        executable = {
          command = 'codelldb',
          args = { "--port", "${port}" },
        }
      }

      dap.configurations.odin = {
        {
          name = "Launch Odin Binary",
          type = "codelldb",
          request = "launch",
          program = function()
            local default_path = vim.fn.getcwd() .. '/' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
            return vim.fn.input('Path to executable: ', default_path, 'file')
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
          args = {},
        },
      }

      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

      local keymap = vim.keymap.set
      keymap("n", "<leader>b", function() require('dap').toggle_breakpoint() end)
      keymap("n", "<F5>", function() require('dap').continue() end)
      keymap("n", "<F10>", function() require('dap').step_over() end)
      keymap("n", "<F11>", function() require('dap').step_into() end)
      keymap("n", "<F12>", function() require('dap').step_out() end)
      keymap("n", "<leader>dq", function() require('dap').terminate(); require('dapui').close() end)
    end
  }
})

-- Auto folds
local fold_group = vim.api.nvim_create_augroup("RememberFolds", { clear = true })
vim.api.nvim_create_autocmd("BufWinLeave", {
  group = fold_group,
  pattern = "*.*",
  command = "mkview",
})
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = fold_group,
  pattern = "*.*",
  command = "silent! loadview",
})

-- Statusline
local modes = {
  ["n"] = "NORMAL", ["i"] = "INSERT", ["v"] = "VISUAL", ["V"] = "V-LINE",
  ["\22"] = "V-BLOCK", ["c"] = "COMMAND", ["R"] = "REPLACE",
}

local function get_mode()
  local m = vim.api.nvim_get_mode().mode
  return string.format(" %s ", modes[m] or m:upper())
end

local function get_lsp_diagnostics()
  local count = {
    errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR }),
    warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN }),
    info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO }),
    hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT }),
  }

  local parts = {}
  if count.errors > 0 then table.insert(parts, "%#DiagnosticError# ● " .. count.errors) end
  if count.warnings > 0 then table.insert(parts, "%#DiagnosticWarn# ● " .. count.warnings) end
  if count.info > 0 then table.insert(parts, "%#DiagnosticInfo# ● " .. count.info) end
  if count.hints > 0 then table.insert(parts, "%#DiagnosticHint# ● " .. count.hints) end

  return table.concat(parts, " ") .. "%#StatusLine#"
end

function MyStatusLine()
  return table.concat({
    "%#ModeMsg#",
    get_mode(),
    "%#StatusLine#",
    " %f %m%r",             -- File info
    get_lsp_diagnostics(),  -- Diagnostics
    "%=",                   -- Align right
    " %l/%L:%c ",           -- Line/Col
  })
end

vim.opt.statusline = "%!v:lua.MyStatusLine()"
vim.opt.laststatus = 3 

-- Autocomplete colors
vim.api.nvim_set_hl(0, "BlinkCmpMenu", { link = "NormalFloat" })
vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { link = "FloatBorder" })
vim.api.nvim_set_hl(0, "BlinkCmpDoc", { link = "NormalFloat" })
vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { link = "FloatBorder" })
opt.fillchars:append({ eob = " " })
