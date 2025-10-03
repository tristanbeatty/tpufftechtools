# ============================
# Requirements & Configuration
# ============================
#Requires -Version 5.1
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

# ============================
# Run As Administrator
# ============================
function Ensure-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host 'Restarting as Administrator...' -ForegroundColor Yellow

        # Fallback path handling for in-memory execution
        $cmdPath = $PSCommandPath
        if (-not $cmdPath -and $MyInvocation.MyCommand -and ($MyInvocation.MyCommand | Get-Member -Name Path -ErrorAction SilentlyContinue)) {
            $cmdPath = $MyInvocation.MyCommand.Path
        }
        if (-not $cmdPath) { $cmdPath = (Get-Location).Path }

        $args = "-NoProfile -ExecutionPolicy Bypass -File `"`"$cmdPath`"`""
        $exe = (Get-Command pwsh.exe -ErrorAction SilentlyContinue).Source
        if (-not $exe) { $exe = (Get-Command powershell.exe -ErrorAction Stop).Source }

        Start-Process -FilePath $exe -ArgumentList $args -Verb RunAs
        exit
    }
}

# ============================
# Initialization & Paths
# ============================
function Initialize {
    # Fallback if running in-memory (PSCommandPath is null)
    $cmdPath = $PSCommandPath
    if (-not $cmdPath -and $MyInvocation.MyCommand -and ($MyInvocation.MyCommand | Get-Member -Name Path -ErrorAction SilentlyContinue)) {
        $cmdPath = $MyInvocation.MyCommand.Path
    }
    if (-not $cmdPath) { $cmdPath = (Get-Location).Path }

    $script:BaseDir    = Split-Path -Parent $cmdPath
    $script:LogsDir    = Join-Path $BaseDir 'Logs'
    $script:ScriptsDir = Join-Path $BaseDir 'Scripts'
    New-Item -ItemType Directory -Force -Path $LogsDir, $ScriptsDir | Out-Null

    $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
    $script:LogFile = Join-Path $LogsDir "Dashboard_$ts.log"
    try { Start-Transcript -Path $LogFile -Append | Out-Null } catch {}

    $Host.UI.RawUI.WindowTitle = "TPuff Tech Tools - $env:COMPUTERNAME"
}

# ============================
# Section Title Function
# ============================
function Write-SectionTitle {
    param (
        [string]$Title,
        [ConsoleColor]$Color = 'Cyan'
    )
    $line = ('=' * ($Title.Length + 4))
    Write-Host ""
    Write-Host ('+{0}+' -f $line) -ForegroundColor $Color
    Write-Host ('|  {0}  |' -f $Title) -ForegroundColor $Color
    Write-Host ('+{0}+' -f $line) -ForegroundColor $Color
    Write-Host ""
}

# ============================
# Main Header
# ============================
function Show-Header {
    Clear-Host
    Write-SectionTitle "TPuff Tech Tools"
    Write-Host "Computer: $env:COMPUTERNAME"
    Write-Host "Log: $LogFile"
    Write-Host ""
}

# ============================
# Script Picker UI
# ============================
function Invoke-ScriptPicker {
    $items = @(Get-ChildItem -Path $ScriptsDir -Filter *.ps1 -File -ErrorAction SilentlyContinue | Sort-Object Name)

    if (-not $items -or $items.Count -eq 0) {
        Write-Host "No .ps1 files in $ScriptsDir" -ForegroundColor Yellow
        Pause-Return
        return
    }

    Clear-Host
    Write-Host "Available Scripts:" -ForegroundColor Cyan
    Write-Host "------------------"

    for ($i = 0; $i -lt $items.Count; $i++) {
        Write-Host ("[{0}] {1}" -f ($i + 1), $items[$i].Name)
    }
    Write-Host '[M] Back to Main Menu'
    Write-Host ""

    $sel = Read-Host "Choose number of script to run"
    if ($sel.Trim().ToUpper() -eq 'M') { return }

    if ($sel -as [int] -and $sel -ge 1 -and $sel -le $items.Count) {
        $target = $items[$sel - 1].FullName
        try {
            & $target
        } catch {
            Write-Host ("Error running script: {0}" -f $_.Exception.Message) -ForegroundColor Red
        }
    } else {
        Write-Host 'Invalid selection' -ForegroundColor Yellow
    }

    Pause-Return
}

# ============================
# Pause Helper
# ============================
function Pause-Return { [void](Read-Host "Press Enter to return to menu") }

# ============================
# Windows Update Helpers & Menu
# ============================
function Ensure-PSWindowsUpdate {
    try {
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop | Out-Null
            }
            Install-Module -Name PSWindowsUpdate -Force -Scope AllUsers -ErrorAction Stop
        }
        Import-Module PSWindowsUpdate -Force -ErrorAction Stop
    } catch {
        throw "PSWindowsUpdate not available: $($_.Exception.Message)"
    }
}

# ============================
# Windows Update Menu
# ============================
function Run-WindowsUpdateMenu {
    # [unchanged... your existing menu code here]
}

# ============================
# Network Tools Menu
# ============================
function Run-NetworkToolsMenu {
    # [unchanged... your existing menu code here]
}

# ============================
# Printer Tools Menu
# ============================
function Run-PrinterToolsMenu {
    # [unchanged... your existing menu code here]
}

# ============================
# System Tools Menu
# ============================
function Run-SystemToolsMenu {
    # [unchanged... your existing menu code here]
}

# ============================
# Build Main Menu Items
# ============================
function Build-Menu {
    @(
        @{ Key='1'; Name='Network Tools';               Action = { Run-NetworkToolsMenu } }
        @{ Key='2'; Name='Printer Tools';               Action = { Run-PrinterToolsMenu } }
        @{ Key='3'; Name='System Tools';                Action = { Run-SystemToolsMenu } }
        @{ Key='S'; Name='Run a script from .\Scripts'; Action = { Invoke-ScriptPicker } }
        @{ Key='Q'; Name='Quit';                        Action = { $script:ExitRequested = $true } }
    )
}

# ============================
# Show Main Menu
# ============================
function Show-Menu {
    Show-Header
    foreach ($item in $script:Menu) {
        Write-Host ("[{0}] {1}" -f $item.Key, $item.Name)
    }
    Write-Host ""
}

# ============================
# Run Menu Interaction Loop
# ============================
function Run-Menu {
    do {
        Show-Menu
        $choice = (Read-Host "Select option").Trim().ToUpper()
        $match = $script:Menu | Where-Object { $_.Key -eq $choice }
        if ($null -ne $match) {
            try { & $match.Action }
            catch {
                Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
                $_ | Format-List * -Force
                Pause-Return
            }
        } else {
            if ($choice -ne '') {
                Write-Host 'Unknown option.' -ForegroundColor Yellow
                Start-Sleep 1.2
            }
        }
    } until ($script:ExitRequested)
}

# ============================
# Entry Point / Main Loop
# ============================
Ensure-Admin
Initialize
$script:ExitRequested = $false
$script:Menu = Build-Menu
Run-Menu
try { Stop-Transcript | Out-Null } catch {}
