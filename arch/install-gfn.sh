#!/bin/bash
# GPU check: Verify that the graphics card is from AMD
if ! lspci | grep -i 'VGA compatible controller' | grep -iq 'AMD'; then
    echo -e "\e[1;31mERROR: AMD GPU not detected.\e[0m"
    echo -e "\e[0;33mThis installer is specifically designed for systems with AMD graphics cards.\e[0m"
    echo "Script will now exit."
    exit 1
fi
echo ""
echo "✅ AMD GPU detected. So far, so good."
echo ""
# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# Path for the custom launcher script
LAUNCHER_DIR="$HOME/.local/bin"
LAUNCHER_SCRIPT_PATH="$LAUNCHER_DIR/geforce-now-launcher.sh"

# Define the file name and the two key locations
DESKTOP_FILE_NAME="com.nvidia.geforcenow.desktop"
LOCAL_SHARE_APPLICATIONS="$HOME/.local/share/applications"
MENU_FILE_PATH="$HOME/.local/share/applications/$DESKTOP_FILE_NAME" # The "source" file for the app menu
# Find the user's desktop directory, falling back to "$HOME/Desktop" if the command fails
DESKTOP_DIR=$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")
# Define the full path for the desktop shortcut
DESKTOP_FILE_PATH="$DESKTOP_DIR/$DESKTOP_FILE_NAME"
echo ""
echo "Before we start we will need to install Flatpak, which requires root permissions to get it installed"
echo ""
if ! pacman -Q flatpak > /dev/null; then
    sudo pacman -Syu --noconfirm flatpak
echo "✅ root permissions used to install Flatpak. From now on everything will be installed with your standard user permissions"
fi
echo ""
echo "✅ Flatpak is already installed! Good!"
echo ""

# --- Installation Steps ---
echo "🚀 Starting GeForce NOW Installer for AMD Linux Systems..."
echo "1. Adding Flathub repo and installing required Flatpak runtimes..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
# Added '--nonintereactive' to prevent the script from asking and '|| true' to prevent script from exiting if this step fails (e.g., due to user input issues).
flatpak install --noninteractive -y --system flathub org.freedesktop.Platform//24.08 || true
flatpak install --noninteractive -y --system flathub org.freedesktop.Sdk//24.08 || true
echo "✅ Required runtimes installed added"

echo "2. Adding the GeForce NOW Flatpak repository..."
flatpak remote-add --user --if-not-exists GeForceNOW https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow.flatpakrepo || true
echo "✅ GeForce NOW repo added"

echo "3. Installing GeForce NOW..."
flatpak uninstall --noninteractive -y --user com.nvidia.geforcenow &>/dev/null || echo "✅ GeForce NOW not found. Ready for a fresh installation."
flatpak install --noninteractive -y --user GeForceNOW com.nvidia.geforcenow || true
# We are also downloading the logo because for some reason our installer doens't and otherwise the icon of the app will be blank in the menu and desktop
curl -sL -o "$HOME/.local/share/icons/hicolor/512x512/apps/com.nvidia.geforcenow.png" https://raw.githubusercontent.com/titooo7/gfn-installer-linux-amd/main/arch/img/com.nvidia.geforcenow.png
echo "✅ GeForce NOW installed. Tweaking few things so it can launch succesfully..."
echo "4. Applying required Flatpak overrides..."
flatpak override --user --nosocket=wayland com.nvidia.geforcenow
flatpak override --user --nofilesystem=host-etc com.nvidia.geforcenow
echo "✅ Flatpak overrides applied"

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
VARIANT_ID=LegionGoS
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
# Ensure /home/your-real-username/.local/share/applications/ exists
mkdir -p "$LOCAL_SHARE_APPLICATIONS"
# Creating the custom com.nvidia.geforcenow.desktp at /home/your-real-username/.local/share/applications

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
echo "🎉 Installation complete! You can now launch GeForce NOW from your desktop OR your application menu."
