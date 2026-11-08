local opt = vim.opt
local keymap = vim.keymap.set

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

vim.lsp.config("*", {
  capabilities = capabilities,
})

-- Filetype-specific indentation
local indent_group = vim.api.nvim_create_augroup("CustomIndentation", { clear = true })
local indent_settings = {
  lua = 2,
  python = 4,
  go = 4,
  javascript = 2,
  html = 2,
  json = 2,
  c = 4,
  odin = 4,
}

for ft, spaces in pairs(indent_settings) do
  vim.api.nvim_create_autocmd("FileType", {
    group = indent_group,
    pattern = ft,
    callback = function()
      vim.opt_local.shiftwidth = spaces
      vim.opt_local.tabstop = spaces
      vim.opt_local.softtabstop = spaces
    end,
  })
end

-- Folding: Default to indent, automatically upgrade to Treesitter if a parser exists
opt.foldmethod = "indent"
opt.foldtext = ""
opt.foldlevel = 99
opt.foldlevelstart = 99

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("NativeTreesitter", { clear = true }),
  callback = function(ev)
    if pcall(vim.treesitter.start, ev.buf) then
      vim.opt_local.foldmethod = "expr"
      vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    end
  end,
})

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

-- Diagnostics
vim.diagnostic.config({
  float = { border = "rounded", max_width = 80 },
  signs = false,
  underline = true,
})

-- ============================================================================
-- Native LSP Definitions (Zero-Plugin Setup)
-- ============================================================================

-- 1. Python (ty)
vim.lsp.config("ty", {
  cmd = { "ty", "server" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "ty.toml", "setup.py", "requirements.txt", ".git" },
})

-- 2. Go (gopls)
vim.lsp.config("gopls", {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { "go.work", "go.mod", ".git" },
  settings = {
    gopls = {
      completeUnimported = true,
      staticcheck = true,
      codelenses = {
        gc_details = true,         
        generate = true,         
        regenerate_cgo = true,
        tidy = true, 
        upgrade_dependency = true,
        vendor = true,
      },
      analyses = {
        unusedparams = true,
      },
    },
  },
})

-- 3. Lua (lua-language-server)
vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc", ".stylua.toml", "stylua.toml", ".git" },
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = {
        globals = { "vim", "MiniIcons", "MiniFiles", "MiniPick", "MiniBufremove" },
      },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
        },
      },
      telemetry = { enable = false },
    },
  },
})

-- Enable all servers
vim.lsp.enable({ "ty", "gopls" })

-- ============================================================================
-- LSP Keymaps & Auto-Format on Save
-- ============================================================================
local lsp_group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
  group = lsp_group,
  callback = function(event)
    local bufopts = { noremap = true, silent = true, buffer = event.buf }
    local client = vim.lsp.get_client_by_id(event.data.client_id)

    keymap("n", "gd", vim.lsp.buf.definition, bufopts)
    keymap("n", "gi", vim.lsp.buf.implementation, bufopts)
    keymap("n", "gr", vim.lsp.buf.references, bufopts)
    keymap("n", "K", function() vim.lsp.buf.hover({ border = "rounded" }) end, bufopts)
    keymap("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
    keymap("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
    keymap("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, bufopts)
    keymap("n", "<C-w>d", function() vim.diagnostic.open_float({ border = "rounded" }) end, bufopts)
    keymap("n", "<leader>cl", vim.lsp.codelens.run, bufopts)

    -- Auto-format on save if the attached LSP supports it
    if client and client:supports_method("textDocument/formatting") then
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = lsp_group,
        buffer = event.buf,
        callback = function()
          vim.lsp.buf.format({ bufnr = event.buf, id = client.id, timeout_ms = 1000 })
        end,
      })
    end
  end,
})
