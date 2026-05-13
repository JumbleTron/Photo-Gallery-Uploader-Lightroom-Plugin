return {
  appVersion = "12.0",
  LrSdkVersion = 12.0,
  LrSdkMinimumVersion = 10.0,
  LrToolkitIdentifier = "com.photogalleryuploader.lightroom",
  LrPluginName = "Photo Gallery Uploader",
  LrPluginInfoUrl = "https://example.com",
  LrPluginInfoProvider = "PhotoGalleryUploaderInfo.lua",

  LrExportServiceProvider = {
    title = LOC "$$$/PhotoGalleryUploader/ExportProvider/Title=Photo Gallery Uploader",
    file = "lua/export/PublishServiceProvider.lua",
    exportDialogTooltip = "Upload photos to Photo Gallery system",
    showLeadingIndicators = false,
    showLeadingLabels = false,
  },

  LrExportFilterProvider = {
    title = LOC "$$$/PhotoGalleryUploader/ExportProvider/Title=Photo Gallery Uploader",
    file = "lua/ui/PublishServiceExportDialog.lua",
  },

  LrMetadataProvider = "Metadata.lua",

  LrPublishedCollectionMenuItems = {
    {
      title = "Sync feedback from client",
      file = "lua/export/PublishServiceProvider.lua",
      handler = "publishServiceProvider.syncFeedbackForCollection",
    },
  },

  LrLibraryMenuItems = {
    {
      title = LOC "$$$/PhotoGalleryUploader/Menu/SyncAllFeedback=Photo Gallery Uploader: Sync feedback (all galleries)",
      file = "lua/export/PublishServiceProvider.lua",
      handler = "publishServiceProvider.syncAllFeedback",
    },
  },

  LrExportMenuItems = {
    {
      title = LOC "$$$/PhotoGalleryUploader/Menu/UploadPhoto=Upload photo to gallery",
      file = "lua/export/SinglePhotoExport.lua",
      handler = "singlePhotoExport.exportMenuItemHandler",
    },
  },

  VERSION = {
    major = 0,
    minor = 1,
    revision = 0,
    build = 1,
  },
}
