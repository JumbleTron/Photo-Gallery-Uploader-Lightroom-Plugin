-- Luacheck configuration for Photo Gallery Uploader plugin
std = "lua54"

-- Lightroom SDK globals
globals = {
  "LOC",           -- Localization function
  "import",        -- Module import function
}

-- Read-only globals from Lightroom
read_globals = {
  "LrApplication",
  "LrBinding",
  "LrDialogs",
  "LrErrors",
  "LrExportSession",
  "LrFunctionContext",
  "LrHttp",
  "LrPathUtils",
  "LrPrefs",
  "LrProgressScope",
}

-- Allow unused variables starting with underscore
unused_args = false
unused_secondaries = false

-- Max line length (warn only)
max_line_length = 120
max_code_line_length = 120

-- Ignore specific warnings
ignore = {
  "212",  -- Unused arguments
  "411",  -- Line is too long (will be handled by StyLua)
  "412",  -- Line is too long
}

-- Files to exclude
exclude_files = {
  "lua/vendor/*",
  ".git/*",
}

-- Per-file configuration
files["PhotoGalleryUploader.lrplugin/lua/core/"] = {
  globals = { "json" },  -- json library
}
