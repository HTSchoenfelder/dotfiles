return {
  "mfussenegger/nvim-lint",
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      ruby = { "rubocop" },
    }

    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
      group = vim.api.nvim_create_augroup("project_lint", { clear = true }),
      callback = function()
        lint.try_lint()
      end,
    })
  end,
}
