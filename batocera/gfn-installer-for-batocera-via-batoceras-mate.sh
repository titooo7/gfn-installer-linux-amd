#!/bin/bash
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
