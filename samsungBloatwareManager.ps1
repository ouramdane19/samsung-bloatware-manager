# ===============================================
# # Samsung Bloatware Manager - Interactive Version with Readable Names
# Description:
#   This PowerShell script allows you to manage Samsung bloatware on your Android device.
#   Features include:
#     - Downloading and installing ADB if missing
#     - Listing installed apps with readable names
#     - Uninstalling/restoring predefined Samsung bloatware
#     - Interactive selection for uninstall/restore
#
# Prerequisites:
#   - Windows PC
#   - USB debugging enabled on your Samsung device
#   - ADB installed (the script can download it if missing)
# ===============================================

# Function to download and install ADB if not found
function Install-ADB {
    $url = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
    $zipPath = "$env:env:USERPROFILE\Downloads\platform-tools-latest-windows.zip"
    $extractPath = "$env:USERPROFILE\Downloads\platform-tools-latest-windows"

    Write-Host "📥 Downloading ADB from Google..."
    # Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

    # Add platform-tools to user PATH
    $envPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    if ($envPath -notlike "*platform-tools*") {
        [System.Environment]::SetEnvironmentVariable("PATH", "$envPath;$extractPath", "User")
    }

    Write-Host "✅ ADB installed at $extractPath"
    Remove-Item $zipPath -Force
}

# Check if ADB is available
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    Write-Host "❌ ADB not detected."
    $install = Read-Host "👉 Do you want to download and install ADB now? (y/n)"
    if ($install -eq "y") { Install-ADB } else { exit }
}

# Predefined Samsung bloatware packages
$packages = @(
    "com.sec.android.app.sbrowser",                # Samsung Internet
    "com.samsung.android.app.sbrowseredge",       # Samsung Internet Edge
    #"com.sec.android.app.samsungapps",           # Galaxy Store (commented out)
    "com.samsung.android.spay",                   # Samsung Pay
    "com.samsung.android.spayfw",                # Samsung Pay Framework
    "com.sec.android.app.music",                  # Samsung Music
    "com.samsung.android.video",                  # Samsung Video
    "com.samsung.android.game.gamehome",          # Game Launcher
    "com.samsung.android.game.gos",               # Game Optimizing Service
    #"com.samsung.android.scloud",               # Samsung Cloud (commented out)
    #"com.samsung.android.samsungcloudsync",     # Samsung Cloud Sync (commented out)
    #"com.osp.app.signin",                        # Samsung Account (commented out)
    #"com.sec.android.app.shealth",               # Samsung Health (commented out)
    "com.samsung.android.app.spage",              # Samsung Free / Daily
    "com.samsung.android.bixby.service",          # Bixby Core
    "com.samsung.android.visionintelligence",     # Bixby Vision
    "com.samsung.android.arzone"                  # AR Zone
)

# Function to get readable app label (placeholder, currently returns package name)
function Get-AppLabel {
    param([string]$pkg)
    $label = adb shell dumpsys package $pkg | Select-String "labelRes=" -ErrorAction SilentlyContinue
    if ($label) {
        return $pkg
    } else {
        return $pkg
    }
}

# Function to list installed apps with package names
function List-Packages {
    param([string]$filter = "")

    Write-Host "`n📋 Installed apps list:"
    $global:pkgList = adb shell pm list packages | ForEach-Object { $_.Replace("package:", "") }

    if ($filter -ne "") {
        $global:pkgList = $global:pkgList | Where-Object { $_ -like "*$filter*" }
    }

    $i = 1
    foreach ($pkg in $global:pkgList) {
        $label = adb shell dumpsys package $pkg | Select-String "ApplicationInfo" -ErrorAction SilentlyContinue
        if ($label) {
            $line = $label.ToString().Split(" ") | Where-Object { $_ -like "*label*" }
            Write-Host "$i. $pkg    ($line)"
        } else {
            Write-Host "$i. $pkg"
        }
        $i++
    }
}

# Interactive menu
Write-Host "===== Samsung Bloatware Manager ====="
Write-Host "1. Uninstall predefined Samsung bloatware"
Write-Host "2. Restore predefined Samsung bloatware"
Write-Host "3. List all apps and choose one to uninstall"
Write-Host "4. List all apps and choose one to restore"
Write-Host "5. Exit"
$choice = Read-Host "👉 Choose an option (1-5)"

switch ($choice) {
    "1" {
        foreach ($pkg in $packages) {
            Write-Host "🚀 Uninstalling $pkg"
            adb shell pm uninstall --user 0 $pkg | Out-Null
        }
        Write-Host "✅ Done."
    }
    "2" {
        foreach ($pkg in $packages) {
            Write-Host "🔄 Restoring $pkg"
            adb shell cmd package install-existing $pkg | Out-Null
        }
        Write-Host "✅ Done."
    }
    "3" {
        List-Packages
        $num = Read-Host "👉 Enter the number of the app to uninstall"
        $target = $pkgList[$num-1]
        Write-Host "🚀 Uninstalling $target..."
        adb shell pm uninstall --user 0 $target
    }
    "4" {
        List-Packages
        $num = Read-Host "👉 Enter the number of the app to restore"
        $target = $pkgList[$num-1]
        Write-Host "🔄 Restoring $target..."
        adb shell cmd package install-existing $target
    }
    "5" { exit }
}
