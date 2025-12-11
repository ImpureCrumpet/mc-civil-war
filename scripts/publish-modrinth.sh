#!/bin/bash
# Publish a version to Modrinth using the Modrinth API
# Usage: ./scripts/publish-modrinth.sh <minecraft_version> <mod_version> [changelog_file]
# Example: ./scripts/publish-modrinth.sh 1.21.7 1.0.1 CHANGELOG.md
#
# Requirements:
#   - curl (for API requests)
#   - jq (for JSON parsing) - install with: brew install jq (macOS) or apt-get install jq (Linux)
#   - MODRINTH_TOKEN environment variable or .env file with MODRINTH_TOKEN

set -e

MC_VERSION="${1}"
MOD_VERSION="${2}"
CHANGELOG_FILE="${3:-}"

if [ -z "$MC_VERSION" ] || [ -z "$MOD_VERSION" ]; then
    echo "Usage: $0 <minecraft_version> <mod_version> [changelog_file]"
    echo "Example: $0 1.21.7 1.0.1 CHANGELOG.md"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Load environment variables from .env.local or .env file if they exist
# .env.local takes precedence over .env (for local overrides)
if [ -f ".env.local" ]; then
    export $(cat .env.local | grep -v '^#' | xargs)
elif [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Check for required environment variables
if [ -z "$MODRINTH_TOKEN" ]; then
    echo "❌ Error: MODRINTH_TOKEN not set"
    echo ""
    echo "Please set MODRINTH_TOKEN in one of these ways:"
    echo "  1. Create a .env file (see .env.example)"
    echo "  2. Export as environment variable: export MODRINTH_TOKEN=your_token"
    echo ""
    echo "Get your PAT from: https://modrinth.com/settings/account"
    exit 1
fi

MODRINTH_PROJECT_SLUG="${MODRINTH_PROJECT_ID:-civil-war}"
MODRINTH_API_URL="${MODRINTH_API_URL:-https://api.modrinth.com/v2}"

# If project_id looks like a slug (contains hyphens), look up the actual project ID
# Modrinth API requires base62 ID (8 alphanumeric chars) for project_id in version creation
# Note: Private projects require authentication to look up
if [[ "$MODRINTH_PROJECT_SLUG" == *"-"* ]] || [ ${#MODRINTH_PROJECT_SLUG} -gt 8 ]; then
    echo "🔍 Looking up project ID for slug: $MODRINTH_PROJECT_SLUG"
    PROJECT_RESPONSE=$(curl -s -X GET \
        -H "Authorization: ${MODRINTH_TOKEN}" \
        -H "User-Agent: ImpureCrumpet/civil-war/1.0.0 (github.com/ImpureCrumpet/mc-civil-war)" \
        "${MODRINTH_API_URL}/project/${MODRINTH_PROJECT_SLUG}")
    
    MODRINTH_PROJECT_ID=$(echo "$PROJECT_RESPONSE" | jq -r '.id' 2>/dev/null)
    
    if [ -z "$MODRINTH_PROJECT_ID" ] || [ "$MODRINTH_PROJECT_ID" = "null" ]; then
        echo "❌ Error: Could not find project with slug: $MODRINTH_PROJECT_SLUG"
        echo "   Response: $(echo "$PROJECT_RESPONSE" | jq -r '.error // .description // "Unknown error"' 2>/dev/null || echo "$PROJECT_RESPONSE")"
        echo ""
        echo "   Possible issues:"
        echo "   - Project doesn't exist or slug is incorrect"
        echo "   - Token doesn't have permission to view the project"
        echo "   - Set MODRINTH_PROJECT_ID in .env.local to the actual base62 project ID"
        exit 1
    else
        echo "✅ Found project ID: $MODRINTH_PROJECT_ID"
    fi
else
    # Looks like it's already a base62 ID
    MODRINTH_PROJECT_ID="$MODRINTH_PROJECT_SLUG"
    echo "📋 Using project ID: $MODRINTH_PROJECT_ID"
fi

# Check for required tools
if ! command -v curl &> /dev/null; then
    echo "❌ Error: curl is required but not installed"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq is required but not installed"
    echo "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
    exit 1
fi

# Find the built JAR
JAR_FILE=$(find build/libs -name "civil-war-*.jar" ! -name "*-sources.jar" | head -1)
if [ -z "$JAR_FILE" ]; then
    echo "❌ Error: Could not find built JAR file"
    echo "   Run './gradlew build' first"
    exit 1
fi

echo "========================================="
echo "Publishing to Modrinth"
echo "========================================="
echo "Project ID: $MODRINTH_PROJECT_ID"
echo "Minecraft Version: $MC_VERSION"
echo "Mod Version: $MOD_VERSION"
echo "JAR File: $JAR_FILE"
echo "API URL: $MODRINTH_API_URL"
echo ""

# Read changelog if provided
CHANGELOG=""
if [ -n "$CHANGELOG_FILE" ] && [ -f "$CHANGELOG_FILE" ]; then
    CHANGELOG=$(cat "$CHANGELOG_FILE")
    echo "📝 Using changelog from: $CHANGELOG_FILE"
elif [ -z "$CHANGELOG" ]; then
    CHANGELOG="No code changes, retargeted dependencies for MC $MC_VERSION"
    echo "⚠️  No changelog file provided, using default message"
fi

VERSION_NAME="${MOD_VERSION} (MC ${MC_VERSION})"
VERSION_NUMBER="${MOD_VERSION}+mc${MC_VERSION}"
FILE_PART_NAME="file"

# Create version metadata JSON (properly escaped)
VERSION_DATA=$(jq -n \
  --arg name "$VERSION_NAME" \
  --arg version_number "$VERSION_NUMBER" \
  --arg changelog "$CHANGELOG" \
  --arg mc_version "$MC_VERSION" \
  --arg project_id "$MODRINTH_PROJECT_ID" \
  --arg file_part "$FILE_PART_NAME" \
  '{
    "name": $name,
    "version_number": $version_number,
    "changelog": $changelog,
    "dependencies": [],
    "game_versions": [$mc_version],
    "version_type": "release",
    "loaders": ["fabric"],
    "featured": false,
    "project_id": $project_id,
    "file_parts": [$file_part],
    "primary_file": $file_part,
    "status": "listed"
  }')

echo ""
echo "📤 Creating version and uploading file to Modrinth..."

# Create temporary file for JSON data to avoid shell escaping issues
TEMP_JSON=$(mktemp)
echo "$VERSION_DATA" > "$TEMP_JSON"

# Create version with file upload using multipart/form-data
# Note: Modrinth API requires multipart/form-data with 'data' field containing JSON and file parts
VERSION_RESPONSE=$(curl -s -X POST \
    -H "Authorization: ${MODRINTH_TOKEN}" \
    -H "User-Agent: ImpureCrumpet/civil-war/1.0.0 (github.com/ImpureCrumpet/mc-civil-war)" \
    -F "data=@${TEMP_JSON}" \
    -F "${FILE_PART_NAME}=@${JAR_FILE}" \
    "${MODRINTH_API_URL}/version")

# Clean up temp file
rm -f "$TEMP_JSON"

# Check for errors
if echo "$VERSION_RESPONSE" | grep -q '"error"'; then
    echo "❌ Error creating version:"
    echo "$VERSION_RESPONSE" | jq '.' 2>/dev/null || echo "$VERSION_RESPONSE"
    exit 1
fi

VERSION_ID=$(echo "$VERSION_RESPONSE" | jq -r '.id' 2>/dev/null)

if [ -z "$VERSION_ID" ] || [ "$VERSION_ID" = "null" ]; then
    echo "❌ Error: Could not extract version ID from response"
    echo "Response:"
    echo "$VERSION_RESPONSE" | jq '.' 2>/dev/null || echo "$VERSION_RESPONSE"
    exit 1
fi

echo "✅ Version created and file uploaded successfully"
echo ""
echo "🎉 Version published successfully!"
echo ""
echo "Version Details:"
echo "  Name: $VERSION_NAME"
echo "  Number: $VERSION_NUMBER"
echo "  ID: $VERSION_ID"
echo "  URL: https://modrinth.com/mod/${MODRINTH_PROJECT_ID}/version/${VERSION_NUMBER}"
