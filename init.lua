-- ============================================================================
-- Leader Keys & Base Options
-- ============================================================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

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
opt.mousescroll = "ver:3,hor:6"
opt.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50"
opt.completeopt = "menuone,noinsert"
opt.winborder = "rounded"
opt.fillchars = { fold = " ", eob = " " }
opt.pumheight = 8
opt.pumwidth = 25
opt.laststatus = 3

-- Undo Configuration & History Limits
opt.undofile = true
opt.undolevels = 500
opt.undodir = vim.fn.expand("~/.config/nvim/undodir")

if vim.fn.isdirectory(vim.o.undodir) == 0 then
  vim.fn.mkdir(vim.o.undodir, "p")
end

-- ============================================================================
-- Orphaned Undo Files Automatic Cleanup
-- ============================================================================
local function clean_orphaned_undofiles(silent)
  local undodir = vim.o.undodir
  local handle = vim.uv.fs_scandir(undodir)
  if not handle then return end

  local count = 0
  while true do
    local name, type = vim.uv.fs_scandir_next(handle)
    if not name then break end

    if type == "file" then
      local original_path = name:gsub("%%", "/")
      if not original_path:match("^/") then
        original_path = "/" .. original_path
      end

      if vim.uv.fs_stat(original_path) == nil then
        local undo_path = undodir .. "/" .. name
        local success = vim.uv.fs_unlink(undo_path)
        if success then count = count + 1 end
      end
    end
  end

  if not silent and count > 0 then
    vim.notify(string.format("Pruned %d orphaned undo file(s)", count), vim.log.levels.INFO)
  end
end

vim.api.nvim_create_autocmd("BufWipeout", {
  callback = function(ev)
    local file = vim.api.nvim_buf_get_name(ev.buf)
    if file ~= "" and vim.uv.fs_stat(file) == nil then
      local undopath = vim.fn.undofile(file)
      if vim.uv.fs_stat(undopath) then
        vim.uv.fs_unlink(undopath)
      end
    end
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.schedule(function()
      clean_orphaned_undofiles(true)
    end)
  end,
})

vim.api.nvim_create_user_command("UndoClean", function()
  clean_orphaned_undofiles(false)
end, { desc = "Purge orphaned undo history files" })

-- ============================================================================
-- Core Keymaps
-- ============================================================================
local keymap = vim.keymap.set

keymap("n", "<Esc>", function()
  if vim.snippet.active() then
    vim.snippet.stop()
  end
  vim.cmd("nohlsearch")
  return "<Esc>"
end, { expr = true, silent = true })

keymap("n", "<leader>x", function() MiniBufremove.delete(0, true) end, { silent = true, desc = "Delete Buffer" })
keymap({ "n", "v" }, "<Leader>y", '"+y', { silent = true, desc = "Yank to Clipboard" })
keymap({ "n", "v" }, "<Leader>p", '"+p', { silent = true, desc = "Paste from Clipboard" })
keymap("n", "<leader>tu", "<cmd>UndoClean<CR>", { silent = true, desc = "Purge Orphaned Undos" })

-- ============================================================================
-- Built-in Package Manager (vim.pack)
-- ============================================================================
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local kind = ev.data.kind
    local name = ev.data.spec.name
    vim.notify(string.format("Plugin %s: %s", kind, name), vim.log.levels.INFO)
  end,
})

vim.pack.add({
  "https://github.com/echasnovski/mini.nvim",
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/rafamadriz/friendly-snippets",
})

