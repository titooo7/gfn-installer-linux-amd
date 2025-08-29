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
echo "🛑 IMPORTANT 🛑"
echo "Your Batocera build needs to have profork installed in your Batocera one Desktop from Multi-App Arch Container"
echo "Otherwise the app might get installed but it won't launch"
echo ""
echo "Instructions on how to install batocera.pro fork (profork) are at https://github.com/profork/profork"
echo ""
echo "Once profork is executed, select the option 'Install Multi-App Arch Container' and click OK"
echo ""
echo "Then select the option 'Install/Update Arch Container' and click OK"
echo ""
echo "And finally you need to select the option 'Addon: XCFE/MATE/LXDE DESKTOP Mode' and click OK"
echo ""
sleep 10
echo "Now it's time for the GeForce NOW installer to do the magic!"

# Define the URL and the destination path
DOWNLOAD_URL="https://raw.githubusercontent.com/titooo7/gfn-installer-linux-amd/main/batocera/gfn-install-core.sh"
INSTALLER_SCRIPT_TO_RUN="/userdata/system/gfn-install-core.sh"

# Download the latest version of the installation script
echo "Downloading the latest installer setup script..."
if ! curl -fL -o "$INSTALLER_SCRIPT_TO_RUN" "$DOWNLOAD_URL"; then
    echo "⚠️ Download failed (file not found or network error). Exiting."
    exit 1
fi

# Make the downloaded script executable
chmod +x "$INSTALLER_SCRIPT_TO_RUN"

# Define the path to conty
conty=/userdata/system/pro/steam/conty.sh
if [ ! -x "$conty" ]; then
    echo "⚠️ ERROR: conty.sh not found at $conty Please make sure to install the Multi-App Arch Container using Profork"
    exit 1
fi

# Execute the script inside the container using MATE's fish shell
"$conty" \
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
