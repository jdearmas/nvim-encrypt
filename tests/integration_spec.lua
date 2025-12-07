-- Integration tests for end-to-end workflow

local helper = require("tests.helper")
local nvim_encrypt = require("nvim-encrypt")

describe("Integration Tests", function()
  before_each(function()
    helper.setup_gpg()
    nvim_encrypt.setup({
      gpg_key_id = helper.GPG_KEY_ID,
    })
  end)
  
  after_each(function()
    helper.cleanup()
  end)
  
  it("should complete full encryption and decryption workflow", function()
    local test_file = helper.TEST_DIR .. "/workflow_test.txt"
    local plaintext = helper.TEST_TEXT
    
    -- Create new buffer
    vim.cmd("enew")
    
    -- Enable encryption
    nvim_encrypt.toggle()
    assert.is_true(nvim_encrypt._enabled)
    
    -- Type text
    for i = 1, #plaintext do
      nvim_encrypt.capture(plaintext:sub(i, i))
    end
    
    -- Wait for encryption
    vim.wait(200)
    
    -- Save encrypted file
    vim.cmd("write " .. test_file)
    
    -- Verify file contains encrypted content
    local file_content = helper.read_file(test_file)
    assert.is_not_nil(file_content)
    assert.matches("BEGIN PGP MESSAGE", file_content)
    
    -- Disable encryption
    nvim_encrypt.toggle()
    assert.is_false(nvim_encrypt._enabled)
    
    -- Decrypt the file using GPG
    local decrypted_file = helper.TEST_DIR .. "/decrypted_workflow.txt"
    assert.is_true(helper.decrypt_file(test_file, decrypted_file))
    
    -- Verify decrypted content matches original
    local decrypted_content = helper.read_file(decrypted_file)
    assert.is_not_nil(decrypted_content)
    decrypted_content = decrypted_content:gsub("%s+$", "")
    assert.equals(plaintext, decrypted_content)
  end)
  
  it("should handle encrypting, saving, and decrypting buffer", function()
    local test_file = helper.TEST_DIR .. "/buffer_test.txt"
    local plaintext = "Quick test"
    
    -- Create new buffer
    vim.cmd("enew")
    
    -- Enable encryption and type
    nvim_encrypt.toggle()
    for i = 1, #plaintext do
      nvim_encrypt.capture(plaintext:sub(i, i))
    end
    vim.wait(200)
    
    -- Save
    vim.cmd("write " .. test_file)
    
    -- Load the encrypted file
    vim.cmd("edit " .. test_file)
    
    -- Decrypt buffer
    local initial_wins = #vim.api.nvim_list_wins()
    nvim_encrypt.decrypt_buffer()
    vim.wait(100)
    
    -- Verify decrypted content
    local current_buf = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
    local decrypted = table.concat(lines, "\n"):gsub("%s+$", "")
    assert.equals(plaintext, decrypted)
  end)
  
  it("should persist encryption state correctly", function()
    -- Enable encryption
    nvim_encrypt.toggle()
    assert.is_true(nvim_encrypt._enabled)
    
    -- Type some text
    nvim_encrypt.capture("A")
    assert.equals("A", nvim_encrypt._plaintext)
    
    -- Disable
    nvim_encrypt.toggle()
    assert.is_false(nvim_encrypt._enabled)
    
    -- Re-enable should reset plaintext
    nvim_encrypt.toggle()
    assert.is_true(nvim_encrypt._enabled)
    assert.equals("", nvim_encrypt._plaintext)
  end)
end)

