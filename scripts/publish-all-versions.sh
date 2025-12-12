#!/bin/bash
# Build and publish versions for all Minecraft 1.21.x versions
# 
# Usage: ./scripts/publish-all-versions.sh [starting_version] [ending_version]
# Example: ./scripts/publish-all-versions.sh 1.21.0 1.21.11
#
# Before running, ensure versions-config.json has correct versions for all target MC versions.
# Use ./scripts/update-versions-config.sh to update individual versions.
# Or visit https://fabricmc.net/develop to find version information.

set -e

START_VERSION="${1:-1.21.0}"
END_VERSION="${2:-1.21.11}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSIONS_CONFIG="${SCRIPT_DIR}/versions-config.json"

cd "$PROJECT_ROOT"

# Load environment variables
if [ -f ".env.local" ]; then
    export $(cat .env.local | grep -v '^#' | xargs)
elif [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

if [ -z "$MODRINTH_TOKEN" ]; then
    echo "❌ Error: MODRINTH_TOKEN not set"
    echo "   Create .env.local with your Modrinth PAT"
    exit 1
fi

if [ ! -f "$VERSIONS_CONFIG" ]; then
    echo "❌ Error: versions-config.json not found"
    exit 1
fi

echo "========================================="
echo "Building and Publishing All 1.21.x Versions"
echo "========================================="
echo "Start Version: $START_VERSION"
echo "End Version: $END_VERSION"
echo ""

# Extract patch numbers
START_PATCH=$(echo "$START_VERSION" | cut -d'.' -f3)
END_PATCH=$(echo "$END_VERSION" | cut -d'.' -f3)

# Validate we're working with 1.21.x
if ! echo "$START_VERSION" | grep -q "^1\.21\." || ! echo "$END_VERSION" | grep -q "^1\.21\."; then
    echo "❌ Error: This script only supports Minecraft 1.21.x versions"
    exit 1
fi

# Array to track results
SUCCESSFUL=()
FAILED=()
SKIPPED=()

# Iterate through all patch versions
for patch in $(seq $START_PATCH $END_PATCH); do
    MC_VERSION="1.21.${patch}"
    MOD_VERSION="1.0.0"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Processing MC $MC_VERSION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Get version config from JSON
    YARN_MAPPINGS=$(jq -r ".\"${MC_VERSION}\".yarn_mappings" "$VERSIONS_CONFIG")
    FABRIC_VERSION=$(jq -r ".\"${MC_VERSION}\".fabric_version" "$VERSIONS_CONFIG")
    LOADER_VERSION=$(jq -r ".\"${MC_VERSION}\".loader_version" "$VERSIONS_CONFIG")
    STATUS=$(jq -r ".\"${MC_VERSION}\".status" "$VERSIONS_CONFIG")
    
    # Check if version is configured
    if [ "$YARN_MAPPINGS" = "TBD" ] || [ "$FABRIC_VERSION" = "TBD" ] || [ "$YARN_MAPPINGS" = "null" ] || [ "$FABRIC_VERSION" = "null" ]; then
        echo "⏭️  Version $MC_VERSION not yet configured (TBD in versions-config.json)"
        echo "   Please update versions-config.json with correct versions from https://fabricmc.net/develop"
        SKIPPED+=("$MC_VERSION (not configured)")
        continue
    fi
    
    # Check if version already exists on Modrinth
    echo "🔍 Checking if version already exists on Modrinth..."
    VERSION_NUMBER="${MOD_VERSION}+mc${MC_VERSION}"
    
    # Get project ID first
    MODRINTH_PROJECT_SLUG="${MODRINTH_PROJECT_ID:-mob-civil-war}"
    if [[ "$MODRINTH_PROJECT_SLUG" == *"-"* ]]; then
        PROJECT_RESPONSE=$(curl -s -X GET \
            -H "Authorization: ${MODRINTH_TOKEN}" \
            -H "User-Agent: ImpureCrumpet/civil-war/1.0.0 (github.com/ImpureCrumpet/mc-civil-war)" \
            "https://api.modrinth.com/v2/project/${MODRINTH_PROJECT_SLUG}")
        ACTUAL_PROJECT_ID=$(echo "$PROJECT_RESPONSE" | jq -r '.id' 2>/dev/null)
    else
        ACTUAL_PROJECT_ID="$MODRINTH_PROJECT_SLUG"
    fi
    
    VERSION_CHECK=$(curl -s -X GET \
        -H "User-Agent: ImpureCrumpet/civil-war/1.0.0 (github.com/ImpureCrumpet/mc-civil-war)" \
        "https://api.modrinth.com/v2/project/${ACTUAL_PROJECT_ID}/version/${VERSION_NUMBER}" 2>/dev/null || echo "")
    
    if echo "$VERSION_CHECK" | grep -q '"id"'; then
        echo "⏭️  Version ${VERSION_NUMBER} already exists on Modrinth, skipping..."
        SKIPPED+=("$MC_VERSION (already published)")
        continue
    fi
    
    # Backup gradle.properties
    cp gradle.properties gradle.properties.backup
    
    # Update gradle.properties for this version
    echo "📝 Updating gradle.properties for $MC_VERSION..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^minecraft_version=.*/minecraft_version=${MC_VERSION}/" gradle.properties
        sed -i '' "s/^yarn_mappings=.*/yarn_mappings=${YARN_MAPPINGS}/" gradle.properties
        sed -i '' "s/^fabric_version=.*/fabric_version=${FABRIC_VERSION}/" gradle.properties
        sed -i '' "s/^loader_version=.*/loader_version=${LOADER_VERSION}/" gradle.properties
        sed -i '' "s/^mod_version=.*/mod_version=${MOD_VERSION}/" gradle.properties
    else
        sed -i "s/^minecraft_version=.*/minecraft_version=${MC_VERSION}/" gradle.properties
        sed -i "s/^yarn_mappings=.*/yarn_mappings=${YARN_MAPPINGS}/" gradle.properties
        sed -i "s/^fabric_version=.*/fabric_version=${FABRIC_VERSION}/" gradle.properties
        sed -i "s/^loader_version=.*/loader_version=${LOADER_VERSION}/" gradle.properties
        sed -i "s/^mod_version=.*/mod_version=${MOD_VERSION}/" gradle.properties
    fi
    
    # Build the version
    echo "🔨 Building for $MC_VERSION..."
    if ! ./gradlew clean build --quiet > /tmp/build-${MC_VERSION}.log 2>&1; then
        echo "❌ Build failed for $MC_VERSION"
        echo "   Check /tmp/build-${MC_VERSION}.log for details"
        FAILED+=("$MC_VERSION (build failed)")
        mv gradle.properties.backup gradle.properties
        continue
    fi
    
    echo "✅ Build successful"
    
    # Publish to Modrinth
    echo "📤 Publishing to Modrinth..."
    PUBLISH_OUTPUT=$(./scripts/publish-modrinth.sh "$MC_VERSION" "$MOD_VERSION" 2>&1)
    
    if echo "$PUBLISH_OUTPUT" | grep -q "🎉 Version published successfully"; then
        echo "✅ Successfully published $MC_VERSION"
        SUCCESSFUL+=("$MC_VERSION")
    else
        echo "❌ Failed to publish $MC_VERSION"
        echo "$PUBLISH_OUTPUT" | tail -10
        FAILED+=("$MC_VERSION (publish failed)")
    fi
    
    # Restore gradle.properties
    mv gradle.properties.backup gradle.properties
done

# Summary
echo ""
echo "========================================="
echo "Summary"
echo "========================================="
echo "✅ Successful: ${#SUCCESSFUL[@]}"
for v in "${SUCCESSFUL[@]}"; do
    echo "   - $v"
done

echo ""
echo "❌ Failed: ${#FAILED[@]}"
for v in "${FAILED[@]}"; do
    echo "   - $v"
done

echo ""
echo "⏭️  Skipped: ${#SKIPPED[@]}"
for v in "${SKIPPED[@]}"; do
    echo "   - $v"
done

if [ ${#FAILED[@]} -gt 0 ]; then
    exit 1
fi



