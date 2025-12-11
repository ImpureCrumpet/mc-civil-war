#!/bin/bash
# Helper script to update gradle.properties for a specific Minecraft version
# Usage: ./scripts/update-version.sh <minecraft_version> [mod_version]
# Example: ./scripts/update-version.sh 1.21.7 1.0.1

set -e

MC_VERSION="${1}"
MOD_VERSION="${2:-1.0.0}"

if [ -z "$MC_VERSION" ]; then
    echo "Usage: $0 <minecraft_version> [mod_version]"
    echo "Example: $0 1.21.7 1.0.1"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

if [ ! -f "gradle.properties" ]; then
    echo "❌ Error: gradle.properties not found"
    exit 1
fi

echo "========================================="
echo "Updating gradle.properties for MC $MC_VERSION"
echo "========================================="
echo ""
echo "⚠️  This script will update gradle.properties with:"
echo "   - minecraft_version=$MC_VERSION"
echo "   - mod_version=$MOD_VERSION"
echo ""
echo "📋 You will need to manually update:"
echo "   - yarn_mappings (check https://fabricmc.net/develop)"
echo "   - fabric_version (check https://fabricmc.net/develop)"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Backup current gradle.properties
cp gradle.properties gradle.properties.backup

# Update minecraft_version
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/^minecraft_version=.*/minecraft_version=$MC_VERSION/" gradle.properties
    sed -i '' "s/^mod_version=.*/mod_version=$MOD_VERSION/" gradle.properties
else
    # Linux
    sed -i "s/^minecraft_version=.*/minecraft_version=$MC_VERSION/" gradle.properties
    sed -i "s/^mod_version=.*/mod_version=$MOD_VERSION/" gradle.properties
fi

echo ""
echo "✅ Updated gradle.properties:"
echo "   minecraft_version=$MC_VERSION"
echo "   mod_version=$MOD_VERSION"
echo ""
echo "📝 Next steps:"
echo "   1. Edit gradle.properties to update yarn_mappings and fabric_version"
echo "   2. Run: ./scripts/validate-version.sh $MC_VERSION"
echo "   3. Run: ./scripts/build-version.sh $MC_VERSION $MOD_VERSION"
echo ""
echo "💾 Backup saved as gradle.properties.backup"