-- ============================================================================
-- Colorscheme: Official Nord Specification via mini.base16 + Custom Italics
-- ============================================================================
local nord = {
  bg_dark    = "#2E3440", -- nord0 (Polar Night base)
  bg_light   = "#3B4252", -- nord1 (Statusline base / Pmenu)
  bg_select  = "#434C5E", -- nord2 (Visual selection / PmenuSel / Statusline pill)
  bg_gutter  = "#4C566A", -- nord3 (Borders / Inactive text)
  comment    = "#616E88", -- nord3 brightened (Official Nord comment contrast)
  fg_dark    = "#D8DEE9", -- nord4 (Snow Storm main text)
  fg_norm    = "#E5E9F0", -- nord5 (Snow Storm brighter text)
  fg_light   = "#ECEFF4", -- nord6 (Snow Storm pure white)
  teal       = "#8FBCBB", -- nord7 (Frost Teal - Types/Classes)
  cyan       = "#88C0D0", -- nord8 (Frost Cyan - Functions/Methods)
  blue       = "#81A1C1", -- nord9 (Frost Blue - Keywords/Operators)
  dark_blue  = "#5E81AC", -- nord10 (Frost Dark Blue - PreProc/Macros)
  red        = "#BF616A", -- nord11 (Aurora Red - Errors/Deletions)
  orange     = "#D08770", -- nord12 (Aurora Orange - Annotations/Special)
  yellow     = "#EBCB8B", -- nord13 (Aurora Yellow - Warnings/Escape chars)
  green      = "#A3BE8C", -- nord14 (Aurora Green - Strings)
  purple     = "#B48EAD", -- nord15 (Aurora Purple - Numbers/Constants)
}

