#!/bin/bash

# Define the path to conty
conty=/userdata/system/pro/steam/conty.sh

DIRECT_LAUNCHER_SCRIPT_PATH="/userdata/system/.local/bin/geforce-now-launcher.sh"
chmod +x "$DIRECT_LAUNCHER_SCRIPT_PATH"

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
