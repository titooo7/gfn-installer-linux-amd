#!/bin/bash
# GPU check: Verify that the graphics card is from AMD
if ! lspci | grep -i 'VGA' | grep -qi 'amd\|advanced micro devices'; then
    echo "⚠️ This script requires an AMD GPU. Exiting."
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
# --- NEW: Define sudoers file for passwordless mounting ---
SUDOERS_FILE="/etc/sudoers.d/99-geforcenow-spoof"

echo ""
echo "Before we start we will need to install Flatpak, which requires root permissions to get it installed"
echo ""
if ! pacman -Q flatpak > /dev/null; then
    sudo pacman -Syu --noconfirm flatpak
echo "✅ root permissions used to install Flatpak. From now on everything will be installed with your standard user permissions, with one exception that will be explained."
fi
echo ""
echo "✅ Flatpak is already installed! Good!"
echo ""

# --- Installation Steps ---
echo "🚀 Starting GeForce NOW Installer for AMD Linux Systems..."
echo "1. Adding Flathub repo and installing required Flatpak runtimes..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
flatpak install --noninteractive -y --system flathub org.freedesktop.Platform//24.08 || true
flatpak install --noninteractive -y --system flathub org.freedesktop.Sdk//24.08 || true
echo "✅ Required runtimes installed"

echo "2. Adding the GeForce NOW Flatpak repository..."
flatpak remote-add --user --if-not-exists GeForceNOW https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow.flatpakrepo || true
echo "✅ GeForce NOW repo added"

echo "3. Installing GeForce NOW..."
flatpak uninstall --noninteractive -y --user com.nvidia.geforcenow &>/dev/null || echo "✅ GeForce NOW not found. Ready for a fresh installation."
flatpak install --noninteractive -y --user GeForceNOW com.nvidia.geforcenow ||  echo "✅ App installed. In the next steps we'll apply some custom tweaks so it can work."
mkdir -p "$HOME/.local/share/icons/hicolor/512x512/apps"
curl -sL -o "$HOME/.local/share/icons/hicolor/512x512/apps/com.nvidia.geforcenow.png" https://raw.githubusercontent.com/titooo7/gfn-installer-linux-amd/main/arch/img/com.nvidia.geforcenow.png
echo "✅ GeForce NOW installed. Tweaking few things so it can launch succesfully..."
echo "4. Applying required Flatpak overrides..."
flatpak override --user --nosocket=wayland com.nvidia.geforcenow
flatpak override --user --nofilesystem=host-etc com.nvidia.geforcenow
echo "✅ Flatpak overrides applied"

# --- NEW STEP: Configure passwordless sudo for the mounting commands ---
echo "5. Configuring passwordless sudo for automatic system value spoofing..."
echo "   This step allows the launcher to mount/umount system values without asking for a password every time."
echo "   It will create a file at '$SUDOERS_FILE' to grant permissions for ONLY the required commands."
echo "   This is only required if you want to have upto 4K 120FPS rather than just 4K 90FP."
echo "   THIS WILL SPOOF YOUR DEVICE PRODUCT, VENDOR AND BOARD WHILE GEFORCE NOW IS RUNNING."
echo "   I DO NOT RECOMMEND TO PERFORM ANY UPDATES TO YOUR OS WHILE GFN IS OPEN. DO IT AT YOUR OWN RISK."
read -p "   Do you want to proceed? (y/N) " -n 1 -r
echo # Move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Define the exact commands that will be allowed without a password
    SUDOERS_CONTENT="
# Allow user $USER to run mount/umount for GeForce NOW DMI spoofing
$USER ALL=(ALL) NOPASSWD: /usr/bin/mount --bind /tmp/fake_product_name /sys/class/dmi/id/product_name
$USER ALL=(ALL) NOPASSWD: /usr/bin/mount --bind /tmp/fake_sys_vendor /sys/class/dmi/id/sys_vendor
$USER ALL=(ALL) NOPASSWD: /usr/bin/mount --bind /tmp/fake_board_vendor /sys/class/dmi/id/board_vendor
$USER ALL=(ALL) NOPASSWD: /usr/bin/mount --bind /tmp/fake_board_name /sys/class/dmi/id/board_name
$USER ALL=(ALL) NOPASSWD: /usr/bin/umount /sys/class/dmi/id/product_name
$USER ALL=(ALL) NOPASSWD: /usr/bin/umount /sys/class/dmi/id/sys_vendor
$USER ALL=(ALL) NOPASSWD: /usr/bin/umount /sys/class/dmi/id/board_vendor
$USER ALL=(ALL) NOPASSWD: /usr/bin/umount /sys/class/dmi/id/board_name
"
    # Use tee with sudo to write the file, as we need root privileges
    echo "$SUDOERS_CONTENT" | sudo tee "$SUDOERS_FILE" > /dev/null
    sudo chmod 0440 "$SUDOERS_FILE"
    echo "✅ Sudoers file created successfully."
else
    echo "⚠️  Skipping sudoers configuration. The launcher will not be able to spoof DMI values."
