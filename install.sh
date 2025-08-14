source find-ports.sh

port_file="refactor-ports.txt"

 if [ -f "$port_file" ]; then
    echo "Reading $port_file; remove this file if you want to scan other ports"

    while IFS='\n' read -r rest_port mcp_port react_port; do
        echo r=$rest_port m=$mcp_port r2=$react_port
    done < $port_file

    # Validate all three ports are numbers
    if [[ "$rest_port" =~ ^[0-9]+$ ]] && [[ "$mcp_port" =~ ^[0-9]+$ ]] && [[ "$react_port" =~ ^[0-9]+$ ]]; then
        echo "REST port :  $rest_port"
        echo "MCP port  :  $mcp_port"
        echo "React port:  $react_port"
    else 
        echo "Not all lines in $port_file represent port numbers."
        exit 1
    fi
    
else 
    # Use the function and capture the base port
    if base_port=$(find_ports "$1"); then
        rest_port=$base_port
        mcp_port=$((base_port + 1))
        react_port=$((base_port + 2))
        cat > "$port_file" << EOF
$rest_port
$mcp_port
$react_port
EOF
    else
        echo "Failed to find available ports"
        exit 1
    fi

fi
