-- REST client keymaps
vim.keymap.set('n', '<leader>tr', ':hor Rest run<CR>', { desc = 'Rest [R]un request', buffer = true })
vim.keymap.set('n', '<leader>tl', ':hor Rest logs<CR>', { desc = 'Rest requests [l]ogs', buffer = true })
vim.keymap.set('n', '<leader>to', ':hor Rest open<CR>', { desc = '[O]pen Rest requests pane', buffer = true })
vim.keymap.set('n', '<leader>tc', ':Rest cookies<CR>', { desc = 'Open [c]ookies file', buffer = true })

