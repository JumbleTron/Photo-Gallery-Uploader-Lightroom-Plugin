# GitHub Actions Workflow Details

## Overview

The **Lint & Format Check** workflow runs on every push to `main` and every pull request to ensure code quality standards.

## Workflows & Jobs

### 1. **Luacheck Linter** ✅
**Trigger:** Every push & PR
**Status:** ✅ Required to pass

Detects:
- Undefined variables
- Unused variables and functions
- Shadowed variables
- Code style issues
- Suspicious patterns

**Configuration:** `.luacheckrc`

```bash
# Local run
luacheck PhotoGalleryUploader.lrplugin/lua/ --globals LOC import export --no-undefined-globals
```

---

### 2. **StyLua Format Check** ✅
**Trigger:** Every push & PR
**Status:** ✅ Required to pass

Validates:
- Indentation (2 spaces)
- Line length (120 chars max)
- Quote consistency (single quotes preferred)
- Bracket spacing
- Function formatting

**Configuration:** `.stylua.toml`

```bash
# Local run - check formatting
stylua --check PhotoGalleryUploader.lrplugin/lua/

# Auto-fix formatting
stylua PhotoGalleryUploader.lrplugin/lua/
```

---

### 3. **Lua Syntax Check** ✅
**Trigger:** Every push & PR
**Status:** ✅ Required to pass

Validates:
- Lua compilation
- Syntax errors
- Unmatched brackets/parentheses

Uses Lua compiler (`luac`)

```bash
# Local run
luac -p PhotoGalleryUploader.lrplugin/*.lua PhotoGalleryUploader.lrplugin/lua/**/*.lua
```

---

### 4. **Version Consistency Check** ✅
**Trigger:** Every push & PR
**Status:** ✅ Required to pass

Validates:
- Version extracted from `PhotoGalleryUploader.lrplugin/Info.lua`
- Semantic versioning format (X.Y.Z)
- Version exists and is properly formatted

Example:
```lua
VERSION = {
  major = 0,
  minor = 1,
  revision = 0,
  build = 1,
}
```

✅ Valid: `0.1.0`
❌ Invalid: `1`, `v1.0.0`, `1.0`

---

### 5. **Plugin Size Check** 📦
**Trigger:** Every push & PR
**Status:** ⚠️ Warning only (not required)

Monitors:
- Plugin size (limit: 10MB)
- File count
- Warns if size exceeds limit

Output example:
```
📦 Plugin Size: 156K
📄 File count: 12
✅ Plugin size is within limits
```

---

### 6. **Code Complexity Check** 📊
**Trigger:** Every push & PR
**Status:** ⚠️ Informational (not required)

Analyzes:
- Total number of functions
- Lines of code (LOC)
- Average function size
- Functions > 50 lines (warning)

Output example:
```
📊 Total functions: 45
📝 Lines of code: 2340
📏 Average function size: 52 lines
```

**Best practices:**
- Keep average function size < 50 lines
- Complex functions should be broken down
- Use helper functions to improve readability

---

### 7. **Changelog Validation** 📝
**Trigger:** Pull requests only
**Status:** ⚠️ Warning only

Checks:
- `CHANGELOG.md` exists
- `CHANGELOG.md` was updated in the PR

Note: This is informational. Contributors should manually update changelog, but CI won't block if forgotten.

See [CHANGELOG.md](../CHANGELOG.md) for format guidelines.

---

### 8. **Build Plugin Package** 📦
**Trigger:** Successful merge to `main` only
**Status:** ℹ️ Creates artifacts

Runs after all quality checks pass:
1. Extracts version from `Info.lua`
2. Creates distribution package: `PhotoGalleryUploader-vX.Y.Z.zip`
3. Uploads as GitHub Actions artifact (30 days retention)
4. Available for download in Actions tab

Example output:
```
📦 Created: PhotoGalleryUploader-v0.1.0.zip (156 KB)
```

**Usage:**
1. Go to GitHub Actions tab
2. Find latest "Lint & Format Check" workflow
3. Download artifact from "Artifacts" section
4. Share with users or use for release

---

## Concurrency Control

The workflow uses concurrency to:
- Cancel in-progress runs when new push arrives
- Only one workflow runs per branch at a time
- Saves CI/CD resources

---

## Required vs Optional Checks

### ✅ Required (blocks merge)
- Luacheck Linter
- StyLua Format Check
- Lua Syntax Check
- Version Consistency Check

### ⚠️ Optional (information only)
- Plugin Size Check
- Code Complexity Check
- Changelog Validation

---

## Local Development

Run all checks locally before pushing:

```bash
./scripts/check.sh
```

This runs the same checks as GitHub Actions.

---

## Debugging Failed Checks

### Luacheck failed
```bash
luacheck PhotoGalleryUploader.lrplugin/lua/ --globals LOC import export
# Fix issues shown in output
```

### StyLua failed
```bash
# Auto-fix formatting
stylua PhotoGalleryUploader.lrplugin/lua/

# Or check specific directory
stylua --check PhotoGalleryUploader.lrplugin/lua/ui/
```

### Syntax error
```bash
luac -p PhotoGalleryUploader.lrplugin/lua/core/Config.lua
# Shows line number of error
```

### Version mismatch
Update `PhotoGalleryUploader.lrplugin/Info.lua`:
```lua
VERSION = {
  major = 0,
  minor = 1,
  revision = 0,
  build = 1,
}
```

---

## Troubleshooting

### "Workflow syntax error"
- Check `.github/workflows/lint-format.yml` for YAML syntax
- Ensure consistent indentation (2 spaces)
- Validate at: https://github.com/rhysd/actionlint

### "Job failed: setup failed"
- Check if Ubuntu packages are available
- Try re-running workflow

### "Artifact upload failed"
- Check artifact file path is correct
- Ensure file exists before upload step

---

## Performance

Typical workflow runtime:
- **Linting:** 30-60 seconds
- **Formatting:** 10-20 seconds
- **Syntax check:** 5-10 seconds
- **Version check:** 2-5 seconds
- **Complexity:** 10-20 seconds
- **Build package:** 10-15 seconds

**Total:** ~2-3 minutes per workflow run

---

## Future Enhancements

Potential additions:
- 🔒 Security scanning (semgrep, etc.)
- 📖 Documentation generation (LuaDoc)
- 🧪 Test execution (when tests are added)
- 📊 Code coverage reports
- 🎯 Performance benchmarking
- 📲 Release automation