local function apply_nord_spec_and_italics()
  local set_hl = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- 1. Core UI, Borders, Menus & Floating Windows
  set_hl("Normal",       { fg = nord.fg_dark, bg = nord.bg_dark })
  set_hl("NormalFloat",  { fg = nord.fg_dark, bg = nord.bg_dark })
  set_hl("FloatBorder",  { fg = nord.bg_gutter, bg = nord.bg_dark })
  set_hl("FloatTitle",   { fg = nord.cyan, bg = nord.bg_dark, bold = true })
  set_hl("StatusLine",   { fg = nord.fg_dark, bg = nord.bg_light })
  set_hl("StatusLineNC", { fg = nord.bg_gutter, bg = nord.bg_dark })
  set_hl("WinSeparator", { fg = nord.bg_gutter, bg = nord.bg_dark })
  set_hl("SignColumn",   { fg = nord.bg_gutter, bg = nord.bg_dark })
  set_hl("Visual",       { bg = nord.bg_select })
  set_hl("Search",       { fg = nord.bg_dark, bg = nord.cyan })
  set_hl("IncSearch",    { fg = nord.bg_dark, bg = nord.yellow })
  set_hl("CurSearch",    { fg = nord.bg_dark, bg = nord.yellow, bold = true })
  set_hl("MatchParen",   { fg = nord.cyan, bg = nord.bg_select, bold = true })
  set_hl("Directory",    { fg = nord.cyan })
  set_hl("Title",        { fg = nord.cyan, bold = true })

  -- Autocomplete Menu (Clean dark grey selection bar + cyan matching text, no white box)
  set_hl("Pmenu",          { fg = nord.fg_dark, bg = nord.bg_light })
  set_hl("PmenuSel",       { fg = nord.fg_light, bg = nord.bg_select, bold = true })
  set_hl("PmenuMatch",     { fg = nord.cyan, bg = "NONE", bold = true })
  set_hl("PmenuMatchSel",  { fg = nord.cyan, bg = "NONE", bold = true })
  set_hl("PmenuKind",      { fg = nord.teal, bg = nord.bg_light })
  set_hl("PmenuKindSel",   { fg = nord.teal, bg = nord.bg_select, bold = true })
  set_hl("PmenuExtra",     { fg = nord.comment, bg = nord.bg_light })
  set_hl("PmenuExtraSel",  { fg = nord.fg_dark, bg = nord.bg_select })
  set_hl("PmenuThumb",     { bg = nord.bg_gutter })
  set_hl("PmenuSbar",      { bg = nord.bg_light })

  -- 2. Official Nord Syntax, Treesitter & LSP Semantic Tokens
  set_hl("Comment",                 { fg = nord.comment, italic = true })
  set_hl("@comment",                { fg = nord.comment, italic = true })
  set_hl("@lsp.type.comment",       { fg = nord.comment, italic = true })

  set_hl("Identifier",              { fg = nord.fg_dark })
  set_hl("@variable",               { fg = nord.fg_dark })
  set_hl("@variable.member",        { fg = nord.fg_dark })
  set_hl("@variable.parameter",     { fg = nord.fg_dark })
  set_hl("@variable.builtin",       { fg = nord.blue, italic = true })
  set_hl("@property",               { fg = nord.fg_dark })
  set_hl("@field",                  { fg = nord.fg_dark })
  set_hl("@module",                 { fg = nord.fg_dark })
  set_hl("@lsp.type.variable",      { fg = nord.fg_dark })
  set_hl("@lsp.type.parameter",     { fg = nord.fg_dark })
  set_hl("@lsp.type.property",      { fg = nord.fg_dark })
  set_hl("@lsp.type.namespace",     { fg = nord.fg_dark })

  set_hl("Function",                { fg = nord.cyan })
  set_hl("@function",               { fg = nord.cyan })
  set_hl("@function.call",          { fg = nord.cyan })
  set_hl("@function.builtin",       { fg = nord.cyan, italic = true })
  set_hl("@function.macro",         { fg = nord.dark_blue, italic = true })
  set_hl("@method",                 { fg = nord.cyan })
  set_hl("@function.method",        { fg = nord.cyan })
  set_hl("@function.method.call",   { fg = nord.cyan })
  set_hl("@constructor",            { fg = nord.cyan })
  set_hl("@lsp.type.function",      { fg = nord.cyan })
  set_hl("@lsp.type.method",        { fg = nord.cyan })

  set_hl("Keyword",                 { fg = nord.blue, italic = true })
  set_hl("Statement",               { fg = nord.blue, italic = true })
  set_hl("Conditional",             { fg = nord.blue, italic = true })
  set_hl("Repeat",                  { fg = nord.blue, italic = true })
  set_hl("Exception",               { fg = nord.blue, italic = true })
  set_hl("Include",                 { fg = nord.blue, italic = true })
  set_hl("Operator",                { fg = nord.blue })
  set_hl("@operator",               { fg = nord.blue })
  set_hl("@keyword",                { fg = nord.blue, italic = true })
  set_hl("@keyword.function",       { fg = nord.blue, italic = true })
  set_hl("@keyword.return",         { fg = nord.blue, italic = true })
  set_hl("@keyword.operator",       { fg = nord.blue, italic = true })
  set_hl("@keyword.import",         { fg = nord.blue, italic = true })
  set_hl("@keyword.conditional",    { fg = nord.blue, italic = true })
  set_hl("@keyword.repeat",         { fg = nord.blue, italic = true })
  set_hl("@keyword.exception",      { fg = nord.blue, italic = true })
  set_hl("@lsp.type.keyword",       { fg = nord.blue, italic = true })

  set_hl("Type",                    { fg = nord.teal, italic = true })
  set_hl("Structure",               { fg = nord.teal, italic = true })
  set_hl("StorageClass",            { fg = nord.blue, italic = true })
  set_hl("@type",                   { fg = nord.teal, italic = true })
  set_hl("@type.builtin",           { fg = nord.blue, italic = true })
  set_hl("@type.definition",        { fg = nord.teal, italic = true })
  set_hl("@type.qualifier",         { fg = nord.blue, italic = true })
  set_hl("@lsp.type.type",          { fg = nord.teal, italic = true })
  set_hl("@lsp.type.struct",        { fg = nord.teal, italic = true })
  set_hl("@lsp.type.class",         { fg = nord.teal, italic = true })
  set_hl("@lsp.type.interface",     { fg = nord.teal, italic = true })
  set_hl("@lsp.type.enum",          { fg = nord.teal, italic = true })

  set_hl("String",                  { fg = nord.green, italic = true })
  set_hl("@string",                 { fg = nord.green, italic = true })
  set_hl("@string.escape",          { fg = nord.yellow })
  set_hl("@string.regex",           { fg = nord.yellow })
  set_hl("Number",                  { fg = nord.purple })
  set_hl("Float",                   { fg = nord.purple })
  set_hl("@number",                 { fg = nord.purple })
  set_hl("@number.float",           { fg = nord.purple })
  set_hl("Boolean",                 { fg = nord.blue, italic = true })
  set_hl("@boolean",                { fg = nord.blue, italic = true })
  set_hl("Constant",                { fg = nord.fg_dark, italic = true })
  set_hl("@constant",               { fg = nord.fg_dark, italic = true })
  set_hl("@constant.builtin",       { fg = nord.blue, italic = true })
  set_hl("@lsp.type.enumMember",    { fg = nord.fg_dark, italic = true })

  set_hl("PreProc",                 { fg = nord.dark_blue })
  set_hl("Macro",                   { fg = nord.dark_blue, italic = true })
  set_hl("Special",                 { fg = nord.cyan })
  set_hl("Delimiter",               { fg = nord.fg_light })
  set_hl("@punctuation.delimiter",  { fg = nord.fg_light })
  set_hl("@punctuation.bracket",    { fg = nord.fg_light })
  set_hl("@punctuation.special",    { fg = nord.blue })
  set_hl("@tag",                    { fg = nord.blue, italic = true })
  set_hl("@tag.attribute",          { fg = nord.teal, italic = true })
  set_hl("@tag.delimiter",          { fg = nord.fg_light })

  -- 3. Diagnostics, Jump2d, Pick & Statusline in Official Nord
  set_hl("DiagnosticError",         { fg = nord.red })
  set_hl("DiagnosticWarn",          { fg = nord.yellow })
  set_hl("DiagnosticInfo",          { fg = nord.cyan })
  set_hl("DiagnosticHint",          { fg = nord.dark_blue })

  set_hl("MiniJump2dSpot",          { fg = nord.bg_dark, bg = nord.yellow, bold = true })
  set_hl("MiniJump2dSpotAhead",     { fg = nord.bg_dark, bg = nord.cyan })
  set_hl("MiniJump2dDim",           { fg = nord.comment })
  set_hl("MiniCursorword",          { underline = true })
  set_hl("MiniCursorwordCurrent",   { underline = true })
  set_hl("MiniPickMatchCurrent",    { bg = nord.bg_select, bold = true })
  set_hl("MiniPickMatchMarked",     { fg = nord.bg_dark, bg = nord.cyan, bold = true })
  set_hl("MiniPickPrompt",          { fg = nord.cyan, bg = nord.bg_dark, bold = true })

  -- Nord Statusline Badges (Lualine/Airline specification)
  set_hl("MiniStatuslineModeNormal",  { fg = nord.bg_dark, bg = nord.blue,   bold = true })
  set_hl("MiniStatuslineModeInsert",  { fg = nord.bg_dark, bg = nord.green,  bold = true })
  set_hl("MiniStatuslineModeVisual",  { fg = nord.bg_dark, bg = nord.teal,   bold = true })
  set_hl("MiniStatuslineModeReplace", { fg = nord.bg_dark, bg = nord.red,    bold = true })
  set_hl("MiniStatuslineModeCommand", { fg = nord.bg_dark, bg = nord.yellow, bold = true })
  set_hl("MiniStatuslineModeOther",   { fg = nord.bg_dark, bg = nord.purple, bold = true })

  set_hl("MiniStatuslineDevinfo",     { fg = nord.fg_norm, bg = nord.bg_select })
  set_hl("MiniStatuslineFilename",    { fg = nord.fg_dark, bg = nord.bg_light })
  set_hl("MiniStatuslineFileinfo",    { fg = nord.fg_norm, bg = nord.bg_select })
  set_hl("MiniStatuslineInactive",    { fg = nord.bg_gutter, bg = nord.bg_dark })

  set_hl("NordStatusDiagError",       { fg = nord.red,       bg = nord.bg_select, bold = true })
  set_hl("NordStatusDiagWarn",        { fg = nord.yellow,    bg = nord.bg_select, bold = true })
  set_hl("NordStatusDiagInfo",        { fg = nord.cyan,      bg = nord.bg_select, bold = true })
  set_hl("NordStatusDiagHint",        { fg = nord.dark_blue, bg = nord.bg_select, bold = true })

  -- Keep native tabstops invisible
  set_hl("SnippetTabstop", {})
  set_hl("SnippetTabstopActive", {})

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
end

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = apply_nord_spec_and_italics,
})

