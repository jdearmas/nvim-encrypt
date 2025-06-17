-- Main test entry point for nvim-encrypt
-- Run with: nvim --headless -u test.lua

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
vim.opt.runtimepath:prepend(root)

-- Load plenary.nvim
local plenary_path = root .. "/tests/plenary.nvim"
if vim.fn.isdirectory(plenary_path) == 0 then
  print("ERROR: plenary.nvim not found at " .. plenary_path)
  print("Please run: make setup-tests")
  vim.cmd("qall!")
  os.exit(1)
end
vim.opt.runtimepath:prepend(plenary_path)

-- Load the plugin
require("nvim-encrypt")

-- Use plenary's test harness
local busted = require("plenary.test_harness")

-- Run tests in the tests directory
local test_dir = root .. "/tests"
print("Running tests from: " .. test_dir)
print("")

local success = busted.test_directory(test_dir, {
  minimal = false,
  verbose = true,
})

if success then
  print("")
  print("✓ All tests passed!")
  vim.cmd("qall!")
  os.exit(0)
else
  print("")
  print("✗ Some tests failed")
  vim.cmd("qall!")
  os.exit(1)
end

