#!/bin/bash
# Build and publish versions 1.21-1.21.6 to Modrinth
# Usage: ./scripts/publish-versions-1.21-1.21.6.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Load environment variables
if [ -f ".env.local" ]; then
    export $(cat .env.local | grep -v '^#' | xargs)
fi

# Ensure MODRINTH_PROJECT_ID is set
export MODRINTH_PROJECT_ID="${MODRINTH_PROJECT_ID:-mob-civil-war}"

MOD_VERSION="1.0.0"
VERSIONS=(
    "1.21|1.21+build.9|0.102.0+1.21"
    "1.21.1|1.21.1+build.3|0.116.7+1.21.1"
    "1.21.2|1.21.2+build.1|0.106.1+1.21.2"
    "1.21.3|1.21.3+build.2|0.114.1+1.21.3"
    "1.21.4|1.21.4+build.8|0.119.4+1.21.4"
    "1.21.5|1.21.5+build.1|0.128.2+1.21.5"
    "1.21.6|1.21.6+build.1|0.128.2+1.21.6"
)

echo "========================================="
echo "Building and Publishing to Modrinth"
echo "Project: $MODRINTH_PROJECT_ID"
echo "========================================="
echo ""

# Backup gradle.properties
cp gradle.properties gradle.properties.original

SUCCESSFUL=()
FAILED=()

for VERSION_DATA in "${VERSIONS[@]}"; do
    IFS='|' read -r MC_VERSION YARN_MAPPINGS FABRIC_VERSION <<< "$VERSION_DATA"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Processing MC $MC_VERSION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Update gradle.properties
    echo "📝 Updating gradle.properties..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^minecraft_version=.*/minecraft_version=$MC_VERSION/" gradle.properties
        sed -i '' "s/^yarn_mappings=.*/yarn_mappings=$YARN_MAPPINGS/" gradle.properties
        sed -i '' "s/^fabric_version=.*/fabric_version=$FABRIC_VERSION/" gradle.properties
        sed -i '' "s/^mod_version=.*/mod_version=$MOD_VERSION/" gradle.properties
    else
        sed -i "s/^minecraft_version=.*/minecraft_version=$MC_VERSION/" gradle.properties
        sed -i "s/^yarn_mappings=.*/yarn_mappings=$YARN_MAPPINGS/" gradle.properties
        sed -i "s/^fabric_version=.*/fabric_version=$FABRIC_VERSION/" gradle.properties
        sed -i "s/^mod_version=.*/mod_version=$MOD_VERSION/" gradle.properties
    fi
    
    echo "   minecraft_version=$MC_VERSION"
    echo "   yarn_mappings=$YARN_MAPPINGS"
    echo "   fabric_version=$FABRIC_VERSION"
    
    # Build
    echo ""
    echo "🔨 Building for $MC_VERSION..."
    if ./gradlew clean build --quiet; then
        echo "✅ Build successful"
        
        # Publish
        echo ""
        echo "📤 Publishing to Modrinth..."
        if ./scripts/publish-modrinth.sh "$MC_VERSION" "$MOD_VERSION" 2>&1 | grep -q "🎉 Version published successfully"; then
            echo "✅ Successfully published $MC_VERSION"
            SUCCESSFUL+=("$MC_VERSION")
        else
            echo "❌ Failed to publish $MC_VERSION"
            FAILED+=("$MC_VERSION")
        fi
    else
        echo "❌ Build failed for $MC_VERSION"
        FAILED+=("$MC_VERSION (build failed)")
    fi
    
    # Restore gradle.properties for next iteration
    cp gradle.properties.original gradle.properties
done

# Restore original gradle.properties
mv gradle.properties.original gradle.properties

# Summary
echo ""
echo "========================================="
echo "Summary"
echo "========================================="
echo "✅ Successful: ${#SUCCESSFUL[@]}"
for v in "${SUCCESSFUL[@]}"; do
    echo "   - MC $v"
done

if [ ${#FAILED[@]} -gt 0 ]; then
    echo ""
    echo "❌ Failed: ${#FAILED[@]}"
    for v in "${FAILED[@]}"; do
        echo "   - $v"
    done
fi

echo ""
echo "📋 View published versions at:"
echo "   https://modrinth.com/mod/$MODRINTH_PROJECT_ID"
echo ""

