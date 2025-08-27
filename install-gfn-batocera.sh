#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# Set the home directory to the required static path.
USER_HOME="/userdata/system"

# Path for the custom launcher script
LAUNCHER_DIR="$USER_HOME/.local/bin"
LAUNCHER_SCRIPT_PATH="$LAUNCHER_DIR/geforce-now-launcher.sh"

# Define the file name and the two key locations
DESKTOP_FILE_NAME="com.nvidia.geforcenow.desktop"
MENU_FILE_PATH="$USER_HOME/.local/share/applications/$DESKTOP_FILE_NAME" # The "source" file for the app menu
# Define the user's desktop directory using the static home path
DESKTOP_DIR="$USER_HOME/Desktop"
# Define the full path for the desktop shortcut
DESKTOP_FILE_PATH="$DESKTOP_DIR/$DESKTOP_FILE_NAME"

# --- Installation Steps ---
echo "🚀 Starting GeForce NOW Installer for AMD Linux Systems..."

echo "1. Adding Flathub repo and installing required Flatpak runtimes..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --noninteractive -y --system flathub org.freedesktop.Platform//24.08 || true
flatpak install --noninteractive -y --system flathub org.freedesktop.Sdk//24.08 || true

echo "2. Adding the GeForce NOW Flatpak repository..."
flatpak remote-add --user GeForceNOW https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow.flatpakrepo || true

echo "3. Installing GeForce NOW..."
flatpak install --noninteractive -y --user GeForceNOW com.nvidia.geforcenow || true

# echo "4. Applying required Flatpak overrides..."
# flatpak override --user --nosocket=wayland com.nvidia.geforcenow
# flatpak override --user --nofilesystem=host-etc com.nvidia.geforcenow

echo "5. Creating the custom launcher script..."
# Ensure the local bin directory exists
mkdir -p "$LAUNCHER_DIR"

# Create the launcher script using a heredoc
cat > "$LAUNCHER_SCRIPT_PATH" << 'EOF'
#!/bin/bash

# GeForce NOW SteamOS Spoof Script with Certificate Fix
# This script runs GeForce NOW with SteamOS /etc/os-release information
# and provides the necessary SSL certificates to prevent network errors.

# Creating the required flatpak overrides before launching the app. Otherwise the app won't launch on Batocera mate or xcfe so in reality overrides of step 4 can be deleted as that works in CachyOS but not batocera
flatpak override --user --nosocket=wayland com.nvidia.geforcenow
flatpak override --user --nofilesystem=host-etc com.nvidia.geforcenow

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
echo ""
echo "🎉 Installation complete! You can now launch MATE or XCFE and from there launch GeForce NOW from your desktop OR your application menu."
