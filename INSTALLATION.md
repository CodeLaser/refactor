# CodeLaser Refactor Documentation

This document describes technical aspects of CodeLaser's refactor server related to installation, configuration, and preparing your project for use by the server.

## Download

The installation starting point is the [CodeLaser/refactor](https://github.com/CodeLaser/refactor) GitHub project.
You may have received a clone of this project in the form of a zip file.

## Contact

Please email us at [support@codelaser.io](mailto:support@codelaser.io) for any questions.

## Prerequisites

- **Java 24 or higher** to run the REST server
- **Docker** to run the MCP and UI servers
- **jq** for the installation script
- **mcp-proxy** from [https://github.com/sparfenyuk/mcp-proxy](https://github.com/sparfenyuk/mcp-proxy) to allow applications like Claude Desktop to communicate with the MCP server (stdio → http)

Note that most testing has been done on macOS. The system should run fine on Linux.

## Installation

NOTE: This directory can also be found at [https://github.com/CodeLaser/refactor](https://github.com/CodeLaser/refactor).

Run the installation script, which will guide you through:
 - Accepting the EULA (End User License Agreement)
 - Choosing 4 free ports from a range that you can set yourself
 - Obtaining the latest JAR for the REST server
 - Loading the latest Docker image for the MCP server and UI server
 - Writing out configuration files in the `./config` directory
 - Writing out start and stop scripts in the current directory
 - Ensuring the existence of `./projects`, `./logs`, and `./work` directories

Feel free to re-run this script to check for updates—it will not overwrite any changes you make to the configuration, work, or project directories.

## Starting and Stopping the Servers

### Starting the Servers

The `start-all.sh` script starts both the Docker servers and the Java server using the individual scripts `start-java.sh` and `start-mcp.sh`.

Either can be stopped or started independently of each other—there is no required order.

### Java Server Options

- **Heap memory**: 4GB is fine for smaller projects; a 3 million line project will need 24GB
- **Configuration**: `-Dmicronaut.config.files=file:config/application.yml` for user-definable properties

### Stopping the Servers

- The MCP server can be stopped using the `stop-mcp.sh` script, which uses the `docker stop` command
- The REST server can be stopped using the `exit` command in the command line

## Connecting LLM Applications to the MCP Server

Note the (external) port number used by the MCP server. In the following examples, it is 12341.

### Claude Desktop

Edit the file that contains MCP server definitions. The result should look like:

```json
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
        "http://127.0.0.1:12341/mcp"
      ]
    }
  }
}
```

(The `desktop-commander` entry is optional and shown only as an example.)

### Claude Code

If you already have the MCP server installed in Claude Desktop, simply run:

```bash
claude mcp add-from-claude-desktop
```

Otherwise, edit and run the following command:

```bash
claude mcp add codelaser-refactor -- /absolute/path/to/your/home/.local/bin/mcp-proxy --transport=streamablehttp http://127.0.0.1:12341/mcp
```

Ensure that `mcp-proxy` can be found and that the port number is correct.

## Directory Structure

### Projects Directory

The `./projects` directory is monitored by the server. Any symlink to a Java project will be recognized as a possible project.

Example:

```bash
cd ./projects
ln -s ~/git/myproject
ln -s ~/git2/myproject myproject2
```

This is sufficient for the Refactor server to know the name (the name of the link) and the location (the target of the link) of these two projects.

### Work Directory

The `./work` directory is used by the Refactor server to store:
- Project configuration (`project.yml`)
- Generated details (`build.javac.txt`, `build.inputConfiguration.yml`)

These are stored in a directory with the name of the symbolic link in `./projects`.

### Logs Directory

The `./logs` directory contains:
- Main log file: `application.log`
- Separate log file detailing all activity related to activating and validating the license key
- Separate log file to avoid accepting the license agreement multiple times

### Config Directory

Files in the `./config` directory are system-wide configurations, independent of your projects.

## The Refactor Server's Command Line

The command line has three modes: **main**, **configure**, and **select**.

### Main Mode

The starting mode. Available commands:

- `activate-license-key` — Activate the license key
- `add-project` — Add a project. This command simple adds a symbolic link in `./projects`
- `remove-project` — Remove a project. This command simply removes a symbolic link from `./projects`, and optionally removes the `work/<projectName>` directory.
- `list` — Show the current projects linked in `./projects`
- `exit` — Exit the command line **and stop the server**
- `configure <project>` — Move to configuration mode
- `select <project>` — Move to select mode

### Configuration Mode

Configure your project for use by the Refactor server. Exit only by using:
- `save` — Save changes and exit
- `cancel` — Drop changes and exit

The default configuration procedure consists of two steps:

1. `discover` — Try to discover the value of some configuration properties
2. `build-input-configuration` — Start a multi-step process to build the input configuration for your project

Additional commands:

- `set` — Individually set the value of any property
- `show` — Shows the values of the properties
- `run-analyzer` — Test-run the analyzer

### Select Mode

Run Refactor server commands on the command line. Exit this mode using the `exit` command.

Notable command:
- `update-docstrings` — Start docstring generation

## Different Java Versions

The Refactor server itself needs **Java 24 or higher** to run. Its JARs have been compiled with bytecode that cannot be read by older JDKs.

Many projects, however, cannot be built with Java version 24 or 25. They accept a range of versions such as 17-21 or even 8-11.

### Example: Gson Project

The Gson open-source project builds with Java 21 but refuses to build with Java 23 and higher. Its build system is Maven, so simply setting the `JAVA_HOME` environment variable to point to JDK 21 ensures that when the refactor server tells the shell to execute `mvn compile`, this is the JDK used by the build system.

On macOS, set `JAVA_HOME` with:

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 21)  # bash, zsh
set -x JAVA_HOME (/usr/libexec/java_home -v 25)   # fish
```

### Java Modules

A second consideration is the origin of the Java modules loaded by the refactor server as part of parsing your project. In many cases, there is sufficient backward compatibility in the JDK for the user not to worry. The Java modules of JDK 24 or 25 used to run the server are then used.

If a dedicated version is required: the input configuration has a field called `alternativeJREDirectory` which you can set (for now, by hand, in the `build.inputConfiguration.json` file). If non-empty, Java modules will be loaded from this directory + `/jmods`.

## Configuration of a Project

For the refactor server to parse the sources of your project, it must have access to:
- All the sources
- The library dependencies of the project
- If the project consists of multiple sub-projects, the relation between these sub-projects

Typically, this information is encoded in a build system such as Ant, Maven, or Gradle. The build system composes the correct arguments to the Java compiler to compile your sources and build your library JARs and executables.

### Build System Approach

The refactor server does not try to parse build files. Instead, it asks the user to provide sufficient information to run the whole compilation process in debug mode. In debug mode, the details of the `javac` command calls are revealed. The user must provide a means of grepping these commands from the debug log. This is straightforward for Maven and Gradle, and most likely possible for other build systems.

The refactor server then analyzes the `javac` commands and builds an input configuration for the parser from these commands. It constructs proper names for the different source sets and assigns library dependencies to each of them.

### Maven Example

For Maven, the following input is usually sufficient:

```bash
build.clean_command: mvn clean
build.compile_debug_command: mvn -Dmaven.build.cache.enabled=false compile test-compile -X
build.compile_debug_pattern: \[DEBUG] (-d (.+))
```

- The `clean` command ensures that the `compile_debug` command will compile all files
- The `-X` flag activates debug mode
- The `pattern` extracts the `javac` commands

### Gradle Example

For standard Gradle builds, these three properties are set by default to:

```bash
build.clean_command: ./gradlew clean
build.compile_debug_command: ./gradlew compileTestJava --debug --no-build-cache
build.compile_debug_pattern: .+Compiler arguments: (.+)
```

(Note that wrappers are used if they are present; otherwise, the command is assumed to be in the execution path of the shell.)

### Discovery and Configuration

The `discover` terminal command will inspect the project directory and try to recognize the build system. Currently, only Maven and Gradle are recognized. If your build system is not or not correctly recognized, you can set the equivalent clean and compile commands and add a pattern using the `set` command.

### Output Files

After saving the configuration and running `build-input-configuration`, you'll find in the `work/yourproject` directory:

- `build.javac.txt` — The result of the compilation debug process
- `build.inputConfiguration.json` — The serialization of the list of source sets and library dependencies that will be used by the refactor server's parser

### Important Notes

- By default, the JDK modules prefixed with `java.` (such as `java.base`) are loaded. If you need extra Java modules, add them using the `build.extra_jmods` property, then rebuild the input configuration
- Analyzing the `javac` log does not provide information about the recursive dependencies of each library dependency/JAR file. Dependency information is only present for source sets
- Source sets are named based on the destination directory (`-d …`) of the `javac` command. Their names may not be elegant, but they are not overly important
- The locations of JAR files are those provided by the build system:
  - Maven: often in `~/.m2/repository/…`
  - Gradle: often in `~/.gradle/cache/…`
  - Be careful not to remove them during the operation of the refactor server
- The `build.monitor` property holds a list of build files. When any of these change, a rebuild of the input configuration is required. **[Currently inactive, not sufficiently tested.]**

### Git Integration

The refactor server needs your source files to be managed by Git. It keeps track of a Git directory for each source set. These are normally discovered correctly with the `discover` command.

### Example configurations

In the `examples/` directory you find configurations of a selection of open source projects.

## Limitations of the Java Parser

The Java parser has been tested on:
- One 3 million line commercial closed-source project
- Several medium-sized open-source projects:
  - **dubbo**: 4K Java files, 300K lines of code
  - **nacos**: 3.2K Java files, 310K lines of code
  - **conductor**: 0.7K Java files, 175K lines of code
  - **jedis**: 0.8K Java files, 125K lines of code
  - **spring-core**: 1K Java files, 100K lines of code

The weakest point of the parser is type forwarding to lambdas inside method arguments. Crashes can be avoided by simplifying the statement: move lambdas to separate variables.

Note that part of the refactor server parser is open-source: it is the latest iteration of the e2immu project (https://github.com/e2immu), which is in the process of being renamed to "maddi" (modification analyzer for duplication detection and immutability). It has moved to [https://github.com/CodeLaser/maddi](https://github.com/CodeLaser/maddi), please report issues there.

## License Manager

Without a valid license, the refactor server falls back to a default restriction on the number of primary types (Java classes) that can be loaded for many refactor queries and operations. Currently, the restrictions are:

- no license: 100 types
- demo/free license: 1,000 types
- paid license: no limit.

The successful activation of a license (using the 'activate-license-key' command) generates 3 files in the refactor server directory:

- `license-info.yml`: information about the license (expiry date, description, order and product IDs).
- `license-key.enc`: the license key, encrypted. This file is used to periodically validate the license.
- `license-offline.enc`: a cache for a validated license. This allows you to continue using the refactor server when you are offline.

The activation and occasional validation of the licenses are done via a REST call to the 'https://codelaser.io/' domain. Please ensure that your network allows this.

Please contact us at 'support@codelaser.io' for any issues related to licenses. If available, append the `license-info.yml` file.


## Docstrings

Docstrings are textual explanations of a Java type (class, interface, record, etc.) generated by an LLM. The Refactor server allows you to generate them and then use these descriptions to help refactor your code.

A docstring consists of:
- A textual representation
- A number of tags (currently unused)
- An embedding vector of this representation in some embedding model

The embedding vector is used to compute "nearness" of types and "matches" between descriptions and the docstring.

### Embedding Model

The refactor server expects an embedding model running locally. Currently tested is Ollama with the `nomic-embed-text:latest` model.

### Storage Location

The Refactor server expects docstrings to be represented in annotations of the `package-info.java` file of the type's package. This is a compromise between not disturbing the source files yet still having the docstrings tied Java-wise to the classes so that they can follow refactorings.

**Warning**: The current implementation may overwrite your existing `package-info.java` information.

### Generation

Docstrings can be generated from the server's command line using the `update-docstrings` command after selecting your project.

Reliability of local LLM responses is not always high, so you may want to monitor the generation of the docstrings closely. Docstrings are written out per chunk, so you can interrupt and start again. Any docstrings already generated should not be lost.

## Configuration of Docstrings

Two sets of parameters are needed: one for the LLM that generates the docstrings, and one for the embedding model.

### Docstring Generation Configuration

Governed by properties with the `llm.docstring` prefix:

- `modelName`
- `provider`
- `baseUrl`
- `prompt`
- `apiKeyEnvVar`
- `maxInputSize`
- `maxTypesInChunk`

### Embedding Model Configuration

The server has the following defaults:

```
llm.embedding.baseUrl=http://localhost:11434
llm.embedding.modelName=nomic-embed-text:latest
```

### Command Parameters

The `update-docstrings` command has parameters that allow you to override the default values from the `application.yml`/`application.properties` files. It has an `apiKey` parameter that allows you to directly specify the key.

## Generation of Docstrings

The `llm.docstring.prompt` property governs the information sent to the LLM. It is tightly coupled to the LLM: an explanation for `gpt-oss:latest` may not work well with `llama3.2:latest`, and vice versa.

### Annotations Dependency

The `@Docstrings` and `@Docstring` annotations in the `package-info.java` files are read from CodeLaser's `io.codelaser:maddi-support:0.8.2` JAR:

```xml
<!-- https://mvnrepository.com/artifact/io.codelaser/maddi-support -->
<dependency>
    <groupId>io.codelaser</groupId>
    <artifactId>maddi-support</artifactId>
    <version>0.8.2</version>
</dependency>
```

Please add this dependency to your project and make sure to re-run `build-input-configuration`, as these annotations have become part of your project.