require("mini.base16").setup({
  palette = {
    base00 = nord.bg_dark,   -- #2E3440
    base01 = nord.bg_light,  -- #3B4252
    base02 = nord.bg_select, -- #434C5E
    base03 = nord.comment,   -- #616E88
    base04 = nord.fg_dark,   -- #D8DEE9
    base05 = nord.fg_norm,   -- #E5E9F0
    base06 = nord.fg_light,  -- #ECEFF4
    base07 = nord.teal,      -- #8FBCBB
    base08 = nord.red,       -- #BF616A
    base09 = nord.orange,    -- #D08770
    base0A = nord.yellow,    -- #EBCB8B
    base0B = nord.green,     -- #A3BE8C
    base0C = nord.cyan,      -- #88C0D0
    base0D = nord.blue,      -- #81A1C1
    base0E = nord.purple,    -- #B48EAD
    base0F = nord.dark_blue, -- #5E81AC
  },
  use_cterm = true,
  plugins = { default = true },
})
apply_nord_spec_and_italics()

-- ============================================================================
-- Core Editing & Navigation Modules (mini.nvim)
-- ============================================================================
require("mini.icons").setup()
MiniIcons.mock_nvim_web_devicons()

require("mini.extra").setup()
require("mini.ai").setup({ n_lines = 500 })
require("mini.comment").setup()
require("mini.pairs").setup()
require("mini.bufremove").setup()
require("mini.bracketed").setup()
require("mini.cursorword").setup({ delay = 100 })

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

