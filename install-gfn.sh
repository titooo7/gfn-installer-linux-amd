#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# Path for the custom launcher script
LAUNCHER_DIR="$HOME/.local/bin"
LAUNCHER_SCRIPT_PATH="$LAUNCHER_DIR/geforce-now-launcher.sh"

# Define the file name and the two key locations
DESKTOP_FILE_NAME="com.nvidia.geforcenow.desktop"
MENU_FILE_PATH="$HOME/.local/share/applications/$DESKTOP_FILE_NAME" # The "source" file for the app menu
# Find the user's desktop directory, falling back to "$HOME/Desktop" if the command fails
DESKTOP_DIR=$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")
# Define the full path for the desktop shortcut
DESKTOP_FILE_PATH="$DESKTOP_DIR/$DESKTOP_FILE_NAME"

ANOTHER_FILE="$HOME/.local/share/applications/NVIDIA GeForce NOW" # This was the script created by Nvidia installer, I'm replicating it's creation but we won't use it anyway. Therefore this line and lines 126 to 302 could be deleted from the script

# --- Installation Steps ---
echo "🚀 Starting GeForce NOW Installer for AMD Linux Systems..."

echo "1. Installing required Flatpak runtimes..."
flatpak install -y --system flathub org.freedesktop.Platform//24.08
flatpak install -y --system flathub org.freedesktop.Sdk//24.08

echo "2. Adding the GeForce NOW Flatpak repository..."
flatpak remote-add --user --if-not-exists GeForceNOW https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow.flatpakrepo

echo "3. Installing GeForce NOW..."
flatpak install -y --user GeForceNOW com.nvidia.geforcenow

echo "4. Applying required Flatpak overrides..."
flatpak override --user --nosocket=wayland com.nvidia.geforcenow
flatpak override --user --nofilesystem=host-etc com.nvidia.geforcenow

echo "5. Creating the custom launcher script..."
# Ensure the local bin directory exists
mkdir -p "$LAUNCHER_DIR"

# Create the launcher script using a heredoc
cat > "$LAUNCHER_SCRIPT_PATH" << 'EOF'
#!/bin/bash

# GeForce NOW SteamOS Spoof Script with Certificate Fix
# This script runs GeForce NOW with SteamOS /etc/os-release information
# and provides the necessary SSL certificates to prevent network errors.

# Run the flatpak command with the required setup
flatpak run --user --command=bash com.nvidia.geforcenow -c '
    # Exit immediately if a command exits with a non-zero status.
    set -e

    # Create the directory that holds the os-release and SSL certs
    mkdir -p /run/host/etc/ssl

    # Create the SteamOS os-release file
    cat > /run/host/etc/os-release << EOL
NAME="SteamOS"
PRETTY_NAME="SteamOS"
VERSION_CODENAME=holo
ID=steamos
ID_LIKE=arch
ANSI_COLOR="1;35"
HOME_URL="https://www.steampowered.com/"
DOCUMENTATION_URL="https://support.steampowered.com/"
SUPPORT_URL="https://support.steampowered.com/"
BUG_REPORT_URL="https://support.steampowered.com/"
LOGO=steamos
VARIANT_ID=steamdeck
BUILD_ID=20250522.1
VERSION_ID=3.7.8
EOL

    # Recursively copy the host system'\''s SSL certificates into the sandbox
    cp -r /etc/ssl /run/host/etc/

    # Launch GeForce NOW
    /app/bin/GeForceNOW
'
EOF

# Make the launcher script executable
chmod +x "$LAUNCHER_SCRIPT_PATH"
echo "✅ Custom launcher script created at: $LAUNCHER_SCRIPT_PATH"

echo "6. Creating and modifying the main application menu shortcut..."
cat > "$MENU_FILE_PATH" << EOF
[Desktop Entry]
Version=1.0
Name=NVIDIA GeForce NOW
GenericName=NVIDIA GeForce NOW
Exec=$LAUNCHER_SCRIPT_PATH
Icon=com.nvidia.geforcenow
Type=Application
Categories=Network;Game;
EOF

echo "✅ Main menu shortcut modified to use the custom launcher."

echo "7. Creating/Updating the desktop shortcut..."
# Copy the already modified file to the desktop, ensuring consistency
cp "$MENU_FILE_PATH" "$DESKTOP_FILE_PATH"
echo "✅ Desktop shortcut created and synchronized with the main menu entry."

echo "8. Making shortcuts launchable..."
# We now apply the correct method to BOTH the menu file and the desktop file.

case "$XDG_CURRENT_DESKTOP" in
    # For GNOME, Cinnamon, MATE, etc., we use the 'gio' command.
    *GNOME*|*Cinnamon*|*MATE*|*Budgie*)
        echo "   Detected a GNOME-based desktop. Using 'gio' to trust files."
        /usr/bin/gio set "$MENU_FILE_PATH" metadata::trusted true || echo "⚠️  Warning: Could not trust the main menu shortcut."
        /usr/bin/gio set "$DESKTOP_FILE_PATH" metadata::trusted true || echo "⚠️  Warning: Could not trust the desktop shortcut."
        ;;

    # For KDE and all other desktops as a fallback, we make the files executable.
    *KDE*|*)
        echo "✅ Detected KDE or another desktop. Setting executable permissions."
        chmod +x "$MENU_FILE_PATH"
        chmod +x "$DESKTOP_FILE_PATH"
        ;;
