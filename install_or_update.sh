#!/bin/bash

EULA_FILE="EULA.txt"
echo "Start installation of Refactor server"

# Function to display EULA
display_eula() {
    clear
    echo "========================================"
    echo "  END USER LICENSE AGREEMENT"
    echo "  BETA SOFTWARE - NO WARRANTY"
    echo "========================================"
    echo ""
    
    # Check if EULA file exists
    if [ ! -f "$EULA_FILE" ]; then
        echo "ERROR: EULA file not found at $EULA_FILE"
        exit 1
    fi
    
    # Display EULA with pagination
    if command -v cat >/dev/null 2>&1; then
        cat "$EULA_FILE"
    elif command -v more >/dev/null 2>&1; then
        more "$EULA_FILE"
    else
        cat "$EULA_FILE"
        echo ""
        echo "Press Enter to continue..."
        read
    fi
}

# Function to get user acknowledgment
get_acknowledgment() {
    echo ""
    echo "========================================"
    echo "IMPORTANT: Please read the above EULA carefully."
    echo ""
    echo "This is BETA software provided WITHOUT WARRANTY."
    echo "By accepting, you acknowledge:"
    echo "  - This software may contain bugs and errors"
    echo "  - No warranty or support is provided"
    echo "  - You use this software at your own risk"
    echo "========================================"
    echo ""
    
    while true; do
        read -p "Do you accept the terms of the EULA? (yes/no): " response
        
        case "$response" in
            [Yy][Ee][Ss]|[Yy])
                echo ""
                echo "EULA accepted. Proceeding with installation..."
                return 0
                ;;
            [Nn][Oo]|[Nn])
                echo ""
                echo "EULA not accepted. Installation cancelled."
                exit 1
                ;;
            *)
                echo "Please answer 'yes' or 'no'."
                ;;
        esac
    done
}

# Display EULA and get acknowledgment
mkdir -p logs
INSTALL_LOG="logs/install.log"

# Check if EULA was already accepted
if [ -f "$INSTALL_LOG" ] && grep -q "EULA accepted by user" "$INSTALL_LOG"; then
    echo "EULA previously accepted on: $(grep "EULA accepted by user" "$INSTALL_LOG" | tail -1 | cut -d: -f1-5)"
    echo "Skipping EULA display..."
else
    # Display EULA and get acknowledgment
    display_eula
    get_acknowledgment
    echo "$(date): EULA accepted by user" >> $INSTALL_LOG
fi


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

application_properties="config/application.yml"

if [ ! -f "$application_properties" ]; then 
    echo "Writing $application_properties; you may want to edit the Ollama properties for docstring use and generation"
    cat > $application_properties << EOF
micronaut:
    server:
        port: ${java_rest_port}
llm:
    docstring:
        modelName: gpt-oss:latest
        provider: ollama
        baseUrl: http://localhost:11434
        prompt: |
            You are given the Java source code of one or more classes.
            Your task is to generate concise, plain-text explanations of what each class does.
            Input Format:
            The input will consist of one or more Java classes.
            Each class is clearly delineated using the following markers:
            ### BEGIN CLASS: <ClassName>
            <Java source code for this class>
            ### END CLASS: <ClassName>
            For very large methods, instead of full method bodies, only a list of invoked method names may be shown. 
            Example:
            public void processOrder(Order order) {
                // calls: validateOrder, calculateTotal, saveOrder, notifyCustomer
            }
            Output Format:
            For each class, produce a short, human-readable explanation of what the class is and what it does.
            Delineate your output with the following markers:
            ### BEGIN SUMMARY: <ClassName>
            <one or two concise paragraphs explaining the class>
            ### END SUMMARY: <ClassName>
            Requirements:
            - Focus only on the class as a whole
            - Explain its main purpose, responsibilities, and role in the system.
            - Mention if it represents a concept/entity, manages data, coordinates logic, or provides utilities.
            Conciseness:
            - 2–5 sentences maximum per class.
            - avoid repeating method-level details unless they are central to the class’s purpose.
            Abstraction Level:
            - Summarize intent, not implementation.
            If method bodies are replaced with call lists, infer class purpose from the invoked methods.
            Plain Text Only! Do not use JavaDoc (/** ... */) or code formatting.
            Output should be natural text, suitable for embeddings and semantic comparison.
            Example:
            Input:
            ### BEGIN CLASS: OrderService
            public class OrderService {
                public void processOrder(Order order) {
                    // calls: validateOrder, calculateTotal, saveOrder, notifyCustomer
                }
                public double calculateTotal(Order order) {
                    // ...
                }
            }
            ### END CLASS: OrderService
            Output:
            ### BEGIN SUMMARY: OrderService
            The OrderService class is responsible for handling the end-to-end processing of customer orders.  
            It validates incoming orders, calculates the total cost, persists the order to storage, and ensures that customers are notified.  
            This class centralizes core order-management logic in the system.
            ### END SUMMARY: OrderService
            End of example. Now comes the real classes to examine.
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
version_output=$(get_prerelease | tail -n 1)
jar_version=$(echo "$version_output" | cut -d' ' -f1)
docker_version=$(echo "$version_output" | cut -d' ' -f2)