-- Move lines and visual selections (Alt + hjkl)
require("mini.move").setup({
  mappings = {
    left = "<M-h>",
    right = "<M-l>",
    down = "<M-j>",
    up = "<M-k>",
    line_left = "<M-h>",
    line_right = "<M-l>",
    line_down = "<M-j>",
    line_up = "<M-k>",
  },
})

-- 2D Jump on <CR> in Normal/Visual mode
local jump2d = require("mini.jump2d")
jump2d.setup({
  spotter = jump2d.gen_spotter.pattern("[^%s%p]+"),
  labels = "tnseriaogmplfuwyqbjdhvkzxc",
  view = {
    dim = true,
    n_steps_ahead = 1,
  },
  mappings = {
    start_jumping = "<CR>",
  },
})

vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter", "CmdwinEnter" }, {
  callback = function(ev)
    local bt = vim.bo[ev.buf].buftype
    local ft = vim.bo[ev.buf].filetype
    if bt ~= "" or ft == "qf" or ft == "help" or ft:match("^mini") then
      vim.b[ev.buf].minijump2d_disable = true
    end
  end,
})

-- Smooth Scrolling (ignores mouse wheel / single-line steps so it never stutters)
local animate = require("mini.animate")
local mouse_scrolled = false

for _, scroll in ipairs({ "Up", "Down" }) do
  local key = "<ScrollWheel" .. scroll .. ">"
  keymap({ "", "i" }, key, function()
    mouse_scrolled = true
    return key
  end, { expr = true })
end

animate.setup({
  cursor = { enable = false },
  scroll = {
    enable = true,
    timing = animate.gen_timing.quadratic({ duration = 120, unit = "total" }),
    subscroll = animate.gen_subscroll.equal({
      predicate = function(total_scroll)
        if mouse_scrolled then
          mouse_scrolled = false
          return false
        end
        return total_scroll > 3
      end,
    }),
  },
  resize = { enable = false },
  open = { enable = false },
  close = { enable = false },
})

-- Highlight Hex Colors (#88C0D0) and TODO/FIXME/NOTE
local hipatterns = require("mini.hipatterns")
hipatterns.setup({
  highlighters = {
    fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
    hack  = { pattern = "%f[%w]()HACK()%f[%W]",  group = "MiniHipatternsHack" },
    todo  = { pattern = "%f[%w]()TODO()%f[%W]",  group = "MiniHipatternsTodo" },
    note  = { pattern = "%f[%w]()NOTE()%f[%W]",  group = "MiniHipatternsNote" },
    hex_color = hipatterns.gen_highlighter.hex_color(),
  },
})

-- Trailing whitespace highlighter & trimmer
require("mini.trailspace").setup()
keymap("n", "<leader>tw", function()
  MiniTrailspace.trim()
  MiniTrailspace.trim_last_lines()
end, { silent = true, desc = "Trim Whitespace" })

-- ============================================================================
-- Centered File Explorer (mini.files)
-- ============================================================================
require("mini.files").setup({
  windows = { preview = true, width_focus = 35, width_preview = 45 },
})

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesWindowUpdate",
  callback = function(args)
    local config = vim.api.nvim_win_get_config(args.data.win_id)
    config.row = math.floor(0.5 * (vim.o.lines - config.height))
    local total_width = 85
    local base_col = math.max(0, math.floor(0.5 * (vim.o.columns - total_width)))
    config.col = config.col + base_col
    vim.api.nvim_win_set_config(args.data.win_id, config)
  end,
})

