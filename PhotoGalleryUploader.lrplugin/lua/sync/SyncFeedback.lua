local LrApplication = import "LrApplication"
local LrDialogs = import "LrDialogs"
local LrProgressScope = import "LrProgressScope"
local Config = require "lua/core/Config"

local SyncFeedback = {}

local function setPickStatus(photo, status, keywordsOnly)
  if keywordsOnly then return end

  if status == "picked" then
    photo:setRawMetadata("pickStatus", 1)
  elseif status == "rejected" then
    photo:setRawMetadata("pickStatus", -1)
  end
end

local function addKeywordForStatus(photo, status)
  if status == "picked" then
    photo:addKeyword("client-picked")
  elseif status == "rejected" then
    photo:addKeyword("client-rejected")
  end
end

local function addComments(photo, comments)
  if comments and comments ~= "" then
    photo:setRawMetadata("caption", comments)
  end
end

local function applyFeedbackToPhoto(photo, status, comments, keywordsOnly)
  setPickStatus(photo, status, keywordsOnly)
  addKeywordForStatus(photo, status)
  addComments(photo, comments)
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

local function processFeedbackItem(publishedCollection, feedback, keywordsOnly, stats)
  local publishedPhoto = findPublishedPhotoByRemoteId(publishedCollection, feedback.remoteId)

  if publishedPhoto then
    local photo = publishedPhoto:getPhoto()
    applyFeedbackToPhoto(photo, feedback.status, feedback.comments, keywordsOnly)

    if feedback.status == "picked" then
      stats.picked = stats.picked + 1
    elseif feedback.status == "rejected" then
      stats.rejected = stats.rejected + 1
    else
      stats.pending = stats.pending + 1
    end
  end
end

function SyncFeedback.syncSingleGallery(publishedCollection)
  local client = Config.createClient()
  if not client then return end

  local collectionSettings = publishedCollection:getCollectionSettings()
  local galleryId = collectionSettings.gallery_id

  if not galleryId or galleryId == "" then
    LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Error=Error", LOC "$$$/PhotoGalleryUploader/Error/NoGalleryId=ID galerii nie jest ustawione", "warning")
    return
  end

  local success, feedbackList = client:getFeedback(galleryId)
  if not success then
    LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Error=Error", LOC("$$$/PhotoGalleryUploader/Error/FailedFetchFeedback=Nie udało się pobrać feedback: ^1", feedbackList), "warning")
    return
  end

  local catalog = LrApplication.activeCatalog()
  local prefs = import "LrPrefs".prefsForPlugin()
  local keywordsOnly = prefs.sync_keywords_only or false
  local stats = { picked = 0, rejected = 0, pending = 0 }

  local progressScope = LrProgressScope {
    title = LOC "$$$/PhotoGalleryUploader/Progress/SyncingFeedback=Synchronizowanie feedback...",
  }
  progressScope:setPortionComplete(0, #feedbackList)

  catalog:withWriteAccessDo("Sync Gallery Feedback", function(context)
    for i, feedback in ipairs(feedbackList) do
      processFeedbackItem(publishedCollection, feedback, keywordsOnly, stats)
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
  local client = Config.createClient()
  if not client then return end

  local catalog = LrApplication.activeCatalog()
  local allPublishedCollections = catalog:getPublishedCollections()
  local prefs = import "LrPrefs".prefsForPlugin()
  local stats = { picked = 0, rejected = 0, pending = 0, skipped = 0 }
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
    else
      local success, feedbackList = client:getFeedback(galleryId)

      if success and feedbackList then
        catalog:withWriteAccessDo("Sync All Gallery Feedback", function(context)
          for _, feedback in ipairs(feedbackList) do
            processFeedbackItem(publishedCollection, feedback, keywordsOnly, stats)
          end
        end)
      end
    end

    progressScope:setPortionComplete(collIdx, #allPublishedCollections)
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
