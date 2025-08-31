#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# Set the target user home directory.
USER_HOME="/userdata/system"

# Path for the custom geforce now launch script.
LAUNCHER_DIR="$USER_HOME/.local/bin"
LAUNCHER_SCRIPT_PATH="$LAUNCHER_DIR/geforce-now-launcher.sh"

# Define the shortcut file name and paths.
DESKTOP_FILE_NAME="com.nvidia.geforcenow.desktop"
MENU_FILE_PATH="$USER_HOME/.local/share/applications/$DESKTOP_FILE_NAME"
DESKTOP_DIR="$USER_HOME/Desktop"
DESKTOP_FILE_PATH="$DESKTOP_DIR/$DESKTOP_FILE_NAME"

# --- Installation Steps ---
echo "🚀 Starting GeForce NOW Installer for AMD Linux Systems..."

echo "1. Adding Flathub repo and installing required Flatpak runtimes..."
echo ""
# Use || true to prevent the script from exiting if the command fails (e.g., remote already exists).
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
flatpak install --noninteractive -y --system flathub org.freedesktop.Platform//24.08 || true
flatpak install --noninteractive -y --system flathub org.freedesktop.Sdk//24.08 || true
echo "✅ Required runtimes installed."
echo ""
echo "2. Adding the official GeForce NOW Flatpak repository..."
flatpak remote-add --user --if-not-exists GeForceNOW https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow.flatpakrepo || true
echo "✅ GeForce NOW repo added."
echo ""
echo "3. Installing GeForce NOW..."
# Uninstall any previous version silently. The || echo provides user feedback if it wasn't installed.
flatpak uninstall --noninteractive -y --user com.nvidia.geforcenow &>/dev/null || echo "✅ GeForce NOW not found. Ready for a fresh installation."
flatpak install -y --user GeForceNOW com.nvidia.geforcenow || true
# Download the application icon.
mkdir -p "$USER_HOME/.local/share/icons/hicolor/512x512/apps"
curl -sL -o "$USER_HOME/.local/share/icons/hicolor/512x512/apps/com.nvidia.geforcenow.png" https://raw.githubusercontent.com/titooo7/gfn-installer-linux-amd/main/arch/img/com.nvidia.geforcenow.png
echo "✅ GeForce NOW installed."
echo ""
echo "4. Applying required Flatpak overrides for Batocera..."
# These settings are persistent and only need to be run once.
flatpak override --user --nosocket=wayland com.nvidia.geforcenow
flatpak override --user --nofilesystem=host-etc com.nvidia.geforcenow
# Provide read-only access to host SSL certificates, the correct and efficient method.
flatpak override --user --filesystem=/etc/ssl/certs:ro com.nvidia.geforcenow
echo "✅ Overrides applied."
echo ""
echo "5. Creating the custom launcher script..."
# Ensure the local bin directory exists.
mkdir -p "$LAUNCHER_DIR"

# Create the launcher script using a heredoc.
# The single quotes around 'EOF' prevent variable expansion inside the block.
cat > "$LAUNCHER_SCRIPT_PATH" << 'EOF'
#!/bin/bash

# GeForce NOW SteamOS Spoof Script
# This script runs GeForce NOW with SteamOS /etc/os-release information.

# Run the flatpak command with the required setup.
flatpak run --user --command=bash com.nvidia.geforcenow -c '
    # Exit immediately if a command exits with a non-zero status.
    set -e

    # Create the directory for the spoofed os-release file.
    mkdir -p /run/host/etc

    # Create the SteamOS os-release file.
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

    # Launch GeForce NOW (SSL certs are now handled by the flatpak override).
    /app/bin/GeForceNOW
'
EOF

