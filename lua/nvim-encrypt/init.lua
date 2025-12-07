-- lua/nvim-encrypt/init.lua
-- nvim-encrypt.nvim: A Neovim plugin for real-time GPG encryption/decryption of your buffer content
--
-- Description:
--   This plugin allows you to encrypt everything you type in Insert mode in real-time using GPG,
--   and decrypt existing encrypted buffers into a readable split. 
--
-- Installation (with packer.nvim):
--   use {
--     'jdearmas/nvim-encrypt.nvim',
--     config = function()
--       require('nvim-encrypt').setup {
--         gpg_key_id  = 'YOUR_KEY_ID',    -- optional: GPG key ID (will prompt if not set)
--         toggle_key  = '<Leader>e',      -- optional: key to toggle encrypt mode
--         decrypt_cmd = '<Leader>d'       -- optional: key to decrypt buffer
--       }
--     end
--   }
--
-- Usage:
--   :EncryptToggle             -- toggle real-time encryption on/off
--   :DecryptBuffer             -- decrypt current buffer into a new split
--   :EncryptSelectKey          -- interactively select and set default GPG key
--   Press <Leader>e in Normal mode to toggle encryption
--   Press <Leader>d in Normal mode to decrypt buffer
--
-- GPG Key Management:
--   - If no gpg_key_id is configured, the plugin will prompt you to select one
--   - Use :EncryptSelectKey to interactively choose from available GPG keys
--   - Selected key is automatically saved as default for future sessions
--   - Keys are saved to ~/.local/share/nvim/nvim-encrypt/default_key
--

local M = {}

-- Default configuration
M.config = {
  gpg_key_id  = nil,       -- GPG recipient key ID for encryption
  toggle_key  = '<Leader>e',-- Keymap to toggle encryption
  decrypt_cmd = '<Leader>d'-- Keymap to decrypt buffer
}

-- Internal state
M._plaintext = ''
M._enabled   = false

-- Utility: run shell command and capture output
local function run(cmd)
  local handle = io.popen(cmd)
  if not handle then
    return ''
  end
  local result = handle:read('*a') or ''
  handle:close()
  return result
end

-- Get list of available GPG keys
function M.get_gpg_keys()
  -- Use GNUPGHOME if set in environment
  local gpg_home = vim.env.GNUPGHOME or ""
  local env_prefix = ""
  if gpg_home ~= "" then
    -- Escape GNUPGHOME path to handle spaces and special characters
    local escaped_gpg_home = gpg_home:gsub("'", "'\\''")
    env_prefix = string.format("GNUPGHOME='%s' ", escaped_gpg_home)
  end
  local cmd = env_prefix .. "gpg --list-secret-keys --with-colons | grep '^sec' | cut -d: -f5"
  local output = run(cmd)
  local keys = {}
  
  for key_id in output:gmatch('[^\n]+') do
    if key_id and #key_id > 0 then
      -- Escape key_id to prevent shell injection (though GPG key IDs are typically safe)
      local escaped_key_id = key_id:gsub("'", "'\\''")
      local uid_cmd = string.format("%sgpg --list-secret-keys --with-colons '%s' | grep '^uid' | head -n1 | cut -d: -f10", env_prefix, escaped_key_id)
      local uid = run(uid_cmd):gsub('\n', '')
      table.insert(keys, {
        id = key_id,
        display = string.format("%s (%s)", key_id, uid ~= '' and uid or 'No description')
      })
    end
  end
  
  return keys
end

