# Makefile for nvim-encrypt plugin

.PHONY: test test-verbose test-lua test-run clean help setup-tests

# Default target
help:
	@echo "nvim-encrypt Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  test         - Run Lua tests (default)"
	@echo "  test-lua     - Run Lua tests using plenary.nvim"
	@echo "  test-verbose - Run tests with verbose output"
	@echo "  test-run     - Launch Neovim with plugin loaded (for manual testing)"
	@echo "  setup-tests  - Set up plenary.nvim test dependency"
	@echo "  clean        - Remove test artifacts"
	@echo "  help         - Show this help message"

# Set up plenary.nvim as a git submodule
setup-tests:
	@if [ ! -f "tests/plenary.nvim/lua/plenary/init.lua" ]; then \
		echo "Setting up plenary.nvim..."; \
		git submodule update --init --recursive 2>/dev/null || true; \
		if [ ! -f "tests/plenary.nvim/lua/plenary/init.lua" ]; then \
			rm -rf tests/plenary.nvim 2>/dev/null || true; \
			git clone --depth 1 https://github.com/nvim-lua/plenary.nvim tests/plenary.nvim; \
		fi; \
	else \
		echo "plenary.nvim already set up"; \
	fi

# Run the Lua test suite
test-lua: setup-tests
	@echo "Running nvim-encrypt Lua tests..."
	@nvim --headless -u test.lua 2>&1 || exit 1

# Run tests with verbose output
test-verbose: setup-tests
	@echo "Running nvim-encrypt Lua tests (verbose)..."
	@nvim --headless -u test.lua 2>&1

# Launch Neovim with plugin loaded for manual testing
test-run:
	@echo "Launching Neovim with nvim-encrypt plugin loaded..."
	@nvim -u test_init.lua

# Default: run Lua tests
test: test-lua

# Clean up any test artifacts
clean:
	@echo "Cleaning up test artifacts..."
	@find . -name "*.tmp" -delete 2>/dev/null || true
	@rm -rf /tmp/tmp.* 2>/dev/null || true
	@echo "Clean complete."