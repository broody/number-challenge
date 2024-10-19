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
TOKEN_ADDR="$3"

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Path to the TOML file
TOML_FILE="$SCRIPT_DIR/../manifests/$PROFILE_NAME/deployment/manifest.toml"

# Check if the TOML file exists
if [ ! -f "$TOML_FILE" ]; then
    echo "Error: TOML file not found at $TOML_FILE"
    exit 1
fi

# Find the address where tag = "nums-game_actions"
GAME_ACTIONS_ADDR=$(awk '/\[\[contracts\]\]/,/tag = "nums-game_actions"/ {
    if ($1 == "address" && $2 == "=") {
        gsub(/[",]/, "", $3)
        print $3
        exit
    }
}' "$TOML_FILE")

JACKPOT_ACTIONS_ADDR=0x757277be717167d860501f4eab213a233896dbe4ba37e85c71b46e059135281

if [ -z "$JACKPOT_ACTIONS_ADDR" ]; then
    echo "Error: Could not find address for tag 'nums-jackpot_actions'"
    exit 1
fi

if [ -z "$GAME_ACTIONS_ADDR" ]; then
    echo "Error: Could not find address for tag 'nums-game_actions'"
    exit 1
fi

# Find the WorldContract address
WORLD_ADDR=$(awk '/\[world\]/,/address =/ {
    if ($1 == "address" && $2 == "=") {
        gsub(/[",]/, "", $3)
        print $3
        exit
    }
}' "$TOML_FILE")

# Check if WorldContract address was found
if [ -z "$WORLD_ADDR" ]; then
    echo "Error: Could not find WorldContract address"
    exit 1
fi

# Execute commands based on the provided command
case "$COMMAND" in
    auth)
        echo "Granting authentication for profile: $PROFILE_NAME"
        sozo auth grant writer m:Name,$GAME_ACTIONS_ADDR --profile $PROFILE_NAME --world $WORLD_ADDR
        sozo auth grant writer m:Slot,$GAME_ACTIONS_ADDR --profile $PROFILE_NAME --world $WORLD_ADDR
        sozo auth grant writer m:Game,$GAME_ACTIONS_ADDR --profile $PROFILE_NAME --world $WORLD_ADDR
        sozo auth grant writer m:Config,$GAME_ACTIONS_ADDR --profile $PROFILE_NAME --world $WORLD_ADDR
        sozo auth grant writer m:Reward,$GAME_ACTIONS_ADDR --profile $PROFILE_NAME --world $WORLD_ADDR
        sozo auth grant writer m:Jackpot,$JACKPOT_ACTIONS_ADDR --profile $PROFILE_NAME --world $WORLD_ADDR
        ;;
    set_config)
        echo "Setting config for profile: $PROFILE_NAME"
        # no rewards
        # sozo execute $GAME_ACTIONS_ADDR set_config -c 0,0,20,1000,1,1 --profile $PROFILE_NAME --world $WORLD_ADDR
        if [ -z "$TOKEN_ADDR" ]; then
            sozo execute $GAME_ACTIONS_ADDR set_config -c 0,0,20,1000,1,1 --profile $PROFILE_NAME --world $WORLD_ADDR
        else
            sozo execute $GAME_ACTIONS_ADDR set_config -c 0,0,20,1000,1,0,$TOKEN_ADDR,9,10,1,13,2,14,4,15,8,16,16,17,32,18,64,19,128,20,256 --profile $PROFILE_NAME --world $WORLD_ADDR
        fi
        ;;
    create_jackpot)
        echo "Creating jackpot for profile: $PROFILE_NAME"
        sozo execute $JACKPOT_ACTIONS_ADDR create_jackpot -c 1,1,1,0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7,0,0x1234,0,1,0 --profile $PROFILE_NAME --world $WORLD_ADDR
        ;;
    create_game)
        echo "Creating game for profile: $PROFILE_NAME"
        sozo execute $GAME_ACTIONS_ADDR create_game -c 0x0,0x6 --profile $PROFILE_NAME --world $WORLD_ADDR
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'"
        echo "Available commands: auth, create_game, set_config"
        exit 1
        ;;
esac

echo "Command '$COMMAND' executed successfully for profile: $PROFILE_NAME and world: $WORLD_ADDR"