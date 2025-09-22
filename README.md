CodeLaser Refactor
==================

## Quick Install

```bash
curl -L -o install_or_update.sh https://raw.githubusercontent.com/CodeLaser/refactor/main/install_or_update.sh
chmod +x install_or_update.sh
./install_or_update.sh
```

This downloads and configures:
- Java REST server (JAR)
- MCP server + React UI (Docker)

## Usage

```bash
# Start everything
./start-all.sh

# Start individual components  
./start-java.sh     # Java REST server only
./start-docker.sh   # Docker container only

# Stop everything
./stop-all.sh
```

## Endpoints

After installation:
- React UI: `http://localhost:PORT+2`
- MCP server: `http://localhost:PORT+1/mcp`
- Java REST API: `http://localhost:PORT`
- Configure server: `http://localhost:PORT+3/mcp-configure`

Ports are auto-allocated starting from 12340.

## Requirements

- `jq`
-  mcp-proxy: 'https://github.com/sparfenyuk/mcp-proxy' 
- `docker` (optional, for MCP server and UI)
- Java 17+ (for REST server)
