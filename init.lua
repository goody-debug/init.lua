-- Leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Base options
local opt = vim.opt
vim.cmd("filetype plugin indent on")
vim.cmd("syntax on")

opt.swapfile = false
opt.backup = false
opt.writebackup = false
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
opt.mousescroll = "ver:3,hor:6"
opt.undodir = vim.fn.expand("~/.config/nvim/undodir")
opt.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50"
opt.completeopt = "menuone,noinsert"
opt.winborder = "rounded"
opt.fillchars = { fold = " ", eob = " " }
opt.pumheight = 8
opt.pumwidth = 25

-- Core Keymaps
local keymap = vim.keymap.set

-- Exit Insert mode and cancel active snippet session
keymap("i", "jj", function()
  if vim.snippet.active() then
    vim.snippet.stop()
  end
  return "<Esc>"
end, { expr = true, silent = true })

-- Normal mode Esc: cancel any lingering snippet session and clear search highlights
keymap("n", "<Esc>", function()
  if vim.snippet.active() then
    vim.snippet.stop()
  end
  vim.cmd("nohlsearch")
  return "<Esc>"
end, { expr = true, silent = true })
keymap("n", "<leader>x", function() MiniBufremove.delete(0, true) end, { silent = true })
keymap({ "n", "v" }, "<Leader>y", '"+y')
keymap({ "n", "v" }, "<Leader>p", '"+p')

-- ============================================================================
-- Built-in Package Manager (vim.pack)
-- ============================================================================
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local kind = ev.data.kind -- "install", "update", or "delete"
    local name = ev.data.spec.name
    vim.notify(string.format("Plugin %s: %s", kind, name), vim.log.levels.INFO)
  end,
})

vim.pack.add({
  "https://github.com/gbprod/nord.nvim",
  "https://github.com/echasnovski/mini.nvim",
  "https://github.com/nvim-treesitter/nvim-treesitter",
})

-- ============================================================================
-- Colorscheme (Nord)
-- ============================================================================
require("nord").setup({
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
    vim.api.nvim_set_hl(0, "NormalFloat", { link = "Normal" })

    local italic_groups = {
      "Comment", "String", "@comment", "@string",
      "Keyword", "Statement", "Conditional", "Repeat", "Exception", "Include",
      "@keyword", "@conditional", "@repeat", "@exception", "@include",
      "@keyword.conditional", "@keyword.repeat", "@keyword.exception", "@keyword.import",
      "Boolean", "Constant", "@boolean", "@constant.builtin",
      "Type", "StorageClass", "Structure",
      "@type", "@type.builtin", "@type.qualifier", "@keyword.modifier", "@keyword.type",
      "@variable.builtin",
      "Macro", "@function.builtin", "@function.macro",
      "markdownItalic", "@markup.italic",
      "@tag", "@tag.attribute",
    }

    for _, group in ipairs(italic_groups) do
      local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
      if next(hl) ~= nil then
        hl.italic = true
        vim.api.nvim_set_hl(0, group, hl)
      end
    end
  end,
})

vim.cmd.colorscheme("nord")

-- ============================================================================
-- mini.nvim Modules
-- ============================================================================
require("mini.icons").setup()
MiniIcons.mock_nvim_web_devicons()

require("mini.comment").setup()
require("mini.pairs").setup()
require("mini.surround").setup({
  mappings = {
    add = "ys",
    delete = "ds",
    replace = "cs",
    find = "",
    find_left = "",
    highlight = "",
    update_n_lines = "",
  },
})

require("mini.bufremove").setup()

-- ============================================================================
-- Centered File Explorer (mini.files)
-- ============================================================================
require("mini.files").setup({
  windows = { preview = true, width_focus = 35, width_preview = 45 },
})

-- Automatically center mini.files floating windows on screen
vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesWindowUpdate",
  callback = function(args)
    local config = vim.api.nvim_win_get_config(args.data.win_id)
    -- Center vertically
    config.row = math.floor(0.5 * (vim.o.lines - config.height))
    -- Offset horizontally from the left edge toward the center
    local total_width = 85 -- approximate width of focus + preview columns
    local base_col = math.max(0, math.floor(0.5 * (vim.o.columns - total_width)))
    config.col = config.col + base_col
    vim.api.nvim_win_set_config(args.data.win_id, config)
  end,
})

