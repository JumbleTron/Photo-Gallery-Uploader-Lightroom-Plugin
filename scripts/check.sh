#!/bin/bash
# Code quality check script - runs locally same checks as GitHub Actions

set -e

RESET='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'

echo -e "${YELLOW}=== Photo Gallery Uploader - Code Quality Checks ===${RESET}\n"

# Check if tools are installed
check_tool() {
  if ! command -v $1 &> /dev/null; then
    echo -e "${RED}❌ $1 not found. Install it first:${RESET}"
    echo "   $2"
    exit 1
  fi
}

# 1. Lua Syntax Check
echo -e "${YELLOW}[1/4] Checking Lua Syntax...${RESET}"
check_tool "luac" "brew install lua (macOS) or apt-get install lua5.4 (Ubuntu)"

SYNTAX_ERRORS=0
while IFS= read -r file; do
  if ! luac -p "$file" 2>/dev/null; then
    SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
    echo -e "${RED}  ✗ $file${RESET}"
  fi
done < <(find PhotoGalleryUploader.lrplugin -name "*.lua" -type f; echo "PhotoGalleryUploader.lrplugin/Info.lua"; echo "PhotoGalleryUploader.lrplugin/Metadata.lua")

if [ $SYNTAX_ERRORS -eq 0 ]; then
  echo -e "${GREEN}✅ All files have valid Lua syntax${RESET}\n"
else
  echo -e "${RED}❌ Found $SYNTAX_ERRORS files with syntax errors${RESET}\n"
  exit 1
fi

# 2. Luacheck Linting
echo -e "${YELLOW}[2/4] Running Luacheck (linter)...${RESET}"

if command -v luacheck &> /dev/null; then
  if luacheck PhotoGalleryUploader.lrplugin/lua/ \
      --globals LOC import export \
      --no-undefined-globals \
      --config .luacheckrc; then
    echo -e "${GREEN}✅ Luacheck passed${RESET}\n"
  else
    echo -e "${RED}❌ Luacheck found issues${RESET}\n"
    exit 1
  fi
else
  echo -e "${YELLOW}⚠️  Luacheck not installed (optional)${RESET}"
  echo -e "${YELLOW}Install with: luarocks install luacheck${RESET}\n"
fi

# 3. StyLua Format Check
echo -e "${YELLOW}[3/4] Checking code formatting with StyLua...${RESET}"

if command -v stylua &> /dev/null; then
  if stylua --check PhotoGalleryUploader.lrplugin/lua/; then
    echo -e "${GREEN}✅ Code formatting is correct${RESET}\n"
  else
    echo -e "${RED}❌ Code formatting issues found${RESET}"
    echo -e "${YELLOW}Run 'stylua PhotoGalleryUploader.lrplugin/lua/' to auto-fix${RESET}\n"
    exit 1
  fi
else
  echo -e "${YELLOW}⚠️  StyLua not installed (optional)${RESET}"
  echo -e "${YELLOW}Install with: cargo install stylua${RESET}\n"
fi

# 4. Info.lua references
echo -e "${YELLOW}[4/4] Checking Info.lua file references...${RESET}"

FILE_ERRORS=0
while IFS= read -r file; do
  if [ ! -z "$file" ]; then
    full_path="PhotoGalleryUploader.lrplugin/$file"
    if [ ! -f "$full_path" ]; then
      FILE_ERRORS=$((FILE_ERRORS + 1))
      echo -e "${RED}  ✗ Missing: $full_path${RESET}"
    fi
  fi
done < <(grep 'file = "' PhotoGalleryUploader.lrplugin/Info.lua | cut -d'"' -f2)

if [ $FILE_ERRORS -eq 0 ]; then
  echo -e "${GREEN}✅ All file references are valid${RESET}\n"
else
  echo -e "${RED}❌ Found $FILE_ERRORS missing file references${RESET}\n"
  exit 1
fi

# All checks passed
echo -e "${GREEN}════════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}✅ ALL CHECKS PASSED!${RESET}"
echo -e "${GREEN}════════════════════════════════════════════════════════${RESET}\n"
