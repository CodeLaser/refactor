

##### write or update config/refactor-ports.txt #####


source find-ports.sh

port_file="config/refactor-ports.txt"
mkdir -p config

if [ -f "$port_file" ]; then
    echo "Reading $port_file; remove this file if you want to scan other ports"

    IFS=' ' read -r java_rest_port mcp_port ui_port configure_port < $port_file
    
    # Validate all four ports are numbers
    if [[ "$java_rest_port" =~ ^[0-9]+$ ]] && [[ "$mcp_port" =~ ^[0-9]+$ ]] && [[ "$ui_port" =~ ^[0-9]+$ ]] && [[ "$configure_port" =~ ^[0-9]+$ ]]; then
        echo "Java REST port:     $java_rest_port"
        echo "MCP port:           $mcp_port"
        echo "UI port:            $ui_port"
        echo "Configure port:     $configure_port"
    else 
        echo "Expected 4 port numbers in $port_file, separated by spaces"
        exit 1
    fi
    
else 
    # Use the function and capture the base port
    if base_port=$(find_ports "$1"); then
        java_rest_port=$base_port
        mcp_port=$((base_port + 1))
        ui_port=$((base_port + 2))
        configure_port=$((base_port + 3))
        echo "$java_rest_port $mcp_port $ui_port $configure_port" > "$port_file"
    else
        echo "Failed to find available ports"
        exit 1
    fi
fi

##### write or update config/application.properties #####

application_properties="config/application.properties"

if [ ! -f "$application_properties" ]; then 
    echo "Writing $application_properties; you may want to edit the Ollama properties for docstring use and generation"
    cat > $application_properties << EOF
llm.docstringModelName=llama3.2:latest
llm.docstringProvider=ollama
llm.docstringBaseUrl=http://localhost:11434
micronaut.server.port=${java_rest_port}
EOF
else
    current_port=$(grep "^micronaut.server.port=" $application_properties | cut -d'=' -f2)
    if [ "$current_port" != "$java_rest_port" ]; then
        echo "Updating Java REST port number in $application_properties"
        sed -i .backup "s/^micronaut.server.port=.*/micronaut.server.port=$java_rest_port/" $application_properties
    else
        echo "Not updating $application_properties"
    fi
fi

##### get the latest release #####

source get-prerelease.sh
version=$(get_prerelease)
#debug echo "Latest version: '$version'"

##### write or update Docker environment configuration #####

docker_env_file="config/docker.env"

echo "Writing Docker environment configuration to $docker_env_file"
cat > $docker_env_file << EOF
# Docker environment configuration for refactor-mcp
# External service URLs (container to host communication)
REFACTOR_REST_URL=http://host.docker.internal:${java_rest_port}
SWAGGER_URL=http://host.docker.internal:${java_rest_port}
# External ports for URL generation (passed to container for AI client URLs)
UI_HOST=localhost
UI_PORT=${ui_port}
MCP_HOST=localhost
MCP_PORT=${mcp_port}
CONFIGURE_MCP_HOST=localhost
CONFIGURE_MCP_PORT=${configure_port}
# Container binding (let container use its defaults)
MCP_PATH=/mcp
EOF

##### write or update start scripts #####

# Java server start script
java_start_file="start-java.sh"
jar_file="refactor-$version.jar"

echo "Writing Java server start script: $java_start_file"
cat > $java_start_file << EOF
#!/bin/bash
echo "Starting Java REST server on port ${java_rest_port}..."
java -Xmx4G -Dmicronaut.config.files=file:$application_properties -jar $jar_file
EOF
chmod +x $java_start_file

# Docker start script
docker_start_file="start-docker.sh"

echo "Writing Docker start script: $docker_start_file"
cat > $docker_start_file << EOF
#!/bin/bash
echo "Starting Docker container with MCP server and React UI..."

# Stop existing container if running
docker rm -f refactor-mcp 2>/dev/null || true

