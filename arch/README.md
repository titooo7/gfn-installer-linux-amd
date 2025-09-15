-----

# Unofficial GeForce NOW Installer for AMD on Linux 🌩️🎮

An automated installer script to **configure the official NVIDIA GeForce NOW** application for use on Arch-based Linux distributions with AMD graphics cards.

This script automates the installation and applies the necessary configurations enabling the official GeForce NOW app to run on hardware and Linux software that is not officially supported by NVIDIA.

-----

## Overview

  * **Enables GeForce NOW on Unsupported Systems:** NVIDIA’s official Linux support is currently limited to ChromeOS and the Steam Deck. This script installs the official Steam Deck application of GeForce NOW and creates a custom launcher with the required arguments to bypass these restrictions.

  * **Supports High-Resolution Streaming:** Enables GeForce NOW Ultimate subscribers to stream not just at 1440p 120FPS, but also up to 4K 90FPS, provided their AMD GPU and display are capable.

  * **Minimal and Safe:** The script installs the official GeForce NOW application via Flatpak. The only addition is a lightweight launcher script to apply necessary settings, without modifying core system files.

-----

## Features

  * **Automated Installation:** A single script handles the download, installation, and configuration.
  * **Custom Launcher:** Generates a launcher script that applies the required arguments to run GeForce NOW on unsupported systems.
  * **Configuration Fixes:** Applies command-line arguments to resolve common launch and connection errors.
  * **Wayland Compatibility Fix:** Disables the native Wayland socket via Flatpak override, forcing the application to use XWayland for greater stability on modern display servers.
  * **Shortcut Integration:** Modifies the application menu entry and the desktop shortcut to use the custom launcher.
  * **Desktop Environment Detection:** Detects GNOME/Cinnamon versus KDE/XFCE to correctly set permissions and ensure desktop shortcuts are executable.

-----

## Script Actions

The installer performs the following steps:

1.  **Install Application:** Installs the official GeForce NOW application and its dependencies using Flatpak.
2.  **Configure Flatpak Overrides:** Sets necessary permissions for the application sandbox and disables the Wayland socket `(--nosocket=wayland)` to ensure compatibility on CachyOS or Batocera.
3.  **Create Custom Launcher:** Creates a bash script at `$HOME/.local/bin/geforce-now-launcher.sh` which starts the application with the required arguments.
4.  **Modify Desktop Entries:** Updates the `Exec` line in the `.desktop` files for both the application menu and the desktop to point to the new launcher script.
5.  **Set Shortcut Permissions:** Makes the desktop shortcut executable using `gio set` (for GNOME/Cinnamon) or `chmod +x` (for KDE/XFCE/Other).

-----

## Requirements

  * An Arch-based Linux distribution such as CachyOS.
      * *Note: While the script may function on any Linux distribution that uses Flatpak, it has only been verified on CachyOS.*
  * An AMD GPU (integrated or dedicated).
  * **Flatpak** must be installed and configured. To install it on Arch-based systems:
    ```bash
    sudo pacman -S flatpak
    ```

### Tested Hardware

Successfully tested on a system with the following specifications, which confirmed upto 4K 90FPS streaming capability on 1080p monitor and a 4K TV.

  * **Device:** Chuwi Aubox mini-pc running CachyOS
  * **CPU:** AMD Ryzen 7 8845HS
  * **GPU:** AMD Radeon 780M (iGPU)

-----

## Installation for CachyOS

Open a Terminal app and copy and paste the following command:

```bash
curl -sL -o install-gfn.sh https://raw.githubusercontent.com/titooo7/gfn-installer-linux-amd/main/arch/install-gfn.sh
chmod +x install-gfn.sh
./install-gfn.sh
```


-----
## Uninstallation (CachyOS)

To remove the application and all related files created by this script, execute the following commands in your terminal:

```bash
# Uninstall the Flatpak application and its data
flatpak uninstall --delete-data com.nvidia.geforcenow

# Remove the custom launcher script
rm -f "$HOME/.local/bin/geforce-now-launcher.sh"

# Remove the application menu shortcut (if it exists in the user directory)
rm -f "$HOME/.local/share/applications/com.nvidia.geforcenow.desktop"

# Remove the desktop shortcut
rm -f "$HOME/Desktop/com.nvidia.geforcenow.desktop"
```

-----
## Uninstallation (Batocera)

To remove the application and all related files created by this script, execute the following commands in your terminal:

-----

## Credits

This script was developed thanks to the findings and solutions shared by several users in this Gist thread: [https://gist.github.com/Mihitoko/bd76340e56e78ec972c8a1365abb0d55](https://gist.github.com/Mihitoko/bd76340e56e78ec972c8a1365abb0d55)

-----

## Disclaimer

This is an unofficial installer and is not affiliated with or endorsed by NVIDIA. The script is provided as-is, without any warranty.

DO NOT contact NVIDIA support for issues encountered if you used this unofficial installer. Any problems should be raised as issues on the project's GitHub repository.