keymap("n", "<leader>e", function()
  if not MiniFiles.close() then
    MiniFiles.open(vim.api.nvim_buf_get_name(0), false)
  end
end, { silent = true })

-- ============================================================================
-- Centered Fuzzy Picker (mini.pick: files, grep_live, buffers, help)
-- ============================================================================
require("mini.pick").setup({
  window = {
    config = function()
      local height = math.floor(0.618 * vim.o.lines)
      local width = math.floor(0.618 * vim.o.columns)
      return {
        anchor = "NW",
        height = height,
        width = width,
        row = math.floor(0.5 * (vim.o.lines - height)),
        col = math.floor(0.5 * (vim.o.columns - width)),
        border = "rounded",
      }
    end,
  },
})

keymap("n", "<leader>ff", "<cmd>Pick files<CR>", { silent = true })
keymap("n", "<leader>fg", "<cmd>Pick grep_live<CR>", { silent = true })
keymap("n", "<leader>fb", "<cmd>Pick buffers<CR>", { silent = true })
keymap("n", "<leader>fh", "<cmd>Pick help<CR>", { silent = true })

-- ============================================================================
-- AutoComplete
-- ============================================================================
require("mini.completion").setup({
  window = {
    info = { height = 12, width = 45, border = "rounded" },
    signature = { height = 6, width = 45, border = "rounded" },
  },
  lsp_completion = {
    process_items = function(items, base)
      for _, item in ipairs(items) do
        item.labelDetails = nil
        if item.label and #item.label > 30 then
          item.label = item.label:sub(1, 29) .. "…"
        end
      end
      return MiniCompletion.default_process_items(items, base)
    end,
  },
})

-- Clear any subtle background tint on native snippet tabstops so the UI stays 100% clean
vim.api.nvim_set_hl(0, "SnippetTabstop", {})
vim.api.nvim_set_hl(0, "SnippetTabstopActive", {})

-- Automatically exit the snippet session whenever leaving Insert or Select mode
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = { "i:n", "s:n" },
  callback = function()
    if vim.snippet.active() then
      vim.snippet.stop()
    end
  end,
})

-- Map jj in both Insert ("i") and Select ("s") mode so it works even when a placeholder is highlighted
keymap({ "i", "s" }, "jj", function()
  if vim.snippet.active() then
    vim.snippet.stop()
  end
  return "<Esc>"
end, { expr = true, silent = true })

-- Normal mode Esc: stop any active snippet and clear search highlight
keymap("n", "<Esc>", function()
  if vim.snippet.active() then
    vim.snippet.stop()
  end
  vim.cmd("nohlsearch")
  return "<Esc>"
end, { expr = true, silent = true })

-- Super-Tab: cycle completion menu if open, otherwise jump native snippet placeholders
keymap({ "i", "s" }, "<Tab>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-n>"
  elseif vim.snippet.active({ direction = 1 }) then
    vim.schedule(function()
      vim.snippet.jump(1)
    end)
    return ""
  else
    return "<Tab>"
  end
end, { expr = true, silent = true })

keymap({ "i", "s" }, "<S-Tab>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-p>"
  elseif vim.snippet.active({ direction = -1 }) then
    vim.schedule(function()
      vim.snippet.jump(-1)
    end)
    return ""
  else
    return "<S-Tab>"
  end
end, { expr = true, silent = true })

keymap("i", "<CR>", 'pumvisible() ? "\\<C-y>" : "\\<CR>"', { expr = true })
-- ============================================================================
-- Floating Notifications (mini.notify)
-- ============================================================================
local notify = require("mini.notify")
notify.setup({
  content = {
    format = function(notif)
      return notif.msg
    end,
  },
  lsp_progress = {
    enable = true,
    duration_last = 1000,
  },
  window = {
    config = {
      border = "rounded",
    },
    max_width_share = 0.382,
    winblend = 0,
  },
})

vim.notify = notify.make_notify()
keymap("n", "<leader>h", function() MiniNotify.show_history() end, { silent = true })
-- ============================================================================
-- Load Language & LSP Configuration
-- ============================================================================
require("lang")

-- ============================================================================
-- Statusline
-- ============================================================================
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
    errors   = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR }),
    warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN }),
    info     = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO }),
    hints    = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT }),
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
    " %f %m%r",
    get_lsp_diagnostics(),
    "%=",
    " %l/%L:%c ",
  })
end

opt.statusline = "%!v:lua.MyStatusLine()"
opt.laststatus = 3
