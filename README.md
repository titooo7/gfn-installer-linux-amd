-----

# GeForce NOW Unofficial Installer for AMD PC's running Linux 🚀

A simple, one-step installer script to get NVIDIA GeForce NOW running perfectly on Arch-based Linux distributions with AMD hardware.

This script automates the entire process of installing GeForce NOW and applies the necessary workarounds to make it run flawlessly, just as it would on a Steam Deck.

-----

## Why Should I Use This Installer? 🤔

* **Run GeForce NOW on Linux computers not officially supported yet:** 
As of August 2025, NVIDIA only provides official support for GeForce NOW on Linux via Steam Deck. This script installs the official application and creates a custom launcher with the necessary tweaks to overcome the standard installation restrictions on other Linux PC's.

* **Unlock Higher Resolutions:** This script enables GeForce NOW Ultimate subscribers toplay at  **4K 60FPS** (as long as your AMD GPU/iGPU  is capable).

* **Safe and Minimal:** We aren't installing anything that the official application wouldn't. The only addition is a lightweight launcher script that makes it all work seamlessly.
-----

## Features ✨

  * **Fully Automated:** Runs a single script to handle everything from installation to configuration.
  * **Custom Launcher:** Creates a special launcher with the required tweaks to run GeForce NOW on unsupported systems.
  * **Error Fixes:** Automatically applies configurations to prevent common connection and launch issues.
  * **Universal Shortcut Creation:** Modifies both the **Application Menu** entry and the **Desktop** shortcut to use the custom launcher.
  * **Adaptive Configuration:** It detects your desktop environment (GNOME/Cinnamon vs. KDE/Other) to make shortcuts launchable correctly.

-----

## Requirements 📋

  * An **Arch-based Linux distribution** (e.g., CachyOS).
      * *Note: It may work on other Linux distributions that support Flatpak, but I only tested it on CachyOS (Arch-based system).*
  * An **AMD CPU and integrated AMD GPU**.
  * **Flatpak** installed and configured on your system. If you don't have it, you can install it with:
    ```bash
    sudo pacman -S flatpak
    ```

### Tested Hardware ✔️

This script was successfully tested on a **Chuwi AuBox Mini-PC** with the following specifications:

  * **CPU:** AMD Ryzen 7 8845HS
  * **GPU:** AMD Radeon 780M

I'm now able to play at 4K 60FPS when my MiniPC is connected to my 4K TV.

-----


## How It Works ⚙️

The script performs the following actions:

1.  **Installs GeForce NOW:** It uses Flatpak to install the official GeForce NOW application along with its required runtimes.
2.  **Applies Overrides:** It configures the Flatpak sandbox with necessary permissions.
3.  **Creates a Custom Launcher:** A new bash script (`geforce-now-launcher.sh`) is created in `$HOME/.local/bin/`. This launcher applies specific configurations and parameters before starting the app.
4.  **Modifies Shortcuts:** The script finds the `.desktop` files for both the application menu and the desktop icon and changes their `Exec` command to point to our new custom launcher.
5.  **Makes Shortcuts Launchable:** It detects your desktop environment and uses the appropriate command (`gio set` for GNOME/Cinnamon or `chmod +x` for KDE/XFCE) to ensure the icons are immediately clickable.

-----

## 🛠️ Installation & Usage


**Option 1. You can install it with one single command without saving the script on your disk::**

```bash
curl -L https://raw.githubusercontent.com/titooo7/gfn-installer-linux-amd/main/install-gfn.sh | bash
```

**Option 2. Download the Installer Script, Make it Executable and Run it:**

```bash
curl -L -o install-gfn.sh https://raw.githubusercontent.com/titooo7/gfn-installer-linux-amd/main/install-gfn.sh
```

```bash
chmod +x install-gfn.sh
```

```bash
./install-gfn.sh
```

The script will handle the rest. Once it finishes, you can launch GeForce NOW from either your application menu or the icon on your desktop\!

-----

## 🛑 If you want to uninstall it

Open your terminal and run the following commands:

```bash
flatpak uninstall --delete-data com.nvidia.geforcenow
```

```bash
rm -f "$HOME/.local/bin/geforce-now-launcher.sh"
```

```bash
rm -f "$HOME/.local/share/applications/com.nvidia.geforcenow.desktop"
```

```bash
rm -f "$HOME/Desktop/com.nvidia.geforcenow.desktop"
```

-----

## Credits

I was able to create this thanks to the information shared by several users in this thread https://gist.github.com/Mihitoko/bd76340e56e78ec972c8a1365abb0d55#file-install-geforcenow-on-desktop-linux-md
If if wasn't thanks to several users there I wouldn't have been able to create this installer.

-----

## Disclaimer

This is an Unofficial installation script and it's not affiliated with NVIDIA. It is provided as-is in the hope that it will be useful for other users of Arch based linux distros.
Please DO NOT contact Nvidia to report bugs  related to the use of GeForce NOW if you installed the app on Linux using custom installers like this one.