# Make the launcher script executable.
chmod +x "$LAUNCHER_SCRIPT_PATH"
echo "✅ Custom launcher script created at: $LAUNCHER_SCRIPT_PATH"
echo ""
echo "6. Creating application menu and desktop shortcuts..."
# Define the content for the shortcut in a variable.
# The variable $LAUNCHER_SCRIPT_PATH will be expanded here.
DESKTOP_ENTRY_CONTENT="[Desktop Entry]
Version=1.0
Name=NVIDIA GeForce NOW
GenericName=NVIDIA GeForce NOW
Exec=$LAUNCHER_SCRIPT_PATH
Icon=com.nvidia.geforcenow
Type=Application
Categories=Network;Game;"

# Write the content to both the menu and desktop files directly.
echo "$DESKTOP_ENTRY_CONTENT" > "$MENU_FILE_PATH"
echo "$DESKTOP_ENTRY_CONTENT" > "$DESKTOP_FILE_PATH"
echo "✅ Menu and desktop shortcuts created."
echo ""
echo "7. Making shortcuts launchable..."
# Apply the correct method to make shortcuts trusted/executable.
case "$XDG_CURRENT_DESKTOP" in
    # For GNOME, Cinnamon, MATE, etc., use 'gio'.
    *GNOME*|*Cinnamon*|*MATE*|*Budgie*)
        echo "✅ Detected a GNOME-based desktop. Using 'gio' to trust files."
        /usr/bin/gio set "$MENU_FILE_PATH" metadata::trusted true || echo "⚠️  Warning: Could not trust the main menu shortcut."
        /usr/bin/gio set "$DESKTOP_FILE_PATH" metadata::trusted true || echo "⚠️  Warning: Could not trust the desktop shortcut."
        ;;

    # For KDE and all other desktops as a fallback, make the files executable.
    *KDE*|*)
        echo "✅ Detected KDE or another desktop. Setting executable permissions."
        chmod +x "$MENU_FILE_PATH"
        chmod +x "$DESKTOP_FILE_PATH"
        ;;
esac
echo "✅ Both shortcuts are now ready to launch."
echo ""

# --- Optional: Create Main Menu Entry ---
echo "------------------------------------------------------------------"
echo "🛑 Would you like to create a dedicated GeForce NOW entry in Batocera's main menu?"
echo "This requires copying a theme and will use approximately 170MB of space."
echo ""