esac
echo "✅ Both shortcuts are now ready to launch."


echo "✅ Creating another file."
cat > "$ANOTHER_FILE" << 'EOF'
#!/usr/bin/env bash

# Copyright (c) 2025, NVIDIA CORPORATION.  All rights reserved.
#
# NVIDIA CORPORATION and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.  Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA CORPORATION is strictly prohibited.


DIR="$HOME/.local/state/NVIDIA/GeForceNOW"
LOG_FILE="$DIR/gfn-launcher.log"

APP_ID="com.nvidia.geforcenow"
REPO="GeForceNOW"

APP_DIR="$HOME/.var/app/com.nvidia.geforcenow/.local/state/NVIDIA/GeForceNOW"
SELF_UPDATE_FILE="$APP_DIR/gfnupdate.json"
RESTART_FILE="$APP_DIR/restart.json"
ERROR_REPORT_FILE="$APP_DIR/installerstatus.json"

MAX_FAILURE_COUNT=2

ERR_CODE_CORRUPTED_PACKAGE=-468713472

SELF="$0"

if [ ! -d "$DIR" ]; then
    mkdir -p "$DIR"
fi

if [ -f "$LOG_FILE" ]; then
    mv "$LOG_FILE" "$LOG_FILE".bak
fi
# Reset the log file at the start
> "$LOG_FILE"

export LD_PRELOAD=

# Log messages with timestamps
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Log errors
log_error() {
    log "ERROR: $1"
}

# Log informational messages
log_info() {
    log "INFO: $1"
}

# Execute a command and log its outcome
run_command() {
    log_info "Running command: $*"
    "$@" >>"$LOG_FILE" 2>&1
    local r_status=$?
    if [ $r_status -ne 0 ]; then
        log_error "Command failed: $* (exit code: $r_status)"
    else
        log_info "Command succeeded: $*"
    fi
    return $r_status
}

selfupdate() {
    TMP_SCRIPT=$(mktemp --tmpdir=/tmp "$(basename "$SELF")-XXXXXX.sh")
    log_info "Move: $SELF -> $TMP_SCRIPT"

    if ! mv "$SELF" "$TMP_SCRIPT"; then
        log_error "Failed to move $SELF to $TMP_SCRIPT"
        return 1
    fi

    if ! cp "$HOME/.local/share/flatpak/app/$APP_ID/current/active/files/bin/NVIDIA GeForce NOW" "$SELF"; then
        log_error "Failed to copy updated script to $SELF"
        return 1
    fi

    exec "$SELF"
}

# Update App
update() {
    local r_status=0

    # Check for update in cache
    LATEST_COMMIT=$(LANG=POSIX flatpak info "$APP_ID" 2>>"$LOG_FILE" | grep -i "Latest commit:" | awk '{print $3}')
    if [[ -z "$LATEST_COMMIT" && ! -f "$SELF_UPDATE_FILE" ]]; then
        log_info "No update found."
    else
        log_info "Update found. Updating app ..."
        run_command flatpak update -y --no-pull --user "$APP_ID"
        r_status=$?
        if [ $r_status -eq 0 ]; then
            log_info "App updated successfully."
            if [ -f "$SELF_UPDATE_FILE" ]; then
                run_command rm "$SELF_UPDATE_FILE"
            fi

            if [ -f "$ERROR_REPORT_FILE" ]; then
                log_info "Removing error file."
                run_command rm "$ERROR_REPORT_FILE"
            fi

            selfupdate
        else
            log_error "Failed to update."
        fi
    fi

    return $r_status
}

# Main script logic
run() {
    local launch_app=true
    local failure_count=0
    local r_status=0

    while [ "$launch_app" = true ]; do

        # Update app
        while true; do
            update
            if [ $? -ne 0 ]; then
                failure_count=$((failure_count + 1))
                if [ $failure_count -ge $MAX_FAILURE_COUNT ]; then
                    log_error "Maximum update attempts exceeded. Reporting error."

                    version=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([0-9\.]*\)".*/\1/p' $SELF_UPDATE_FILE)
                    json_string="{\"clientVersion\": \"$version\", \"errorcode\": $ERR_CODE_CORRUPTED_PACKAGE}"

                    if echo "$json_string" > "$ERROR_REPORT_FILE"; then
                        log_info "Error: $json_string reported at: $ERROR_REPORT_FILE"
                    else
                        log_error "FATAL: Failed to write error report."
                    fi
                    break
                else
                    log_info "Retrying update after failure $failure_count of $MAX_FAILURE_COUNT."
                fi
            else
                failure_count=0
                break
            fi
        done

        # Run app
        run_command flatpak run "$APP_ID"
        r_status=$?


        # Check for restart
        if [ -f "$RESTART_FILE" ]; then
            log_info "Restart detected. Relaunching application."
            launch_app=true
            run_command rm "$RESTART_FILE"
        else
            launch_app=false
        fi
    done

    return $r_status
}

# Main entry point
run
exit $?
EOF


echo ""
echo "🎉 Installation complete! You can now launch GeForce NOW from your desktop OR your application menu."
