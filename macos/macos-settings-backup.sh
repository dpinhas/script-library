#!/bin/bash

# Script to backup or restore macOS settings

# Backup directory
backup_dir="$HOME/macos_settings_backup"
mkdir -p "$backup_dir"

# Backup preferences
backup_preferences() {
    declare -a preference_domains=(
        "com.apple.dock"
        "com.apple.finder"
        "NSGlobalDomain"
        # Add more preference domains here
    )

    for domain in "${preference_domains[@]}"; do
        backup_file="$backup_dir/$domain.plist"
        defaults export "$domain" - > "$backup_file"
        echo "Backed up $domain to $backup_file"
    done
}

# Restore preferences
restore_preferences() {
    for file in "$backup_dir"/*.plist; do
        domain=$(basename "$file" .plist)
        defaults import "$domain" - < "$file"
        echo "Restored $file to $domain"
    done
}

# Decide whether to backup or restore based on argument
if [ "$1" == "backup" ]; then
    backup_preferences
    echo
    echo "macOS settings backup complete. Backup saved in: $backup_dir"

elif [ "$1" == "restore" ]; then
    restore_preferences
    echo "macOS settings restore complete."
else
    echo "Invalid argument. Usage: ./macos-settings.sh [backup|restore]"
    exit 1
fi

