# GitHub Configuration & Workflows

This directory contains GitHub-specific configuration and workflows for the Photo Gallery Uploader project.

## 📁 Structure

```
.github/
├── workflows/
│   └── lint-format.yml          # Main CI/CD workflow
├── README.md                     # This file
├── CONTRIBUTING.md               # Contribution guidelines
└── WORKFLOW_DETAILS.md          # Detailed workflow documentation
```

## 🚀 Quick Start

### For Contributors
- Read [CONTRIBUTING.md](CONTRIBUTING.md) for setup and guidelines
- Run `./scripts/check.sh` before committing
- Update [CHANGELOG.md](../CHANGELOG.md) with your changes

### For Maintainers
- Monitor workflow runs in [Actions tab](https://github.com/grzegorz-kielar/lr-plugin/actions)
- Download plugin packages from artifacts
- Review code quality metrics

## 📋 Workflows

### Lint & Format Check
**File:** `workflows/lint-format.yml`
**Trigger:** Push to `main` & Pull Requests

Runs 8 quality checks:
1. ✅ Luacheck (linter)
2. ✅ StyLua (formatter)
3. ✅ Lua Syntax validation
4. ✅ Version consistency
5. 📊 Plugin size monitoring
6. 📊 Code complexity analysis
7. 📝 Changelog validation
8. 📦 Plugin packaging (on `main` only)

See [WORKFLOW_DETAILS.md](WORKFLOW_DETAILS.md) for detailed explanations.

## 🔧 Configuration Files

| File | Purpose |
|------|---------|
| `.luacheckrc` | Luacheck linter configuration |
| `.stylua.toml` | StyLua formatter configuration |
| `.github/workflows/lint-format.yml` | Main CI/CD workflow |
| `scripts/check.sh` | Local quality check script |

## ✨ Features

### Automated Quality Checks
- Code style consistency
- Lint analysis
- Syntax validation
- Version tracking

### Continuous Integration
- Runs on every push and PR
- Blocks merge if checks fail
- Concurrent workflow cancellation
- Artifact retention management

### Plugin Distribution
- Automatic packaging on `main` branch
- Version-based naming (e.g., `v0.1.0.zip`)
- 30-day artifact retention
- Download via Actions tab

## 📊 Check Requirements

### Required (blocks merge)
- ✅ Luacheck Linter - Code quality
- ✅ StyLua Format - Code formatting
- ✅ Lua Syntax - Compilation validation
- ✅ Version Check - Semantic versioning

### Optional (informational)
- 📊 Plugin Size - Monitor package size
- 📊 Complexity - Code metrics
- 📝 Changelog - Update tracking

## 🔄 Workflow Status

Check the latest workflow status:
- [GitHub Actions Dashboard](https://github.com/grzegorz-kielar/lr-plugin/actions)
- Branch-specific status in PR checks

## 📚 Documentation

- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Setup & contribution guidelines
- **[WORKFLOW_DETAILS.md](WORKFLOW_DETAILS.md)** - Detailed workflow documentation
- **[../CHANGELOG.md](../CHANGELOG.md)** - Version history
- **[../README.md](../README.md)** - Project overview

## 🛠️ Local Development

### Run Quality Checks
```bash
./scripts/check.sh
```

### Individual Checks
```bash
# Linting
luacheck PhotoGalleryUploader.lrplugin/lua/ --globals LOC import export

# Format check
stylua --check PhotoGalleryUploader.lrplugin/lua/

# Auto-format
stylua PhotoGalleryUploader.lrplugin/lua/

# Syntax check
luac -p PhotoGalleryUploader.lrplugin/*.lua PhotoGalleryUploader.lrplugin/lua/**/*.lua
```

## 🚨 Troubleshooting

### Workflow failed?
1. Check the workflow run details in [Actions tab](https://github.com/grzegorz-kielar/lr-plugin/actions)
2. Look at the failed step's error message
3. Run `./scripts/check.sh` locally to reproduce
4. See [WORKFLOW_DETAILS.md](WORKFLOW_DETAILS.md#troubleshooting) for solutions

### Need to update workflow?
Edit `.github/workflows/lint-format.yml` and commit to `main`. GitHub automatically validates YAML.

## 📦 Release Process

1. Update version in `PhotoGalleryUploader.lrplugin/Info.lua`
2. Update [CHANGELOG.md](../CHANGELOG.md)
3. Merge to `main` branch
4. Workflow automatically packages plugin as `PhotoGalleryUploader-vX.Y.Z.zip`
5. Download from [Actions artifacts](https://github.com/grzegorz-kielar/lr-plugin/actions)
6. Create GitHub release with artifact

## 📞 Questions?

- Check [WORKFLOW_DETAILS.md](WORKFLOW_DETAILS.md) for detailed explanations
- Review [CONTRIBUTING.md](CONTRIBUTING.md) for setup help
- Open an issue on GitHub for questions/bugs
