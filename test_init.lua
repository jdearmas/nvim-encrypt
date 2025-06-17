-- Minimal init file for testing nvim-encrypt plugin
-- Run with: nvim -u test_init.lua

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
vim.opt.runtimepath:prepend(root)

-- Load the plugin
require("nvim-encrypt").setup({
  -- You can configure your GPG key here, or use :EncryptSelectKey
  -- gpg_key_id = 'YOUR_GPG_KEY_ID',
})

print("nvim-encrypt loaded!")
print("Commands:")
print("  :EncryptToggle - Toggle encryption mode")
print("  :DecryptBuffer - Decrypt current buffer")
print("  :EncryptSelectKey - Select GPG key")
print("  <Leader>e - Toggle encryption")
print("  <Leader>d - Decrypt buffer")

