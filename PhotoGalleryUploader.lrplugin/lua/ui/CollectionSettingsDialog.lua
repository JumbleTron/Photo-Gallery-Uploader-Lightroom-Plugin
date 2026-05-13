local LrBinding = import "LrBinding"
local LrDialogs = import "LrDialogs"
local LrFunctionContext = import "LrFunctionContext"
local Config = require "lua/core/Config"

local dialog = {}

function dialog.buildView(f, propertyTable, editContext)
  local collectionSettings = editContext.collectionSettings

  collectionSettings.mode = collectionSettings.mode or "existing"
  collectionSettings.gallery_id = collectionSettings.gallery_id or ""
  collectionSettings.gallery_name = collectionSettings.gallery_name or ""
  collectionSettings.new_gallery_name = collectionSettings.new_gallery_name or ""
  collectionSettings.new_gallery_deadline = collectionSettings.new_gallery_deadline or ""
  collectionSettings.new_gallery_message = collectionSettings.new_gallery_message or ""
  collectionSettings.galleries_list = collectionSettings.galleries_list or {}

  local modeBinding = LrBinding.makeKeyBinding(collectionSettings, "mode")
  local galleryIdBinding = LrBinding.makeKeyBinding(collectionSettings, "gallery_id")
  local newNameBinding = LrBinding.makeKeyBinding(collectionSettings, "new_gallery_name")
  local deadlineBinding = LrBinding.makeKeyBinding(collectionSettings, "new_gallery_deadline")
  local messageBinding = LrBinding.makeKeyBinding(collectionSettings, "new_gallery_message")

  local view = f:group_box {
    title = LOC "$$$/PhotoGalleryUploader/CollectionSettings/Title=Konfiguracja Galerii",
    f:row {
      f:radio_button_group {
        value = modeBinding,
        {
          title = LOC "$$$/PhotoGalleryUploader/CollectionSettings/CreateNew=Stwórz nową galerię",
          value = "new",
        },
        {
          title = LOC "$$$/PhotoGalleryUploader/CollectionSettings/UseExisting=Powiąż z istniejącą galerię",
          value = "existing",
        },
      },
    },

    f:separator { fill_horizontal = true },

    f:view {
      visible = LrBinding.makeKeyBinding(collectionSettings, "mode", function(mode)
        return mode == "existing"
      end),

      f:row {
        f:static_text {
          title = LOC "$$$/PhotoGalleryUploader/CollectionSettings/Gallery=Galeria:",
          width = 100,
        },
        f:column {
          f:popup_menu {
            value = galleryIdBinding,
            items = function()
              local items = {}
              for i, gallery in ipairs(collectionSettings.galleries_list) do
                table.insert(items, {
                  title = gallery.name,
                  value = gallery.id,
                })
              end
              return items
            end,
            width_in_chars = 40,
          },
          f:push_button {
            title = LOC "$$$/PhotoGalleryUploader/CollectionSettings/RefreshGalleries=Odśwież Galerie",
            action = function()
              dialog.refreshGalleries(collectionSettings)
            end,
          },
        },
      },
    },

    f:view {
      visible = LrBinding.makeKeyBinding(collectionSettings, "mode", function(mode)
        return mode == "new"
      end),

      f:row {
        f:static_text {
          title = LOC "$$$/PhotoGalleryUploader/CollectionSettings/GalleryName=Nazwa Galerii:",
          width = 100,
        },
        f:edit_field {
          value = newNameBinding,
          width_in_chars = 40,
          tooltip = "Name for the new gallery",
        },
      },

      f:row {
        f:static_text {
          title = LOC "$$$/PhotoGalleryUploader/CollectionSettings/Deadline=Deadline (opt):",
          width = 100,
        },
        f:edit_field {
          value = deadlineBinding,
          width_in_chars = 40,
          tooltip = LOC "$$$/PhotoGalleryUploader/CollectionSettings/DeadlineTooltip=Data akceptacji (YYYY-MM-DD)",
        },
      },

      f:row {
        f:static_text {
          title = LOC "$$$/PhotoGalleryUploader/CollectionSettings/Message=Wiadomość (opt):",
          width = 100,
        },
        f:edit_field {
          value = messageBinding,
          height_in_lines = 3,
          width_in_chars = 40,
          tooltip = LOC "$$$/PhotoGalleryUploader/CollectionSettings/MessageTooltip=Wiadomość dla klienta",
        },
      },
    },
  }

  return view
end

function dialog.refreshGalleries(collectionSettings)
  LrFunctionContext.callAsyncFunction(function(context)
    local client = Config.createClient()
    if not client then return end

    local success, galleries = client:getGalleries()

    if success then
      collectionSettings.galleries_list = galleries
      LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Success=Success", LOC("$$$/PhotoGalleryUploader/Success/TriedLoaded=Wczytano ^1 galerii", #galleries), "info")
    else
      LrDialogs.message(LOC "$$$/PhotoGalleryUploader/Error=Error", LOC("$$$/PhotoGalleryUploader/Error/FailedLoadGalleries=Nie udało się wczytać galerii: ^1", galleries), "warning")
    end
  end)
end

return dialog
