local LrHttp = import "LrHttp"
local LrErrors = import "LrErrors"
local json = require "json"

local ApiClient = {}

function ApiClient.new(baseUrl, apiKey)
  local client = {
    baseUrl = baseUrl,
    apiKey = apiKey,
  }
  setmetatable(client, { __index = ApiClient })
  return client
end

local function buildHeaders(apiKey)
  return {
    ["X-API-Key"] = apiKey,
    ["Content-Type"] = "application/json",
  }
end

function ApiClient:request(method, endpoint, body, headers)
  headers = headers or {}
  headers["X-API-Key"] = self.apiKey
  headers["Content-Type"] = "application/json"

  local url = self.baseUrl .. endpoint
  local bodyStr = body and json.encode(body) or nil

  local success, response = LrHttp.request {
    url = url,
    method = method,
    headers = headers,
    body = bodyStr,
  }

  if not success then
    return false, "HTTP request failed: " .. (response or "unknown error")
  end

  local status = response.status or 0
  if status < 200 or status >= 300 then
    return false, "HTTP " .. status .. ": " .. (response.body or "no body")
  end

  local decodedBody = response.body and response.body ~= "" and json.decode(response.body) or {}
  return true, decodedBody
end

function ApiClient:testConnection()
  return self:request("GET", "/api/galleries")
end

function ApiClient:getGalleries()
  return self:request("GET", "/api/galleries")
end

function ApiClient:createGallery(name, deadline, clientMessage)
  local body = {
    name = name,
    deadline = deadline,
    clientMessage = clientMessage,
  }
  return self:request("POST", "/api/galleries", body)
end

function ApiClient:updateGallery(galleryId, name)
  local body = { name = name }
  return self:request("PATCH", "/api/galleries/" .. galleryId, body)
end

function ApiClient:uploadPhoto(galleryId, filePath, originalName, captureTime)
  headers = {
    ["X-API-Key"] = self.apiKey,
  }
  local url = self.baseUrl .. "/api/galleries/" .. galleryId .. "/photos"

  local success, response = LrHttp.post {
    url = url,
    headers = headers,
    filePath = filePath,
  }

  if not success then
    return false, "Upload failed: " .. (response or "unknown error")
  end

  local status = response.status or 0
  if status < 200 or status >= 300 then
    return false, "HTTP " .. status .. ": " .. (response.body or "no body")
  end

  local decodedBody = response.body and response.body ~= "" and json.decode(response.body) or {}
  return true, decodedBody
end

function ApiClient:updatePhoto(galleryId, remoteId, filePath)
  headers = {
    ["X-API-Key"] = self.apiKey,
  }
  local url = self.baseUrl .. "/api/galleries/" .. galleryId .. "/photos/" .. remoteId

  local success, response = LrHttp.put {
    url = url,
    headers = headers,
    filePath = filePath,
  }

  if not success then
    return false, "Update failed: " .. (response or "unknown error")
  end

  local status = response.status or 0
  if status < 200 or status >= 300 then
    return false, "HTTP " .. status .. ": " .. (response.body or "no body")
  end

  local decodedBody = response.body and response.body ~= "" and json.decode(response.body) or {}
  return true, decodedBody
end

function ApiClient:deletePhoto(galleryId, remoteId)
  return self:request("DELETE", "/api/galleries/" .. galleryId .. "/photos/" .. remoteId)
end

function ApiClient:getFeedback(galleryId)
  return self:request("GET", "/api/galleries/" .. galleryId .. "/feedback")
end

return ApiClient
