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
echo ""
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
# Added '--nonintereactive' to prevent the script from asking and '|| true' to prevent script from exiting if this step fails (e.g., due to user input issues).
flatpak install --noninteractive -y --system flathub org.freedesktop.Platform//24.08 || true
flatpak install --noninteractive -y --system flathub org.freedesktop.Sdk//24.08 || true
echo "✅ Required runtimes installed added"
echo ""
echo "2. Adding the official GeForce NOW Flatpak repository..."
flatpak remote-add --user --if-not-exists GeForceNOW https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow.flatpakrepo || true
echo "✅ GeForce NOW repo added"
echo ""
echo "3. Installing GeForce NOW..."
flatpak uninstall --noninteractive -y --user com.nvidia.geforcenow &>/dev/null || echo "✅ GeForce NOW not found. Ready for a fresh installation."
flatpak install -y --user GeForceNOW com.nvidia.geforcenow || true
# We are also downloading the logo because for some reason our installer doens't and otherwise the icon of the app will be blank in the menu and desktop
mkdir -p "$USER_HOME/.local/share/icons/hicolor/512x512/apps"
curl -sL -o "$USER_HOME/.local/share/icons/hicolor/512x512/apps/com.nvidia.geforcenow.png" https://raw.githubusercontent.com/titooo7/gfn-installer-linux-amd/main/arch/img/com.nvidia.geforcenow.png
echo "✅ GeForce NOW installed. Tweaking few things so it can launch succesfully..."
echo ""
echo "4. Applying required Flatpak overrides."
# flatpak override --user --nosocket=wayland com.nvidia.geforcenow
# flatpak override --user --nofilesystem=host-etc com.nvidia.geforcenow
# Provide SSL certs from the host. If I uncomment the following override, then the line that contains 'cp -r /etc/ssl /run/host/etc/'  might not be required, but I'm tired of testing so... if it ain't broken...
# flatpak override --user --filesystem=/etc/ssl/certs:ro com.nvidia.geforcenow
echo "✅ Not required in this step for Batocera as we'll do it later"
echo ""
echo "5. Creating the custom launcher script..."
# Ensure the local bin directory exists
mkdir -p "$LAUNCHER_DIR"

# Create the launcher script using a heredoc
cat > "$LAUNCHER_SCRIPT_PATH" << 'EOF'
#!/bin/bash

# GeForce NOW SteamOS Spoof Script with Certificate Fix
# This script runs GeForce NOW with SteamOS /etc/os-release information
# and provides the necessary SSL certificates to prevent network errors.

# Creating the required flatpak overrides before launching the app. Otherwise the app won't launch on Batocera's MATE or XCFE Desktop
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
VERSION_ID=3.7.13
BUILD_ID=20250630.1
STEAMOS_DEFAULT_UPDATE_BRANCH=stable
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
echo ""
echo "6. Creating and modifying the main application menu shortcut"
echo "That's for the MATE or XCFE Desktop installed via Profork Arch Multi-App..."

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
echo ""
echo "7. Creating/Updating the desktop shortcut..."
# Copy the already modified file to the desktop, ensuring consistency
cp "$MENU_FILE_PATH" "$DESKTOP_FILE_PATH"
echo "✅ Desktop shortcut created and synchronized with the main menu entry."
echo ""
echo "8. Making shortcuts launchable..."
# We now apply the correct method to BOTH the menu file and the desktop file.

case "$XDG_CURRENT_DESKTOP" in
    # For GNOME, Cinnamon, MATE, etc., we use the 'gio' command.
    *GNOME*|*Cinnamon*|*MATE*|*Budgie*)
        echo "✅ Detected a GNOME-based desktop. Using 'gio' to trust files."
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
echo "9. Creating shortcut to allow GeForce NOW to be launched from ES-DE main menu"
echo "That way you don't need to launch MATE/XCFE first to launch GeForce NOW"
echo "But DO NOT uninstall MATE/XCFE. If you do that, then GeForce NOW won't launch!"
cat > "/userdata/roms/ports/Official GeForce NOW App.sh" << 'EOF'
#!/bin/bash

# Define the path to conty
#------------------------------------------------
conty=/userdata/system/pro/steam/conty.sh
#------------------------------------------------
#batocera-mouse show
DIRECT_LAUNCHER_SCRIPT_PATH="/userdata/system/.local/bin/geforce-now-launcher.sh"

# Execute the script inside the container using MATE's fish shell
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
fish -c "$DIRECT_LAUNCHER_SCRIPT_PATH"
EOF
echo "✅ Shortcut for the official GeForce NOW created in Ports section of the main menu."
echo ""
echo "👌 You can now launch MATE or XCFE, and from there launch GeForce NOW (using the desktop icon or the one in MATE/XCFE application menu)."
echo ""
echo ""
# --- Optional: Create Main Menu Entry ---
echo "------------------------------------------------------------------"
echo "🛑 Would you like to have a GeForce NOW entry in Batocera's (ES-DE) main menu?"
echo "Please note that this requires making a copy of the es-theme-carbon theme"
echo "and will use approximately 170MB of space."
echo ""

