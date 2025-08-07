#!/bin/bash
# get-prerelease.sh - Download latest pre-release JAR for testing

set -e

# Configuration
GITHUB_REPO="CodeLaser/refactor"

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed."
    echo "Install with: apt install jq  or  brew install jq"
    exit 1
fi

echo "Fetching latest pre-release for testing..."

# Get all releases
RELEASES_INFO=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases")

# Find the latest pre-release (not draft) - releases are already sorted by date
PRERELEASE=$(echo "$RELEASES_INFO" | jq -r '.[] | select(.prerelease == true and .draft == false) | {tag_name: .tag_name, assets: .assets} | @base64' | head -1)

if [ -z "$PRERELEASE" ] || [ "$PRERELEASE" = "null" ]; then
    echo "No pre-releases found. Getting latest stable release..."
    RELEASE_INFO=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest")
    VERSION=$(echo "$RELEASE_INFO" | jq -r '.tag_name')
    JAR_URL=$(echo "$RELEASE_INFO" | jq -r '.assets[] | select(.name | endswith(".jar")) | .browser_download_url' | head -1)
    
    if [ "$VERSION" = "null" ]; then
        echo "No releases found in repository"
        exit 1
    fi
else
    # Decode and extract info from pre-release
    RELEASE_DATA=$(echo "$PRERELEASE" | base64 -d)
    VERSION=$(echo "$RELEASE_DATA" | jq -r '.tag_name')
    JAR_URL=$(echo "$RELEASE_DATA" | jq -r '.assets[] | select(.name | endswith(".jar")) | .browser_download_url' | head -1)
    echo "Found pre-release: $VERSION"
fi

if [ -z "$JAR_URL" ] || [ "$JAR_URL" = "null" ]; then
    echo "No JAR found in release $VERSION"
    echo "Available assets:"
    if [ -n "$PRERELEASE" ] && [ "$PRERELEASE" != "null" ]; then
        echo "$RELEASE_DATA" | jq -r '.assets[].name'
    else
        echo "$RELEASE_INFO" | jq -r '.assets[].name'
    fi
    exit 1
fi

echo "Found version: $VERSION"
echo "Downloading JAR from: $JAR_URL"
curl -L -o "refactor-$VERSION.jar" "$JAR_URL"

echo "Downloaded: refactor-$VERSION.jar"
echo "Run with: java -jar refactor-$VERSION.jar"
