-- minimal neovim 0.12+ config: vim.pack + built-in LSP + Nix-managed tools

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

-- vim.pack: built-in package manager (neovim 0.12+)
vim.pack.add({
  { src = "https://github.com/rebelot/kanagawa.nvim" },
  { src = "https://github.com/ibhagwan/fzf-lua" },
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1.*") },
  { src = "https://github.com/supermaven-inc/supermaven-nvim" },
  { src = "https://github.com/christoomey/vim-tmux-navigator" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
  { src = "https://github.com/stevearc/oil.nvim" },
  { src = "https://github.com/tpope/vim-fugitive" },
  { src = "https://github.com/norcalli/nvim-colorizer.lua" },
})

vim.pack.add({
  { src = "https://github.com/windwp/nvim-autopairs" },
}, { load = false })

require("fzf-lua").setup({})
require("blink.cmp").setup({
  keymap = { preset = "default" },
  appearance = { nerd_font_variant = "mono" },
  completion = { documentation = { auto_show = true, auto_show_delay_ms = 200 } },
  sources = { default = { "lsp", "path", "snippets", "buffer" } },
  fuzzy = { implementation = "prefer_rust_with_warning" },
})

require("supermaven-nvim").setup({
  keymaps = {
    accept_suggestion = "<C-y>",
    clear_suggestion = "<C-]>",
    accept_word = "<C-j>",
  },
  ignore_filetypes = {
    gitcommit = true,
    gitrebase = true,
    help = true,
    oil = true,
  },
})

require("nvim-web-devicons").setup({})
require("colorizer").setup({
  "*",
}, {
  RGB = true,
  RRGGBB = true,
  RRGGBBAA = true,
  names = false,
  rgb_fn = true,
  hsl_fn = true,
  css = true,
  css_fn = true,
  mode = "background",
})
require("oil").setup({
  columns = { "icon" },
})

vim.api.nvim_create_autocmd("InsertEnter", {
  once = true,
  callback = function()
    vim.cmd.packadd("nvim-autopairs")
    require("nvim-autopairs").setup({})
  end,
})

vim.cmd.colorscheme("kanagawa")

local fzf = require("fzf-lua")
vim.keymap.set("n", "<leader>sf", fzf.files, { desc = "Find files" })
vim.keymap.set("n", "<leader>sg", fzf.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>gs", function()
  vim.cmd("Git")
end, { desc = "Git status" })
vim.keymap.set("n", "<leader><Space>", fzf.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>di", vim.diagnostic.setqflist, { desc = "Diagnostics quickfix" })
vim.keymap.set("n", "<leader>pt", function()
  vim.cmd("Oil")
end, { desc = "Open Oil" })

vim.keymap.set("x", "<leader>y", '"+y', { desc = "Yank selection to system clipboard" })
vim.keymap.set("n", "<leader>p", '"+p', { desc = "Paste below from system clipboard" })
vim.keymap.set("x", "<leader>p", '"+p', { desc = "Paste below from system clipboard" })
vim.keymap.set("n", "<leader>P", '"+P', { desc = "Paste above from system clipboard" })
vim.keymap.set("x", "<leader>P", '"+P', { desc = "Paste above from system clipboard" })

require("lsp").setup(require("blink.cmp").get_lsp_capabilities())

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end

    map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    map("n", "gr", vim.lsp.buf.references, "References")
    map("n", "K", vim.lsp.buf.hover, "Hover")
    map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
    map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("n", "[d", function()
      vim.diagnostic.jump({
        count = -1,
        on_jump = function(_, bufnr)
          vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
        end,
      })
    end, "Prev diagnostic")
    map("n", "]d", function()
      vim.diagnostic.jump({
        count = 1,
        on_jump = function(_, bufnr)
          vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
        end,
      })
    end, "Next diagnostic")
  end,
})
