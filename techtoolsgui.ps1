# ============================
# Load .NET WinForms
# ============================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================
# Pause Helper
# ============================
function Pause-Return { [System.Windows.Forms.MessageBox]::Show("Press OK to continue.","TPuff Tech Tools") }

# ============================
# Network Tools
# ============================
function Run-NetworkTools {
    $menu = New-Object System.Windows.Forms.Form
    $menu.Text = "Network Tools"
    $menu.Size = '500,300'
    $menu.StartPosition = "CenterScreen"

    $btn1 = New-Object System.Windows.Forms.Button
    $btn1.Text = "Show IP Configuration"
    $btn1.Size = '200,40'
    $btn1.Location = '30,30'
    $btn1.Add_Click({ ipconfig /all | Out-Host; Pause-Return })
    $menu.Controls.Add($btn1)

    $btn2 = New-Object System.Windows.Forms.Button
    $btn2.Text = "Release/Renew DHCP"
    $btn2.Size = '200,40'
    $btn2.Location = '30,80'
    $btn2.Add_Click({ ipconfig /release; Start-Sleep 2; ipconfig /renew | Out-Host; Pause-Return })
    $menu.Controls.Add($btn2)

    $btn3 = New-Object System.Windows.Forms.Button
    $btn3.Text = "Flush DNS Cache"
    $btn3.Size = '200,40'
    $btn3.Location = '30,130'
    $btn3.Add_Click({ ipconfig /flushdns | Out-Host; Pause-Return })
    $menu.Controls.Add($btn3)

    $btn4 = New-Object System.Windows.Forms.Button
    $btn4.Text = "Display Routing Table"
    $btn4.Size = '200,40'
    $btn4.Location = '30,180'
    $btn4.Add_Click({ route print | Out-Host; Pause-Return })
    $menu.Controls.Add($btn4)

    $btn5 = New-Object System.Windows.Forms.Button
    $btn5.Text = "Show Active Connections"
    $btn5.Size = '200,40'
    $btn5.Location = '30,230'
    $btn5.Add_Click({ netstat -ano | Out-Host; Pause-Return })
    $menu.Controls.Add($btn5)

    $menu.ShowDialog()
}

# ============================
# Printer Tools
# ============================
function Run-PrinterTools {
    $menu = New-Object System.Windows.Forms.Form
    $menu.Text = "Printer Tools"
    $menu.Size = '500,350'
    $menu.StartPosition = "CenterScreen"

    $btn1 = New-Object System.Windows.Forms.Button
    $btn1.Text = "Open Devices & Printers"
    $btn1.Size = '250,40'
    $btn1.Location = '30,30'
    $btn1.Add_Click({ Start-Process control.exe printers })
    $menu.Controls.Add($btn1)

    $btn2 = New-Object System.Windows.Forms.Button
    $btn2.Text = "Restart Spooler"
    $btn2.Size = '250,40'
    $btn2.Location = '30,80'
    $btn2.Add_Click({
        try { Restart-Service spooler -Force; [System.Windows.Forms.MessageBox]::Show("Spooler restarted.") }
        catch { [System.Windows.Forms.MessageBox]::Show("Failed: $($_.Exception.Message)") }
    })
    $menu.Controls.Add($btn2)

    $btn3 = New-Object System.Windows.Forms.Button
    $btn3.Text = "Clear Print Queue"
    $btn3.Size = '250,40'
    $btn3.Location = '30,130'
    $btn3.Add_Click({
        try {
            Stop-Service spooler -Force
            Remove-Item "$env:SystemRoot\System32\spool\PRINTERS\*" -Force -ErrorAction SilentlyContinue
            Start-Service spooler
            [System.Windows.Forms.MessageBox]::Show("Print queue cleared.")
        } catch { [System.Windows.Forms.MessageBox]::Show("Failed: $($_.Exception.Message)") }
    })
    $menu.Controls.Add($btn3)

    $btn4 = New-Object System.Windows.Forms.Button
    $btn4.Text = "List Printers"
    $btn4.Size = '250,40'
    $btn4.Location = '30,180'
    $btn4.Add_Click({ Get-Printer | Format-Table | Out-Host; Pause-Return })
    $menu.Controls.Add($btn4)

    $btn5 = New-Object System.Windows.Forms.Button
    $btn5.Text = "List Printer Ports"
    $btn5.Size = '250,40'
    $btn5.Location = '30,230'
    $btn5.Add_Click({ Get-PrinterPort | Format-Table | Out-Host; Pause-Return })
    $menu.Controls.Add($btn5)

    $btn6 = New-Object System.Windows.Forms.Button
    $btn6.Text = "Add Network Printer"
    $btn6.Size = '250,40'
    $btn6.Location = '30,280'
    $btn6.Add_Click({
        $path = [System.Windows.Forms.InputBox]::Show("Enter printer path (\\Server\Printer)","Add Printer","")
        if ($path) {
            try { Add-Printer -ConnectionName $path; [System.Windows.Forms.MessageBox]::Show("Added $path") }
            catch { [System.Windows.Forms.MessageBox]::Show("Failed: $($_.Exception.Message)") }
        }
    })
    $menu.Controls.Add($btn6)

    $menu.ShowDialog()
}

