local LrHttp = import "LrHttp"
local LrErrors = import "LrErrors"
local json = require "json"

local ApiClient = {}

local function buildHeaders(apiKey)
  return {
    ["X-API-Key"] = apiKey,
    ["Content-Type"] = "application/json",
  }
end

local function handleResponse(success, response)
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

function ApiClient.new(baseUrl, apiKey)
  local client = {
    baseUrl = baseUrl,
    apiKey = apiKey,
  }
  setmetatable(client, { __index = ApiClient })
  return client
end

function ApiClient:request(method, endpoint, body, headers)
  headers = headers or buildHeaders(self.apiKey)
  headers["X-API-Key"] = self.apiKey

  local url = self.baseUrl .. endpoint
  local bodyStr = body and json.encode(body) or nil

  local success, response = LrHttp.request {
    url = url,
    method = method,
    headers = headers,
    body = bodyStr,
  }

  return handleResponse(success, response)
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
  local url = self.baseUrl .. "/api/galleries/" .. galleryId .. "/photos"
  local headers = buildHeaders(self.apiKey)

  local success, response = LrHttp.post {
    url = url,
    headers = headers,
    filePath = filePath,
  }

  return handleResponse(success, response)
end

function ApiClient:updatePhoto(galleryId, remoteId, filePath)
  local url = self.baseUrl .. "/api/galleries/" .. galleryId .. "/photos/" .. remoteId
  local headers = buildHeaders(self.apiKey)

  local success, response = LrHttp.put {
    url = url,
    headers = headers,
    filePath = filePath,
  }

  return handleResponse(success, response)
end

function ApiClient:deletePhoto(galleryId, remoteId)
  return self:request("DELETE", "/api/galleries/" .. galleryId .. "/photos/" .. remoteId)
end

function ApiClient:getFeedback(galleryId)
  return self:request("GET", "/api/galleries/" .. galleryId .. "/feedback")
end

return ApiClient
