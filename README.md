# Samsung Bloatware Manager - Documentation

## Overview
This PowerShell script helps manage Samsung bloatware on Android devices via ADB. It is interactive and allows:
- Downloading and installing ADB if missing
- Listing installed apps with readable names
- Uninstalling or restoring predefined Samsung apps
- Selecting individual apps to uninstall or restore

## Predefined Bloatware
The script targets apps such as:
- com.sec.android.app.sbrowser (Samsung Internet)
- com.samsung.android.app.sbrowseredge (Samsung Internet Edge)
- com.samsung.android.spay / spayfw (Samsung Pay)
- com.sec.android.app.music (Samsung Music)
- com.samsung.android.video (Samsung Video)
- com.samsung.android.game.gamehome (Game Launcher)
- com.samsung.android.game.gos (Game Optimizing Service)
- com.samsung.android.app.spage (Samsung Free / Daily)
- com.samsung.android.bixby.service (Bixby Core)
- com.samsung.android.visionintelligence (Bixby Vision)
- com.samsung.android.arzone (AR Zone)

## Usage
1. Enable USB Debugging on your Samsung device.
2. Connect the device to your PC.
3. Run the script in PowerShell.
4. Choose from the interactive menu to uninstall or restore apps.
5. For custom apps, choose option 3 or 4.

## Safety Notes
- Only uninstall apps you are sure you do not use.
- Some apps (Samsung Account, Calendar, Email) are critical for Samsung services.
- Uninstalling apps via `--user 0` is reversible. Root removal is permanent and risky.
