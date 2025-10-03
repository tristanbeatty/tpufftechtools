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
        if (-not $cmdPath) {
            Write-Host "Cannot determine script path when running in-memory. Relaunch manually if needed." -ForegroundColor Red
            exit 1
        }

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

    try { $Host.UI.RawUI.WindowTitle = "TPuff Tech Tools - $env:COMPUTERNAME" } catch {}
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
                    Get-WindowsUpdate -Verbose
                } catch {
                    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                }
                Pause-Return
            }
            '2' {
                try {
                    Ensure-PSWindowsUpdate
                    Install-WindowsUpdate -Verbose
                } catch {
                    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                }
                Pause-Return
            }
            '3' {
                try {
                    Ensure-PSWindowsUpdate
                    Write-Host "Scanning for updates..." -ForegroundColor Cyan
                    $updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreUserInput -ErrorAction Stop
                    if ($updates) {
                        Write-Host "Installing updates..." -ForegroundColor Cyan
                        Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot -Verbose
                    } else {
                        Write-Host "No updates found." -ForegroundColor Yellow
                    }
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
# Dell Update Helpers
# ============================
function Ensure-DellCommandUpdate {
    $dcuPath = "${env:ProgramFiles(x86)}\Dell\CommandUpdate\dcu-cli.exe"
    if (-not (Test-Path $dcuPath)) {
        Write-Host "Dell Command | Update not found. Downloading installer..." -ForegroundColor Yellow
        $url = "https://downloads.dell.com/FOLDER09891821M/1/Dell-Command-Update-Windows-Universal-Application_5F7N4_WIN_5.1.0_A00.EXE"
        $temp = Join-Path $env:TEMP "DellCommandUpdate.exe"
        try {
            Invoke-WebRequest -Uri $url -OutFile $temp -UseBasicParsing -ErrorAction Stop
            Write-Host "Installing Dell Command | Update..." -ForegroundColor Cyan
            Start-Process -FilePath $temp -ArgumentList "/quiet" -Wait
            Remove-Item $temp -Force
        } catch {
            throw "Failed to download or install Dell Command | Update: $($_.Exception.Message)"
        }
    }
    return $dcuPath
}

function Run-DellUpdate {
    try {
        $dcu = Ensure-DellCommandUpdate

        Write-Host "Scanning for Dell updates..." -ForegroundColor Cyan
        & $dcu /scan

        Write-Host "Installing available updates..." -ForegroundColor Cyan
        & $dcu /applyUpdates -reboot=enable -autoSuspendBitLocker=enable

        Write-Host "Dell updates process completed. If a reboot is required, the system will restart automatically." -ForegroundColor Yellow
    } catch {
        Write-Host "Error during Dell update: $($_.Exception.Message)" -ForegroundColor Red
    }
    Pause-Return
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
    do {
        Clear-Host
        Write-SectionTitle "System Tools"
        Write-Host '[1] Show System Info'
        Write-Host '[2] Change Computer Name'
        Write-Host '[3] List Local Users'
        Write-Host '[4] Remove Local User'
        Write-Host '[5] Create Local User'
        Write-Host '[6] Activate Local User'
        Write-Host '[7] Deactivate Local User'
        Write-Host '[8] Change User Password'
        Write-Host '[9] Windows Update Tools'
        Write-Host '[10] Dell Updates'
        Write-Host '[M] Main Menu'
        Write-Host '[Q] Quit'
        Write-Host ""

        $choice = (Read-Host "Select an option").Trim().ToUpper()

        switch ($choice) {
            '1' {
                try {
                    Write-Host "Computer" -ForegroundColor Cyan
                    Get-CimInstance Win32_ComputerSystem |
                        Select-Object Name, Manufacturer, Model, TotalPhysicalMemory
                    Get-CimInstance Win32_OperatingSystem |
                        Select-Object Caption, Version, BuildNumber, LastBootUpTime
                    Get-Volume |
                        Select-Object DriveLetter,FileSystemLabel,FileSystem,
                                      @{n='Free(GB)';e={[math]::Round($_.SizeRemaining/1GB,1)}},
                                      @{n='Size(GB)';e={[math]::Round($_.Size/1GB,1)}} |
                        Sort-Object DriveLetter | Format-Table -Auto
                } catch {
                    Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
                }
                Pause-Return
            }
            '2' {
                $newName = (Read-Host "Enter new computer name").Trim()
                if ([string]::IsNullOrWhiteSpace($newName)) {
                    Write-Host 'No name entered.' -ForegroundColor Yellow
                    Pause-Return
                    return
                }
                try {
                    Rename-Computer -NewName $newName -Force
                    Write-Host ("Computer name set to {0}" -f $newName) -ForegroundColor Green
                    $r = (Read-Host "Restart now to apply? (Y/N)").Trim().ToUpper()
                    if ($r -eq 'Y') { Restart-Computer -Force }
                } catch {
                    Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
                }
                Pause-Return
            }
            '3' {
                try {
                    Get-LocalUser |
                        Select-Object Name,Enabled,LastLogon,PasswordRequired,PasswordNeverExpires |
                        Sort-Object Name | Format-Table -Auto
                } catch {
                    Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
                }
                Pause-Return
            }
            '4' {
                $user = (Read-Host "Enter local username to remove").Trim()
                if ([string]::IsNullOrWhiteSpace($user)) {
                    Write-Host 'No username entered.' -ForegroundColor Yellow
                    Pause-Return
                    return
                }
                try {
                    $lu = Get-LocalUser -Name $user -ErrorAction SilentlyContinue
                    if (-not $lu) {
                        Write-Host ("User '{0}' not found." -f $user) -ForegroundColor Yellow
                    } elseif ($lu.Name -in @('Administrator','Guest')) {
                        Write-Host "Refusing to remove built-in accounts." -ForegroundColor Yellow
                    } elseif ($lu.Name -eq $env:USERNAME) {
                        Write-Host "Refusing to remove the currently logged-in user." -ForegroundColor Yellow
                    } else {
                        $conf = (Read-Host "Type DELETE to confirm removing '$user'").ToUpper()
                        if ($conf -eq 'DELETE') {
                            Remove-LocalUser -Name $user
                            Write-Host ("User '{0}' removed." -f $user) -ForegroundColor Green
                        } else {
                            Write-Host 'Cancelled.' -ForegroundColor Yellow
                        }
                    }
                } catch {
                    Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
                }
                Pause-Return
            }
            '5' {
                $name = (Read-Host "Enter new username").Trim()
                if ([string]::IsNullOrWhiteSpace($name)) {
                    Write-Host 'No username entered.' -ForegroundColor Yellow
                    Pause-Return
                    return
                }
                try {
                    if (Get-LocalUser -Name $name -ErrorAction SilentlyContinue) {
                        Write-Host ("User '{0}' already exists." -f $name) -ForegroundColor Yellow
                        Pause-Return
                        return
                    }

                    $full = Read-Host "Full name (optional)"
                    $desc = Read-Host "Description (optional)"
                    Write-Host "Enter initial password:" -ForegroundColor Cyan
                    $pwd = Read-Host -AsSecureString

                    New-LocalUser -Name $name -Password $pwd -FullName $full -Description $desc -ErrorAction Stop
                    Enable-LocalUser -Name $name

                    $grp = (Read-Host "(A)dd to Administrators, (U)sers, or (N)o group change [A/U/N]").Trim().ToUpper()
                    switch ($grp) {
                        'A' { Add-LocalGroupMember -Group 'Administrators' -Member $name -ErrorAction Stop; Write-Host "Added to Administrators." -ForegroundColor Green }
                        'U' { Add-LocalGroupMember -Group 'Users' -Member $name -ErrorAction Stop; Write-Host "Added to Users." -ForegroundColor Green }
                        default { Write-Host 'No group changes.' -ForegroundColor Yellow }
                    }

                    Write-Host ("User '{0}' created." -f $name) -ForegroundColor Green
                } catch {
                    Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
                }
                Pause-Return
            }
            '6' {
                $user = (Read-Host "Enter local username to activate").Trim()
                if ([string]::IsNullOrWhiteSpace($user)) {
                    Write-Host 'No username entered.' -ForegroundColor Yellow
                    Pause-Return
                    return
                }
                try {
                    $lu = Get-LocalUser -Name $user -ErrorAction SilentlyContinue
                    if (-not $lu) {
                        Write-Host ("User '{0}' not found." -f $user) -ForegroundColor Yellow
                    } elseif ($lu.Enabled) {
                        Write-Host ("User '{0}' is already active." -f $user) -ForegroundColor Yellow
                    } else {
                        $conf = (Read-Host "Type ENABLE to confirm activating '$user'").ToUpper()
                        if ($conf -eq 'ENABLE') {
                            Enable-LocalUser -Name $user -ErrorAction Stop
                            Write-Host ("User '{0}' activated." -f $user) -ForegroundColor Green
                        } else {
                            Write-Host 'Cancelled.' -ForegroundColor Yellow
                        }
                    }
                } catch {
                    Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
                }
                Pause-Return
            }
            '7' {
                $user = (Read-Host "Enter local username to deactivate").Trim()
                if ([string]::IsNullOrWhiteSpace($user)) {
                    Write-Host 'No username entered.' -ForegroundColor Yellow
                    Pause-Return
                    return
                }
                try {
                    $lu = Get-LocalUser -Name $user -ErrorAction SilentlyContinue
                    if (-not $lu) {
                        Write-Host ("User '{0}' not found." -f $user) -ForegroundColor Yellow
                    } elseif (-not $lu.Enabled) {
                        Write-Host ("User '{0}' is already disabled." -f $user) -ForegroundColor Yellow
                    } elseif ($lu.Name -eq $env:USERNAME) {
                        Write-Host "Refusing to disable the currently logged-in user." -ForegroundColor Yellow
                    } elseif ($lu.Name -in @('Administrator','Guest')) {
                        $conf = (Read-Host "Type CONFIRMBUILTIN to disable built-in account '$user'").ToUpper()
                        if ($conf -eq 'CONFIRMBUILTIN') {
                            Disable-LocalUser -Name $user -ErrorAction Stop
                            Write-Host ("Built-in account '{0}' deactivated." -f $user) -ForegroundColor Green
                        } else {
                            Write-Host 'Cancelled.' -ForegroundColor Yellow
                        }
                    } else {
                        $conf = (Read-Host "Type DISABLE to confirm disabling '$user'").ToUpper()
                        if ($conf -eq 'DISABLE') {
                            Disable-LocalUser -Name $user -ErrorAction Stop
                            Write-Host ("User '{0}' deactivated." -f $user) -ForegroundColor Green
                        } else {
                            Write-Host 'Cancelled.' -ForegroundColor Yellow
                        }
                    }
                } catch {
                    Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
                }
                Pause-Return
            }
            '8' {
                $user = (Read-Host "Enter local username to change password").Trim()
                if ([string]::IsNullOrWhiteSpace($user)) {
                    Write-Host 'No username entered.' -ForegroundColor Yellow
                    Pause-Return
                    return
                }
                try {
                    $lu = Get-LocalUser -Name $user -ErrorAction SilentlyContinue
                    if (-not $lu) {
                        Write-Host ("User '{0}' not found." -f $user) -ForegroundColor Yellow
                    } else {
                        Write-Host "Enter new password for '$user':" -ForegroundColor Cyan
                        $pwd = Read-Host -AsSecureString
                        $conf = (Read-Host "Type PASSWORD to confirm changing password for '$user'").ToUpper()
                        if ($conf -eq 'PASSWORD') {
                            Set-LocalUser -Name $user -Password $pwd -ErrorAction Stop
                            Write-Host ("Password for '{0}' updated." -f $user) -ForegroundColor Green
                        } else {
                            Write-Host 'Cancelled.' -ForegroundColor Yellow
                        }
                    }
                } catch {
                    Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
                }
                Pause-Return
            }
            '9' { Run-WindowsUpdateMenu }
            '10' { Run-DellUpdate }
            'M' { return }
            'Q' { $script:ExitRequested = $true; return }
            default {
                if ($choice -ne '') {
                    Write-Host 'Unknown option.' -ForegroundColor Yellow
                    Start-Sleep 1.2
                }
            }
        }
    } until ($false)
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