# Read user input with validation (case-insensitive)
while true; do
    read -p "Do you want to proceed? (Y/n): " response < /dev/tty
    
    # Convert to lowercase for case-insensitive comparison
    response_lower=$(echo "$response" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$response_lower" =~ ^(n|no)$ ]]; then
        echo "Exiting script as requested."
        exit 0
    elif [[ -z "$response" || "$response_lower" =~ ^(y|yes)$ ]]; then
        echo "👍 OK, proceeding with the main menu setup..."
        echo ""
        break
    else
        echo "Invalid response. Please enter Y or N."
    fi
done
echo ""
# TODO: TRYING TO ADD GeForce NOW TO ES-DE MAIN MENU AND LAUNCH IT DIRECTLY FROM THE MAIN MENU ICON
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
    <command>sh %ROM%</command>
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
# The above file will make a GeForce NOW appear in ES-DE main menu,but it wont launch the app directly yet... it will still just show the sh scripts that are saved in the path mentioned in that cfg file. 
# I'm still trying to figure out how to fix that...
#
# The next lines are the ones required to copy the launch script to the location related to the main menu. That way when we click on GeForce NOW it will show a geforce now script. 
# Remember that the goal is to click on the menu and launch GeForce NOW and not to show a list of sh scripts
# But since we cant do that yet then lets add a script there so geforce now can be launched...
mkdir -p /userdata/roms/geforcenow
# 
cp "/userdata/roms/ports/Official GeForce NOW App.sh" "/userdata/roms/geforcenow/"
#
# The last lines are just to download the images and logos for the Geforce Now entry in ES-DE main menu
echo "Downloading images for GeForce NOW entry in ES-DE main menu"

# Define the persistent theme directory for ES-THEME-CARBON
#THEME_DIR="/batocera/userdata/system/etc/emulationstation/themes/es-theme-carbon"
# Download images to the persistent directories
#curl -sL -o "$THEME_DIR/art/logos/geforcenow.png" https://raw.githubusercontent.com/titooo7/gfn-installer-linux-amd/main/batocera/img/menu/geforcenow.png
#curl -sL -o "$THEME_DIR/art/background/geforcenow.jpg" https://raw.githubusercontent.com/titooo7/gfn-installer-linux-amd/main/batocera/img/background/geforcenow.jpg
#curl -sL -o "$THEME_DIR/art/controllers/geforcenow.svg" https://raw.githubusercontent.com/titooo7/gfn-installer-linux-amd/main/batocera/img/controllers/geforcenow.svg
#curl -sL -o "$THEME_DIR/art/consoles/geforcenow.png" https://raw.githubusercontent.com/titooo7/gfn-installer-linux-amd/main/batocera/img/consoles/geforcenow.png

echo "Creating a clone/mod of es-theme-carbon theme, so we can have GeForce NOW in the main menu"
cp -r /batocera/usr/share/emulationstation/themes/es-theme-carbon /userdata/themes/es-theme-carbon-gfn
echo ""
# Define the persistent theme directory
THEME_DIR="/userdata/themes/es-theme-carbon-gfn"
# Define target directories and URLs
declare -A files=(
    ["$THEME_DIR/art/logos/geforcenow.png"]="https://raw.githubusercontent.com/titooo7/gfn-installer-linux-amd/main/batocera/img/menu/geforcenow.png"
    ["$THEME_DIR/art/background/geforcenow.jpg"]="https://raw.githubusercontent.com/titooo7/gfn-installer-linux-amd/main/batocera/img/background/geforcenow.jpg"
    ["$THEME_DIR/art/controllers/geforcenow.svg"]="https://raw.githubusercontent.com/titooo7/gfn-installer-linux-amd/main/batocera/img/controllers/geforcenow.svg"
    ["$THEME_DIR/art/consoles/geforcenow.png"]="https://raw.githubusercontent.com/titooo7/gfn-installer-linux-amd/main/batocera/img/consoles/geforcenow.png"
)

# Loop through the files, create directories, and download
for dest in "${!files[@]}"; do
    url="${files[$dest]}"
    dir=$(dirname "$dest")

    echo "Ensuring directory exists: $dir"
    mkdir -p "$dir"
    
    echo "Downloading to: $dest"
    curl -sL -o "$dest" "$url"

    # Verify download and report status
    if [ $? -eq 0 ]; then
        echo "✅ Success."
    else
        echo "🚨 Error: Failed to download from $url"
        # Optional: exit the script if a download fails
        # exit 1
    fi
done

echo "✅ You can now select ES-THEME-CARBON-GFN in the User Interface Settings"
# We give permission to the script that should be used in the main menu
chmod +x "/userdata/roms/geforcenow/Official GeForce NOW App.sh"
echo "🎉 Installation complete! Now you can launch the Official GeForce NOW App from Batocera's main menu (ES-DE)"
