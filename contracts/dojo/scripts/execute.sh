#!/bin/bash

# Check if command and profile name are provided
if [ $# -lt 2 ]; then
    echo "Error: Please provide a command and a profile name"
    echo "Usage: $0 <command> <profile_name>"
    echo "Commands: auth, create_game, set_config"
    exit 1
fi

# Get the command and profile name from the command line arguments
COMMAND="$1"
PROFILE_NAME="$2"

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Path to the TOML file
TOML_FILE="$SCRIPT_DIR/../manifests/$PROFILE_NAME/deployment/manifest.toml"

# Check if the TOML file exists
if [ ! -f "$TOML_FILE" ]; then
    echo "Error: TOML file not found at $TOML_FILE"
    exit 1
fi

# Find the address where tag = "nums-actions"
ADDRESS=$(awk '/\[\[contracts\]\]/,/tag = "nums-actions"/ {
    if ($1 == "address" && $2 == "=") {
        gsub(/[",]/, "", $3)
        print $3
        exit
    }
}' "$TOML_FILE")

# Check if address was found
if [ -z "$ADDRESS" ]; then
    echo "Error: Could not find address for tag 'nums-actions'"
    exit 1
fi

# Execute commands based on the provided command
case "$COMMAND" in
    auth)
        echo "Authorizing for profile: $PROFILE_NAME"
        sozo auth grant writer m:Name,$ADDRESS --profile $PROFILE_NAME
        sozo auth grant writer m:Slot,$ADDRESS --profile $PROFILE_NAME
        sozo auth grant writer m:Game,$ADDRESS --profile $PROFILE_NAME
        sozo auth grant writer m:Config,$ADDRESS --profile $PROFILE_NAME
        sozo auth grant writer m:Jackpot,$ADDRESS --profile $PROFILE_NAME
        ;;
    create_game)
        echo "Creating game for profile: $PROFILE_NAME"
        sozo execute $ADDRESS create_game -c 0x1 --profile $PROFILE_NAME
        ;;
    set_config)
        echo "Setting config for profile: $PROFILE_NAME"
        sozo execute $ADDRESS set_config -c 0,0,20,1000,0,1 --profile $PROFILE_NAME
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'"
        echo "Available commands: auth, create_game, set_config"
        exit 1
        ;;
esac

echo "Command '$COMMAND' executed successfully with address: $ADDRESS for profile: $PROFILE_NAME"