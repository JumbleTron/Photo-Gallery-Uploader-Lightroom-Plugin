# Photo Gallery Uploader for Lightroom Classic

A professional Lightroom Classic plugin for **[creea.art](https://creea.art/)** — seamless integration between Lightroom and the creea.art photo acceptance system.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Lightroom Classic](https://img.shields.io/badge/Lightroom-Classic-blue)
![Language: Lua](https://img.shields.io/badge/Language-Lua-000080)
![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-brightgreen)

## What is This?

**Photo Gallery Uploader** is a Lightroom Classic plugin that integrates with [creea.art](https://creea.art/) to streamline the photo approval workflow:

1. **Upload photos** directly from Lightroom to creea.art galleries
2. **Sync client feedback** (pick/reject + comments) back into Lightroom
3. **Manage galleries** (create, rename, delete) from within Lightroom
4. **Re-publish modified photos** without losing client feedback
5. **Work in your favorite app** — never leave Lightroom

## Features

### 📤 Photo Publishing
- **Bulk upload** — drag & drop photos to Published Collections
- **Single-photo upload** — upload individual photos without creating a collection
- **Auto-gallery creation** — create new galleries directly in the plugin
- **Gallery selection** — link to existing galleries on creea.art
- **Smart re-publish** — edit photos, re-upload with PUT request (feedback preserved)

### 📥 Feedback Synchronization
- **Client pick/reject status** → Lightroom pick flags + keywords
- **Client comments** → Stored in photo Caption field
- **Batch sync** — synchronize single gallery or all galleries at once
- **Safe mode** — sync keywords only without touching your own pick flags
- **Keywords** — `client-picked`, `client-rejected` for easy filtering

### ⚙️ Gallery Management
- **Create galleries** with optional deadline and client message
- **Rename galleries** — synced to creea.art backend
- **Delete photos** — remove from both Lightroom and creea.art
- **List galleries** — dropdown selection from existing galleries

### 🌍 Localization
- **English** — full UI + dialogs
- **Polish** — pełna obsługa w języku polskim
- Auto-detect based on system locale

## Installation

### Prerequisites
- **Lightroom Classic** 10.0 or newer
- **API Key** from [creea.art](https://creea.art/) (contact admin)
- **API URL** (e.g., `https://creea.art/api`)

### Steps

1. **Download the plugin**
   ```bash
   git clone https://github.com/yourusername/Photo-Gallery-Uploader-LR.git
   cd Photo-Gallery-Uploader-LR
   ```

2. **Install in Lightroom**
   - Open Lightroom Classic
   - Go to **File → Plug-in Manager**
   - Click **Open Plug-in Folder**
   - Copy `PhotoGalleryUploader.lrplugin` folder into the opened directory
   - Restart Lightroom

3. **Configure API credentials**
   - Go to **Library → Publish Services → Set Up**
   - Select **Photo Gallery Uploader**
   - Enter:
     - **API URL**: `https://creea.art/api` (or your instance)
     - **API Key**: Your API key from creea.art admin
   - Click **Test Connection** to verify

## Quick Start

### Create a New Gallery

1. In **Publish Services** → right-click **Photo Gallery Uploader** → **Create Published Collection**
2. Choose:
   - **Create new gallery**: Enter name, optional deadline and message
   - **Use existing gallery**: Select from dropdown
3. Drag & drop photos from Library
4. Click **Publish** → photos upload to creea.art

### Sync Client Feedback

1. **Single gallery**: Right-click Published Collection → **Sync feedback from client**
2. **All galleries**: **Library → Plug-in Extras → Photo Gallery Uploader: Sync feedback (all galleries)**
3. Client feedback appears as:
   - Pick flag (✓) / Reject flag (✗)
   - Keywords: `client-picked`, `client-rejected`
   - Comments in **Caption** field

### Edit & Re-Publish

1. Edit photo in **Develop** module
2. Lightroom marks it as **"Modified Photos to Re-Publish"**
3. Click **Publish**
4. Plugin sends PUT request to replace photo
5. ✅ Client feedback is preserved!

### Solo Upload (No Collection)

1. Right-click any photo → **Photo Gallery Uploader: Upload photo to gallery**
2. Select gallery from dropdown
3. Optionally add to Published Collection
4. Upload immediately

## Configuration

### Auth & API Settings
- **File → Plug-in Manager → Photo Gallery Uploader → Plug-in Info**
- Configure:
  - **API URL** (base URL of creea.art)
  - **API Key** (from admin)
  - **Sync mode** (keywords only vs. flags + keywords)

### Feedback Sync Options

#### Default Mode (Flags + Keywords)
- Client `picked` → Your pick flag (✓) + `client-picked` keyword
- Client `rejected` → Your reject flag (✗) + `client-rejected` keyword
- Best when: client feedback is authoritative

#### Keywords-Only Mode
- Client feedback → Only keywords (`client-picked`, `client-rejected`)
- Your pick flags remain untouched
- Best when: you use flags for your own workflow

**Enable keywords-only:**
- **Publish Services → Set Up → Feedback Settings**
- Check: **"Keywords only, don't touch flags"**

## Project Structure

```
PhotoGalleryUploader.lrplugin/
├── Info.lua                       # Plugin manifest & registration
├── PublishServiceProvider.lua     # Publish Service callbacks
├── PublishServiceExportDialog.lua # Auth configuration UI
├── CollectionSettingsDialog.lua   # Gallery selection dialog
├── SinglePhotoExport.lua          # Single-photo upload
├── SyncFeedback.lua               # Feedback synchronization
├── ApiClient.lua                  # HTTP API wrapper
├── Metadata.lua                   # Custom metadata fields
├── README.md                      # Plugin documentation
└── strings/
    ├── en.txt                     # English localization
    └── pl.txt                     # Polish localization
```

## API Integration

### Expected Endpoints

The plugin expects creea.art API to provide:

```
GET  /api/galleries                              # List user's galleries
POST /api/galleries                              # Create gallery
PATCH /api/galleries/{id}                        # Rename gallery

POST /api/galleries/{id}/photos                  # Upload new photo
PUT /api/galleries/{id}/photos/{remoteId}       # Replace photo (preserve feedback!)
DELETE /api/galleries/{id}/photos/{remoteId}    # Delete photo

GET /api/galleries/{id}/feedback                 # Get client feedback
```

### Authentication

All requests include header:
```
X-API-Key: <your-api-key>
```

### Feedback Response Format

```json
GET /api/galleries/{id}/feedback
[
  {
    "remoteId": "photo_123",
    "status": "picked|rejected|pending",
    "comments": "Client feedback text (optional)"
  }
]
```

## Troubleshooting

### Plugin doesn't appear in Publish Services
- Make sure Lightroom was restarted after installation
- Check that `PhotoGalleryUploader.lrplugin` folder is in the correct location:
  - macOS: `~/Library/Application Support/Adobe/Lightroom Classic/Plug-ins/`
  - Windows: `%APPDATA%\Adobe\Lightroom Classic\Plug-ins\`

### "API credentials not configured"
- Go to **Publish Services → Set Up → Photo Gallery Uploader**
- Enter API URL and Key
- Click **Test Connection**

### Connection fails
- Verify API URL is correct (e.g., `https://creea.art/api`)
- Check API key has not expired
- Ensure creea.art server is reachable
- Check firewall/proxy settings

### Feedback doesn't sync
- Verify photos have been published (have `remoteId`)
- Check that client has submitted feedback on creea.art
- Ensure "Sync feedback" is run for the correct gallery
- Check Lightroom console for error messages

## Development

### Requirements
- Lightroom Classic 10.0+
- Lua 5.1 (built into Lightroom SDK)
- Text editor (VS Code recommended)

### Building/Packaging

To distribute the plugin:

```bash
# Create distribution package
zip -r PhotoGalleryUploader-v0.1.0.zip PhotoGalleryUploader.lrplugin/

# Users extract to Lightroom plugins folder
```

### Contributing

Found a bug or have a feature request?
- Open an issue on GitHub
- Check existing issues first
- Include Lightroom version and detailed steps to reproduce

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or feedback:
- 🐛 **Bug reports**: [GitHub Issues](https://github.com/yourusername/Photo-Gallery-Uploader-LR/issues)
- 💬 **Questions**: [GitHub Discussions](https://github.com/yourusername/Photo-Gallery-Uploader-LR/discussions)
- 📧 **Contact**: [creea.art](https://creea.art/) admin

## Changelog

### v0.1.0 (2026-05-13)
- ✅ Initial release
- ✅ Publish Service with bulk upload
- ✅ Single-photo upload
- ✅ Feedback synchronization with pick/reject + comments
- ✅ Gallery management (create/rename/delete)
- ✅ Re-publish support (PUT with feedback preservation)
- ✅ Keywords-only sync mode
- ✅ Localization (EN + PL)

## Roadmap

Planned features:
- [ ] Retry logic for failed uploads
- [ ] Batch deduplication by file hash
- [ ] Parallel uploads for large galleries
- [ ] Progress UI in Lightroom panels
- [ ] Lightroom CC support
- [ ] Custom metadata mapping

## Related Links

- 🎨 [creea.art](https://creea.art/) — Photo acceptance gallery system
- 📚 [Lightroom SDK Documentation](https://github.com/Adobe-CEP/CEP-Resources)
- 💡 [Lua 5.1 Reference](https://www.lua.org/manual/5.1/)

---

**Made with ❤️ for photographers who want to streamline their approval workflow.**