keymap("n", "<leader>e", function()
  if not MiniFiles.close() then
    MiniFiles.open(vim.api.nvim_buf_get_name(0), false)
  end
end, { silent = true, desc = "File Explorer" })

-- ============================================================================
-- Centered Fuzzy Picker (mini.pick + mini.extra)
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

keymap("n", "<leader>ff", "<cmd>Pick files<CR>", { silent = true, desc = "Find Files" })
keymap("n", "<leader>fg", "<cmd>Pick grep_live<CR>", { silent = true, desc = "Live Grep" })
keymap("n", "<leader>fb", "<cmd>Pick buffers<CR>", { silent = true, desc = "Find Buffers" })
keymap("n", "<leader>fh", "<cmd>Pick help<CR>", { silent = true, desc = "Help Tags" })
keymap("n", "<leader>fd", "<cmd>Pick diagnostic<CR>", { silent = true, desc = "Diagnostics" })
keymap("n", "<leader>fs", "<cmd>Pick lsp scope='document_symbol'<CR>", { silent = true, desc = "LSP Symbols" })

-- ============================================================================
-- AutoComplete (mini.completion)
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

-- ============================================================================
-- Clean Native Snippets + friendly-snippets in Popup Menu
-- ============================================================================
local native_expand = vim.snippet.expand

local snippets = require("mini.snippets")
snippets.setup({
  snippets = {
    snippets.gen_loader.from_lang(),
  },
  mappings = {
    expand = "",
    jump_next = "",
    jump_prev = "",
    stop = "",
  },
  expand = {
    insert = function(snippet)
      native_expand(snippet.body)
    end,
  },
})

MiniSnippets.start_lsp_server()

vim.schedule(function()
  vim.snippet.expand = native_expand
end)

-- ============================================================================
-- Super-Tab, Enter, and Snippet Exit Controls
-- ============================================================================
local function feedkeys(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), "n", false)
end

keymap({ "i", "s" }, "<Tab>", function()
  if vim.fn.pumvisible() == 1 then
    feedkeys("<C-n>")
  elseif vim.snippet.active({ direction = 1 }) then
    vim.snippet.jump(1)
  else
    feedkeys("<Tab>")
  end
end, { silent = true })

keymap({ "i", "s" }, "<S-Tab>", function()
  if vim.fn.pumvisible() == 1 then
    feedkeys("<C-p>")
  elseif vim.snippet.active({ direction = -1 }) then
    vim.snippet.jump(-1)
  else
    feedkeys("<S-Tab>")
  end
end, { silent = true })

keymap("i", "<CR>", function()
  if vim.fn.pumvisible() == 1 then
    feedkeys("<C-y>")
  else
    feedkeys("<CR>")
  end
end, { silent = true })

keymap({ "i", "s" }, "jj", function()
  if vim.snippet.active() then
    vim.snippet.stop()
  end
  feedkeys("<Esc>")
end, { silent = true })

vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = { "i:n", "s:n" },
  callback = function()
    if vim.snippet.active() then
      vim.snippet.stop()
    end
  end,
})

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
keymap("n", "<leader>h", function() MiniNotify.show_history() end, { silent = true, desc = "Notification History" })

-- ============================================================================
-- Keymap Documentation Popup (mini.clue)
-- ============================================================================
local miniclue = require("mini.clue")
miniclue.setup({
  triggers = {
    { mode = "n", keys = "<Leader>" },
    { mode = "x", keys = "<Leader>" },
    { mode = "i", keys = "<C-x>" },
    { mode = "n", keys = "g" },
    { mode = "x", keys = "g" },
    { mode = "n", keys = "'" },
    { mode = "n", keys = "`" },
    { mode = "n", keys = '"' },
    { mode = "x", keys = '"' },
    { mode = "n", keys = "<C-w>" },
    { mode = "n", keys = "z" },
    { mode = "x", keys = "z" },
    { mode = "n", keys = "[" },
    { mode = "n", keys = "]" },
  },
  clues = {
    { mode = "n", keys = "<Leader>f", desc = "+Find (Pick)" },
    { mode = "n", keys = "<Leader>t", desc = "+Trim/Cleanup" },
    miniclue.gen_clues.builtin_completion(),
    miniclue.gen_clues.g(),
    miniclue.gen_clues.marks(),
    miniclue.gen_clues.registers(),
    miniclue.gen_clues.windows(),
    miniclue.gen_clues.z(),
  },
  window = {
    delay = 300,
    config = {
      width = "auto",
      border = "rounded",
    },
  },
})

