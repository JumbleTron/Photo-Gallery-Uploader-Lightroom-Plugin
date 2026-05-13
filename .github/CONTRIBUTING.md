# Contributing to Photo Gallery Uploader

## Code Quality Checks

This project uses automated tools to maintain code quality:

### GitHub Actions Workflows

- **Lint & Format Check** (`.github/workflows/lint-format.yml`)
  - Runs on every push to `main` and PR
  - Checks for code issues and formatting
  - Must pass before merging to `main`

## Local Setup

### Prerequisites

```bash
# Install Lua tools (macOS)
brew install lua luarocks

# Install Lua tools (Ubuntu/Debian)
sudo apt-get install lua5.4 luarocks
```

### Install Linting & Formatting Tools

```bash
# Install luacheck (linter)
luarocks install luacheck

# Install stylua (formatter) - requires Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install stylua
```

## Running Checks Locally

### 1. Syntax Check
```bash
# Check Lua syntax
for file in PhotoGalleryUploader.lrplugin/*.lua PhotoGalleryUploader.lrplugin/lua/**/*.lua; do
  echo "Checking: $file"
  luac -p "$file"
done
```

### 2. Linting
```bash
# Run luacheck
luacheck PhotoGalleryUploader.lrplugin/lua/ \
  --globals LOC import export \
  --no-undefined-globals
```

Configuration: `.luacheckrc`

### 3. Code Formatting Check
```bash
# Check formatting without modifying files
stylua --check PhotoGalleryUploader.lrplugin/lua/
```

### 4. Auto-Format Code
```bash
# Automatically format all Lua files
stylua PhotoGalleryUploader.lrplugin/lua/
```

Configuration: `.stylua.toml`

## Workflow Details

### Luacheck (Linter)
Checks for:
- Undefined variables
- Unused variables
- Syntax errors
- Code quality issues

Configuration: `.luacheckrc`

**Globals defined for Lightroom API:**
- `LOC` - Localization function
- `import` - Module import
- `LrApplication`, `LrBinding`, `LrDialogs`, `LrErrors`, `LrExportSession`, `LrFunctionContext`, `LrHttp`, `LrPathUtils`, `LrPrefs`, `LrProgressScope`

### StyLua (Formatter)
Enforces consistent code formatting:
- 2-space indentation
- 120 character line width
- Single quotes preferred
- Consistent spacing and brackets

Configuration: `.stylua.toml`

### Lua Syntax Check
Validates Lua syntax using `luac` compiler.

## Before Committing

Run all checks:

```bash
#!/bin/bash
set -e

echo "=== Checking Lua Syntax ==="
for file in PhotoGalleryUploader.lrplugin/*.lua PhotoGalleryUploader.lrplugin/lua/**/*.lua; do
  echo "Checking: $file"
  luac -p "$file"
done

echo -e "\n=== Running Luacheck ==="
luacheck PhotoGalleryUploader.lrplugin/lua/ \
  --globals LOC import export \
  --no-undefined-globals

echo -e "\n=== Checking Code Format ==="
stylua --check PhotoGalleryUploader.lrplugin/lua/

echo -e "\n✅ All checks passed!"
```

Save as `check.sh` and run: `chmod +x check.sh && ./check.sh`

## Fixing Formatting Issues

If StyLua reports formatting issues, auto-fix them:

```bash
stylua PhotoGalleryUploader.lrplugin/lua/
```

Then commit the formatted code.

## Code Style Guidelines

### Naming
- `snake_case` for variables, functions, and modules
- `camelCase` for Lightroom API calls (as defined by SDK)

### Structure
- One file per module
- Helper functions should be `local`
- Public functions should be clear and documented

### Comments
- Only add comments for non-obvious WHY, not WHAT
- Keep comments close to code they describe

### Line Length
- Prefer keeping lines ≤ 120 characters
- Break long lines logically

## Questions?

See [Contributing Guidelines](../../CONTRIBUTING.md) for more details.
