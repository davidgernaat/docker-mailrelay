#!/bin/bash

# IP Whitelist Management Script for Mail Relay
# Usage: ./manage_whitelist.sh [add|remove|list] [IP/SUBNET]

CONTAINER_NAME="relay-postfix"
WHITELIST_FILE="/etc/postfix/whitelist"

case "$1" in
    "add")
        if [[ -z "$2" ]]; then
            echo "Usage: $0 add <IP/SUBNET>"
            echo "Example: $0 add 192.168.1.100"
            echo "Example: $0 add 10.0.0.0/8"
            exit 1
        fi
        
        IP="$2"
        echo "Adding $IP to whitelist..."
        
        # Add IP to whitelist file
        docker exec $CONTAINER_NAME sh -c "echo '$IP OK' >> $WHITELIST_FILE"
        
        # Rebuild whitelist database
        docker exec $CONTAINER_NAME postmap $WHITELIST_FILE
        
        # Reload Postfix configuration
        docker exec $CONTAINER_NAME postfix reload
        
        echo "✅ Added $IP to whitelist and reloaded Postfix"
        ;;
        
    "remove")
        if [[ -z "$2" ]]; then
            echo "Usage: $0 remove <IP/SUBNET>"
            exit 1
        fi
        
        IP="$2"
        echo "Removing $IP from whitelist..."
        
        # Remove IP from whitelist file
        docker exec $CONTAINER_NAME sh -c "sed -i '/^$IP /d' $WHITELIST_FILE"
        
        # Rebuild whitelist database
        docker exec $CONTAINER_NAME postmap $WHITELIST_FILE
        
        # Reload Postfix configuration
        docker exec $CONTAINER_NAME postfix reload
        
        echo "✅ Removed $IP from whitelist and reloaded Postfix"
        ;;
        
    "list")
        echo "Current IP whitelist:"
        docker exec $CONTAINER_NAME cat $WHITELIST_FILE | grep -v "^#" | grep -v "^$"
        ;;
        
    "reload")
        echo "Reloading Postfix configuration..."
        docker exec $CONTAINER_NAME postmap $WHITELIST_FILE
        docker exec $CONTAINER_NAME postfix reload
        echo "✅ Postfix configuration reloaded"
        ;;
        
    *)
        echo "IP Whitelist Management for Mail Relay"
        echo ""
        echo "Usage: $0 [add|remove|list|reload] [IP/SUBNET]"
        echo ""
        echo "Commands:"
        echo "  add <IP/SUBNET>    Add IP or subnet to whitelist"
        echo "  remove <IP/SUBNET> Remove IP or subnet from whitelist"
        echo "  list               Show current whitelist"
        echo "  reload             Reload Postfix configuration"
        echo ""
        echo "Examples:"
        echo "  $0 add 192.168.1.100"
        echo "  $0 add 10.0.0.0/8"
        echo "  $0 remove 192.168.1.100"
        echo "  $0 list"
        ;;
esac