# Read user input with validation.
while true; do
    read -p "Do you want to proceed? (Y/n): " response < /dev/tty
    response_lower=$(echo "$response" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$response_lower" =~ ^(n|no)$ ]]; then
        echo "👍 Skipping main menu entry. Adding a shortcut to Ports section"
        echo "8. Creating shortcut for EmulationStation (Ports)..."
cat > "/userdata/roms/ports/Official GeForce NOW App.sh" << 'EOF'
#!/bin/bash

# Path to conty runner
conty=/userdata/system/pro/steam/conty.sh
DIRECT_LAUNCHER_SCRIPT_PATH="/userdata/system/.local/bin/geforce-now-launcher.sh"

# Execute the launcher inside the appropriate container environment.
"$conty" \
        --bind /userdata/system/containers/storage /var/lib/containers/storage \
        --bind /userdata/system/flatpak /var/lib/flatpak \
        --bind /userdata/system/etc/passwd /etc/passwd \
        --bind /userdata/system/etc/group /etc/group \
        --bind /var/run/nvidia /run/nvidia \
        --bind /userdata/system /home/batocera \
        --bind /sys/fs/cgroup /sys/fs/cgroup \
        --bind /userdata/system /home/root \
        --bind /etc/fonts /etc/fonts \
        --bind /userdata /userdata \
        --bind /newroot /newroot \
        --bind / /batocera \
bash -c "$DIRECT_LAUNCHER_SCRIPT_PATH"
EOF
echo "✅ Shortcut for GeForce NOW created in the Ports section."
echo ""
echo "👌 You can now launch GeForce NOW from the MATE/XFCE desktop or from the Ports menu in EmulationStation."
echo ""
        exit 0
    elif [[ -z "$response" || "$response_lower" =~ ^(y|yes)$ ]]; then
        echo "👍 OK, creating the main menu entry..."
        echo ""
        break
    else
        echo "Invalid response. Please enter Y or N."
    fi
done

echo "Creating EmulationStation system configuration..."
cat > "/userdata/system/configs/emulationstation/es_systems_gfn.cfg" << 'EOF'
<?xml version="1.0"?>
<systemList>
  <system>
    <fullname>GeForce NOW</fullname>
    <name>geforcenow</name>
    <manufacturer>NVIDIA</manufacturer>
    <release>2025</release>
    <hardware>port</hardware>
    <path>/userdata/roms/geforcenow</path>
    <extension>.sh .SH</extension>
    <command>%ROM%</command>
    <platform>pc</platform>
    <theme>geforcenow</theme>
    <emulators>
      <emulator name="geforcenow">
        <cores>
          <core default="true">heroic2</core>
        </cores>
      </emulator>
    </emulators>
  </system>
</systemList>
EOF

cat > "/userdata/roms/geforcenow/Official GeForce NOW App.sh" << 'EOF'
#!/bin/bash

# Path to conty runner
conty=/userdata/system/pro/steam/conty.sh
DIRECT_LAUNCHER_SCRIPT_PATH="/userdata/system/.local/bin/geforce-now-launcher.sh"

# Execute the launcher inside the appropriate container environment.
"$conty" \
        --bind /userdata/system/containers/storage /var/lib/containers/storage \
        --bind /userdata/system/flatpak /var/lib/flatpak \
        --bind /userdata/system/etc/passwd /etc/passwd \
        --bind /userdata/system/etc/group /etc/group \
        --bind /var/run/nvidia /run/nvidia \
        --bind /userdata/system /home/batocera \
        --bind /sys/fs/cgroup /sys/fs/cgroup \
        --bind /userdata/system /home/root \
        --bind /etc/fonts /etc/fonts \
        --bind /userdata /userdata \
        --bind /newroot /newroot \
        --bind / /batocera \
bash -c "$DIRECT_LAUNCHER_SCRIPT_PATH"
EOF

chmod +x "/userdata/roms/geforcenow/Official GeForce NOW App.sh"
echo "Setting up ROMS directory and launch script..."
mkdir -p /userdata/roms/geforcenow

echo "Cloning theme for main menu integration..."
cp -r /batocera/usr/share/emulationstation/themes/es-theme-carbon /userdata/themes/es-theme-carbon-gfn
echo ""

# Define theme directory and required image assets.
THEME_DIR="/userdata/themes/es-theme-carbon-gfn"
declare -A files=(
    ["$THEME_DIR/art/logos/geforcenow.png"]="https://raw.githubusercontent.com/titooo7/gfn-installer-linux-amd/main/batocera/img/menu/geforcenow.png"
    ["$THEME_DIR/art/background/geforcenow.jpg"]="https://raw.githubusercontent.com/titooo7/gfn-installer-linux-amd/main/batocera/img/background/geforcenow.jpg"
    ["$THEME_DIR/art/controllers/geforcenow.svg"]="https://raw.githubusercontent.com/titooo7/gfn-installer-linux-amd/main/batocera/img/controllers/geforcenow.svg"
    ["$THEME_DIR/art/consoles/geforcenow.png"]="https://raw.githubusercontent.com/titooo7/gfn-installer-linux-amd/main/batocera/img/consoles/geforcenow.png"
)

echo "Downloading theme assets..."
# Loop through the files, create directories, and download.
for dest in "${!files[@]}"; do
    url="${files[$dest]}"
    dir=$(dirname "$dest")
    mkdir -p "$dir"
    echo "Downloading to: $dest"
    if curl -sL -o "$dest" "$url"; then
        echo "✅ Success."
    else
        echo "🚨 Error: Failed to download from $url"
    fi
done

echo ""
echo "✅ You can now select the 'ES-THEME-CARBON-GFN' theme in UI Settings."
echo ""
echo "🎉 Installation complete! GeForce NOW is now available in the Batocera main menu."

