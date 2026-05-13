# Plugin Lightroom Classic — Photo Gallery Uploader

Wtyczka do Lightroom Classic integrująca się z backendem Symfony (REST API + auth przez API key) do uploadu zdjęć do galerii akceptacyjnych i synchronizacji feedbacku klienta z powrotem do Lightrooma.

## Decyzje projektowe (ustalone)

- **Target:** Lightroom Classic (pełne Lua SDK).
- **Model integracji:** Publish Service — każda galeria w systemie = jedna Published Collection w LR.
- **Feedback w LR:** Pick flag (✓ / ✗) + keyword (`client-picked`, `client-rejected`).
- **Re-edycja zdjęcia:** Republish nadpisuje plik w galerii (PUT), `remoteId` i feedback zachowane.
- **Auth:** nagłówek `X-API-Key`.

---

## Architektura w skrócie

Plugin typu Publish Service w LR Classic, w Lua, na bazie `LrPublishedCollection` + `LrHttp` + `LrTasks`. Każda galeria = Published Collection. Edycja w LR + Publish/Republish wysyła pliki przez REST API. Osobna komenda menu pobiera feedback klienta i ustawia w LR flagi pick/reject + keyword.

## Struktura plików pluginu

```
PhotoGalleryUploader.lrplugin/
├── Info.lua                       # manifest, wersja, hooks menu
├── PublishServiceProvider.lua     # definicja usługi publish
├── PublishServiceExportDialog.lua # konfiguracja konta (API key, URL)
├── CollectionSettings.lua         # dialog wyboru galerii dla kolekcji
├── SyncFeedback.lua               # akcja "Pobierz feedback z serwera"
├── ApiClient.lua                  # wspólny HTTP + auth + parsowanie JSON
└── strings/                       # tłumaczenia PL/EN
```

---

## Co dokładnie user klika w Lightroomie

### 1. Jednorazowa konfiguracja konta
- **Library → File → Plug-in Manager → "Photo Gallery Uploader" → Plug-in Info**
- Pola: **API URL** (np. `https://twoj-system.pl/api`), **API Key**, przycisk **Test connection**.
- Po sukcesie plugin zapisuje credentiale w preferencjach LR (`LrPrefs`) — szyfrowane per-machine.

### 2. Utworzenie usługi publish
- W lewym panelu Library, sekcja **Publish Services** → **Set Up…** obok "Photo Gallery Uploader".
- Standardowy dialog LR z dwiema dodatkowymi sekcjami:
  - **Account** — pokazuje aktualny API key + status połączenia.
  - **Export settings** — JPEG quality, sRGB, max długość boku (np. 2560px), watermark off (defaulty rozsądne, user może zmienić).

### 3. Tworzenie kolekcji = galerii
- Prawym na "Photo Gallery Uploader" w panelu → **Create Published Collection…**
- Custom dialog (`viewForCollectionSettings`):
  - Radio: **Stwórz nową galerię w systemie** vs **Powiąż z istniejącą**.
  - "Istniejąca" → dropdown ładuje listę z `GET /api/galleries` (galerie do zatwierdzenia, nazwy).
  - "Nowa" → pole **Nazwa galerii** + opcjonalne **deadline akceptacji**, **wiadomość dla klienta**.
- **Synchronizacja nazw:** nazwa Published Collection w LR = nazwa galerii w systemie. Zmiana nazwy kolekcji w LR → `PATCH /api/galleries/{id}` (rename hook w `PublishServiceProvider`).

### 4. Wrzucanie zdjęć

**Sposób A — bulk (główny flow):**
- Drag&drop zdjęć na Published Collection → **Publish** (przycisk u góry panelu / prawym → Publish Now).
- LR woła `processRenderedPhotos` — plugin uploaduje rendered JPEG na `POST /api/galleries/{id}/photos` (multipart, metadane: oryginalna nazwa, capture time, LR catalog ID).
- Backend zwraca `{ remoteId, url }` → plugin zapisuje przez `rendition:recordPublishedPhotoId(remoteId)` + `recordPublishedPhotoUrl(url)`. LR przesuwa zdjęcie z "New Photos to Publish" do "Published Photos".

**Sposób B — pojedyncza fotka po obróbce:**
- W Library/Develop prawym na zdjęciu → **Photo Gallery Uploader → Wrzuć do galerii…** (custom menu item, `LrExportMenuItem`).
- Mały dialog: dropdown galerii (lista z API), opcjonalnie checkbox "Dodaj też do Published Collection w LR".
- **Upload** → render w tle (LrTasks + LrExportSession), upload, toast.