# ============================
# System Tools
# ============================
function Run-SystemTools {
    $menu = New-Object System.Windows.Forms.Form
    $menu.Text = "System Tools"
    $menu.Size = '500,350'
    $menu.StartPosition = "CenterScreen"

    $btn1 = New-Object System.Windows.Forms.Button
    $btn1.Text = "Show System Info"
    $btn1.Size = '250,40'
    $btn1.Location = '30,30'
    $btn1.Add_Click({
        Get-ComputerInfo | Select-Object CsName,OsName,OsVersion,OsBuildNumber | Out-Host
        Pause-Return
    })
    $menu.Controls.Add($btn1)

    $btn2 = New-Object System.Windows.Forms.Button
    $btn2.Text = "List Local Users"
    $btn2.Size = '250,40'
    $btn2.Location = '30,80'
    $btn2.Add_Click({ Get-LocalUser | Format-Table Name,Enabled,LastLogon | Out-Host; Pause-Return })
    $menu.Controls.Add($btn2)

    $btn3 = New-Object System.Windows.Forms.Button
    $btn3.Text = "Change Computer Name"
    $btn3.Size = '250,40'
    $btn3.Location = '30,130'
    $btn3.Add_Click({
        $new = [System.Windows.Forms.InputBox]::Show("Enter new computer name","Rename PC","")
        if ($new) {
            try { Rename-Computer -NewName $new -Force; [System.Windows.Forms.MessageBox]::Show("Renamed. Restart to apply.") }
            catch { [System.Windows.Forms.MessageBox]::Show("Failed: $($_.Exception.Message)") }
        }
    })
    $menu.Controls.Add($btn3)

    $btn4 = New-Object System.Windows.Forms.Button
    $btn4.Text = "Windows Update"
    $btn4.Size = '250,40'
    $btn4.Location = '30,180'
    $btn4.Add_Click({ Run-WindowsUpdate })
    $menu.Controls.Add($btn4)

    $menu.ShowDialog()
}

# ============================
# Windows Update (simplified GUI)
# ============================
function Run-WindowsUpdate {
    try {
        Import-Module PSWindowsUpdate -ErrorAction Stop
    } catch { [System.Windows.Forms.MessageBox]::Show("PSWindowsUpdate not installed.") ; return }

    $menu = New-Object System.Windows.Forms.Form
    $menu.Text = "Windows Update"
    $menu.Size = '400,250'
    $menu.StartPosition = "CenterScreen"

    $btn1 = New-Object System.Windows.Forms.Button
    $btn1.Text = "Check Updates"
    $btn1.Size = '150,40'
    $btn1.Location = '30,30'
    $btn1.Add_Click({ Get-WindowsUpdate | Out-Host; Pause-Return })
    $menu.Controls.Add($btn1)

    $btn2 = New-Object System.Windows.Forms.Button
    $btn2.Text = "Install (Prompt)"
    $btn2.Size = '150,40'
    $btn2.Location = '30,80'
    $btn2.Add_Click({ Install-WindowsUpdate -Verbose | Out-Host; Pause-Return })
    $menu.Controls.Add($btn2)

    $btn3 = New-Object System.Windows.Forms.Button
    $btn3.Text = "Install (Auto)"
    $btn3.Size = '150,40'
    $btn3.Location = '30,130'
    $btn3.Add_Click({ Install-WindowsUpdate -AcceptAll -AutoReboot -Verbose | Out-Host })
    $menu.Controls.Add($btn3)

    $menu.ShowDialog()
}

# ============================
# Main Form
# ============================
$form = New-Object System.Windows.Forms.Form
$form.Text = "TPuff Tech Tools"
$form.Size = '400,400'
$form.StartPosition = "CenterScreen"

$btnNet = New-Object System.Windows.Forms.Button
$btnNet.Text = "Network Tools"
$btnNet.Size = '150,40'
$btnNet.Location = '30,30'
$btnNet.Add_Click({ Run-NetworkTools })
$form.Controls.Add($btnNet)

$btnPrint = New-Object System.Windows.Forms.Button
$btnPrint.Text = "Printer Tools"
$btnPrint.Size = '150,40'
$btnPrint.Location = '30,80'
$btnPrint.Add_Click({ Run-PrinterTools })
$form.Controls.Add($btnPrint)

$btnSys = New-Object System.Windows.Forms.Button
$btnSys.Text = "System Tools"
$btnSys.Size = '150,40'
$btnSys.Location = '30,130'
$btnSys.Add_Click({ Run-SystemTools })
$form.Controls.Add($btnSys)

$btnUpdate = New-Object System.Windows.Forms.Button
$btnUpdate.Text = "Windows Update"
$btnUpdate.Size = '150,40'
$btnUpdate.Location = '30,180'
$btnUpdate.Add_Click({ Run-WindowsUpdate })
$form.Controls.Add($btnUpdate)

$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Text = "Exit"
$btnExit.Size = '150,40'
$btnExit.Location = '30,230'
$btnExit.Add_Click({ $form.Close() })
$form.Controls.Add($btnExit)

[System.Windows.Forms.Application]::EnableVisualStyles()
$form.Topmost = $true
$form.ShowDialog()