-- ============================================================================
-- Nord Statusline (mini.statusline)
-- ============================================================================
local statusline = require("mini.statusline")

local function nord_diagnostics()
  if statusline.is_truncated(75) then return "" end
  local count = vim.diagnostic.count(0)
  local err   = count[vim.diagnostic.severity.ERROR] or 0
  local warn  = count[vim.diagnostic.severity.WARN]  or 0
  local info  = count[vim.diagnostic.severity.INFO]  or 0
  local hint  = count[vim.diagnostic.severity.HINT]  or 0

  local parts = {}
  if err > 0  then table.insert(parts, "%#NordStatusDiagError#● " .. err) end
  if warn > 0 then table.insert(parts, "%#NordStatusDiagWarn#● " .. warn) end
  if info > 0 then table.insert(parts, "%#NordStatusDiagInfo#● " .. info) end
  if hint > 0 then table.insert(parts, "%#NordStatusDiagHint#● " .. hint) end

  if #parts == 0 then return "" end
  return table.concat(parts, " ") .. "%#MiniStatuslineDevinfo#"
end

statusline.setup({
  use_icons = true,
  content = {
    active = function()
      local mode, mode_hl = statusline.section_mode({ trunc_width = 120 })
      local diagnostics   = nord_diagnostics()
      local filename      = statusline.section_filename({ trunc_width = 140 })

      return statusline.combine_groups({
        { hl = mode_hl,                  strings = { mode:upper() } },
        { hl = "MiniStatuslineDevinfo",  strings = { diagnostics } },
        "%<",
        { hl = "MiniStatuslineFilename", strings = { filename } },
        "%=",
        { hl = mode_hl,                  strings = { "%l/%L:%c" } },
      })
    end,
    inactive = function()
      return "%#MiniStatuslineInactive# %f %="
    end,
  },
})

-- ============================================================================
-- Minimal Cheatsheet Plugin (<leader>? for Floating UI, <leader>fk for Picker)
-- ============================================================================
local cheatsheet_sections = {
  {
    title = "Navigation & Jumping",
    items = {
      { key = "<CR>",          desc = "2D Jump to any word on screen (mini.jump2d)" },
      { key = "[d / ]d",       desc = "Previous / Next LSP diagnostic (mini.bracketed)" },
      { key = "[b / ]b",       desc = "Previous / Next buffer (mini.bracketed)" },
      { key = "[q / ]q",       desc = "Previous / Next quickfix item (mini.bracketed)" },
      { key = "<C-d> / <C-u>", desc = "Smooth half-page scroll down / up (mini.animate)" },
    },
  },
  {
    title = "Editing & Selection",
    items = {
      { key = "Alt + h/j/k/l", desc = "Move line or visual selection (mini.move)" },
      { key = "ys{motion}{c}", desc = "Add surrounding character (mini.surround)" },
      { key = "ds{char}",      desc = "Delete surrounding character (mini.surround)" },
      { key = "cs{old}{new}",  desc = "Replace surrounding character (mini.surround)" },
      { key = "gc / gcc",      desc = "Toggle comment selection / line (mini.comment)" },
      { key = "vaq / ciq",     desc = "Select / change inside any quote (mini.ai)" },
      { key = "vab / cib",     desc = "Select / change inside any bracket (mini.ai)" },
      { key = "vaf / cif",     desc = "Select / change function call (mini.ai)" },
      { key = "vaa / cia",     desc = "Select / change function argument (mini.ai)" },
    },
  },
  {
    title = "Fuzzy Picker & Explorer",
    items = {
      { key = "<Space>e",  desc = "Toggle centered file explorer (mini.files)" },
      { key = "<Space>ff", desc = "Find files in project (mini.pick)" },
      { key = "<Space>fg", desc = "Live grep across project (mini.pick)" },
      { key = "<Space>fb", desc = "Switch open buffers (mini.pick)" },
      { key = "<Space>fd", desc = "Workspace diagnostics (mini.extra)" },
      { key = "<Space>fs", desc = "LSP document symbols (mini.extra)" },
      { key = "<Space>fh", desc = "Search Neovim help tags (mini.pick)" },
      { key = "<Space>fk", desc = "Fuzzy-search this Cheatsheet (mini.pick)" },
    },
  },
  {
    title = "Core & Buffers",
    items = {
      { key = "jj",          desc = "Exit Insert/Select mode & stop snippet" },
      { key = "Tab / S-Tab", desc = "Cycle completion menu / jump snippet tabstops" },
      { key = "<Space>x",    desc = "Delete current buffer cleanly (mini.bufremove)" },
      { key = "<Space>y",    desc = "Yank selection/motion to system clipboard" },
      { key = "<Space>p",    desc = "Paste from system clipboard" },
      { key = "<Space>tw",   desc = "Trim trailing whitespace & empty lines" },
      { key = "<Space>tu",   desc = "Purge orphaned undo files from disk" },
      { key = "<Space>h",    desc = "Show notification history (mini.notify)" },
      { key = "<Space>?",    desc = "Toggle this Nord Keymap Cheatsheet" },
    },
  },
}

