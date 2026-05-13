# Analiza Kodu i Rekomendacje Refaktoringu

## 🔴 PROBLEMY KRYTYCZNE

### 1. **ApiClient.lua - Globalny scope dla headers**
**Lokacja:** Linie 74, 99  
**Problem:** Zmienne `headers` nie są oznaczone jako `local`
```lua
headers = {  -- ❌ GLOBALNY scope!
  ["X-API-Key"] = self.apiKey,
}
```
**Wpływ:** Zanieczyszczenie globalnego scope'u, możliwe konflikty.  
**Rozwiązanie:**
```lua
local headers = {  -- ✅ LOKALNY scope
  ["X-API-Key"] = self.apiKey,
}
```

---

### 2. **ApiClient.lua - Nieużywana funkcja `buildHeaders`**
**Lokacja:** Linie 16-21  
**Problem:** Funkcja jest zdefiniowana ale nie jest nigdzie używana
```lua
local function buildHeaders(apiKey)  -- ❌ Martwy kod
  return {
    ["X-API-Key"] = apiKey,
    ["Content-Type"] = "application/json",
  }
end
```
**Rozwiązanie:** Usunąć lub zrefaktoryzować do użytku

---

## 🟡 PROBLEMY Z KODEM (SOLID, DRY)

### 3. **Duplikacja nagłówków HTTP**
**Lokacje:** 
- `ApiClient:request()` (linie 23-26)
- `ApiClient:uploadPhoto()` (linia 75)
- `ApiClient:updatePhoto()` (linia 100)

**Problem:** Każda metoda ręcznie ustawia nagłówki zamiast delegować do wspólnej funkcji.

