-- Harpoon: Fast navigation between frequently used files
return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local harpoon = require("harpoon")

    -- REQUIRED: Initialize harpoon
    harpoon:setup({
      settings = {
        save_on_toggle = true,
        sync_on_ui_close = true,
        key = function()
          return vim.uv.cwd()
        end,
      },
    })

    -- Keymaps
    local keymap = vim.keymap

    -- Add/remove files
    keymap.set("n", "<leader>a", function()
      harpoon:list():add()
      vim.notify("Added to Harpoon", vim.log.levels.INFO)
    end, { desc = "Add file to Harpoon" })

    -- Toggle Harpoon quick menu
    keymap.set("n", "<C-e>", function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = "Toggle Harpoon menu" })

    -- Quick navigation to first 4 files (ThePrimeagen's workflow)
    keymap.set("n", "<leader>1", function()
      harpoon:list():select(1)
    end, { desc = "Harpoon file 1" })

    keymap.set("n", "<leader>2", function()
      harpoon:list():select(2)
    end, { desc = "Harpoon file 2" })

    keymap.set("n", "<leader>3", function()
      harpoon:list():select(3)
    end, { desc = "Harpoon file 3" })

    keymap.set("n", "<leader>4", function()
      harpoon:list():select(4)
    end, { desc = "Harpoon file 4" })

    -- Navigate to next/previous in harpoon list
    keymap.set("n", "<C-S-P>", function()
      harpoon:list():prev()
    end, { desc = "Harpoon previous" })

    keymap.set("n", "<C-S-N>", function()
      harpoon:list():next()
    end, { desc = "Harpoon next" })
  end,
}
