-- Test helper utilities for nvim-encrypt tests

local M = {}

-- Test configuration
M.TEST_DIR = nil
M.GPG_HOME = nil
M.GPG_KEY_ID = nil
M.TEST_TEXT = "Hello World! This is a test message for nvim-encrypt."

-- Setup test GPG environment
function M.setup_gpg()
  local tmpdir = vim.fn.tempname()
  vim.fn.mkdir(tmpdir, "p")
  M.TEST_DIR = tmpdir
  M.GPG_HOME = tmpdir .. "/.gnupg"
  vim.fn.mkdir(M.GPG_HOME, "p", 448) -- 448 = 0700 in decimal
  
  -- Set GPG home and passphrase for testing
  vim.env.GNUPGHOME = M.GPG_HOME
  vim.env.GPG_PASSPHRASE = "testpassword"
  
  -- Configure GPG for non-interactive use
  local gpg_agent_conf = M.GPG_HOME .. "/gpg-agent.conf"
  local gpg_conf = M.GPG_HOME .. "/gpg.conf"
  
  local function write_file(path, content)
    local file = io.open(path, "w")
    if file then
      file:write(content)
      file:close()
    end
  end
  
  write_file(gpg_agent_conf, [[
default-cache-ttl 600
max-cache-ttl 7200
pinentry-program /usr/bin/pinentry-tty
]])
  
  write_file(gpg_conf, [[
use-agent
pinentry-mode loopback
batch
]])
  
  -- Generate test GPG key
  local gpg_batch = tmpdir .. "/gpg_batch"
  write_file(gpg_batch, [[
Key-Type: RSA
Key-Length: 2048
Subkey-Type: RSA
Subkey-Length: 2048
Name-Real: Test User
Name-Email: test@example.com
Expire-Date: 1y
Passphrase: testpassword
%commit
]])
  
  -- Generate key (with GNUPGHOME set)
  local cmd = string.format("GNUPGHOME=%s gpg --batch --generate-key %s 2>/dev/null", M.GPG_HOME, gpg_batch)
  local success = os.execute(cmd)
  assert(success == 0, "Failed to generate GPG key")
  
  -- Get the key ID (with GNUPGHOME set)
  local key_cmd = string.format("GNUPGHOME=%s gpg --list-secret-keys --keyid-format=long 2>/dev/null | grep '^sec' | sed 's/.*\\/\\([A-F0-9]*\\).*/\\1/' | head -n1", M.GPG_HOME)
  local handle = io.popen(key_cmd)
  if handle then
    local key_id = handle:read("*a"):gsub("\n", "")
    handle:close()
    assert(key_id and #key_id > 0, "Failed to get GPG key ID")
    M.GPG_KEY_ID = key_id
  else
    error("Failed to get GPG key ID")
  end
end

-- Cleanup test environment
function M.cleanup()
  if M.TEST_DIR and vim.fn.isdirectory(M.TEST_DIR) == 1 then
    vim.fn.delete(M.TEST_DIR, "rf")
  end
  M.TEST_DIR = nil
  M.GPG_HOME = nil
  M.GPG_KEY_ID = nil
  vim.env.GNUPGHOME = nil
  vim.env.GPG_PASSPHRASE = nil
end

-- Run shell command and return output
function M.run_cmd(cmd)
  local handle = io.popen(cmd)
  if not handle then
    return nil
  end
  local result = handle:read("*a")
  handle:close()
  return result
end

-- Decrypt file using GPG directly
function M.decrypt_file(encrypted_file, output_file)
  local gpg_home = M.GPG_HOME or vim.env.GNUPGHOME or ""
  local env_prefix = ""
  if gpg_home ~= "" then
    env_prefix = string.format("GNUPGHOME=%s ", gpg_home)
  end
  local cmd = string.format(
    '%secho "testpassword" | gpg --batch --yes --trust-model always --pinentry-mode loopback --passphrase-fd 0 --decrypt %s > %s 2>/dev/null',
    env_prefix,
    encrypted_file,
    output_file
  )
  return os.execute(cmd) == 0
end

-- Read file content
function M.read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local content = file:read("*a")
  file:close()
  return content
end

-- Write file content
function M.write_file(path, content)
  local file = io.open(path, "w")
  if not file then
    return false
  end
  file:write(content)
  file:close()
  return true
end

return M

