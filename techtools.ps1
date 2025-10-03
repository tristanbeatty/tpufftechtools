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

function Run-WindowsUpdateMenu {
    do {
        Clear-Host
        Write-SectionTitle "Windows Update Tools"
        Write-Host '[1] Check for Updates'
        Write-Host '[2] Install Updates (prompt each)'
        Write-Host '[3] Install Updates (auto, reboot if needed)'
        Write-Host '[4] Show Update History'
        Write-Host '[M] System Tools Menu'
        Write-Host '[Q] Quit'
        Write-Host ""

        $choice = (Read-Host "Select an option").Trim().ToUpper()

        switch ($choice) {
            '1' {
                try {
                    Ensure-PSWindowsUpdate
                    Get-WindowsUpdate
                } catch {
                    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                }
                Pause-Return
            }
            '2' {
                try {
                    Ensure-PSWindowsUpdate
                    Install-WindowsUpdate
                } catch {
                    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                }
                Pause-Return
            }
            '3' {
                try {
                    Ensure-PSWindowsUpdate
                    Install-WindowsUpdate -AcceptAll -AutoReboot
                } catch {
                    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                }
                Pause-Return
            }
            '4' {
                try {
                    Ensure-PSWindowsUpdate
                    Get-WUHistory | Select-Object -First 20
                } catch {
                    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                }
                Pause-Return
            }
            'M' { return }
            'Q' { $script:ExitRequested = $true; return }
            default {
                if ($choice -ne '') {
                    Write-Host 'Invalid selection.' -ForegroundColor Yellow
                    Start-Sleep 1.2
                }
            }
        }
    } while ($true)
}

# ============================
# Network Tools Menu
# ============================
function Run-NetworkToolsMenu {
    do {
        Clear-Host
        Write-SectionTitle "Network Tools"
        Write-Host '[1] Show IP configuration'
        Write-Host '[2] Release/Renew DHCP'
        Write-Host '[3] Flush DNS cache'
        Write-Host '[4] Display Routing Table'
        Write-Host '[5] Show Active Connections'
        Write-Host '[M] Main Menu'
        Write-Host '[Q] Quit'
        Write-Host ""

        $netChoice = (Read-Host "Select an option").Trim().ToUpper()
        switch ($netChoice) {
            '1' { ipconfig /all; Pause-Return }
            '2' { ipconfig /release; Start-Sleep 2; ipconfig /renew; Pause-Return }
            '3' { ipconfig /flushdns; Pause-Return }
            '4' { route print; Pause-Return }
            '5' { netstat -ano; Pause-Return }
            'M' { return }
            'Q' { $script:ExitRequested = $true; return }
            default { Write-Host 'Unknown option.' -ForegroundColor Yellow; Start-Sleep 1.2 }
        }
    } until ($false)
}

# ============================
# Printer Tools Menu
# ============================
function Run-PrinterToolsMenu {
    do {
        Clear-Host
        Write-SectionTitle "Printer Tools"
        Write-Host '[1] Open Devices & Printers'
        Write-Host '[2] Restart Spooler'
        Write-Host '[3] Clear Print Queue'
        Write-Host '[4] List Installed Printers'
        Write-Host '[5] List Printer Ports'
        Write-Host '[6] Add Network Printer'
        Write-Host '[M] Main Menu'
        Write-Host '[Q] Quit'
        Write-Host ""

        $netChoice = (Read-Host "Select an option").Trim().ToUpper()
        switch ($netChoice) {
            '1' { Start-Process control.exe printers; Pause-Return }
            '2' {
                try {
                    Restart-Service spooler -Force
                    Write-Host 'Print Spooler restarted' -ForegroundColor Green
                } catch {
                    Write-Host ("Failed to restart spooler: {0}" -f $_.Exception.Message) -ForegroundColor Red
                }
                Pause-Return
            }
            '3' {
                try {
                    Stop-Service spooler -Force
                    Remove-Item "$env:SystemRoot\System32\spool\PRINTERS\*" -Force -ErrorAction SilentlyContinue
                    Start-Service spooler
                    Write-Host 'Print Queue cleared' -ForegroundColor Green
                } catch {
                    Write-Host ("Failed to clear queue: {0}" -f $_.Exception.Message) -ForegroundColor Red
                }
                Pause-Return
            }
            '4' { Get-Printer | Format-Table Name, DriverName, PortName; Pause-Return }
            '5' { Get-PrinterPort | Format-Table Name, PrinterHostAddress; Pause-Return }
            '6' {
                $path = Read-Host "Enter network printer path (\\Server\Printer)"
                try {
                    Add-Printer -ConnectionName $path
                    Write-Host ("Printer added: {0}" -f $path) -ForegroundColor Green
                } catch {
                    Write-Host ("Error adding printer: {0}" -f $_.Exception.Message) -ForegroundColor Red
                }
                Pause-Return
            }
            'M' { return }
            'Q' { $script:ExitRequested = $true; return }
            default { Write-Host 'Invalid selection' -ForegroundColor Yellow; Start-Sleep 2 }
        }
    } until ($false)
}

# ============================
# System Tools Menu
# ============================
function Run-SystemToolsMenu {
    # [your full System Tools Menu code stays here — unchanged from your version]
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
