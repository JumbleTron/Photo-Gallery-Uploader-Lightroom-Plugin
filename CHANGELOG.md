# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub Actions CI/CD pipeline for code quality checks
- Luacheck linter integration
- StyLua code formatter integration
- Lua syntax validation in CI
- Version consistency checks
- Plugin size monitoring
- Code complexity analysis
- Local quality check script (`scripts/check.sh`)
- Organized code structure with `lua/` subdirectories:
  - `lua/core/` - API and configuration modules
  - `lua/ui/` - User interface dialogs
  - `lua/sync/` - Feedback synchronization
  - `lua/export/` - Export operations
- Config.lua module for centralized credential management

### Changed
- Refactored code to eliminate credential management duplication
- Improved code organization with helper functions
- Separated concerns in ApiClient.lua with `handleResponse()` helper
- Enhanced SyncFeedback.lua with SRP-compliant design

### Fixed
- Global scope variable bug in ApiClient:uploadPhoto() and updatePhoto()
- Missing prefs initialization in SyncFeedback:syncSingleGallery()
- Incorrect progress message in SinglePhotoExport

## [0.1.0] - 2025-05-13

### Added
- Initial plugin release
- Photo upload to creea.art galleries
- Single photo and bulk upload support
- Client feedback synchronization (pick/reject status)
- Gallery management (create, rename, delete)
- Lightroom Classic 10.0+ support
- Polish localization
- English localization

### Features
- Bulk upload via Published Collections
- Single-photo upload without collections
- Auto-gallery creation
- Gallery selection and management
- Smart re-publish with feedback preservation
- Client pick/reject status to Lightroom flags
- Client comments to photo captions
- Batch sync for single or all galleries
- Safe mode for keywords-only sync
- Custom keywords: `client-picked`, `client-rejected`

---

## How to Update CHANGELOG

When making changes, update this file in the `[Unreleased]` section:

- **Added** - for new features
- **Changed** - for changes in existing functionality
- **Fixed** - for any bug fixes
- **Deprecated** - for soon-to-be removed features
- **Removed** - for now removed features
- **Security** - in case of security vulnerabilities

Example:
```markdown
### Added
- New feature description

### Fixed
- Bug fix description
```

When releasing a new version:
1. Replace `[Unreleased]` with `[X.Y.Z] - YYYY-MM-DD`
2. Update version in `PhotoGalleryUploader.lrplugin/Info.lua`
3. Create git tag: `git tag vX.Y.Z`
