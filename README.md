# nvim-encrypt

A Neovim plugin for real-time GPG encryption and decryption of buffer content. Type in plain text, see it encrypted in real-time.

## Features

- **Real-time encryption**: Everything you type in Insert mode is encrypted with GPG as you type
- **Buffer decryption**: Decrypt existing encrypted buffers into readable splits
- **GPG integration**: Uses your existing GPG setup for encryption/decryption
- **Simple controls**: Toggle encryption on/off with a keymap
- **WARNING**: Plaintext is only stored in memory during active typing

## Requirements

- Neovim 0.7+
- GPG installed and configured with at least one key pair
- Your GPG key ID for encryption

## Installation

### With [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'jdearmas/nvim-encrypt',
  config = function()
    require('nvim-encrypt').setup({
      gpg_key_id = 'YOUR_GPG_KEY_ID',  -- Replace with your GPG key ID
      toggle_key = '<Leader>e',        -- Optional: key to toggle encrypt mode
      decrypt_cmd = '<Leader>d'        -- Optional: key to decrypt buffer
    })
  end
}
```

### Finding Your GPG Key ID

```bash
gpg --list-secret-keys --keyid-format=long
```

Look for the key ID after `sec   rsa4096/` (e.g., `3AA5C34371567BD2`).

## Usage

### Commands

- `:EncryptToggle` - Toggle real-time encryption mode on/off
- `:DecryptBuffer` - Decrypt the current buffer content into a new split

### Default Keymaps

- `<Leader>e` - Toggle encryption mode (Normal mode)
- `<Leader>d` - Decrypt current buffer (Normal mode)

### Workflow

1. Open a new buffer or file
2. Press `<Leader>e` to enable encryption mode
3. Enter Insert mode and start typing - your text will be encrypted in real-time
4. Press `<Esc>` and `<Leader>e` again to disable encryption mode
5. To read encrypted content, press `<Leader>d` to decrypt into a new split

### Example

```
# Before encryption (what you type):
Hello, this is my secret message!

# After encryption (what appears in buffer):
-----BEGIN PGP MESSAGE-----
hQIMA8OlCKkJ5JzPAQ/+MxN8R7...
...encrypted content...
-----END PGP MESSAGE-----
```

## Configuration

### Default Configuration

```lua
{
  gpg_key_id = nil,           -- GPG recipient key ID (required)
  toggle_key = '<Leader>e',   -- Keymap to toggle encryption
  decrypt_cmd = '<Leader>d'   -- Keymap to decrypt buffer
}
```

### Custom Configuration Example

```lua
require('nvim-encrypt').setup({
  gpg_key_id = '3AA5C34371567BD2',
  toggle_key = '<C-e>',       -- Use Ctrl+e instead
  decrypt_cmd = '<C-d>'       -- Use Ctrl+d instead
})
```

## Security Notes

- Plaintext content is stored in memory only while encryption mode is active
- All GPG operations use shell commands with properly escaped input
- Encrypted content is displayed in the buffer and can be saved to files
- Always verify your GPG key ID is correct before using

## How It Works

1. **Encryption Mode**: When enabled, the plugin maps all printable characters in Insert mode
2. **Real-time Processing**: Each keystroke is captured, added to internal plaintext, and the entire content is re-encrypted
3. **Buffer Updates**: The encrypted result replaces the buffer content immediately
4. **Decryption**: Uses GPG to decrypt buffer content and displays it in a new split window

## Testing

Run the test suite:

```bash
make setup-tests  # First time only
make test         # Run all tests
```

See `tests/README.md` for detailed testing information.
