local LrBinding = import "LrBinding"
local LrDialogs = import "LrDialogs"
local LrExportSession = import "LrExportSession"
local LrApplication = import "LrApplication"
local LrProgressScope = import "LrProgressScope"
local LrFunctionContext = import "LrFunctionContext"
local LrPrefs = import "LrPrefs"
local ApiClient = require "ApiClient"
local CollectionSettingsDialog = require "CollectionSettingsDialog"
local SyncFeedback = require "SyncFeedback"

local publishServiceProvider = {}

function publishServiceProvider.supportsImageRating()
  return false
end

function publishServiceProvider.canExportPhoto(exportContext, photo)
  return true
end

function publishServiceProvider.getCollectionBehaviorInfo()
  return {
    canDelete = true,
    supportsRemovedPhotosTracking = true,
    supportsContentType = true,
  }
end

function publishServiceProvider.startDialog(propertyTable)
  propertyTable.api_url = propertyTable.api_url or ""
  propertyTable.api_key = propertyTable.api_key or ""
  propertyTable.selected_gallery = propertyTable.selected_gallery or ""
end

function publishServiceProvider.sectionsForBottomOfDialog(propertyTable)
  return {}
end

function publishServiceProvider.viewForCollectionSettings(f, editContext)
  return CollectionSettingsDialog.buildView(f, nil, editContext)
end

function publishServiceProvider.processRenderedPhotos(functionContext, exportContext)
  local progressScope = exportContext:waitForProgress()
  local publishedPhotos = exportContext.publishedPhotos
  local publishedCollection = exportContext.publishedCollection
  local collectionSettings = publishedCollection:getCollectionSettings()

  local prefs = LrPrefs.prefsForPlugin()
  local apiUrl = prefs.api_url or ""
  local apiKey = prefs.api_key or ""

  if apiUrl == "" or apiKey == "" then
    LrDialogs.message("Error", "API credentials not configured", "warning")
    return
  end

  local client = ApiClient.new(apiUrl, apiKey)
  local galleryId = collectionSettings.gallery_id

  if collectionSettings.mode == "new" and (not galleryId or galleryId == "") then
    local success, result = client:createGallery(
      collectionSettings.new_gallery_name or "Unnamed Gallery",
      collectionSettings.new_gallery_deadline or "",
      collectionSettings.new_gallery_message or ""
    )

    if success then
      galleryId = result.id
      collectionSettings.gallery_id = galleryId
    else
      LrDialogs.message("Error", "Failed to create gallery: " .. result, "warning")
      return
    end
  end

  if not galleryId or galleryId == "" then
    LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Error=Error", LOC "$$$/PhotoGalleryUploader/Error/NoGalleryId=ID galerii nie jest ustawione", "warning")
    return
  end

  progressScope:setPortionComplete(0, #publishedPhotos)

  for i, photo in ipairs(publishedPhotos) do
    local rendition = photo:getRendition()

    if rendition.wasProcessed then
      local path = rendition.destinationPath
      local photoObj = photo:getPhoto()
      local photoMetadata = photoObj:getMetadata()
      local originalName = photoMetadata.fileName or ("photo_" .. i)
      local remoteId = photo:getRemoteId()

      local success, result

      if remoteId and remoteId ~= "" then
        success, result = client:updatePhoto(galleryId, remoteId, path)
      else
        success, result = client:uploadPhoto(
          galleryId,
          path,
          originalName,
          photoMetadata.captureTime or os.date()
        )
      end

      if success then
        if not remoteId or remoteId == "" then
          remoteId = result.remoteId or ("remote_" .. i .. "_" .. os.time())
          photo:recordPublishedPhotoId(remoteId)
        end
        if result.url then
          photo:recordPublishedPhotoUrl(result.url)
        end
      else
        LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Error=Error", LOC("$$$/PhotoGalleryUploader/Error/UploadFailed=Upload nie powiódł się: ^1", result), "warning")
      end

      progressScope:setPortionComplete(i, #publishedPhotos)
    end
  end
end

function publishServiceProvider.deletePhotosFromPublishedCollection(functionContext, publishedCollection, photoIds)
  local collectionSettings = publishedCollection:getCollectionSettings()
  local galleryId = collectionSettings.gallery_id

  if not galleryId or galleryId == "" then
    return
  end

  local prefs = LrPrefs.prefsForPlugin()
  local apiUrl = prefs.api_url or ""
  local apiKey = prefs.api_key or ""

  if apiUrl == "" or apiKey == "" then
    return
  end

  local client = ApiClient.new(apiUrl, apiKey)

  for _, publishedPhoto in ipairs(publishedCollection:getPublishedPhotos()) do
    local remoteId = publishedPhoto:getRemoteId()
    if remoteId then
      client:deletePhoto(galleryId, remoteId)
    end
  end
end

function publishServiceProvider.syncFeedbackForCollection(context, publishedCollection)
  SyncFeedback.syncSingleGallery(publishedCollection)
end

function publishServiceProvider.syncAllFeedback(context)
  SyncFeedback.syncAllGalleries()
end

function publishServiceProvider.renamePublishedCollection(functionContext, publishedCollection, newName)
  local collectionSettings = publishedCollection:getCollectionSettings()
  local galleryId = collectionSettings.gallery_id

  if not galleryId or galleryId == "" then
    LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Error=Error", LOC "$$$/PhotoGalleryUploader/Error/NoGalleryId=ID galerii nie jest ustawione", "warning")
    return
  end

  local prefs = LrPrefs.prefsForPlugin()
  local apiUrl = prefs.api_url or ""
  local apiKey = prefs.api_key or ""

  if apiUrl == "" or apiKey == "" then
    LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Error=Error", LOC "$$$/PhotoGalleryUploader/Error/CredentialsNotConfigured=Dane do API nie są skonfigurowane", "warning")
    return
  end

  functionContext:callAsyncFunction(function(context)
    local client = ApiClient.new(apiUrl, apiKey)
    local success, result = client:updateGallery(galleryId, newName)

    if success then
      LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Success=Success", LOC("$$$/PhotoGalleryUploader/Success/GalleryRenamed=Galeria zmieniona na: ^1", newName), "info")
    else
      LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Error=Error", LOC("$$$/PhotoGalleryUploader/Error/UploadFailed=Upload nie powiódł się: ^1", result), "warning")
    end
  end)
end

return publishServiceProvider