**Naruszenie:** DRY (Don't Repeat Yourself) + SRP (Single Responsibility)

**Refaktoring:**
```lua
local function buildHeaders(apiKey)
  return {
    ["X-API-Key"] = apiKey,
    ["Content-Type"] = "application/json",
  }
end

function ApiClient:request(method, endpoint, body, headers)
  headers = mergeHeaders(headers, buildHeaders(self.apiKey))
  -- ...
end

function ApiClient:uploadPhoto(...)
  local headers = buildHeaders(self.apiKey)
  -- ...
end
```

---

### 4. **Duplikacja logiki obsługi HTTP response**
**Lokacje:**
- `request()` (linie 42-48)
- `uploadPhoto()` (linie 89-95)
- `updatePhoto()` (linie 114-120)

**Problem:** Każda funkcja powtarza sprawdzanie statusu HTTP i dekodowanie JSON

**Refaktoring:**
```lua
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
```

---

### 5. **PublishServiceProvider.lua - Powtarzająca się logika credentials**
**Lokacje:**
- `processRenderedPhotos()` (linie 50-57)
- `deletePhotosFromPublishedCollection()` (linie 133-139)
- `renamePublishedCollection()` (linie 168-175)
- `CollectionSettingsDialog.lua` (linie 127-134)

**Problem:** Każda funkcja osobno pobiera i waliduje API credentials

**Naruszenie:** DRY + SRP

**Refaktoring - nowy moduł `Config.lua`:**
```lua
local LrPrefs = import "LrPrefs"
local LrDialogs = import "LrDialogs"

local Config = {}

function Config.getCredentials()
  local prefs = LrPrefs.prefsForPlugin()
  local apiUrl = prefs.api_url or ""
  local apiKey = prefs.api_key or ""
  return apiUrl, apiKey
end

function Config.validateCredentials()
  local apiUrl, apiKey = Config.getCredentials()
  if apiUrl == "" or apiKey == "" then
    LrDialogs.message(
      LOC "$$$/PhotoGalleryUploader/Error=Error",
      LOC "$$$/PhotoGalleryUploader/Error/CredentialsNotConfigured=Dane do API nie są skonfigurowane",
      "warning"
    )
    return false
  end
  return true
end

function Config.createClient()
  if not Config.validateCredentials() then
    return nil
  end
  local apiUrl, apiKey = Config.getCredentials()
  local ApiClient = require "ApiClient"
  return ApiClient.new(apiUrl, apiKey)
end

return Config
```

**Użycie:**
```lua
local Config = require "Config"
local client = Config.createClient()
if not client then return end
```

---

### 6. **SyncFeedback.lua - Duplikacja logiki feedback loop**
**Lokacje:**
- `syncSingleGallery()` (linie 74-91)
- `syncAllGalleries()` (linie 139-155)

**Problem:** Prawie identyczna logika w dwóch funkcjach

**Refaktoring:**
```lua
local function processFeedback(publishedCollection, feedbackList, keywordsOnly)
  local stats = { picked = 0, rejected = 0, pending = 0 }
  
  for _, feedback in ipairs(feedbackList) do
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
  
  return stats
end
```

---

### 7. **SyncFeedback.lua - `applyFeedbackToPhoto` narusza SRP**
**Lokacja:** Linie 9-25

**Problem:** Funkcja robi zbyt wiele (ustawia pick status, dodaje keywords, ustawia captions)

**Refaktoring:**
```lua
local function setPickStatus(photo, status)
  if status == "picked" then
    photo:setRawMetadata("pickStatus", 1)
    photo:addKeyword("client-picked")
  elseif status == "rejected" then
    photo:setRawMetadata("pickStatus", -1)
    photo:addKeyword("client-rejected")
  end
end

local function addComments(photo, comments)
  if comments and comments ~= "" then
    photo:setRawMetadata("caption", comments)
  end
end

local function applyFeedbackToPhoto(photo, status, comments, keywordsOnly)
  if not keywordsOnly then
    setPickStatus(photo, status)
  else
    photo:addKeyword(status == "picked" and "client-picked" or "client-rejected")
  end
  addComments(photo, comments)
end
```

---

### 8. **CollectionSettingsDialog.lua - Brak podzielenia odpowiedzialności**
**Problem:** Dialog odpowiada za:
- Budowanie UI
- Pobieranie credentials
- Komunikację z API
- Obsługę błędów

**Refaktoring:** Przenieść logikę API do `Config.lua`, użyć do obsługi błędów

```lua
function dialog.refreshGalleries(collectionSettings)
  LrFunctionContext.callAsyncFunction(function(context)
    local Config = require "Config"
    local client = Config.createClient()
    
    if not client then return end
    
    local success, galleries = client:getGalleries()
    
    if success then
      collectionSettings.galleries_list = galleries
      LrDialogs.message(...)
    else
      LrDialogs.message(...)
    end
  end)
end
```

---

## 📋 PODSUMOWANIE ZMIAN

| Problem | Plik | Typ | Priorytet |
|---------|------|-----|-----------|
| Global `headers` | ApiClient.lua | Bug | 🔴 KRYTYCZNY |
| Nieużywana funkcja | ApiClient.lua | Clean | 🟡 Wysoki |
| Duplikacja nagłówków | ApiClient.lua | DRY | 🟡 Wysoki |
| Duplikacja response | ApiClient.lua | DRY | 🟡 Wysoki |
| Duplikacja credentials | Wiele plików | DRY | 🟡 Wysoki |
| Duplikacja feedback loop | SyncFeedback.lua | DRY | 🟡 Wysoki |
| SRP w feedback | SyncFeedback.lua | SOLID | 🟡 Średni |

---

## 🎯 PLAN REFAKTORINGU (sekwencja)

1. ✅ **Faza 1: Krytyczne bugfixy**
   - Naprawić global `headers` w ApiClient.lua
   
2. ✅ **Faza 2: Ekstrakcja Config**
   - Stworzyć `Config.lua`
   - Zaktualizować wszystkie moduły do użycia Config
   
3. ✅ **Faza 3: Refactoring ApiClient**
   - Implementować `handleResponse()`
   - Usunąć `buildHeaders()` jeśli nieużywana
   - Ujednolicić obsługę nagłówków
   
4. ✅ **Faza 4: Refactoring SyncFeedback**
   - Podzielić `applyFeedbackToPhoto()`
   - Ekstrakcja wspólnej logiki feedback loop
   
5. ✅ **Faza 5: Testy i walidacja**
   - Przetestować wszystkie ścieżki

---

## 📚 Zasady Lua do pamiętania

- **Wszystkie zmienne muszą być `local`** (chyba że celowo globalne)
- **Unikaj goto** (chyba że absolutnie konieczne) - linia 132 w SyncFeedback.lua
- **Funkcje pomocnicze powinny być `local`** jeśli są wewnętrzne
- **One function = one responsibility** (SOLID SRP)
- **DRY - Don't Repeat Yourself** - kod powtarzający się 3+ razy should być wyekstrahowany
