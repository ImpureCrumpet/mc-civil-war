#!/bin/bash
# Helper script to update versions-config.json with version information
# Usage: ./scripts/update-versions-config.sh <mc_version> <yarn_mappings> <fabric_version>
# Example: ./scripts/update-versions-config.sh 1.21.8 "1.21.8+build.1" "0.130.0+1.21.8"

set -e

MC_VERSION="${1}"
YARN_MAPPINGS="${2}"
FABRIC_VERSION="${3}"

if [ -z "$MC_VERSION" ] || [ -z "$YARN_MAPPINGS" ] || [ -z "$FABRIC_VERSION" ]; then
    echo "Usage: $0 <mc_version> <yarn_mappings> <fabric_version>"
    echo "Example: $0 1.21.8 \"1.21.8+build.1\" \"0.130.0+1.21.8\""
    echo ""
    echo "To find versions, visit: https://fabricmc.net/develop"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSIONS_CONFIG="${SCRIPT_DIR}/versions-config.json"

if [ ! -f "$VERSIONS_CONFIG" ]; then
    echo "❌ Error: versions-config.json not found"
    exit 1
fi

# Update the JSON file using jq
TEMP_FILE=$(mktemp)
jq --arg version "$MC_VERSION" \
   --arg yarn "$YARN_MAPPINGS" \
   --arg fabric "$FABRIC_VERSION" \
   '.[$version].yarn_mappings = $yarn | .[$version].fabric_version = $fabric' \
   "$VERSIONS_CONFIG" > "$TEMP_FILE"

mv "$TEMP_FILE" "$VERSIONS_CONFIG"

echo "✅ Updated versions-config.json for $MC_VERSION:"
echo "   yarn_mappings: $YARN_MAPPINGS"
echo "   fabric_version: $FABRIC_VERSION"



