#!/bin/bash

# Script save path
SCRIPT_PATH="$HOME/t3rn.sh"
LOGFILE="$HOME/executor/executor.log"
EXECUTOR_DIR="$HOME/executor"

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    echo "Please try using 'sudo -i' to switch to the root user, then run this script again."
    exit 1
fi

# Main menu function
function main_menu() {
    while true; do
        clear
        echo "Script written by Dadu Community hahaha, Twitter: @ferdie_jhovie, free and open-source. Do not trust paid versions."
        echo "For any issues, contact Twitter. This is the only official account."
        echo "================================================================"
        echo "To exit the script, press Ctrl + C."
        echo "Please select an option:"
        echo "1) Run the script"
        echo "2) View logs"
        echo "3) Delete node"
        echo "5) Exit"
        
        read -p "Enter your choice [1-3]: " choice
        
        case $choice in
            1)
                execute_script
                ;;
            2)
                view_logs
                ;;
            3)
                delete_node
                ;;
            5)
                echo "Exiting the script."
                exit 0
                ;;
            *)
                echo "Invalid choice. Please try again."
                ;;
        esac
    done
}

# Function to execute the script
function execute_script() {
    # Check if pm2 is installed, install it if not
    if ! command -v pm2 &> /dev/null; then
        echo "pm2 is not installed. Installing pm2..."
        sudo npm install -g pm2
        if [ $? -eq 0 ]; then
            echo "pm2 installed successfully."
        else
            echo "pm2 installation failed. Please check npm configuration."
            exit 1
        fi
    else
        echo "pm2 is already installed. Continuing."
    fi

    # Download the latest version of the executor
    echo "Downloading the latest version of the executor..."
    curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | \
    grep -Po '"tag_name": "\K.*?(?=")' | \
    xargs -I {} wget https://github.com/t3rn/executor-release/releases/download/{}/executor-linux-{}.tar.gz

    if [ $? -eq 0 ]; then
        echo "Download successful."
    else
        echo "Download failed. Please check network connection or URL."
        exit 1
    fi

    # Extract the files
    echo "Extracting files..."
    tar -xzf executor-linux-*.tar.gz

    if [ $? -eq 0 ]; then
        echo "Extraction successful."
    else
        echo "Extraction failed. Please check the tar.gz file."
        exit 1
    fi

    # Check for extracted files
    echo "Checking for extracted executor files..."
    if ls | grep -q 'executor'; then
        echo "Executor files detected."
    else
        echo "Executor files not found. Exiting."
        exit 1
    fi

    # Prompt for environment variables
    read -p "Enter EXECUTOR_MAX_L3_GAS_PRICE [default 100]: " EXECUTOR_MAX_L3_GAS_PRICE
    EXECUTOR_MAX_L3_GAS_PRICE="${EXECUTOR_MAX_L3_GAS_PRICE:-100}"

    read -p "Enter RPC_ENDPOINTS_ARBT [default URLs provided]: " RPC_ENDPOINTS_ARBT
    RPC_ENDPOINTS_ARBT="${RPC_ENDPOINTS_ARBT:-https://arbitrum-sepolia.drpc.org, https://sepolia-rollup.arbitrum.io/rpc}"

    read -p "Enter RPC_ENDPOINTS_BAST [default URLs provided]: " RPC_ENDPOINTS_BAST
    RPC_ENDPOINTS_BAST="${RPC_ENDPOINTS_BAST:-https://base-sepolia-rpc.publicnode.com, https://base-sepolia.drpc.org}"

    read -p "Enter RPC_ENDPOINTS_OPST [default URLs provided]: " RPC_ENDPOINTS_OPST
    RPC_ENDPOINTS_OPST="${RPC_ENDPOINTS_OPST:-https://sepolia.optimism.io, https://optimism-sepolia.drpc.org}"

    read -p "Enter RPC_ENDPOINTS_UNIT [default URLs provided]: " RPC_ENDPOINTS_UNIT
    RPC_ENDPOINTS_UNIT="${RPC_ENDPOINTS_UNIT:-https://unichain-sepolia.drpc.org, https://sepolia.unichain.org}"

    export NODE_ENV=testnet
    export LOG_LEVEL=debug
    export LOG_PRETTY=false
    export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,blast-sepolia,optimism-sepolia,l2rn'
    export EXECUTOR_MAX_L3_GAS_PRICE="$EXECUTOR_MAX_L3_GAS_PRICE"

    read -p "Enter PRIVATE_KEY_LOCAL: " PRIVATE_KEY_LOCAL
    export PRIVATE_KEY_LOCAL="$PRIVATE_KEY_LOCAL"

    rm executor-linux-*.tar.gz

    echo "Starting executor using pm2..."
    cd ~/executor/executor/bin
    pm2 start ./executor --name "executor" --log "$LOGFILE" --env NODE_ENV=testnet
    pm2 list

    echo "Executor started using pm2."
    read -n 1 -s -r -p "Press any key to return to the main menu..."
    main_menu
}

# Function to view logs
function view_logs() {
    if [ -f "$LOGFILE" ]; then
        echo "Displaying logs (Press Ctrl+C to exit):"
        tail -f "$LOGFILE"
    else
        echo "Log file not found."
    fi
}

# Function to delete the node
function delete_node() {
    echo "Stopping the executor..."
    pm2 stop "executor"

    if [ -d "$EXECUTOR_DIR" ]; then
        echo "Deleting executor directory..."
        rm -rf "$EXECUTOR_DIR"
        echo "Node deleted."
    else
        echo "Node directory not found."
    fi

    read -n 1 -s -r -p "Press any key to return to the main menu..."
    main_menu
}

# Start the main menu
main_menu
