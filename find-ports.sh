#!/bin/bash

# Function to check if a port is available. This supposedly works on Mac and Linux
is_port_available() {
    local port=$1
    ! lsof -i -P -n | grep -q ":$port "
}

# Function to find four consecutive available ports
find_available_ports() {
    local base_port=$1
    local java_rest_port=$base_port
    local mcp_port=$((base_port + 1))
    local ui_port=$((base_port + 2))
    local configure_port=$((base_port + 3))
    
    if is_port_available $java_rest_port && is_port_available $mcp_port && is_port_available $ui_port && is_port_available $configure_port; then
        echo "✓ Found available ports:" >&2
        echo "  Java REST server:    $java_rest_port" >&2
        echo "  MCP server:          $mcp_port" >&2
        echo "  React UI:            $ui_port" >&2
        echo "  Configure server:    $configure_port" >&2
        return 0
    else
        echo "✗ Ports $java_rest_port-$configure_port are not all available" >&2
        return 1
    fi
}

find_ports() {
    DEFAULT_PORT=${1:-10000}
    MAX_ATTEMPTS=50
    INCREMENT=10

    # Get base port from user input
    if [ $# -eq 0 ] || [ "$1" == "" ]; then
        echo "Find four consecutive available ports for:" >&2
        echo "  - Java REST server (port N)" >&2
        echo "  - MCP server (port N+1)" >&2
        echo "  - React UI (port N+2)" >&2
        echo "  - Configure server (port N+3)" >&2
        echo >&2
        read -p "Enter starting port (default: $DEFAULT_PORT): " user_input
        BASE_PORT=${user_input:-$DEFAULT_PORT}
    else
        BASE_PORT=$1
    fi

    # Validate that BASE_PORT is a number
    if ! [[ "$BASE_PORT" =~ ^[0-9]+$ ]] || [ "$BASE_PORT" -lt 1024 ] || [ "$BASE_PORT" -gt 65532 ]; then
        echo "Error: Port must be a number between 1024 and 65532" >&2
        exit 1
    fi

    echo "Searching for four consecutive available ports starting from $BASE_PORT..." >&2
    echo >&2

    current_base=$BASE_PORT
    attempts=0

    while [ $attempts -lt $MAX_ATTEMPTS ]; do
        if find_available_ports $current_base; then
            # return the base port, this one writes to stdout instead of >&2 stderr
            echo $current_base
            exit 0
        fi
        
        current_base=$((current_base + INCREMENT))
        attempts=$((attempts + 1))
        
        if [ $attempts -lt $MAX_ATTEMPTS ]; then
            echo "  Trying next range: $current_base-$((current_base + 3))"  >&2
        fi
    done

    echo
    echo "❌ Could not find four consecutive available ports after $MAX_ATTEMPTS attempts"  >&2
    echo "Last range tried: $((current_base - INCREMENT))-$((current_base - INCREMENT + 3))"  >&2
    echo "You may need to:"  >&2
    echo "  1. Choose a different starting port range"  >&2
    echo "  2. Stop some running services"  >&2
    echo "  3. Check for processes using ports in this range"  >&2
    return 1
}