local cs_win = nil
local cs_buf = nil

local function toggle_cheatsheet()
  if cs_win and vim.api.nvim_win_is_valid(cs_win) then
    vim.api.nvim_win_close(cs_win, true)
    cs_win = nil
    return
  end

  cs_buf = vim.api.nvim_create_buf(false, true)
  local lines = { "" }
  local highlights = {}

  for _, sec in ipairs(cheatsheet_sections) do
    local header = "  ▍ " .. sec.title
    table.insert(lines, header)
    table.insert(highlights, { "FloatTitle", #lines - 1, 0, -1 })

    for _, item in ipairs(sec.items) do
      local pad_key = string.format("    %-16s", item.key)
      local line = pad_key .. " │ " .. item.desc
      table.insert(lines, line)
      local lnum = #lines - 1
      table.insert(highlights, { "DiagnosticWarn", lnum, 0, #pad_key })
      table.insert(highlights, { "Comment", lnum, #pad_key, #pad_key + 5 })
      table.insert(highlights, { "NormalFloat", lnum, #pad_key + 5, -1 })
    end
    table.insert(lines, "")
  end

  vim.api.nvim_buf_set_lines(cs_buf, 0, -1, false, lines)
  vim.bo[cs_buf].modifiable = false
  vim.bo[cs_buf].bufhidden = "wipe"
  vim.b[cs_buf].minijump2d_disable = true

  local ns = vim.api.nvim_create_namespace("NordCheatsheet")
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(cs_buf, ns, hl[1], hl[2], hl[3], hl[4])
  end

  local width = 74
  local height = math.min(#lines, vim.o.lines - 6)
  cs_win = vim.api.nvim_open_win(cs_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor(0.5 * (vim.o.lines - height)),
    col = math.floor(0.5 * (vim.o.columns - width)),
    style = "minimal",
    border = "rounded",
    title = " Nord Keymap Cheatsheet (q / Esc to close) ",
    title_pos = "center",
  })

  vim.wo[cs_win].cursorline = true
  for _, k in ipairs({ "q", "<Esc>", "<leader>?" }) do
    vim.keymap.set("n", k, function()
      if cs_win and vim.api.nvim_win_is_valid(cs_win) then
        vim.api.nvim_win_close(cs_win, true)
        cs_win = nil
      end
    end, { buffer = cs_buf, silent = true, nowait = true })
  end
end

local function pick_cheatsheet()
  local items = {}
  for _, sec in ipairs(cheatsheet_sections) do
    for _, item in ipairs(sec.items) do
      table.insert(items, string.format("%-15s │ %-45s [%s]", item.key, item.desc, sec.title))
    end
  end
  MiniPick.start({
    source = {
      name = "Keymap Cheatsheet",
      items = items,
      choose = function() end,
    },
  })
end

keymap("n", "<leader>?", toggle_cheatsheet, { silent = true, desc = "Keymap Cheatsheet" })
keymap("n", "<F1>", toggle_cheatsheet, { silent = true, desc = "Keymap Cheatsheet" })
keymap("n", "<leader>fk", pick_cheatsheet, { silent = true, desc = "Search Keymaps" })

-- ============================================================================
-- Load Language & LSP Configuration
-- ============================================================================
require("lang")
