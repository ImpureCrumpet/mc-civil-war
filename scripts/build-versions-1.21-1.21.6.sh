#!/bin/bash
# Build script for creating releases for Minecraft versions 1.21-1.21.6
# Usage: ./scripts/build-versions-1.21-1.21.6.sh [mod_version]
# Example: ./scripts/build-versions-1.21-1.21.6.sh 1.0.0

set -e

MOD_VERSION="${1:-1.0.0}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Version data for 1.21-1.21.6 (from version-matrix.md)
# Format: MC_VERSION|FABRIC_VERSION|YARN_MAPPINGS
VERSION_LIST=(
    "1.21|0.102.0+1.21|1.21+build.9"
    "1.21.1|0.116.7+1.21.1|1.21.1+build.3"
    "1.21.2|0.106.1+1.21.2|1.21.2+build.1"
    "1.21.3|0.114.1+1.21.3|1.21.3+build.2"
    "1.21.4|0.119.4+1.21.4|1.21.4+build.8"
    "1.21.5|0.128.2+1.21.5|1.21.5+build.1"
    "1.21.6|0.128.2+1.21.6|1.21.6+build.1"
)

echo "========================================="
echo "Building Civil War Mod for MC 1.21-1.21.6"
echo "Mod Version: $MOD_VERSION"
echo "========================================="
echo ""

# Backup original gradle.properties
cp gradle.properties gradle.properties.original

SUCCESSFUL_BUILDS=()
FAILED_BUILDS=()

for VERSION_DATA in "${VERSION_LIST[@]}"; do
    IFS='|' read -r MC_VERSION FABRIC_VERSION YARN_MAPPINGS <<< "$VERSION_DATA"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Processing MC $MC_VERSION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Update gradle.properties
    echo "📝 Updating gradle.properties..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/^minecraft_version=.*/minecraft_version=$MC_VERSION/" gradle.properties
        sed -i '' "s/^yarn_mappings=.*/yarn_mappings=$YARN_MAPPINGS/" gradle.properties
        sed -i '' "s/^fabric_version=.*/fabric_version=$FABRIC_VERSION/" gradle.properties
        sed -i '' "s/^mod_version=.*/mod_version=$MOD_VERSION/" gradle.properties
    else
        # Linux
        sed -i "s/^minecraft_version=.*/minecraft_version=$MC_VERSION/" gradle.properties
        sed -i "s/^yarn_mappings=.*/yarn_mappings=$YARN_MAPPINGS/" gradle.properties
        sed -i "s/^fabric_version=.*/fabric_version=$FABRIC_VERSION/" gradle.properties
        sed -i "s/^mod_version=.*/mod_version=$MOD_VERSION/" gradle.properties
    fi
    
    echo "   minecraft_version=$MC_VERSION"
    echo "   yarn_mappings=$YARN_MAPPINGS"
    echo "   fabric_version=$FABRIC_VERSION"
    echo "   mod_version=$MOD_VERSION"
    
    # Build
    echo ""
    echo "🔨 Building JAR for MC $MC_VERSION..."
    if ./gradlew clean build --quiet; then
        echo "✅ Build successful!"
        
        # Find the built JAR
        JAR_FILE=$(find build/libs -name "civil-war-*.jar" ! -name "*-sources.jar" | head -1)
        if [ -n "$JAR_FILE" ]; then
            # Copy JAR to a versioned location
            VERSIONED_JAR="build/libs/civil-war-${MOD_VERSION}-mc${MC_VERSION}.jar"
            cp "$JAR_FILE" "$VERSIONED_JAR"
            echo "📦 JAR saved: $VERSIONED_JAR"
            
            # Create git tag
            TAG_NAME="v${MOD_VERSION}-mc${MC_VERSION}"
            echo "🏷️  Creating tag: $TAG_NAME"
            git tag -a "$TAG_NAME" -m "Release ${MOD_VERSION} for MC ${MC_VERSION}" 2>/dev/null || {
                echo "⚠️  Tag $TAG_NAME already exists, skipping..."
            }
            
            SUCCESSFUL_BUILDS+=("$MC_VERSION")
        else
            echo "⚠️  Warning: Could not find built JAR file"
            FAILED_BUILDS+=("$MC_VERSION (no JAR found)")
        fi
    else
        echo "❌ Build failed!"
        FAILED_BUILDS+=("$MC_VERSION (build failed)")
    fi
    
    # Restore original gradle.properties for next iteration
    cp gradle.properties.original gradle.properties
done

# Restore original gradle.properties
mv gradle.properties.original gradle.properties

# Summary
echo ""
echo "========================================="
echo "Build Summary"
echo "========================================="
echo "✅ Successful builds: ${#SUCCESSFUL_BUILDS[@]}"
for version in "${SUCCESSFUL_BUILDS[@]}"; do
    echo "   - MC $version"
done

if [ ${#FAILED_BUILDS[@]} -gt 0 ]; then
    echo ""
    echo "❌ Failed builds: ${#FAILED_BUILDS[@]}"
    for version in "${FAILED_BUILDS[@]}"; do
        echo "   - MC $version"
    done
fi

echo ""
echo "📋 Next steps:"
echo "   1. Review the built JARs in build/libs/"
echo "   2. Push tags: git push origin --tags"
echo "   3. Create GitHub releases for each tag"
echo "   4. Upload JARs to Modrinth"
echo ""