-- Encrypt using GPG
function M.encrypt(text)
  local key = M.config.gpg_key_id
  assert(key and #key > 0, "nvim-encrypt: gpg_key_id not set")
  local escaped = text:gsub("'", "'\\''")
  -- Escape the GPG key ID to prevent shell injection
  local escaped_key = key:gsub("'", "'\\''")
  -- Use GNUPGHOME if set in environment
  local gpg_home = vim.env.GNUPGHOME or ""
  local env_prefix = ""
  if gpg_home ~= "" then
    -- Escape GNUPGHOME path to handle spaces and special characters
    local escaped_gpg_home = gpg_home:gsub("'", "'\\''")
    env_prefix = string.format("GNUPGHOME='%s' ", escaped_gpg_home)
  end
  local cmd = string.format("%sprintf '%%s' '%s' | gpg --encrypt --armor --recipient '%s'", env_prefix, escaped, escaped_key)
  return run(cmd)
end

-- Decrypt using GPG
function M.decrypt(text)
  local temp_file = os.tmpname()
  local temp_output = os.tmpname()
  
  -- Write encrypted content to temporary file
  local file = io.open(temp_file, 'w')
  if not file then
    os.remove(temp_file)
    os.remove(temp_output)
    error("nvim-encrypt: Failed to create temporary file")
  end
  file:write(text)
  file:close()
  
  -- Decrypt from file to output file
  -- Use GNUPGHOME if set in environment
  local gpg_home = vim.env.GNUPGHOME or ""
  local env_prefix = ""
  if gpg_home ~= "" then
    -- Escape GNUPGHOME path to handle spaces and special characters
    local escaped_gpg_home = gpg_home:gsub("'", "'\\''")
    env_prefix = string.format("GNUPGHOME='%s' ", escaped_gpg_home)
  end
  
  -- Quote temporary file paths to handle spaces and special characters
  local escaped_temp_file = temp_file:gsub("'", "'\\''")
  local escaped_temp_output = temp_output:gsub("'", "'\\''")
  
  -- Check if passphrase is available for testing, otherwise use normal GPG (which uses gpg-agent)
  local passphrase = vim.env.GPG_PASSPHRASE or ""
  local cmd
  if passphrase ~= "" then
    -- Testing mode: use passphrase from environment
    local escaped_passphrase = passphrase:gsub("'", "'\\''")
    cmd = string.format("echo '%s' | %sgpg --batch --yes --trust-model always --pinentry-mode loopback --passphrase-fd 0 --decrypt --output '%s' '%s' 2>/dev/null", escaped_passphrase, env_prefix, escaped_temp_output, escaped_temp_file)
  else
    -- Normal mode: use gpg-agent for passphrase (allows GUI pinentry or cached passphrase)
    cmd = string.format("%sgpg --batch --yes --trust-model always --decrypt --output '%s' '%s' 2>/dev/null", env_prefix, escaped_temp_output, escaped_temp_file)
  end
  local success = os.execute(cmd)
  
  local result = ""
  if success == 0 then
    local output_file = io.open(temp_output, 'r')
    if output_file then
      result = output_file:read('*a') or ''
      output_file:close()
    end
  end
  
  -- Clean up temporary files
  os.remove(temp_file)
  os.remove(temp_output)
  
  return result
end

-- Update buffer with encrypted content
function M._update_encrypted()
  local enc   = M.encrypt(M._plaintext)
  local lines = vim.split(enc, '\n', { trimempty = false })
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

-- Input capture in Insert mode
function M.capture(char)
  M._plaintext = M._plaintext .. char
  M._update_encrypted()
end

-- Handle backspace
function M.backspace()
  if #M._plaintext > 0 then
    M._plaintext = M._plaintext:sub(1, -2)
    M._update_encrypted()
  end
end

-- Map Insert-mode keys for capture
function M._map_keys()
  for i = 32, 126 do
    local k = string.char(i)
    vim.keymap.set('i', k, function() M.capture(k) end, { noremap=true, silent=true })
  end
  vim.keymap.set('i', '<BS>', M.backspace, { noremap=true, silent=true })
end

-- Unmap Insert-mode keys
function M._unmap_keys()
  for i = 32, 126 do
    pcall(vim.keymap.del, 'i', string.char(i))
  end
  pcall(vim.keymap.del, 'i', '<BS>')
end

-- Toggle real-time encryption
function M.toggle()
  if not M._enabled then
    -- Check if GPG key is configured before enabling
    if not M.config.gpg_key_id then
      vim.notify('nvim-encrypt: No GPG key configured. Use :EncryptSelectKey to choose one.', vim.log.levels.ERROR)
      return
    end
    M._enabled = true
    M._plaintext = ''  -- Reset plaintext when enabling
    M._map_keys()
    print('nvim-encrypt: Encryption enabled')
  else
    M._enabled = false
    M._plaintext = ''  -- Clear plaintext when disabling
    M._unmap_keys()
    print('nvim-encrypt: Encryption disabled')
  end
end

-- Interactive GPG key selection with centered floating window
function M.select_gpg_key(callback)
  local keys = M.get_gpg_keys()
  
  if #keys == 0 then
    vim.notify('nvim-encrypt: No GPG secret keys found', vim.log.levels.ERROR)
    return
  end
  
  local items = {}
  for _, key in ipairs(keys) do
    table.insert(items, key.display)
  end
  
  -- Calculate window dimensions
  local max_width = 0
  for _, item in ipairs(items) do
    max_width = math.max(max_width, #item)
  end
  local title = ' Select GPG Key '
  max_width = math.max(max_width, #title) + 4  -- Add padding
  local width = math.min(max_width, math.floor(vim.o.columns * 0.8))
  local height = math.min(#items, math.floor(vim.o.lines * 0.6))
  
  -- Calculate centered position
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  -- Create buffer with items
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, items)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  
  -- Create centered floating window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = title,
    title_pos = 'center',
  })
  
  -- Set window options
  vim.api.nvim_win_set_option(win, 'cursorline', true)
  vim.api.nvim_win_set_option(win, 'winhl', 'Normal:Normal,FloatBorder:FloatBorder')
  
  -- Helper to close window
  local function close_win()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  
  -- Helper to select current item
  local function select_item()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local idx = cursor[1]
    close_win()
    if callback and keys[idx] then
      callback(keys[idx].id)
    end
  end
  
  -- Set up keymaps for the floating window
  local opts = { noremap = true, silent = true, buffer = buf }
  vim.keymap.set('n', '<CR>', select_item, opts)
  vim.keymap.set('n', '<Esc>', close_win, opts)
  vim.keymap.set('n', 'q', close_win, opts)
  vim.keymap.set('n', 'j', 'j', opts)
  vim.keymap.set('n', 'k', 'k', opts)
end

-- Set GPG key and save as default
function M.set_gpg_key()
  M.select_gpg_key(function(key_id)
    M.config.gpg_key_id = key_id
    M.save_default_key(key_id)
    vim.notify(string.format('nvim-encrypt: Set default GPG key to %s', key_id))
  end)
end

-- Save default key to Neovim data directory
function M.save_default_key(key_id)
  local config_dir = vim.fn.stdpath('data') .. '/nvim-encrypt'
  vim.fn.mkdir(config_dir, 'p')
  local config_file = config_dir .. '/default_key'
  local file = io.open(config_file, 'w')
  if file then
    file:write(key_id)
    file:close()
  end
end

-- Load default key from Neovim data directory
function M.load_default_key()
  local config_file = vim.fn.stdpath('data') .. '/nvim-encrypt/default_key'
  local file = io.open(config_file, 'r')
  if file then
    local key_id = file:read('*a')
    file:close()
    if key_id then
      return key_id:gsub('\n', '')
    end
  end
  return nil
end

-- Decrypt entire buffer into a new split
function M.decrypt_buffer()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local text  = table.concat(lines, '\n')
  local dec   = M.decrypt(text)
  local buf   = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(dec, '\n', { trimempty = false }))
  vim.cmd('vsplit')
  vim.api.nvim_set_current_buf(buf)
end

-- Setup and config
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  
  -- Load default key if not provided in config
  if not M.config.gpg_key_id then
    M.config.gpg_key_id = M.load_default_key()
  end
  
  -- If still no key, prompt user to select one
  if not M.config.gpg_key_id then
    vim.schedule(function()
      vim.notify('nvim-encrypt: No GPG key configured. Use :EncryptSelectKey to choose one.', vim.log.levels.WARN)
    end)
  end
  
  vim.api.nvim_create_user_command('EncryptToggle', M.toggle, {})
  vim.api.nvim_create_user_command('DecryptBuffer', M.decrypt_buffer, {})
  vim.api.nvim_create_user_command('EncryptSelectKey', M.set_gpg_key, {})
  vim.keymap.set('n', M.config.toggle_key, M.toggle, { noremap=true, silent=true })
  vim.keymap.set('n', M.config.decrypt_cmd, M.decrypt_buffer, { noremap=true, silent=true })
end

return M