# Use jar version as primary version for backward compatibility
version="$jar_version"
#debug echo "Latest JAR version: '$jar_version', Docker version: '$docker_version'"

##### ensure other directories 

echo "Ensuring directories "
echo "  ./projects    here you link in your Java project"
echo "  ./work        managed by the Java server"
echo "  ./logs        log of the Java server and license manager"
mkdir -p projects work logs

##### write or update Docker environment configuration #####

docker_env_file="config/docker.env"

echo "Writing Docker environment configuration to $docker_env_file"
cat > $docker_env_file << EOF
# Docker environment configuration for refactor-mcp
# Container binding (internal ports - let container use defaults)
MCP_HOST=0.0.0.0
MCP_PORT=8080
UI_HOST=0.0.0.0
UI_PORT=8081
CONFIGURE_MCP_PORT=8082
MCP_PATH=/mcp
# External service URLs (container to host communication)
REFACTOR_REST_URL=http://host.docker.internal:${java_rest_port}
SWAGGER_URL=http://host.docker.internal:${java_rest_port}
# External URLs for AI client access (if container supports these)
EXTERNAL_MCP_URL=http://localhost:${mcp_port}
EXTERNAL_UI_URL=http://localhost:${ui_port}
EXTERNAL_CONFIGURE_URL=http://localhost:${configure_port}
EOF

##### write or update start scripts #####

# Java server start script
java_start_file="start-java.sh"
jar_file="refactor-$jar_version.jar"

echo "Writing Java server start script: $java_start_file"
cat > $java_start_file << EOF
#!/bin/bash
echo "Starting Java REST server on port ${java_rest_port}..."
java -Xmx4G -Dmicronaut.config.files=file:$application_properties -jar $jar_file
EOF
chmod +x $java_start_file

# Docker start script
docker_start_file="start-mcp.sh"

echo "Writing Docker start script: $docker_start_file"
cat > $docker_start_file << EOF
#!/bin/bash
echo "Starting Docker container with MCP server and React UI..."

# Stop existing container if running
docker rm -f refactor-mcp 2>/dev/null || true

# Use the correct Docker version that was downloaded
if [ -n "$docker_version" ] && [ "$docker_version" != "null" ] && [ "$docker_version" != "" ]; then
    IMAGE_TAG="$docker_version"
    echo "Using Docker image version: $docker_version"
else
    echo "Warning: No Docker version available, trying latest..."
    IMAGE_TAG="latest"
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
echo "Starting complete refactor system (Docker + Java)..."

# Start Docker container
echo "Starting Docker container with refactor MCP server and React UI..."
./$docker_start_file

# Start Java server in foreground
echo "Starting Java REST server..."
./$java_start_file 
EOF
chmod +x $combined_start_file

# Stop script
stop_file="stop-mcp.sh"

echo "Writing stop script: $stop_file"
cat > $stop_file << EOF
#!/bin/bash
echo "Stopping refactor MCP server..."

# Stop Docker container
docker stop refactor-mcp 2>/dev/null && echo "✅ Docker container stopped" || echo "⚠️  Docker container not running"
docker rm refactor-mcp 2>/dev/null || true
echo "🛑 refactor MCP server stopped"
EOF
chmod +x $stop_file

echo "\n\nIMPORTANT"
echo "Ensure that your LLM client knows about the MCP server."
echo "Typically it needs to know the url: http://127.0.0.1:$mcp_port/mcp, and the location of the mcp-proxy binary."
echo "For the Claude Desktop app, the MCP server definition should look like: "
cat << EOF
{
  "globalShortcut": "",
  "mcpServers": {
    "desktop-commander": {
      "command": "npx",
      "args": [
        "@wonderwhy-er/desktop-commander@latest"
      ]
    },
    "codelaser-refactor": {
      "command": "/Users/pvremort/.local/bin/mcp-proxy",
      "args": [
        "--transport=streamablehttp",
        "http://127.0.0.1:$mcp_port/mcp"
      ]
    }
  }
}
EOF
echo "Add the MCP server to Claude Code with a statement similar to:"
echo "  claude mcp add codelaser-refactor -- /absolute/path/to/your/home/.local/bin/mcp-proxy --transport=streamablehttp http://127.0.0.1:$mcp_port/mcp"

