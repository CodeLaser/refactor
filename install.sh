#!/bin/bash
# install.sh - Minimal installation script

set -e

# Configuration - Update these for your project
GITHUB_REPO="yourusername/yourproject"
DOCKER_IMAGE="ghcr.io/$GITHUB_REPO"
APP_PORT="8080"
DOCKER_PORT="5432"

echo "Installing $GITHUB_REPO..."

# Check dependencies
command -v java >/dev/null 2>&1 || { echo "Java is required"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "Docker is required"; exit 1; }

# Get latest release info
echo "Fetching latest release..."
RELEASE_INFO=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest")
VERSION=$(echo "$RELEASE_INFO" | grep '"tag_name"' | cut -d'"' -f4)

if [ -z "$VERSION" ]; then
    echo "Failed to get latest version"
    exit 1
fi

echo "Latest version: $VERSION"

# Download JAR
echo "Downloading JAR..."
JAR_URL=$(echo "$RELEASE_INFO" | grep '"browser_download_url".*\.jar"' | cut -d'"' -f4)

if [ -z "$JAR_URL" ]; then
    echo "JAR download URL not found"
    exit 1
fi

curl -L -o "app.jar" "$JAR_URL"

# Pull Docker image
echo "Pulling Docker image..."
docker pull "$DOCKER_IMAGE:latest"

# Create configuration
cat > config.env << EOF
APP_PORT=$APP_PORT
DOCKER_PORT=$DOCKER_PORT
DOCKER_IMAGE=$DOCKER_IMAGE:latest
EOF

# Create run script
cat > run.sh << 'EOF'
#!/bin/bash
source config.env

echo "Starting Docker container..."
docker run -d --name myapp-container -p "$DOCKER_PORT:$DOCKER_PORT" "$DOCKER_IMAGE"

echo "Waiting for container to be ready..."
sleep 5

echo "Starting JAR application..."
java -Dserver.port="$APP_PORT" -jar app.jar
EOF

chmod +x run.sh

echo "Installation complete!"
echo "Run: ./run.sh"