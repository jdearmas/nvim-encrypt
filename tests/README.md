# nvim-encrypt Tests

This directory contains the Lua test suite for nvim-encrypt, using [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) as the testing framework.

## Setup

First, set up the test dependencies:

```bash
make setup-tests
```

This will clone plenary.nvim as a git submodule in `tests/plenary.nvim`.

## Running Tests

Run all tests:

```bash
make test
# or
make test-lua
```

Run tests with verbose output:

```bash
make test-verbose
```

## Test Structure

- `helper.lua` - Test utilities and GPG setup/cleanup
- `encryption_spec.lua` - Tests for encryption functionality
- `decryption_spec.lua` - Tests for decryption functionality
- `gpg_keys_spec.lua` - Tests for GPG key management
- `integration_spec.lua` - End-to-end integration tests

## Test Coverage

The test suite covers:

- ✅ GPG key generation and setup
- ✅ Plugin loading and configuration
- ✅ Real-time encryption during typing
- ✅ File saving with encrypted content
- ✅ GPG decryption verification
- ✅ Plugin decrypt buffer functionality
- ✅ GPG key selection and persistence
- ✅ End-to-end workflow validation

## Requirements

- Neovim (0.7+)
- GPG
- plenary.nvim (automatically set up via `make setup-tests`)

## Local Development/Testing (without plugin manager)

For development and testing without a plugin manager like Lazy.nvim:

### Method 1: Direct Runtime Path

```bash
# Clone the repository
git clone https://github.com/jdearmas/nvim-encrypt.nvim.git
cd nvim-encrypt.nvim

# Start Neovim with the plugin in runtime path
nvim --cmd "set runtimepath+=." -c "lua require('nvim-encrypt').setup({gpg_key_id='YOUR_GPG_KEY_ID'})"
```

### Method 2: Using init.lua

Create a minimal `init.lua` file for testing:

```lua
-- test_init.lua
vim.opt.runtimepath:prepend('/path/to/nvim-encrypt.nvim')

require('nvim-encrypt').setup({
    gpg_key_id = 'YOUR_GPG_KEY_ID',  -- Replace with your GPG key ID
    toggle_key = '<Leader>e',
    decrypt_cmd = '<Leader>d'
})

print("nvim-encrypt loaded for testing")
```

Then run:
```bash
nvim -u test_init.lua
```

### Method 3: Manual Loading

Start Neovim and manually load the plugin:

```bash
nvim
```

Then in Neovim command mode:
```vim
:set runtimepath+=/path/to/nvim-encrypt.nvim
:lua require('nvim-encrypt').setup({gpg_key_id='YOUR_GPG_KEY_ID'})
```

