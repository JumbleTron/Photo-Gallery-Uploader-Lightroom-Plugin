local LrBinding = import "LrBinding"
local LrDialogs = import "LrDialogs"
local LrExportSession = import "LrExportSession"
local LrApplication = import "LrApplication"
local LrProgressScope = import "LrProgressScope"
local LrPrefs = import "LrPrefs"
local LrPathUtils = import "LrPathUtils"
local ApiClient = require "ApiClient"
local CollectionSettingsDialog = require "CollectionSettingsDialog"

local singlePhotoExport = {}

function singlePhotoExport.exportMenuItemHandler(context)
  local catalog = LrApplication.activeCatalog()
  local selectedPhotos = catalog:getTargetPhotos()

  if not selectedPhotos or #selectedPhotos == 0 then
    LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Error=Error", LOC "$$$/PhotoGalleryUploader/Error/NoPhotoSelected=Proszę wybrać zdjęcie", "warning")
    return
  end

  if #selectedPhotos > 1 then
    LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Error=Error", LOC "$$$/PhotoGalleryUploader/Error/MultiplePhotos=Wybierz tylko jedno zdjęcie na raz", "warning")
    return
  end

  local photo = selectedPhotos[1]

  local prefs = LrPrefs.prefsForPlugin()
  local apiUrl = prefs.api_url or ""
  local apiKey = prefs.api_key or ""

  if apiUrl == "" or apiKey == "" then
    LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Error=Error", LOC "$$$/PhotoGalleryUploader/Error/CredentialsNotConfigured=Dane do API nie są skonfigurowane", "warning")
    return
  end

  local client = ApiClient.new(apiUrl, apiKey)
  local success, galleries = client:getGalleries()

  if not success then
    LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Error=Error", LOC("$$$/PhotoGalleryUploader/Error/FailedLoadGalleries=Nie udało się wczytać galerii: ^1", galleries), "warning")
    return
  end

  local galleryItems = {}
  for _, gallery in ipairs(galleries) do
    table.insert(galleryItems, {
      title = gallery.name,
      value = gallery.id,
    })
  end

  if #galleryItems == 0 then
    LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Error=Error", LOC "$$$/PhotoGalleryUploader/Error/NoGalleries=Brak dostępnych galerii. Stwórz jedną najpierw.", "warning")
    return
  end

  local exportOptions = {
    selectedGalleryId = galleryItems[1].value,
    addToCollection = false,
  }

  local f = LrDialogs.presentModalDialog {
    title = LOC "$$$/PhotoGalleryUploader/SinglePhoto/Title=Wrzuć Zdjęcie do Galerii",
    contents = function(f)
      return f:column {
        f:row {
          f:static_text {
            title = LOC "$$$/PhotoGalleryUploader/SinglePhoto/Gallery=Galeria:",
            width = 100,
          },
          f:popup_menu {
            value = LrBinding.makeKeyBinding(exportOptions, "selectedGalleryId"),
            items = galleryItems,
            width_in_chars = 40,
          },
        },

        f:row {
          f:checkbox {
            title = LOC "$$$/PhotoGalleryUploader/SinglePhoto/AddToCollection=Dodaj do Published Collection",
            value = LrBinding.makeKeyBinding(exportOptions, "addToCollection"),
          },
        },

        f:separator { fill_horizontal = true },

        f:row {
          f:push_button {
            title = LOC "$$$/PhotoGalleryUploader/SinglePhoto/Upload=Wrzuć",
            action = function(button)
              button.dialog:endDialog("ok")
            end,
          },
          f:push_button {
            title = LOC "$$$/PhotoGalleryUploader/SinglePhoto/Cancel=Anuluj",
            action = function(button)
              button.dialog:endDialog("cancel")
            end,
          },
        },
      }
    end,
  }

  if f == "ok" then
    singlePhotoExport.performUpload(context, photo, exportOptions.selectedGalleryId, exportOptions.addToCollection)
  end
end

function singlePhotoExport.performUpload(context, photo, galleryId, addToCollection)
  local catalog = LrApplication.activeCatalog()
  local photoMetadata = photo:getMetadata()
  local originalName = photoMetadata.fileName or "photo"

  local prefs = LrPrefs.prefsForPlugin()
  local apiUrl = prefs.api_url or ""
  local apiKey = prefs.api_key or ""

  local client = ApiClient.new(apiUrl, apiKey)

  local progressScope = LrProgressScope {
    title = LOC "$$$/PhotoGalleryUploader/Progress/SyncingFeedback=Synchronizowanie feedback...",
  }

  progressScope:setPortionComplete(0, 1)

  local tempDir = LrPathUtils.getStandardFilePath("temp")
  local exportFilePath = LrPathUtils.child(tempDir, "lr_export_temp.jpg")

  local exportSession = LrExportSession {
    photosToExport = { photo },
    exportPath = tempDir,
    exportFilename = "lr_export_temp",
    exportFormat = "JPEG",
  }

  exportSession:doExportOnNewTask(function(exportContext)
    local renditions = exportContext.renditions

    for _, rendition in ipairs(renditions) do
      if rendition.wasProcessed then
        local filePath = rendition.destinationPath

        local success, result = client:uploadPhoto(
          galleryId,
          filePath,
          originalName,
          photoMetadata.captureTime or os.date()
        )

        if success then
          local remoteId = result.remoteId or ("remote_" .. os.time())

          if addToCollection then
            local allPublishedCollections = catalog:getPublishedCollections()
            local matchingCollection = nil

            for _, col in ipairs(allPublishedCollections) do
              local settings = col:getCollectionSettings()
              if settings.gallery_id == galleryId then
                matchingCollection = col
                break
              end
            end

            if matchingCollection then
              catalog:withWriteAccessDo(LOC "$$$/PhotoGalleryUploader/SinglePhoto/AddToCollection=Dodaj do Published Collection", function(ctx)
                matchingCollection:addPhoto(photo)
              end)
            end
          end

          LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Success=Success", LOC("$$$/PhotoGalleryUploader/Success/PhotoUploaded=Zdjęcie wrzucone! Remote ID: ^1", remoteId), "info")
        else
          LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Error=Error", LOC("$$$/PhotoGalleryUploader/Error/UploadFailed=Upload nie powiódł się: ^1", result), "warning")
        end
      end
    end

    progressScope:setPortionComplete(1, 1)
  end)
end

return singlePhotoExport
