#!/bin/bash
# Build script for creating versioned artifacts
# Usage: ./scripts/build-version.sh <minecraft_version> [mod_version]
# Example: ./scripts/build-version.sh 1.21.7 1.0.1

set -e

MC_VERSION="${1:-1.21.7}"
MOD_VERSION="${2:-1.0.0}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "========================================="
echo "Building Civil War Mod"
echo "Minecraft Version: $MC_VERSION"
echo "Mod Version: $MOD_VERSION"
echo "========================================="

cd "$PROJECT_ROOT"

# Check if we're on the 1.21.x branch
CURRENT_BRANCH=$(git branch --show-current)
if [[ ! "$CURRENT_BRANCH" =~ ^1\.21\. ]]; then
    echo "⚠️  Warning: Not on 1.21.x branch (currently on $CURRENT_BRANCH)"
    echo "   Consider switching to 1.21.x branch for versioned builds"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Backup current gradle.properties
cp gradle.properties gradle.properties.backup

# Update version in gradle.properties (this would need manual editing or a more sophisticated approach)
echo ""
echo "📝 Note: Update gradle.properties with:"
echo "   minecraft_version=$MC_VERSION"
echo "   mod_version=$MOD_VERSION"
echo "   (and corresponding yarn_mappings, fabric_version)"
echo ""
read -p "Press Enter after updating gradle.properties, or Ctrl+C to cancel..."

echo ""
echo "🔨 Building JAR..."
if ./gradlew clean build; then
    echo ""
    echo "✅ Build complete!"
    
    # Find the built JAR
    JAR_FILE=$(find build/libs -name "civil-war-*.jar" ! -name "*-sources.jar" | head -1)
    if [ -n "$JAR_FILE" ]; then
        echo ""
        echo "📦 Built JAR: $JAR_FILE"
        echo ""
        echo "📋 Modrinth Upload Info:"
        echo "   Version Name: $MOD_VERSION (MC $MC_VERSION)"
        echo "   Version Number: ${MOD_VERSION}+mc${MC_VERSION}"
        echo "   Loader: fabric"
        echo "   Environment: client_and_server"
        echo "   Game Versions: $MC_VERSION"
        echo "   JAR File: $JAR_FILE"
    else
        echo "⚠️  Warning: Could not find built JAR file"
    fi
else
    echo "❌ Build failed!"
    mv gradle.properties.backup gradle.properties
    exit 1
fi

# Restore backup
mv gradle.properties.backup gradle.properties

echo ""
echo "✅ Build process complete!"
