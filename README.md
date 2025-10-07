CodeLaser Refactor
==================

## Requirements

- `jq`
- for the mcp servers and UI:
  -  `mcp-proxy`: 'https://github.com/sparfenyuk/mcp-proxy'
  - `docker`
- Java 24+ (for REST server)

## Quick Install

First, run the install_or_update script:

```bash
./install_or_update.sh
```

This downloads and configures:
- Java REST server (JAR)
- MCP server + React UI (Docker)

The script also prints important details on how to connect your LLM client to the MCP server.

## Usage

Either start everything through one script:
```bash
./start-all.sh
```

Or start individual components:
```bash
./start-mcp.sh   # Docker container only
./start-java.sh  # Java REST server only
```
The ```start-java.sh``` script will provide you with a prompt with further instructions for setting up a project.
Setting up a project is required before you can start using CodeLaser tools within your LLM.

Stop everything
```bash
./stop-all.sh
```

## Endpoints

After installation:
- Java REST API: `http://localhost:PORT`
- MCP server: `http://localhost:PORT+1/mcp`
- React UI: `http://localhost:PORT+2`
- Configure server: `http://localhost:PORT+3/mcp-configure`

Ports are auto-allocated starting from 10000.

## Documentation

- `INSTALLATION.md` provides information about installation, and technical information related to configuring your projects.
- `USER_GUIDE.md` shows how you can refactor your project with the MCP server and its companion UI.
- Watch videos at the [CodeLaser's Youtube channel](https://www.youtube.com/@codelaser-refactoring).

## End User License agreement

See `EULA.txt`.
You must agree to this End User License Agreement to use the refactor server software.
