#!/bin/bash
# GPU check: Verify that the graphics card is from AMD
if ! lspci | grep -i 'VGA compatible controller' | grep -iq 'AMD'; then
    echo -e "\e[1;31mERROR: AMD GPU not detected.\e[0m"
    echo -e "\e[0;33mThis installer is specifically designed for systems with AMD graphics cards.\e[0m"
    echo "Script will now exit."
    exit 1
fi
echo ""
echo "AMD GPU detected. So far, so good."
echo ""
echo ""
echo "IMPORTANT: "
echo "Your Batocera build needs to have profork installed in your Batocera one Desktop from Multi-App Arch Container"
echo "Otherwise the app might get installed but it won't launch"
echo ""
echo "Instructions on how to install batocera.pro fork (profork) are at https://github.com/profork/profork"
echo "Once profork is executed, select the option 'Install Multi-App Arch Container' and click OK"
echo "Then select the option 'Insall/Update Arch Container' and click OK"
echo "And finally you need to select the option 'Addon: XCFE/MATE/LXDE DESKTOP Mode' and click K"
echo ""
echo "Now it's time for the GeForce NOW installer to do the magic!"

# Define the URL and the destination path
DOWNLOAD_URL="https://raw.githubusercontent.com/titooo7/gfn-installer-linux-amd/refs/heads/main/batocera/install-gfn-batocera.sh"
SCRIPT_TO_RUN="/userdata/system/install-gfn-batocera.sh"

# Download the latest version of the installation script
echo "Downloading the latest installer script..."
curl -L -o "$SCRIPT_TO_RUN" "$DOWNLOAD_URL"

# Make the downloaded script executable
chmod +x "$SCRIPT_TO_RUN"


# Define the path to conty
conty=/userdata/system/pro/steam/conty.sh

# The script you want to execute inside the container
# IMPORTANT: Use the full path as seen from Batocera
SCRIPT_TO_RUN="/userdata/system/install-gfn-batocera.sh"

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
fish -c "$SCRIPT_TO_RUN"
