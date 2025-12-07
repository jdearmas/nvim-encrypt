-- Test decryption functionality

local helper = require("tests.helper")
local nvim_encrypt = require("nvim-encrypt")

describe("Decryption Tests", function()
  before_each(function()
    helper.setup_gpg()
    nvim_encrypt.setup({
      gpg_key_id = helper.GPG_KEY_ID,
    })
  end)
  
  after_each(function()
    helper.cleanup()
  end)
  
  it("should decrypt encrypted text correctly", function()
    local plaintext = helper.TEST_TEXT
    local encrypted = nvim_encrypt.encrypt(plaintext)
    
    assert.is_not_nil(encrypted)
    
    -- Decrypt
    local decrypted = nvim_encrypt.decrypt(encrypted)
    
    assert.is_not_nil(decrypted)
    -- Remove trailing whitespace/newlines
    decrypted = decrypted:gsub("%s+$", "")
    assert.equals(plaintext, decrypted)
  end)
  
  it("should decrypt file using GPG directly", function()
    local plaintext = helper.TEST_TEXT
    local encrypted = nvim_encrypt.encrypt(plaintext)
    
    local encrypted_file = helper.TEST_DIR .. "/encrypted.txt"
    local decrypted_file = helper.TEST_DIR .. "/decrypted.txt"
    
    -- Write encrypted content to file
    assert.is_true(helper.write_file(encrypted_file, encrypted))
    
    -- Decrypt using GPG
    assert.is_true(helper.decrypt_file(encrypted_file, decrypted_file))
    
    -- Verify decrypted content
    local decrypted_content = helper.read_file(decrypted_file)
    assert.is_not_nil(decrypted_content)
    decrypted_content = decrypted_content:gsub("%s+$", "")
    assert.equals(plaintext, decrypted_content)
  end)
  
  it("should decrypt buffer into new split", function()
    local plaintext = helper.TEST_TEXT
    local encrypted = nvim_encrypt.encrypt(plaintext)
    
    -- Create new buffer and set encrypted content
    vim.cmd("enew")
    local lines = vim.split(encrypted, "\n", { trimempty = false })
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    
    -- Get initial window count
    local initial_windows = #vim.api.nvim_list_wins()
    
    -- Decrypt buffer
    nvim_encrypt.decrypt_buffer()
    
    -- Wait a bit for the split to be created
    vim.wait(100)
    
    -- Verify new window was created
    local final_windows = #vim.api.nvim_list_wins()
    assert.is_true(final_windows > initial_windows)
    
    -- Verify decrypted content in new buffer
    local current_buf = vim.api.nvim_get_current_buf()
    local decrypted_lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
    local decrypted_content = table.concat(decrypted_lines, "\n"):gsub("%s+$", "")
    assert.equals(plaintext, decrypted_content)
  end)
  
  it("should handle invalid encrypted content gracefully", function()
    local invalid_encrypted = "This is not encrypted content"
    
    -- Should not crash, but may return empty or error
    local result = nvim_encrypt.decrypt(invalid_encrypted)
    -- Result might be empty or contain error, but shouldn't crash
    assert.is_not_nil(result)
  end)
end)

