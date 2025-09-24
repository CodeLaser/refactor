#!/bin/bash
# get-prerelease.sh - Download latest pre-release JAR and Docker image for testing

get_prerelease() {
    local GITHUB_REPO RELEASES_INFO JAR_RELEASE JAR_VERSION JAR_URL DOCKER_RELEASE DOCKER_VERSION DOCKER_URL

    # Configuration
    GITHUB_REPO="CodeLaser/refactor"

    # Check if jq is installed
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required but not installed." >&2
        echo "Install with: apt install jq  or  brew install jq" >&2
        exit 1
    fi

    echo "Fetching latest JAR and Docker releases..." >&2

    # Get all releases
    RELEASES_INFO=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases")

    # Find latest release with JAR asset
    JAR_RELEASE=$(echo "$RELEASES_INFO" | tr '\000-\037' ' ' | jq -r '.[] | select(.draft == false and (.assets[] | .name | endswith(".jar"))) | @base64' | head -1)
    if [ -z "$JAR_RELEASE" ] || [ "$JAR_RELEASE" = "null" ]; then
        echo "No JAR found in any release" >&2
        exit 1
    fi

    JAR_VERSION=$(echo "$JAR_RELEASE" | base64 -d | jq -r '.tag_name')
    JAR_URL=$(echo "$JAR_RELEASE" | base64 -d | jq -r '.assets[] | select(.name | endswith(".jar")) | .browser_download_url' | head -1)
    echo "Found latest JAR: $JAR_VERSION" >&2

    # Find latest release with Docker asset
    DOCKER_RELEASE=$(echo "$RELEASES_INFO" | tr '\000-\037' ' ' | jq -r '.[] | select(.draft == false and (.assets[] | .name | test("-docker\\.tar(\\.gz)?$"))) | @base64' | head -1)
    if [ -z "$DOCKER_RELEASE" ] || [ "$DOCKER_RELEASE" = "null" ]; then
        echo "No Docker image found in any release" >&2
        DOCKER_VERSION=""
        DOCKER_URL=""
    else
        DOCKER_VERSION=$(echo "$DOCKER_RELEASE" | base64 -d | jq -r '.tag_name')
        DOCKER_URL=$(echo "$DOCKER_RELEASE" | base64 -d | jq -r '.assets[] | select(.name | test("-docker\\.tar(\\.gz)?$")) | .browser_download_url' | head -1)
        echo "Found latest Docker: $DOCKER_VERSION" >&2
    fi

    # Use JAR version as primary version for backward compatibility
    VERSION="$JAR_VERSION"

    # Download JAR if not present
    if [ ! -f "refactor-$JAR_VERSION.jar" ]; then
        echo "Downloading JAR from: $JAR_URL" >&2
        curl -L -o "refactor-$JAR_VERSION.jar" "$JAR_URL" >&2
        echo "Downloaded: refactor-$JAR_VERSION.jar" >&2
    else
        echo "JAR version $JAR_VERSION already present" >&2
    fi

    # Download and load Docker image if available and Docker is installed
    if command -v docker >/dev/null 2>&1; then
        if [ -n "$DOCKER_URL" ] && [ "$DOCKER_URL" != "null" ]; then
            # Always download fresh Docker image (ignore local cache)
            echo "Downloading latest Docker image..." >&2
            DOCKER_FILE="refactor-mcp-$DOCKER_VERSION-docker.tar.gz"
            curl -L -o "$DOCKER_FILE" "$DOCKER_URL" >&2
            echo "Loading Docker image..." >&2
            # Remove any existing local images first to ensure fresh load
            docker images -q refactor-mcp | xargs -r docker rmi -f 2>/dev/null || true
            if [[ "$DOCKER_FILE" == *.gz ]]; then
                gunzip -c "$DOCKER_FILE" | docker load >&2
            else
                docker load -i "$DOCKER_FILE" >&2
            fi
            rm -f "$DOCKER_FILE"
            echo "Docker image loaded: refactor-mcp:$DOCKER_VERSION" >&2
        else
            echo "No Docker image found in any release" >&2
        fi
    else
        echo "Docker not installed, skipping Docker image download" >&2
    fi

    # Return both versions (JAR version first for backward compatibility, then Docker version)
    echo "$JAR_VERSION $DOCKER_VERSION"
}

if [ "${BASH_SOURCE[0]:-$0}" = "${0}" ]; then
    get_prerelease
fi
