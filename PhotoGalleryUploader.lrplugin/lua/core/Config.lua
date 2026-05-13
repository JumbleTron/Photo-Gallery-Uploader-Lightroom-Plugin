local LrPrefs = import "LrPrefs"
local LrDialogs = import "LrDialogs"
local ApiClient = require "lua/core/ApiClient"

local Config = {}

function Config.getCredentials()
  local prefs = LrPrefs.prefsForPlugin()
  local apiUrl = prefs.api_url or ""
  local apiKey = prefs.api_key or ""
  return apiUrl, apiKey
end

function Config.areCredentialsConfigured()
  local apiUrl, apiKey = Config.getCredentials()
  return apiUrl ~= "" and apiKey ~= ""
end

function Config.showMissingCredentialsError()
  LrDialogs.message(
    LOC "$$$/PhotoGalleryUploader/Error=Error",
    LOC "$$$/PhotoGalleryUploader/Error/CredentialsNotConfigured=Dane do API nie są skonfigurowane",
    "warning"
  )
end

function Config.createClient()
  if not Config.areCredentialsConfigured() then
    Config.showMissingCredentialsError()
    return nil
  end
  local apiUrl, apiKey = Config.getCredentials()
  return ApiClient.new(apiUrl, apiKey)
end

return Config
