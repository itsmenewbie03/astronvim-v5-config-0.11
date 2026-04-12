-- This will run last in the setup process and is a good place to configure
-- things like custom filetypes. This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- Set up custom filetypes
-- vim.filetype.add {
--   extension = {
--     foo = "fooscript",
--   },
--   filename = {
--     ["Foofile"] = "fooscript",
--   },
--   pattern = {
--     ["~/%.config/foo/.*"] = "fooscript",
--   },
-- }
--
--
-- INFO: lineswapping binds
-- Move current line down
vim.keymap.set("n", "<leader>j", ":m .+1<CR>==", { desc = "Move line down" })

-- Move current line up
vim.keymap.set("n", "<leader>k", ":m .-2<CR>==", { desc = "Move line up" })

-- Visual mode mappings
vim.keymap.set("v", "<leader>j", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "<leader>k", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

vim.filetype.add {
  extension = {
    tf = "terraform",
  },
}

-- INFO: using mouse while coding is gay
vim.o.mouse = ""

-- INFO: scroll down when 10 lines is left
vim.o.scrolloff = 10

-- INFO: disable color highlights
require("nvim-highlight-colors").turnOff()
