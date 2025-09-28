# ===============================================
# Samsung Bloatware Manager - Interactive Version
# Features:
#   - Single-device check with robust exception handling
#   - Error logging
#   - Interactive uninstall/restore menu
#   - Predefined Samsung bloatware packages
#   - Optional ADB installation if missing
# Requirements:
#   - Windows PC
#   - USB Debugging enabled on Samsung device
#   - ADB installed (the script can download it)
# ===============================================

$logFile = "$env:USERPROFILE\SamsungBloatwareErrors.log"

# ----------------------------
# Function: Install ADB
# ----------------------------
function Install-ADB {
    $url = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
    $zipPath = "$env:DOWNLOAD\platform-tools-latest-windows.zip"
    $extractPath = "$env:USERPROFILE\Downloads\platform-tools-latest-windows"

    Write-Host "📥 Downloading ADB from Google..."
    # Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

    # Add to PATH if not present
    $envPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    if ($envPath -notlike "*platform-tools*") {
        [System.Environment]::SetEnvironmentVariable("PATH", "$envPath;$extractPath", "User")
    }

    Write-Host "✅ ADB installed at $extractPath"
    #Remove-Item $zipPath -Force
}

# ----------------------------
# Function: Check single authorized device
# ----------------------------

function Check-ADBDevice {
    try {
        # Get raw adb devices output
        $raw = adb devices
        # Remove header and empty lines
        $lines = $raw -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -and ($_ -notlike "List*" ) }

        if ($lines.Count -eq 0) {
            throw "No devices detected. Connect your device with USB debugging enabled."
        }

        if ($lines.Count -gt 1) {
            throw "Multiple devices detected. This script handles only one device. Disconnect other devices."
        }

        # Split device info safely and remove empty entries
        <#$deviceInfo = ($lines[0] -split '\s+') | Where-Object { $_ -ne "" }

        if ($deviceInfo.Count -lt 2) {
            throw "Unable to parse device line: '$($lines[0])'"
        }

        $deviceID = $deviceInfo[0]
        $status   = $deviceInfo[1]

        switch ($status) {
            "device" {
                Write-Host "✅ Authorized device found: $deviceID"
            }
            "unauthorized" {
                throw "Device $deviceID is unauthorized. Accept the USB debugging prompt on your phone."
            }
            "offline" {
                throw "Device $deviceID is offline. Reconnect the USB cable."
            }
            default {
                throw "Unknown device status: $deviceID ($status)"
            }
        }#>

    } catch {
        Write-Error "❌ ADB check error: $_"
        exit
    }
}


# ----------------------------
# Check ADB and device
# ----------------------------
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    Write-Host "❌ ADB not detected."
    $install = Read-Host "👉 Do you want to download and install ADB now? (y/n)"
    if ($install -eq "y") { Install-ADB } else { exit }
}

Check-ADBDevice

# ----------------------------
# Predefined Samsung bloatware packages
# ----------------------------
$packages = @(
    "com.sec.android.app.sbrowser",                # Samsung Internet
    "com.samsung.android.app.sbrowseredge",       # Samsung Internet Edge
    "com.samsung.android.spay",                   # Samsung Pay
    "com.samsung.android.spayfw",                 # Samsung Pay Framework
    "com.sec.android.app.music",                  # Samsung Music
    "com.samsung.android.video",                  # Samsung Video
    "com.samsung.android.game.gamehome",          # Game Launcher
    "com.samsung.android.game.gos",               # Game Optimizing Service
    "com.samsung.android.app.spage",              # Samsung Free / Daily
    "com.samsung.android.bixby.service",          # Bixby Core
    "com.samsung.android.visionintelligence",     # Bixby Vision
    "com.samsung.android.arzone"                  # AR Zone
)

# ----------------------------
# Function: List installed apps
# ----------------------------
function List-Packages {
    param([string]$filter = "")

    try {
        Write-Host "`n📋 Installed apps list:"
        $global:pkgList = adb shell pm list packages | ForEach-Object { $_.Replace("package:", "") }

        if ($filter -ne "") {
            $global:pkgList = $global:pkgList | Where-Object { $_ -like "*$filter*" }
        }

        $i = 1
        foreach ($pkg in $global:pkgList) {
            Write-Host "$i. $pkg"
            $i++
        }
    } catch {
        Write-Warning "⚠️ Failed to retrieve package list. Ensure device is connected and authorized."
        "$((Get-Date).ToString()): Failed to retrieve package list - $_" | Out-File -Append $logFile
    }
}

# ----------------------------
# Function: Uninstall package safely
# ----------------------------
function Uninstall-Package {
    param([string]$pkg)
    try {
        adb shell pm uninstall --user 0 $pkg | Out-Null
        Write-Host "✅ Uninstalled $pkg"
    } catch {
        Write-Warning "⚠️ Could not uninstall $pkg"
        "$((Get-Date).ToString()): Failed to uninstall $pkg - $_" | Out-File -Append $logFile
    }
}

# ----------------------------
# Function: Restore package safely
# ----------------------------
function Restore-Package {
    param([string]$pkg)
    try {
        adb shell cmd package install-existing $pkg | Out-Null
        Write-Host "🔄 Restored $pkg"
    } catch {
        Write-Warning "⚠️ Could not restore $pkg"
        "$((Get-Date).ToString()): Failed to restore $pkg - $_" | Out-File -Append $logFile
    }
}

# ----------------------------
# Interactive menu
# ----------------------------
Write-Host "===== Samsung Bloatware Manager ====="
Write-Host "1. Uninstall predefined Samsung bloatware"
Write-Host "2. Restore predefined Samsung bloatware"
Write-Host "3. List all apps and choose one to uninstall"
Write-Host "4. List all apps and choose one to restore"
Write-Host "5. Exit"
$choice = Read-Host "👉 Choose an option (1-5)"

switch ($choice) {
    "1" { foreach ($pkg in $packages) { Uninstall-Package $pkg } }
    "2" { foreach ($pkg in $packages) { Restore-Package $pkg } }
    "3" {
        List-Packages
        $num = Read-Host "👉 Enter the number of the app to uninstall"
        $target = $pkgList[$num-1]
        Uninstall-Package $target
    }
    "4" {
        List-Packages
        $num = Read-Host "👉 Enter the number of the app to restore"
        $target = $pkgList[$num-1]
        Restore-Package $target
    }
    "5" { exit }
}
