local LrApplication = import "LrApplication"
local LrDialogs = import "LrDialogs"
local LrProgressScope = import "LrProgressScope"
local LrPrefs = import "LrPrefs"
local ApiClient = require "ApiClient"

local SyncFeedback = {}

local function applyFeedbackToPhoto(photo, status, comments, keywordsOnly)
  if status == "picked" then
    if not keywordsOnly then
      photo:setRawMetadata("pickStatus", 1)
    end
    photo:addKeyword("client-picked")
  elseif status == "rejected" then
    if not keywordsOnly then
      photo:setRawMetadata("pickStatus", -1)
    end
    photo:addKeyword("client-rejected")
  end

  if comments and comments ~= "" then
    photo:setRawMetadata("caption", comments)
  end
end

local function findPublishedPhotoByRemoteId(publishedCollection, remoteId)
  local publishedPhotos = publishedCollection:getPublishedPhotos()
  for _, publishedPhoto in ipairs(publishedPhotos) do
    if publishedPhoto:getRemoteId() == remoteId then
      return publishedPhoto
    end
  end
  return nil
end

function SyncFeedback.syncSingleGallery(publishedCollection)
  local prefs = LrPrefs.prefsForPlugin()
  local apiUrl = prefs.api_url or ""
  local apiKey = prefs.api_key or ""

  if apiUrl == "" or apiKey == "" then
    LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Error=Error", LOC "$$$/PhotoGalleryUploader/Error/CredentialsNotConfigured=Dane do API nie są skonfigurowane", "warning")
    return
  end

  local collectionSettings = publishedCollection:getCollectionSettings()
  local galleryId = collectionSettings.gallery_id

  if not galleryId or galleryId == "" then
    LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Error=Error", LOC "$$$/PhotoGalleryUploader/Error/NoGalleryId=ID galerii nie jest ustawione", "warning")
    return
  end

  local client = ApiClient.new(apiUrl, apiKey)
  local success, feedbackList = client:getFeedback(galleryId)

  if not success then
    LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Error=Error", LOC("$$$/PhotoGalleryUploader/Error/FailedFetchFeedback=Nie udało się pobrać feedback: ^1", feedbackList), "warning")
    return
  end

  local catalog = LrApplication.activeCatalog()
  local progressScope = LrProgressScope {
    title = LOC "$$$/PhotoGalleryUploader/Progress/SyncingFeedback=Synchronizowanie feedback...",
  }

  progressScope:setPortionComplete(0, #feedbackList)

  local stats = { picked = 0, rejected = 0, pending = 0 }
  local keywordsOnly = prefs.sync_keywords_only or false

  catalog:withWriteAccessDo("Sync Gallery Feedback", function(context)
    for i, feedback in ipairs(feedbackList) do
      local publishedPhoto = findPublishedPhotoByRemoteId(publishedCollection, feedback.remoteId)

      if publishedPhoto then
        local photo = publishedPhoto:getPhoto()
        if feedback.status == "picked" then
          applyFeedbackToPhoto(photo, "picked", feedback.comments, keywordsOnly)
          stats.picked = stats.picked + 1
        elseif feedback.status == "rejected" then
          applyFeedbackToPhoto(photo, "rejected", feedback.comments, keywordsOnly)
          stats.rejected = stats.rejected + 1
        else
          stats.pending = stats.pending + 1
        end
      end

      progressScope:setPortionComplete(i, #feedbackList)
    end
  end)

  local message = LOC("$$$/PhotoGalleryUploader/Success/SyncedFeedback=Zsynchronizowano: ^1 zaakceptowanych, ^2 odrzuconych, ^3 oczekujących",
    stats.picked,
    stats.rejected,
    stats.pending
  )
  LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Success=Success", message, "info")
end

function SyncFeedback.syncAllGalleries()
  local prefs = LrPrefs.prefsForPlugin()
  local apiUrl = prefs.api_url or ""
  local apiKey = prefs.api_key or ""

  if apiUrl == "" or apiKey == "" then
    LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Error=Error", LOC "$$$/PhotoGalleryUploader/Error/CredentialsNotConfigured=Dane do API nie są skonfigurowane", "warning")
    return
  end

  local catalog = LrApplication.activeCatalog()
  local allPublishedCollections = catalog:getPublishedCollections()

  local stats = { picked = 0, rejected = 0, pending = 0, skipped = 0 }
  local client = ApiClient.new(apiUrl, apiKey)
  local keywordsOnly = prefs.sync_keywords_only or false

  local progressScope = LrProgressScope {
    title = LOC "$$$/PhotoGalleryUploader/Progress/SyncingAllGalleries=Synchronizowanie feedback ze wszystkich galerii...",
  }

  progressScope:setPortionComplete(0, #allPublishedCollections)

  for collIdx, publishedCollection in ipairs(allPublishedCollections) do
    local collectionSettings = publishedCollection:getCollectionSettings()
    local galleryId = collectionSettings.gallery_id

    if not galleryId or galleryId == "" then
      stats.skipped = stats.skipped + 1
      progressScope:setPortionComplete(collIdx, #allPublishedCollections)
      goto continue
    end

    local success, feedbackList = client:getFeedback(galleryId)

    if success and feedbackList then
      catalog:withWriteAccessDo("Sync All Gallery Feedback", function(context)
        for _, feedback in ipairs(feedbackList) do
          local publishedPhoto = findPublishedPhotoByRemoteId(publishedCollection, feedback.remoteId)

          if publishedPhoto then
            local photo = publishedPhoto:getPhoto()
            if feedback.status == "picked" then
              applyFeedbackToPhoto(photo, "picked", feedback.comments, keywordsOnly)
              stats.picked = stats.picked + 1
            elseif feedback.status == "rejected" then
              applyFeedbackToPhoto(photo, "rejected", feedback.comments, keywordsOnly)
              stats.rejected = stats.rejected + 1
            else
              stats.pending = stats.pending + 1
            end
          end
        end
      end)
    end

    progressScope:setPortionComplete(collIdx, #allPublishedCollections)
    ::continue::
  end

  local message = LOC("$$$/PhotoGalleryUploader/Success/SyncedAllGalleries=Łącznie zsynchronizowano: ^1 zaakceptowanych, ^2 odrzuconych, ^3 oczekujących (pominięto ^4)",
    stats.picked,
    stats.rejected,
    stats.pending,
    stats.skipped
  )
  LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Success=Success", message, "info")
end

return SyncFeedback
