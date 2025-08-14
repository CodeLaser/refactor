

##### write or update config/refactor-ports.txt #####


source find-ports.sh

port_file="config/refactor-ports.txt"
mkdir -p config

if [ -f "$port_file" ]; then
    echo "Reading $port_file; remove this file if you want to scan other ports"

    IFS=' ' read -r rest_port mcp_port react_port < $port_file
    
    # Validate all three ports are numbers
    if [[ "$rest_port" =~ ^[0-9]+$ ]] && [[ "$mcp_port" =~ ^[0-9]+$ ]] && [[ "$react_port" =~ ^[0-9]+$ ]]; then
        echo "REST port :  $rest_port"
        echo "MCP port  :  $mcp_port"
        echo "React port:  $react_port"
    else 
        echo "Expected 3 port numbers in $port_file, separated by a space"
        exit 1
    fi
    
else 
    # Use the function and capture the base port
    if base_port=$(find_ports "$1"); then
        rest_port=$base_port
        mcp_port=$((base_port + 1))
        react_port=$((base_port + 2))
        echo "$rest_port $mcp_port $react_port" > "$port_file"
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
micronaut.server.port=${rest_port}
EOF
else
    current_port=$(grep "^micronaut.server.port=" $application_properties | cut -d'=' -f2)
    if [ "$current_port" != "$rest_port" ]; then
        echo "Updating port number in $application_properties"
        sed -i .backup "s/^micronaut.server.port=.*/micronaut.server.port=$rest_port/" $application_properties
    else
        echo "Not updating $application_properties"
    fi
fi

##### get the latest release #####

source get-prerelease.sh
version=$(get_prerelease)
#debug echo "Latest version: '$version'"

##### write or update ./start.sh #####

start_file="start.sh"
jar_file="refactor-$version.jar"

if [ ! -f "$start_file" ]; then
    echo "Writing $start_file; you may want to adjust the memory limit, depending on the size of your project(s)"
    cat > $start_file << EOF
java -Xmx4G -Dmicronaut.config.files=file:$application_properties  -jar $jar_file
EOF
    chmod +x $start_file
else
    current_version=$(grep "java" $start_file | sed  's/.*-\([v0-9][^.]*\.[^.]*\.[^.]*\)\.jar.*/\1/' )
    #debug echo "Current version: '$current_version'"
    if [ "$current_version" != "$version" ]; then
        echo "Updating version number in $start_file"
        sed -i .backup "s/refactor-[0-9.]*\.jar/refactor-$version.jar/" $start_file
    else
        echo "Not updating $start_file"
    fi
fi
