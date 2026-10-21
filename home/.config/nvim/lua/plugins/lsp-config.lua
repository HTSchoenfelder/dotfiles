return {
  "neovim/nvim-lspconfig",
  lazy = false,
  config = function()
    vim.lsp.enable({ "html", "lua_ls", "solargraph", "ts_ls" })
  end,
}
