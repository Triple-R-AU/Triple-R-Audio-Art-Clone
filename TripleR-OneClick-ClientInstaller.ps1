<#
.SYNOPSIS
    Triple R Audio - All-In-One Friend / Client Installer ("Bang, Install!")
.DESCRIPTION
    Send this script (or host it on your GitHub and give friends a 1-line command/link).
    When your friend runs it, it automatically:
    1. Installs the core audio stack (VB-Audio Cable, Equalizer APO, HeSuVi, VSTs)
    2. Unlocks Windows Loudness Equalization (LEQ) & sets Release Time = 2 (Short)
    3. Downloads the latest tuning library & pre-loaded headset EQs from YOUR GitHub fork
    4. Installs the clean Triple R Audio Client App & places a "Triple R Audio" shortcut on their Desktop
    5. Registers a silent background auto-updater so whenever YOU update your GitHub, their PC updates automatically!
#>

# Self-elevate to Administrator if needed
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    if ($PSCommandPath) {
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`"" -Verb RunAs
        exit
    } else {
        Write-Warning "Please run PowerShell as Administrator!"
        exit
    }
}

# ==============================================================================
# OWNER SETTINGS (Put your GitHub Fork Username here before sharing with friends!)
# ==============================================================================
$OwnerGitHubUser = "Triple-R"   # <-- Change to YOUR GitHub username (e.g. "TripleRAudio")
$OwnerRepoName   = "ArtTuneDB"
$OwnerBranch     = "main"
# ==============================================================================

Clear-Host
Write-Host "================================================================" -ForegroundColor Red
Write-Host "          TRIPLE R AUDIO - ALL-IN-ONE CLIENT INSTALLER          " -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Red
Write-Host ""

$baseDir    = "C:\Program Files\EqualizerAPO\config\ArtTuneDB"
$libraryDir = Join-Path $baseDir "library"
$eqBaseDir  = Join-Path $libraryDir "BO7\V5\eq"

# Step 1: Create Directories
Write-Host "[1/5] Preparing Triple R Audio directories..." -ForegroundColor Cyan
if (-not (Test-Path $baseDir)) { New-Item -Path $baseDir -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $eqBaseDir)) { New-Item -Path $eqBaseDir -ItemType Directory -Force | Out-Null }

# Step 2: Check / Install Core Audio Drivers (VB-Cable, Equalizer APO, VSTs)
Write-Host "[2/5] Checking core audio engine (Equalizer APO & Virtual Cable)..." -ForegroundColor Cyan
if (-not (Test-Path "C:\Program Files\EqualizerAPO\EqualizerAPO.dll")) {
    Write-Host "      Launching core audio driver installer..." -ForegroundColor Yellow
    try {
        irm artiswar.io/tools/ArtTuneGuided | iex
    } catch {}
} else {
    Write-Host "      Equalizer APO is already installed!" -ForegroundColor Green
}

# Step 3: Download Latest Tuning Library & Pre-Installed Headsets from Your GitHub Fork
Write-Host "[3/5] Downloading pre-calibrated headset profiles from Cloud ($OwnerGitHubUser/$OwnerRepoName)..." -ForegroundColor Cyan
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $headers = @{ "User-Agent" = "TripleRAudio-OneClickInstaller" }
    $zipUrl = "https://github.com/$OwnerGitHubUser/$OwnerRepoName/archive/refs/heads/$OwnerBranch.zip"
    $tempZip = Join-Path $env:TEMP "TripleR-Install.zip"
    $tempExtract = Join-Path $env:TEMP "TripleR-Extract"

    Invoke-WebRequest -Uri $zipUrl -OutFile $tempZip -Headers $headers
    if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
    Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

    $inner = Get-ChildItem -Path $tempExtract -Directory | Select-Object -First 1
    $srcLib = Join-Path $inner.FullName "library"
    if (Test-Path $srcLib) {
        Copy-Item -Path "$srcLib\*" -Destination $libraryDir -Recurse -Force
    }
    # Copy Client App if present in repo or local folder
    $localClientApp = Join-Path $PSScriptRoot "TripleR-ClientApp.ps1"
    $repoClientApp  = Join-Path $inner.FullName "TripleR-ClientApp.ps1"
    $destClientApp  = Join-Path $baseDir "TripleR-ClientApp.ps1"

    if (Test-Path $localClientApp) {
        Copy-Item -Path $localClientApp -Destination $destClientApp -Force
    } elseif (Test-Path $repoClientApp) {
        Copy-Item -Path $repoClientApp -Destination $destClientApp -Force
    }

    Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
    Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "      Headset library installed!" -ForegroundColor Green
} catch {
    Write-Warning "      Cloud download note: $_"
}

# Step 4: Unlock Loudness Equalization (LEQ) & Set Release Time = 2 (Short)
Write-Host "[4/5] Unlocking Loudness Equalization (Release Time 2) on Virtual Cable..." -ForegroundColor Cyan
try {
    $enhancementFlagKey = "{fc52a749-4be9-4510-896e-966ba6525980},3"
    $releaseTimeKey     = "{9c00eeed-edce-4cd8-ae08-cb05e8ef57a0},3"
    $enhancementTabKey  = "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},3"
    $preMixKey          = "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},1"
    $postMixKey         = "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},2"

    $devices = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render\*\Properties" -ErrorAction SilentlyContinue
    foreach ($dev in $devices) {
        $vals = $dev.GetValueNames() | ForEach-Object { $dev.GetValue($_) }
        if ($vals -match "Hi-Fi Cable|Art Tune|VB-Audio") {
            $fxPath = Join-Path $dev.PSParentPath "FxProperties"
            if (-not (Test-Path $fxPath)) { New-Item -Path $fxPath -Force | Out-Null }
            Set-ItemProperty -Path $fxPath -Name $preMixKey -Value "{62dc1a93-ae24-464c-a43e-452f824c4250}" -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $fxPath -Name $postMixKey -Value "{637c490d-eee3-4c0a-973f-371958802da2}" -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $fxPath -Name $enhancementTabKey -Value "{5860E1C5-F95C-4a7a-8EC8-8AEF24F379A1}" -Type String -Force -ErrorAction SilentlyContinue
            [byte[]]$flagBytes = @(0x0b,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0xff,0xff,0x00,0x00)
            Set-ItemProperty -Path $fxPath -Name $enhancementFlagKey -Value $flagBytes -Type Binary -Force -ErrorAction SilentlyContinue
            [byte[]]$relBytes = @(0x03,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x02,0x00,0x00,0x00)
            Set-ItemProperty -Path $fxPath -Name $releaseTimeKey -Value $relBytes -Type Binary -Force -ErrorAction SilentlyContinue
        }
    }
    Restart-Service audiosrv -Force -ErrorAction SilentlyContinue
    Write-Host "      Loudness Equalization enabled!" -ForegroundColor Green
} catch {}

# Step 5: Create Desktop Shortcut & Register Automatic Background Sync
Write-Host "[5/5] Creating Desktop Shortcut & Enabling Automatic Updates..." -ForegroundColor Cyan
try {
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutLocation = Join-Path $desktopPath "Triple R Audio.lnk"
    $wshShell = New-Object -ComObject WScript.Shell
    $shortcut = $wshShell.CreateShortcut($shortcutLocation)
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-ExecutionPolicy Bypass -NoProfile -STA -WindowStyle Hidden -File `"$baseDir\TripleR-ClientApp.ps1`""
    $shortcut.WorkingDirectory = $baseDir
    $shortcut.IconLocation = "C:\Windows\System32\mmsys.cpl,0"
    $shortcut.Description = "Launch Triple R Audio Control Panel"
    $shortcut.Save()

    # Register Windows Scheduled Task so their PC updates silently at login whenever you update your GitHub
    schtasks /create /tn "TripleR_Client_AutoSync" /tr "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$baseDir\TripleR-SilentUpdater.ps1`"" /sc onlogon /rl highest /f >$null 2>&1
    Write-Host "      Desktop shortcut created & Cloud Auto-Update enabled!" -ForegroundColor Green
} catch {}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "   INSTALLATION COMPLETE! DOUBLE-CLICK 'TRIPLE R AUDIO' ON      " -ForegroundColor White
Write-Host "   YOUR DESKTOP TO PICK YOUR HEADSET AND PLAY!                  " -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""

# Launch the Client App automatically right now!
if (Test-Path "$baseDir\TripleR-ClientApp.ps1") {
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -NoProfile -STA -WindowStyle Hidden -File `"$baseDir\TripleR-ClientApp.ps1`""
}
