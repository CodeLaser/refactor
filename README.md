CodeLaser Refactor
==================

## Quick Install

```bash
git clone git@github.com:CodeLaser/refactor.git
cd refactor
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
- Java REST API: `http://localhost:PORT`
- MCP server: `http://localhost:PORT+1/mcp`
- React UI: `http://localhost:PORT+2`
- Configure server: `http://localhost:PORT+3/mcp-configure`

Ports are auto-allocated starting from 12340.

## Requirements

- `jq`
- for the mcp servers and UI:
  -  mcp-proxy: 'https://github.com/sparfenyuk/mcp-proxy' 
  - `docker`
- Java 24+ (for REST server)

## Documentation

See `DOCUMENTATION.md` for information about installation, and technical information related to configuring your projects.

Watch videos at the [CodeLaser website](https://codelaser.io).

## End User License agreement

See `EULA.txt`.
You must agree to this End User License Agreement to use the refactor server software.
