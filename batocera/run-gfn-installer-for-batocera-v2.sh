#!/bin/bash
# GPU check: Verify that the graphics card is from AMD
if ! lspci | grep -i 'VGA' | grep -qi 'amd\|advanced micro devices'; then
    echo "⚠️ This script requires an AMD GPU. Exiting."
    exit 1
fi
echo ""
echo "✅ AMD GPU detected. So far, so good."
echo ""
echo ""

# Define the file to check
REQUIRED_FILE="/userdata/system/pro/steam/conty.sh"

# Check if the file doesn't exist or is not executable
if [ ! -x "$REQUIRED_FILE" ]; then
    {
        echo "⚠️ ERROR: The installer won't be executed ⚠️"
        echo ""
        echo "You must have Profork installed in your Batocera"
        echo ""
        echo "Instructions on how to install batocera.pro fork (profork) are at https://github.com/profork/profork"
        echo ""
        echo "Once profork is installed you'll need to run it"
        echo ""
        echo "Select the option 'Install Multi-App Arch Container' and click OK"
        echo ""
        echo "And then select the option 'Addon: XCFE/MATE/LXDE DESKTOP Mode' and click OK"
        echo ""
        echo "Once done this installer should no longer fail"
    } >&2 #<-- Redirect the entire block to stderr
    exit 1
fi

echo "It's time for the GeForce NOW installer to do the magic!"

# Define the URL and the destination path
DOWNLOAD_URL="https://raw.githubusercontent.com/titooo7/gfn-installer-linux-amd/main/batocera/gfn-install-core-v2.sh"
INSTALLER_SCRIPT_TO_RUN="/userdata/system/gfn-install-core-v2.sh"

# Download the latest version of the installation script
echo "Downloading the latest installer setup script..."
if ! curl -fL -o "$INSTALLER_SCRIPT_TO_RUN" "$DOWNLOAD_URL"; then
    echo "⚠️ Download failed (file not found or network error). Exiting."
    exit 1
fi

# Make the downloaded script executable
chmod +x "$INSTALLER_SCRIPT_TO_RUN"

# Execute the installer script inside the Arch Multi-App container
"$REQUIRED_FILE" \
        --bind /userdata/system/containers/storage /var/lib/containers/storage \
        --bind /userdata/system/flatpak /var/lib/flatpak \
        --bind /userdata/system/etc/passwd /etc/passwd \
        --bind /userdata/system/etc/group /etc/group \
        --bind /userdata/system /home/batocera \
        --bind /sys/fs/cgroup /sys/fs/cgroup \
        --bind /userdata/system /home/root \
        --bind /etc/fonts /etc/fonts \
        --bind /userdata /userdata \
        --bind /newroot /newroot \
        --bind / /batocera \
bash -c "$INSTALLER_SCRIPT_TO_RUN"