fi


echo "6. Creating the custom launcher script..."
# Ensure the local bin directory exists
mkdir -p "$LAUNCHER_DIR"
# --- HEAVILY MODIFIED: Create the new launcher script with spoofing and cleanup ---
cat > "$LAUNCHER_SCRIPT_PATH" << 'EOF'
#!/bin/bash

# This launcher script performs two main functions:
# 1. DMI Spoofing: Mounts temporary files to pretend the system is a Steam Deck.
# 2. Flatpak Spoofing: Runs GeForce NOW inside a Flatpak sandbox with a fake os-release.
# It automatically cleans up the DMI mounts when the application is closed.

# --- Function to clean up the mounts and temp files ---
cleanup() {
    echo "GeForce NOW closed. Cleaning up DMI spoof..."
    # Unmount in reverse order, ignoring errors if they are already unmounted
    sudo umount /sys/class/dmi/id/board_name &>/dev/null || true
    sudo umount /sys/class/dmi/id/board_vendor &>/dev/null || true
    sudo umount /sys/class/dmi/id/sys_vendor &>/dev/null || true
    sudo umount /sys/class/dmi/id/product_name &>/dev/null || true

    # Remove the temporary files
    rm -f /tmp/fake_product_name /tmp/fake_sys_vendor /tmp/fake_board_vendor /tmp/fake_board_name
    echo "✅ Cleanup complete."
}

# --- Trap the exit signal to ensure cleanup always runs ---
# This makes sure the 'cleanup' function is called when the script exits for any reason.
trap cleanup EXIT

# --- Step 1: Perform DMI Spoofing on the host system ---
#echo "🚀 Applying DMI spoof to mimic a Steam Deck..."
#echo "Jupiter" > /tmp/fake_product_name
#echo "Valve" > /tmp/fake_sys_vendor
#echo "Valve" > /tmp/fake_board_vendor
#echo "Jupiter" > /tmp/fake_board_name
echo "🚀 Applying DMI spoof to mimic a Lenovo Legion GO S..."
echo "83E1" > /tmp/fake_product_name
echo "Lenovo" > /tmp/fake_sys_vendor
echo "Lenovo" > /tmp/fake_board_vendor
echo "8APU1" > /tmp/fake_board_name

# Use sudo for the mount commands (passwordless due to sudoers config)
sudo mount --bind /tmp/fake_product_name /sys/class/dmi/id/product_name
sudo mount --bind /tmp/fake_sys_vendor /sys/class/dmi/id/sys_vendor
sudo mount --bind /tmp/fake_board_vendor /sys/class/dmi/id/board_vendor
sudo mount --bind /tmp/fake_board_name /sys/class/dmi/id/board_name
echo "✅ DMI values spoofed. Launching GeForce NOW..."

# --- Step 2: Launch GeForce NOW with Flatpak Spoofing ---
# The rest of this is the original flatpak sandboxed launch command
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
VERSION_ID=3.7.13
BUILD_ID=20250630.1
STEAMOS_DEFAULT_UPDATE_BRANCH=stable
EOL

    # Recursively copy the host system'\''s SSL certificates into the sandbox
    cp -r /etc/ssl /run/host/etc/

    # Launch GeForce NOW (this command blocks until the app is closed)
    /app/bin/GeForceNOW
'
# The script will automatically call the cleanup function now that flatpak has exited.
EOF

# Make the launcher script executable
chmod +x "$LAUNCHER_SCRIPT_PATH"
echo "✅ Custom launcher script created at: $LAUNCHER_SCRIPT_PATH"

echo "7. Creating and modifying the main application menu shortcut..."
mkdir -p "$LOCAL_SHARE_APPLICATIONS"
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
echo "✅ Main menu shortcut modified to use the custom launcher script."

echo "8. Creating/Updating the desktop shortcut..."
cp "$MENU_FILE_PATH" "$DESKTOP_FILE_PATH"
echo "✅ Desktop shortcut created and synchronized with the main menu entry."

echo "9. Making shortcuts launchable..."
case "$XDG_CURRENT_DESKTOP" in
    *GNOME*|*Cinnamon*|*MATE*|*Budgie*)
        echo "   Detected a GNOME-based desktop. Using 'gio' to trust files."
        /usr/bin/gio set "$MENU_FILE_PATH" metadata::trusted true || echo "⚠️  Warning: Could not trust the main menu shortcut."
        /usr/bin/gio set "$DESKTOP_FILE_PATH" metadata::trusted true || echo "⚠️  Warning: Could not trust the desktop shortcut."
        ;;
    *KDE*|*)
        echo "✅ Detected KDE or another desktop. Setting executable permissions."
        chmod +x "$MENU_FILE_PATH"
        chmod +x "$DESKTOP_FILE_PATH"
        ;;
esac
echo "✅ Both shortcuts are now ready to launch."
echo ""
echo "🎉 Installation complete! You can now launch GeForce NOW from your desktop OR your application menu."