### 5. Re-edycja zdjęcia
- Zmiana develop settings → LR oznacza zdjęcie w Published Collection jako **"Modified Photos to Re-Publish"**.
- **Publish** → plugin woła `PUT /api/galleries/{id}/photos/{remoteId}` z nowym renderem.
- Backend nadpisuje plik, **zachowuje `remoteId` i feedback klienta** (kluczowe — endpoint PUT aktualizuje binary ale nie resetuje statusu pick/reject).

### 6. Usuwanie
- Usunięcie zdjęcia z Published Collection → LR woła `deletePhotosFromPublishedCollection` → plugin robi `DELETE /api/galleries/{id}/photos/{remoteId}`.

### 7. Synchronizacja feedbacku
Dwa wejścia:
- **Dla jednej galerii:** prawym na Published Collection → **Sync feedback from client** (`LrPublishedCollectionMenuItem`).
- **Dla wszystkich:** **Library → Plug-in Extras → Photo Gallery Uploader → Sync feedback (all galleries)**.

Algorytm:
1. `GET /api/galleries/{id}/feedback` zwraca `[{ remoteId, status: "picked"|"rejected"|"pending" }, ...]`.
2. Dla każdego zdjęcia plugin znajduje lokalną fotkę przez `publishedCollection:getPublishedPhotoByRemoteId(remoteId)`.
3. W `catalog:withWriteAccessDo`:
   - `picked` → `photo:setRawMetadata("pickStatus", 1)` + keyword `client-picked`.
   - `rejected` → `pickStatus = -1` + keyword `client-rejected`.
   - `pending` → bez zmian.
4. Progress przez `LrProgressScope`, na końcu podsumowanie ("Zsynchronizowano: 47 picked, 12 rejected, 5 pending").

---

## Wymagania po stronie Symfony API

- `GET /api/galleries` — lista galerii usera (dropdown).
- `POST /api/galleries` — tworzenie galerii z LR.
- `PATCH /api/galleries/{id}` — rename (sync nazwy).
- `POST /api/galleries/{id}/photos` — upload (multipart), zwraca `remoteId`.
- `PUT /api/galleries/{id}/photos/{remoteId}` — replace pliku **bez resetu feedbacku** (krytyczne).
- `DELETE /api/galleries/{id}/photos/{remoteId}`.
- `GET /api/galleries/{id}/feedback` — lista statusów.

Auth: `X-API-Key: <klucz>`.

---

## Plan implementacji w krokach

1. **Szkielet pluginu** — `Info.lua`, rejestracja Publish Service, dummy callbacki, test "ładuje się w Plug-in Manager".
2. **ApiClient.lua** — `LrHttp` wrapper z auth, retry, error mapping, JSON przez `dkjson` (wbudowane w LR SDK).
3. **Auth dialog** — pola API URL + key, test endpoint.
4. **Tworzenie/listowanie galerii w `viewForCollectionSettings`** — dropdown + tryb "nowa".
5. **`processRenderedPhotos`** — upload + `recordPublishedPhotoId`. Obsługa progressu i błędów per-zdjęcie.
6. **Re-publish (PUT)** — wykrycie czy `publishedPhoto` ma `remoteId` → endpoint PUT zamiast POST.
7. **Delete + rename hooks**.
8. **Sync feedback (single + all)** — menu items, write metadata, keywords.
9. **Single-photo upload menu item** (Sposób B) — flow "po obróbce wrzuć jedną".
10. **Polerka:** i18n PL/EN, ikona pluginu (16/32/64px), changelog, README, packowanie do `.lrplugin`.

---

## Otwarte kwestie / ryzyka

- **Konflikt flag:** jeśli już używasz pick/reject do własnych celów, sync może je nadpisać. Rozważ opcję w settings "tylko keyword, nie ruszaj flag".
- **Duże galerie:** upload 500 zdjęć × 10MB ≈ 5GB — backend musi wspierać duże uploady (timeout, ewentualne chunkowanie).
- **Idempotencja:** przerwany upload nie powinien duplikować przy ponownym Publish — dedup po hash w backendzie albo `Idempotency-Key` z pluginu.
- **Komentarze klienta:** dziś feedback jednokierunkowy. Gdybyś chciał komentarze widzieć w LR (np. w polu `Caption`), trywialne dorobienie.
