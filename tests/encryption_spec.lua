-- Test encryption functionality

local helper = require("tests.helper")
local nvim_encrypt = require("nvim-encrypt")

describe("Encryption Tests", function()
  before_each(function()
    helper.setup_gpg()
    nvim_encrypt.setup({
      gpg_key_id = helper.GPG_KEY_ID,
    })
  end)
  
  after_each(function()
    helper.cleanup()
  end)
  
  it("should encrypt text correctly", function()
    local plaintext = helper.TEST_TEXT
    local encrypted = nvim_encrypt.encrypt(plaintext)
    
    assert.is_not_nil(encrypted)
    assert.matches("BEGIN PGP MESSAGE", encrypted)
    assert.matches("END PGP MESSAGE", encrypted)
  end)
  
  it("should enable and disable encryption mode", function()
    assert.is_false(nvim_encrypt._enabled)
    
    nvim_encrypt.toggle()
    assert.is_true(nvim_encrypt._enabled)
    
    nvim_encrypt.toggle()
    assert.is_false(nvim_encrypt._enabled)
  end)
  
  it("should capture and encrypt text in real-time", function()
    nvim_encrypt.toggle()
    
    -- Simulate typing
    local text = "Hello"
    for i = 1, #text do
      nvim_encrypt.capture(text:sub(i, i))
    end
    
    assert.equals("Hello", nvim_encrypt._plaintext)
    
    -- Check that buffer was updated with encrypted content
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local buffer_content = table.concat(lines, "\n")
    assert.matches("BEGIN PGP MESSAGE", buffer_content)
  end)
  
  it("should handle backspace correctly", function()
    nvim_encrypt.toggle()
    -- Ensure plaintext is empty at start
    nvim_encrypt._plaintext = ''
    
    nvim_encrypt.capture("H")
    nvim_encrypt.capture("e")
    nvim_encrypt.capture("l")
    assert.equals("Hel", nvim_encrypt._plaintext)
    
    nvim_encrypt.backspace()
    assert.equals("He", nvim_encrypt._plaintext)
    
    nvim_encrypt.backspace()
    assert.equals("H", nvim_encrypt._plaintext)
    
    nvim_encrypt.toggle()  -- Clean up
  end)
  
  it("should save encrypted content to file", function()
    local test_file = helper.TEST_DIR .. "/encrypted_test.txt"
    
    -- Create new buffer
    vim.cmd("enew")
    
    -- Enable encryption
    nvim_encrypt.toggle()
    
    -- Type some text
    local text = helper.TEST_TEXT
    for i = 1, #text do
      nvim_encrypt.capture(text:sub(i, i))
    end
    
    -- Wait a bit for encryption
    vim.wait(200)
    
    -- Save file
    vim.cmd("write " .. test_file)
    
    -- Verify file exists and contains encrypted content
    assert.is_true(vim.fn.filereadable(test_file) == 1)
    local file_content = helper.read_file(test_file)
    assert.is_not_nil(file_content)
    assert.matches("BEGIN PGP MESSAGE", file_content)
  end)
  
  it("should fail to encrypt without GPG key", function()
    -- Clean up any saved default key first
    local config_file = vim.fn.stdpath("data") .. "/nvim-encrypt/default_key"
    if vim.fn.filereadable(config_file) == 1 then
      vim.fn.delete(config_file)
    end
    
    -- Reset the module state
    nvim_encrypt.config.gpg_key_id = nil
    
    assert.has_error(function()
      nvim_encrypt.encrypt("test")
    end, "nvim-encrypt: gpg_key_id not set")
  end)
end)

