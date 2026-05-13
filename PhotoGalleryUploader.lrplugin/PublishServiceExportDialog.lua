local LrBinding = import "LrBinding"
local LrDialogs = import "LrDialogs"
local LrFunctionContext = import "LrFunctionContext"
local LrPrefs = import "LrPrefs"
local ApiClient = require "ApiClient"

local exportDialogProvider = {}

function exportDialogProvider.startDialog(propertyTable, f)
  local prefs = LrPrefs.prefsForPlugin()
  propertyTable.api_url = propertyTable.api_url or prefs.api_url or ""
  propertyTable.api_key = propertyTable.api_key or prefs.api_key or ""
  propertyTable.sync_keywords_only = propertyTable.sync_keywords_only or prefs.sync_keywords_only or false
end

function exportDialogProvider.endDialog(propertyTable, why)
  if why == "ok" then
    local prefs = LrPrefs.prefsForPlugin()
    prefs.api_url = propertyTable.api_url
    prefs.api_key = propertyTable.api_key
    prefs.sync_keywords_only = propertyTable.sync_keywords_only
  end
end

function exportDialogProvider.sectionsForBottomOfDialog(propertyTable, f)
  local sections = {}

  table.insert(sections, {
    title = LOC "$$$/PhotoGalleryUploader/AuthDialog/Title=Ustawienia Konta",
    synopsis = LOC "$$$/PhotoGalleryUploader/AuthDialog/Synopsis=Konfiguracja API",

    f:group_box {
      title = LOC "$$$/PhotoGalleryUploader/AuthDialog/ApiConfiguration=Konfiguracja API",
      f:row {
        f:static_text {
          title = LOC "$$$/PhotoGalleryUploader/AuthDialog/ApiUrl=URL API:",
          width = 100,
        },
        f:edit_field {
          value = LrBinding.makeKeyBinding(propertyTable, "api_url"),
          width_in_chars = 40,
          tooltip = LOC "$$$/PhotoGalleryUploader/AuthDialog/ApiUrlTooltip=Bazowy URL API (np. https://example.com/api)",
        },
      },
      f:row {
        f:static_text {
          title = LOC "$$$/PhotoGalleryUploader/AuthDialog/ApiKey=Klucz API:",
          width = 100,
        },
        f:password_field {
          value = LrBinding.makeKeyBinding(propertyTable, "api_key"),
          width_in_chars = 40,
          tooltip = LOC "$$$/PhotoGalleryUploader/AuthDialog/ApiKeyTooltip=Twój klucz API do autentykacji",
        },
      },
      f:row {
        f:push_button {
          title = LOC "$$$/PhotoGalleryUploader/AuthDialog/TestConnection=Test Połączenia",
          action = function()
            LrFunctionContext.callAsyncFunction(function(context)
              local url = propertyTable.api_url
              local key = propertyTable.api_key

              if url == "" or key == "" then
                LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Error=Error", LOC "$$$/PhotoGalleryUploader/Error/ConfigureApiFirst=Proszę skonfiguruj API URL i Klucz", "warning")
                return
              end

              local client = ApiClient.new(url, key)
              local success, result = client:testConnection()

              if success then
                LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Success=Success", LOC("$$$/PhotoGalleryUploader/Success/ConnectionSuccessful=Połączenie udane! Znaleziono ^1 galerii.", (#result or 0)), "info")
              else
                LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Error=Error", LOC("$$$/PhotoGalleryUploader/Error/UploadFailed=Upload nie powiódł się: ^1", result), "warning")
              end
            end)
          end,
        },
      },
    },
  })

  table.insert(sections, {
    title = LOC "$$$/PhotoGalleryUploader/AuthDialog/FeedbackSettings=Ustawienia Feedback",
    synopsis = LOC "$$$/PhotoGalleryUploader/AuthDialog/FeedbackSynopsis=Opcje synchronizacji",

    f:group_box {
      title = LOC "$$$/PhotoGalleryUploader/AuthDialog/SyncOptions=Opcje Synchronizacji Feedback",
      f:checkbox {
        title = LOC "$$$/PhotoGalleryUploader/AuthDialog/KeywordsOnly=Tylko keywords, nie ruszaj flag",
        value = LrBinding.makeKeyBinding(propertyTable, "sync_keywords_only"),
        tooltip = LOC "$$$/PhotoGalleryUploader/AuthDialog/KeywordsOnlyTooltip=Jeśli zaznaczone, sync dodaje tylko keywords (client-picked/rejected) bez zmiany flag pick/reject. Przydatne jeśli już używasz flag do własnych celów.",
      },
    },
  })

  return sections
end

return exportDialogProvider
