# Photo Gallery Uploader — Lightroom Classic Plugin

A Lightroom Classic plugin for uploading photos to a Symfony-based photo gallery system with client feedback synchronization.

## Installation

1. In **Lightroom Classic**, open **File → Plug-in Manager**
2. Click **Open Plug-in Folder**
3. Copy the `PhotoGalleryUploader.lrplugin` folder into the opened directory
4. Restart Lightroom (may be required)
5. Plugin should now appear in **Library → Publish Services → Photo Gallery Uploader**

## Project Structure

```
PhotoGalleryUploader.lrplugin/
├── Info.lua                       # Plugin manifest & metadata
├── PublishServiceProvider.lua     # Publish Service callbacks
├── PublishServiceExportDialog.lua # API auth configuration UI
├── ApiClient.lua                  # HTTP API wrapper
├── Metadata.lua                   # Custom metadata fields & keywords
├── strings/
│   └── en.txt                     # UI strings (English)
└── README.md                      # This file
```

## Development Status

- [x] Plugin scaffold (Info.lua, registration)
- [x] ApiClient.lua (HTTP + JSON handling)
- [x] Auth dialog (API URL + key configuration)
- [x] Gallery selection in collection settings (create new / use existing)
- [x] Photo upload workflow (POST with auto-gallery creation)
- [x] Rename hook (PATCH gallery)
- [x] Feedback sync (pick/reject) — menu items + metadata updates
- [x] Deletion hook (DELETE /api/galleries/{id}/photos/{remoteId})
- [x] Re-publish (PUT) support — automatic detection + update without resetting feedback
- [x] Single-photo upload — standalone menu item + gallery selection
- [x] Localization (EN + PL)

## Testing Workflow

1. **Configure credentials:**
   - In Lightroom: **Publish Services → Photo Gallery Uploader → Set Up**
   - Enter API URL & Key, click **Test Connection**

2. **Create Published Collection:**
   - Right-click **Photo Gallery Uploader** → **Create Published Collection**
   - Choose mode: "Create new gallery" or "Use existing gallery"
   - If new: enter gallery name, optional deadline/message
   - If existing: select from dropdown (click "Refresh Galleries" first)

3. **Publish photos:**
   - Drag & drop photos to Published Collection
   - Click **Publish** → plugin uploads to API (POST /api/galleries/{id}/photos)
   - Photos move to "Published Photos" with assigned `remoteId`

4. **Re-publish (modify & republish):**
   - Edit photo in Develop module (adjust exposure, crop, etc.)
   - Lightroom marks it as "Modified Photos to Re-Publish"
   - Click **Publish** → plugin detects `remoteId` exists
   - Plugin sends PUT request (replaces binary on server)
   - **Important:** feedback status & flags are NOT reset (backend preserves them)
   - Photo stays in "Published Photos"

5. **Rename gallery:**
   - Right-click Published Collection → Rename
   - Plugin sends PATCH request to update gallery name on server

6. **Remove photos:**
   - Remove photos from Published Collection
   - Plugin sends DELETE request for each photo

7. **Upload single photo (standalone):**
   - Right-click any photo → **Photo Gallery Uploader: Upload photo to gallery**
   - Dialog opens: select gallery from dropdown
   - Option: "Add to Published Collection" (to link with Publish Service)
   - Upload immediately (doesn't require Published Collection)
   - Useful for uploading individual photos without managing a collection

8. **Sync feedback from client:**
   - **Single gallery:** right-click collection → **Sync feedback from client**
   - **All galleries:** **Library → Plug-in Extras → Photo Gallery Uploader: Sync feedback (all galleries)**
   - Plugin pulls feedback status + comments from API and updates photos:
     - `picked` → sets pick flag + `client-picked` keyword
     - `rejected` → sets reject flag + `client-rejected` keyword
     - `comments` → stored in **Caption** field (visible in Library/Develop)
     - `pending` → no change

## Features Implemented

✅ Complete Publish Service workflow:
- Create/select galleries
- Upload new photos (POST)
- Re-publish modified photos (PUT with feedback preservation)
- Rename galleries (PATCH)
- Delete photos (DELETE)
- Sync client feedback (pick/reject with keywords & flags)

✅ Single-photo upload (standalone):
- Right-click photo → **Photo Gallery Uploader: Upload photo to gallery**
- Dialog: select gallery + option to add to Published Collection
- Upload independent of Published Collections
- Works in Library or Develop module

## Client Feedback Synchronization

When syncing feedback from the client, the plugin captures:

1. **Status** (pick/reject):
   - `picked` → Pick flag (✓) + `client-picked` keyword
   - `rejected` → Reject flag (✗) + `client-rejected` keyword

2. **Comments** (if provided by client):
   - Stored in photo's **Caption** field
   - Visible in Library Grid, Develop module, and Print
   - Example: "Zbyt jasne, chciałbym ciemniejsze"
   - Editable in Lightroom if needed

### Flag Conflict Prevention

If you already use pick/reject flags for your own purposes (e.g., selecting photos to edit), sync can overwrite them.

**Solution:** In **Publish Services → Photo Gallery Uploader → Set Up**:
- Check **"Keywords only, don't touch flags"** option
- Sync will add only keywords (`client-picked`, `client-rejected`)
- Your pick/reject flags remain untouched
- You can use flags for your workflow, keywords for client feedback

**Two modes:**
- **Default (flags + keywords):** Full feedback capture, overwrites existing flags
- **Keywords-only mode:** Safe for existing workflows, client feedback as keywords only

**Workflow:**
1. Client submits feedback with pick/reject + optional comment
2. Gallery admin syncs feedback: right-click collection → "Sync feedback"
3. Plugin fetches from API and updates each photo:
   - Pick status → flag (if enabled) + keyword + caption
   - Comments → Caption field
4. Photographer sees client feedback directly in LR without leaving the app

## Localization

The plugin supports both English and Polish:
- **English (en.txt)** — all UI strings, dialogs, messages
- **Polish (pl.txt)** — pełna obsługa w języku polskim

Lightroom automatically selects the language based on system locale.

## Future Enhancements

1. **Error resilience** — retry logic, timeout handling, graceful failures
2. **Idempotency** — dedup by file hash to prevent duplicates on interrupted uploads
3. **Batch operations** — optimize multi-photo uploads with parallel requests
4. **Progress UI** — visual feedback in Lightroom progress panel
