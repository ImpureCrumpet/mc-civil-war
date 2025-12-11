#!/bin/bash
# Validation script for checking API/mappings compatibility across Minecraft versions
# Usage: ./scripts/validate-version.sh <minecraft_version>
# Example: ./scripts/validate-version.sh 1.21.7

set -e

MC_VERSION="${1:-1.21.7}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "========================================="
echo "Validating Civil War Mod for MC $MC_VERSION"
echo "========================================="

cd "$PROJECT_ROOT"

# Check if gradle.properties exists
if [ ! -f "gradle.properties" ]; then
    echo "❌ Error: gradle.properties not found"
    exit 1
fi

# Backup current gradle.properties
cp gradle.properties gradle.properties.backup

echo ""
echo "📋 Step 1: Checking version compatibility..."
echo "Visit https://fabricmc.net/develop to verify:"
echo "  - Minecraft: $MC_VERSION"
echo "  - Fabric Loader version"
echo "  - Fabric API version"
echo "  - Yarn mappings version"
echo "  - Loom version support"
echo ""
read -p "Press Enter to continue after verifying versions..."

echo ""
echo "🔍 Step 2: Manual API validation checklist..."
echo "Before building, verify these API constants exist in the target version:"
echo "  - EntityTypeTags.RAIDERS"
echo "  - EntityTypeTags.ILLAGER"
echo "  - EntityTypeTags.SENSITIVE_TO_SMITE"
echo "  - EntityTypeTags.ARTHROPOD"
echo "  - EntityType.SILVERFISH"
echo "  - EntityType.BEE"
echo "  - EntityType.ENDERMITE"
echo ""
echo "The build process will fail if these are missing or renamed."
echo ""

echo ""
echo "🔨 Step 3: Running smoke build..."
if ./gradlew build --quiet; then
    echo "✅ Build successful!"
else
    echo "❌ Build failed! Check errors above."
    mv gradle.properties.backup gradle.properties
    exit 1
fi

echo ""
echo "✅ Validation complete for MC $MC_VERSION"
echo ""
echo "Next steps:"
echo "  1. Update ref/version-matrix.md with validated versions"
echo "  2. Test in-game with a single-player world"
echo "  3. Check logs for mixin application messages"
echo "  4. Verify faction targeting works correctly"

# Restore backup
mv gradle.properties.backup gradle.properties
