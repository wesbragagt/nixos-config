-- minimal neovim 0.12+ config: vim.pack + built-in LSP

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true
opt.ignorecase = true
opt.smartcase = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.undofile = true
opt.scrolloff = 8
opt.splitright = true
opt.splitbelow = true

vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
vim.keymap.set("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
vim.keymap.set("n", "<esc>", "<cmd>nohlsearch<cr>")

-- vim.pack: built-in package manager (neovim 0.12+)
vim.pack.add({
  { src = "https://github.com/rebelot/kanagawa.nvim" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/ibhagwan/fzf-lua" },
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1.*") },
})

require("mason").setup()
require("fzf-lua").setup({})
require("blink.cmp").setup({
  keymap = { preset = "default" },
  appearance = { nerd_font_variant = "mono" },
  completion = { documentation = { auto_show = true, auto_show_delay_ms = 200 } },
  sources = { default = { "lsp", "path", "snippets", "buffer" } },
  fuzzy = { implementation = "prefer_rust_with_warning" },
})

vim.cmd.colorscheme("kanagawa")

local fzf = require("fzf-lua")
vim.keymap.set("n", "<leader>sf", fzf.files,      { desc = "Find files" })
vim.keymap.set("n", "<leader>sg", fzf.live_grep,  { desc = "Live grep" })
vim.keymap.set("n", "<leader><Space>", fzf.buffers, { desc = "Buffers" })

-- built-in LSP (neovim 0.11+). Configs live in ~/.config/nvim/lua/lsps/<name>.lua.
local capabilities = require("blink.cmp").get_lsp_capabilities()
vim.lsp.config("*", { capabilities = capabilities })

local servers = { "lua_ls", "ts_ls", "pyright", "nixd", "yamlls", "tofu_ls" }
for _, name in ipairs(servers) do
  vim.lsp.config[name] = require("lsps." .. name)
end
vim.lsp.enable(servers)

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local map = function(m, lhs, rhs, desc)
      vim.keymap.set(m, lhs, rhs, { buffer = bufnr, desc = desc })
    end
    map("n", "gd", vim.lsp.buf.definition,      "Go to definition")
    map("n", "gr", vim.lsp.buf.references,      "References")
    map("n", "K",  vim.lsp.buf.hover,           "Hover")
    map("n", "<leader>rn", vim.lsp.buf.rename,  "Rename")
    map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("n", "[d", vim.diagnostic.goto_prev,    "Prev diagnostic")
    map("n", "]d", vim.diagnostic.goto_next,    "Next diagnostic")
  end,
})
