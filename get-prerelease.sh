#!/bin/bash
# get-prerelease.sh - Download latest pre-release JAR for testing

get_prerelease() {
    local GITHUB_REPO RELEASE_DATA RELEASES_INFO RELEASE_INFO PRERELEASE VERSION JAR_URL

    # Configuration
    GITHUB_REPO="CodeLaser/refactor"

    # Check if jq is installed
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required but not installed." >&2
        echo "Install with: apt install jq  or  brew install jq" >&2
        exit 1
    fi

    echo "Fetching latest pre-release for testing..." >&2

    # Get all releases
    RELEASES_INFO=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases")
    echo "step 1" >&2
    echo "$RELEASES_INFO" > releases.json
    # Find the latest pre-release (not draft) - releases are already sorted by date
    PRERELEASE=$(echo "$RELEASES_INFO"| tr '\000-\037' ' ' | jq -r '.[] | select(.prerelease == true and .draft == false) | {tag_name: .tag_name, assets: .assets} | @base64' | head -1)
    echo "step 2" >&2
    if [ -z "$PRERELEASE" ] || [ "$PRERELEASE" = "null" ]; then
        echo "No pre-releases found. Getting latest stable release..." >&2
        RELEASE_INFO=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest")
        VERSION=$(echo "$RELEASE_INFO" | jq -r '.tag_name')
        JAR_URL=$(echo "$RELEASE_INFO" | jq -r '.assets[] | select(.name | endswith(".jar")) | .browser_download_url' | head -1)
        
        if [ "$VERSION" = "null" ]; then
            echo "No releases found in repository" >&2
            exit 1
        fi
    else
        # Decode and extract info from pre-release
        RELEASE_DATA=$(echo "$PRERELEASE" | base64 -d)
        VERSION=$(echo "$RELEASE_DATA" | jq -r '.tag_name')
        JAR_URL=$(echo "$RELEASE_DATA" | jq -r '.assets[] | select(.name | endswith(".jar")) | .browser_download_url' | head -1)
        echo "Found pre-release: $VERSION" >&2
    fi

    if [ -z "$JAR_URL" ] || [ "$JAR_URL" = "null" ]; then
        echo "No JAR found in release $VERSION" >&2
        echo "Available assets:" >&2
        if [ -n "$PRERELEASE" ] && [ "$PRERELEASE" != "null" ]; then
            echo "$RELEASE_DATA" | jq -r '.assets[].name' >&2
        else
            echo "$RELEASE_INFO" | jq -r '.assets[].name' >&2
        fi
        exit 1
    fi

    echo "Found version: $VERSION" >&2

    if [ ! -f "refactor-$VERSION.jar" ]; then
        echo "Downloading JAR from: $JAR_URL" >&2
        curl -L -o "refactor-$VERSION.jar" "$JAR_URL" >&2

        echo "Downloaded: refactor-$VERSION.jar" >&2
    else
        echo "Latest version $VERSION already present" >&2
    fi
    # return value
    echo $VERSION
}

if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    get_prerelease
fi
