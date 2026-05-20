# =============================================================================
# PolyMC / PrismLauncher -- packwiz pre-launch sync script (Windows)
# =============================================================================
# Syncs a packwiz modpack from a public GitHub repo before the game launches.
# Requires NOTHING from the host beyond Java, which PolyMC already manages.
# Uses only built-in .NET APIs -- no curl, wget, git, or anything extra.
#
# SETUP
# -----
# 1. Edit PACK_URL and optionally BOOTSTRAP_VERSION below.
# 2. Place this file in your instance's .minecraft folder.
# 3. In PolyMC/Prism: Edit Instance -> Settings -> Custom commands
#    Pre-launch command:
#      cmd /c powershell -ExecutionPolicy Bypass -File "%INST_MC_DIR%\pre-launch.ps1"
# 4. Tick "Wait for launch command to finish before starting game".
# =============================================================================

# -----------------------------------------------------------------------------
# USER CONFIGURATION -- edit these lines
# -----------------------------------------------------------------------------

$PackUrl          = "https://raw.githubusercontent.com/Broken7528/gurble-scratchpad/main/pack.toml"
$BootstrapVersion = "0.0.3"

# -----------------------------------------------------------------------------
# SCRIPT -- no need to edit below this line
# -----------------------------------------------------------------------------

$ErrorActionPreference = "Stop"

function Log { param($msg) Write-Host "[packwiz-sync] $msg" }
function Die { param($msg) Write-Error "[packwiz-sync] ERROR: $msg"; exit 1 }

$McDir   = if ($env:INST_MC_DIR) { $env:INST_MC_DIR } else { $PSScriptRoot }
$JavaBin = if ($env:INST_JAVA)   { $env:INST_JAVA }   else { "java" }

$BootstrapJar = Join-Path $McDir "packwiz-installer-bootstrap.jar"
$BootstrapUrl = "https://github.com/packwiz/packwiz-installer-bootstrap/releases/download/v$BootstrapVersion/packwiz-installer-bootstrap.jar"

# ---------- validate config ---------------------------------------------------

if ($PackUrl -like "*YOUR_USERNAME*") {
    Die "PACK_URL has not been configured. Edit pre-launch.ps1 and set your pack.toml URL."
}

# ---------- ensure the bootstrap jar is present ------------------------------

if (-not (Test-Path $BootstrapJar)) {
    Log "packwiz-installer-bootstrap.jar not found -- downloading v$BootstrapVersion..."
    try {
        $client = [System.Net.WebClient]::new()
        $client.Headers.Add("User-Agent", "packwiz-sync/1.0")
        $client.DownloadFile($BootstrapUrl, $BootstrapJar)
        Log "Downloaded packwiz-installer-bootstrap.jar"
    } catch {
        if (Test-Path $BootstrapJar) { Remove-Item $BootstrapJar -Force }
        Die "Failed to download bootstrap jar: $_"
    }
}

# ---------- run packwiz-installer-bootstrap ----------------------------------

Log "Syncing modpack from: $PackUrl"
Log "Instance dir:         $McDir"

Push-Location $McDir
try {
    $args = @("-Xmx256m", "-jar", $BootstrapJar, "-g", "-s", "client", $PackUrl)
    $proc = Start-Process -FilePath $JavaBin -ArgumentList $args -NoNewWindow -Wait -PassThru
    if ($proc.ExitCode -ne 0) {
        Die "packwiz-installer exited with code $($proc.ExitCode)"
    }
} finally {
    Pop-Location
}

Log "Sync complete. Launching Minecraft."