# Check if Docker image exists
if ! docker images | grep -q "refactor-mcp.*$version"; then
    echo "Warning: Docker image refactor-mcp:$version not found"
    echo "Available images:"
    docker images | grep refactor-mcp || echo "No refactor-mcp images found"
    echo "Trying to use refactor-mcp:latest..."
    IMAGE_TAG="latest"
else
    IMAGE_TAG="$version"
fi

echo "Using image: refactor-mcp:\$IMAGE_TAG"
echo "Port mappings:"
echo "  MCP server: $mcp_port -> 8080"
echo "  React UI: $ui_port -> 8081" 
echo "  Configure server: $configure_port -> 8082"

# Run Docker container
docker run -d \\
  --name refactor-mcp \\
  -p $mcp_port:8080 \\
  -p $ui_port:8081 \\
  -p $configure_port:8082 \\
  --env-file $docker_env_file \\
  --restart unless-stopped \\
  refactor-mcp:\$IMAGE_TAG

# Check container status
sleep 2
if docker ps | grep -q refactor-mcp; then
    echo "✅ Docker container started successfully"
    echo "🌐 React UI: http://localhost:$ui_port"
    echo "🔧 MCP server: http://localhost:$mcp_port/mcp"
    echo "⚙️  Configure server: http://localhost:$configure_port/mcp-configure"
else
    echo "❌ Failed to start Docker container"
    echo "Container logs:"
    docker logs refactor-mcp
    exit 1
fi
EOF
chmod +x $docker_start_file

# Combined start script
combined_start_file="start-all.sh"

echo "Writing combined start script: $combined_start_file"
cat > $combined_start_file << EOF
#!/bin/bash
echo "Starting complete refactor system (Java + Docker)..."

# Start Java server in background
echo "Starting Java REST server..."
./$java_start_file &
JAVA_PID=\$!
echo "Java server PID: \$JAVA_PID"

# Wait a moment for Java server to start
sleep 5

# Check if Java server is running
if ! ps -p \$JAVA_PID > /dev/null; then
    echo "❌ Java server failed to start"
    exit 1
fi

# Start Docker container
echo "Starting Docker container..."
./$docker_start_file

echo ""
echo "🚀 System started successfully!"
echo "📊 Java REST API: http://localhost:$java_rest_port"
echo "🌐 React UI: http://localhost:$ui_port"
echo "🔧 MCP server: http://localhost:$mcp_port/mcp"
echo "⚙️  Configure server: http://localhost:$configure_port/mcp-configure"
echo ""
echo "To stop:"
echo "  Java server: kill \$JAVA_PID"
echo "  Docker: docker stop refactor-mcp"
echo "  Both: ./stop-all.sh"

# Save Java PID for stopping later
echo \$JAVA_PID > config/java.pid
EOF
chmod +x $combined_start_file

# Stop script
stop_file="stop-all.sh"

echo "Writing stop script: $stop_file"
cat > $stop_file << EOF
#!/bin/bash
echo "Stopping refactor system..."

# Stop Docker container
docker stop refactor-mcp 2>/dev/null && echo "✅ Docker container stopped" || echo "⚠️  Docker container not running"
docker rm refactor-mcp 2>/dev/null || true

# Stop Java server
if [ -f config/java.pid ]; then
    JAVA_PID=\$(cat config/java.pid)
    if ps -p \$JAVA_PID > /dev/null 2>&1; then
        kill \$JAVA_PID && echo "✅ Java server stopped (PID: \$JAVA_PID)"
    else
        echo "⚠️  Java server not running (PID: \$JAVA_PID)"
    fi
    rm -f config/java.pid
else
    echo "⚠️  No Java PID file found"
fi

echo "🛑 System stopped"
EOF
chmod +x $stop_file

# Legacy start.sh for backward compatibility
start_file="start.sh"
echo "Writing legacy start.sh (points to combined start script)"
cat > $start_file << EOF
#!/bin/bash
# Legacy start script - now launches both Java and Docker
echo "Note: This script now starts both Java REST server and Docker container"
echo "Use start-java.sh, start-docker.sh, or start-all.sh for specific components"
echo ""
exec ./start-all.sh
EOF
chmod +x $start_file
