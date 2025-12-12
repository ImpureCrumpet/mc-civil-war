#!/bin/bash
# Fetch available Fabric API and Yarn mappings versions for Minecraft versions
# Usage: ./scripts/fetch-fabric-versions.sh <minecraft_version>
# Example: ./scripts/fetch-fabric-versions.sh 1.21.7

set -e

MC_VERSION="${1}"
if [ -z "$MC_VERSION" ]; then
    echo "Usage: $0 <minecraft_version>"
    echo "Example: $0 1.21.7"
    exit 1
fi

echo "Fetching versions for Minecraft $MC_VERSION..."
echo ""

# Fetch Yarn mappings
echo "Yarn Mappings:"
YARN_VERSIONS=$(curl -s "https://maven.fabricmc.net/net/fabricmc/yarn/" | grep -oP "${MC_VERSION}\+build\.\d+" | sort -V | tail -5)
if [ -z "$YARN_VERSIONS" ]; then
    echo "  ❌ No yarn mappings found"
else
    echo "  Latest: $(echo "$YARN_VERSIONS" | tail -1)"
    echo "  Available:"
    echo "$YARN_VERSIONS" | sed 's/^/    - /'
fi

echo ""
echo "Fabric API:"
# Fabric API versions are harder to parse from HTML, but we can check the pattern
# Fabric API typically follows: 0.X.X+MC_VERSION
FABRIC_API_VERSIONS=$(curl -s "https://maven.fabricmc.net/net/fabricmc/fabric-api/fabric-api/" | grep -oP "0\.\d+\.\d+\+${MC_VERSION}" | sort -V | tail -5)
if [ -z "$FABRIC_API_VERSIONS" ]; then
    echo "  ⚠️  Could not auto-detect. Check: https://modrinth.com/mod/fabric-api/versions?g=${MC_VERSION}"
    echo "  Or visit: https://fabricmc.net/develop"
else
    echo "  Latest: $(echo "$FABRIC_API_VERSIONS" | tail -1)"
    echo "  Available:"
    echo "$FABRIC_API_VERSIONS" | sed 's/^/    - /'
fi

echo ""
echo "📋 Recommended:"
echo "  Visit https://fabricmc.net/develop for official version recommendations"
echo "  Or check https://modrinth.com/mod/fabric-api/versions?g=${MC_VERSION}"



