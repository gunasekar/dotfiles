-- CSV/TSV viewer — renders delimited files as aligned columns
-- Repo: https://github.com/hat0uma/csvview.nvim

return {
  {
    "hat0uma/csvview.nvim",
    ---@module "csvview"
    ---@type CsvView.Options
    ft = { "csv", "tsv" },
    cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
    opts = {
      -- Treat lines starting with these as comments rather than data rows.
      parser = { comments = { "#", "//" } },
      view = {
        -- "border" draws separators between columns; "highlight" only tints
        -- the delimiter. Border reads more like a spreadsheet.
        display_mode = "border",
      },
      keymaps = {
        -- Field text objects: `if`/`af` to select inner/around a cell.
        textobject_field_inner = { "if", mode = { "o", "x" } },
        textobject_field_outer = { "af", mode = { "o", "x" } },
        -- Excel-like motion between cells/rows.
        jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
        jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
        jump_next_row = { "<Enter>", mode = { "n", "v" } },
        jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
      },
    },
    -- Auto-enable the aligned view whenever a CSV/TSV buffer opens.
    config = function(_, opts)
      require("csvview").setup(opts)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "csv", "tsv" },
        callback = function()
          require("csvview").enable()
          -- Use absolute (normal) line numbers here instead of the global
          -- relativenumber — easier to cross-reference rows in tabular data.
          vim.opt_local.relativenumber = false
        end,
      })
    end,
  },
}
