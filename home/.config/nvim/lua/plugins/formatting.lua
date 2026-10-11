return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      css = { "prettier" },
      eruby = { "erb_format" },
      graphql = { "prettier" },
      html = { "prettier" },
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      json = { "prettier" },
      jsonc = { "prettier" },
      lua = { "stylua" },
      markdown = { "prettier" },
      ruby = { "rubocop" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      yaml = { "prettier" },
    },
  },
  keys = {
    {
      "<leader>gf",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      desc = "Format buffer",
    },
  },
}
