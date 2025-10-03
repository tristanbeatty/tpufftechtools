# ============================
# TPuff Tech Tools - WinForms GUI
# ============================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================
# Helper: Panel Switching
# ============================
function Show-Panel {
    param([System.Windows.Forms.Form]$form, [System.Windows.Forms.Panel]$panel)
    foreach ($c in $form.Controls) {
        if ($c -is [System.Windows.Forms.Panel]) { $c.Visible = $false }
    }
    $panel.Visible = $true
}

# ============================
# Main Form
# ============================
$form = New-Object System.Windows.Forms.Form
$form.Text = "TPuff Tech Tools"
$form.Size = '700,500'
$form.StartPosition = "CenterScreen"

# ============================
# MAIN MENU PANEL
# ============================
$panelMain = New-Object System.Windows.Forms.Panel
$panelMain.Dock = 'Fill'

$btnNet = New-Object System.Windows.Forms.Button
$btnNet.Text = "Network Tools"
$btnNet.Size = '200,50'
$btnNet.Location = '30,30'
$btnNet.Add_Click({ Show-Panel $form $panelNet })
$panelMain.Controls.Add($btnNet)

$btnPrint = New-Object System.Windows.Forms.Button
$btnPrint.Text = "Printer Tools"
$btnPrint.Size = '200,50'
$btnPrint.Location = '30,100'
$btnPrint.Add_Click({ Show-Panel $form $panelPrint })
$panelMain.Controls.Add($btnPrint)

$btnSys = New-Object System.Windows.Forms.Button
$btnSys.Text = "System Tools"
$btnSys.Size = '200,50'
$btnSys.Location = '30,170'
$btnSys.Add_Click({ Show-Panel $form $panelSys })
$panelMain.Controls.Add($btnSys)

$btnUpdate = New-Object System.Windows.Forms.Button
$btnUpdate.Text = "Windows Update"
$btnUpdate.Size = '200,50'
$btnUpdate.Location = '30,240'
$btnUpdate.Add_Click({ Show-Panel $form $panelUpdate })
$panelMain.Controls.Add($btnUpdate)

$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Text = "Exit"
$btnExit.Size = '200,50'
$btnExit.Location = '30,310'
$btnExit.Add_Click({ $form.Close() })
$panelMain.Controls.Add($btnExit)

# ============================
# NETWORK TOOLS PANEL
# ============================
$panelNet = New-Object System.Windows.Forms.Panel
$panelNet.Dock = 'Fill'
$panelNet.Visible = $false

$lblNet = New-Object System.Windows.Forms.Label
$lblNet.Text = "Network Tools"
$lblNet.Font = 'Segoe UI,12,style=Bold'
$lblNet.Location = '30,10'
$panelNet.Controls.Add($lblNet)

$btnIP = New-Object System.Windows.Forms.Button
$btnIP.Text = "Show IP Config"
$btnIP.Size = '200,40'
$btnIP.Location = '30,50'
$btnIP.Add_Click({ ipconfig /all | Out-Host })
$panelNet.Controls.Add($btnIP)

$btnDHCP = New-Object System.Windows.Forms.Button
$btnDHCP.Text = "Release/Renew DHCP"
$btnDHCP.Size = '200,40'
$btnDHCP.Location = '30,100'
$btnDHCP.Add_Click({ ipconfig /release; Start-Sleep 2; ipconfig /renew | Out-Host })
$panelNet.Controls.Add($btnDHCP)

$btnDNS = New-Object System.Windows.Forms.Button
$btnDNS.Text = "Flush DNS Cache"
$btnDNS.Size = '200,40'
$btnDNS.Location = '30,150'
$btnDNS.Add_Click({ ipconfig /flushdns | Out-Host })
$panelNet.Controls.Add($btnDNS)

$btnRoutes = New-Object System.Windows.Forms.Button
$btnRoutes.Text = "Routing Table"
$btnRoutes.Size = '200,40'
$btnRoutes.Location = '30,200'
$btnRoutes.Add_Click({ route print | Out-Host })
$panelNet.Controls.Add($btnRoutes)

$btnConnections = New-Object System.Windows.Forms.Button
$btnConnections.Text = "Active Connections"
$btnConnections.Size = '200,40'
$btnConnections.Location = '30,250'
$btnConnections.Add_Click({ netstat -ano | Out-Host })
$panelNet.Controls.Add($btnConnections)

$btnNetBack = New-Object System.Windows.Forms.Button
$btnNetBack.Text = "Back"
$btnNetBack.Size = '200,40'
$btnNetBack.Location = '30,300'
$btnNetBack.Add_Click({ Show-Panel $form $panelMain })
$panelNet.Controls.Add($btnNetBack)

# ============================
# PRINTER TOOLS PANEL
# ============================
$panelPrint = New-Object System.Windows.Forms.Panel
$panelPrint.Dock = 'Fill'
$panelPrint.Visible = $false

$lblPrint = New-Object System.Windows.Forms.Label
$lblPrint.Text = "Printer Tools"
$lblPrint.Font = 'Segoe UI,12,style=Bold'
$lblPrint.Location = '30,10'
$panelPrint.Controls.Add($lblPrint)

$btnPrinters = New-Object System.Windows.Forms.Button
$btnPrinters.Text = "List Printers"
$btnPrinters.Size = '200,40'
$btnPrinters.Location = '30,50'
$btnPrinters.Add_Click({ Get-Printer | Format-Table | Out-Host })
$panelPrint.Controls.Add($btnPrinters)

$btnPorts = New-Object System.Windows.Forms.Button
$btnPorts.Text = "List Printer Ports"
$btnPorts.Size = '200,40'
$btnPorts.Location = '30,100'
$btnPorts.Add_Click({ Get-PrinterPort | Format-Table | Out-Host })
$panelPrint.Controls.Add($btnPorts)

$btnSpooler = New-Object System.Windows.Forms.Button
$btnSpooler.Text = "Restart Spooler"
$btnSpooler.Size = '200,40'
$btnSpooler.Location = '30,150'
$btnSpooler.Add_Click({ Restart-Service spooler -Force })
$panelPrint.Controls.Add($btnSpooler)

$btnClearQueue = New-Object System.Windows.Forms.Button
$btnClearQueue.Text = "Clear Print Queue"
$btnClearQueue.Size = '200,40'
$btnClearQueue.Location = '30,200'
$btnClearQueue.Add_Click({
    Stop-Service spooler -Force
    Remove-Item "$env:SystemRoot\System32\spool\PRINTERS\*" -Force -ErrorAction SilentlyContinue
    Start-Service spooler
})
$panelPrint.Controls.Add($btnClearQueue)

$btnAddPrinter = New-Object System.Windows.Forms.Button
$btnAddPrinter.Text = "Add Network Printer"
$btnAddPrinter.Size = '200,40'
$btnAddPrinter.Location = '30,250'
$btnAddPrinter.Add_Click({
    $path = [System.Windows.Forms.MessageBox]::Show("Use Add-Printer manually in shell.","Info")
})
$panelPrint.Controls.Add($btnAddPrinter)

$btnPrintBack = New-Object System.Windows.Forms.Button
$btnPrintBack.Text = "Back"
$btnPrintBack.Size = '200,40'
$btnPrintBack.Location = '30,300'
$btnPrintBack.Add_Click({ Show-Panel $form $panelMain })
$panelPrint.Controls.Add($btnPrintBack)

# ============================
# SYSTEM TOOLS PANEL
# ============================
$panelSys = New-Object System.Windows.Forms.Panel
$panelSys.Dock = 'Fill'
$panelSys.Visible = $false

$lblSys = New-Object System.Windows.Forms.Label
$lblSys.Text = "System Tools"
$lblSys.Font = 'Segoe UI,12,style=Bold'
$lblSys.Location = '30,10'
$panelSys.Controls.Add($lblSys)

$btnSysInfo = New-Object System.Windows.Forms.Button
$btnSysInfo.Text = "Show System Info"
$btnSysInfo.Size = '200,40'
$btnSysInfo.Location = '30,50'
$btnSysInfo.Add_Click({ Get-ComputerInfo | Select CsName,OsName,OsVersion,OsBuildNumber | Out-Host })
$panelSys.Controls.Add($btnSysInfo)

$btnUsers = New-Object System.Windows.Forms.Button
$btnUsers.Text = "List Local Users"
$btnUsers.Size = '200,40'
$btnUsers.Location = '30,100'
$btnUsers.Add_Click({ Get-LocalUser | Format-Table Name,Enabled,LastLogon | Out-Host })
$panelSys.Controls.Add($btnUsers)

$btnRename = New-Object System.Windows.Forms.Button
$btnRename.Text = "Change Computer Name"
$btnRename.Size = '200,40'
$btnRename.Location = '30,150'
$btnRename.Add_Click({
    $new = [System.Windows.Forms.MessageBox]::Show("Use Rename-Computer in shell.","Info")
})
$panelSys.Controls.Add($btnRename)

$btnSysBack = New-Object System.Windows.Forms.Button
$btnSysBack.Text = "Back"
$btnSysBack.Size = '200,40'
$btnSysBack.Location = '30,300'
$btnSysBack.Add_Click({ Show-Panel $form $panelMain })
$panelSys.Controls.Add($btnSysBack)

# ============================
# WINDOWS UPDATE PANEL
# ============================
$panelUpdate = New-Object System.Windows.Forms.Panel
$panelUpdate.Dock = 'Fill'
$panelUpdate.Visible = $false

$lblUpdate = New-Object System.Windows.Forms.Label
$lblUpdate.Text = "Windows Update"
$lblUpdate.Font = 'Segoe UI,12,style=Bold'
$lblUpdate.Location = '30,10'
$panelUpdate.Controls.Add($lblUpdate)

$btnWUCheck = New-Object System.Windows.Forms.Button
$btnWUCheck.Text = "Check Updates"
$btnWUCheck.Size = '200,40'
$btnWUCheck.Location = '30,50'
$btnWUCheck.Add_Click({
    try { Import-Module PSWindowsUpdate -ErrorAction Stop; Get-WindowsUpdate | Out-Host }
    catch { [System.Windows.Forms.MessageBox]::Show("PSWindowsUpdate not available.") }
})
$panelUpdate.Controls.Add($btnWUCheck)

$btnWUInstall = New-Object System.Windows.Forms.Button
$btnWUInstall.Text = "Install Updates"
$btnWUInstall.Size = '200,40'
$btnWUInstall.Location = '30,100'
$btnWUInstall.Add_Click({
    try { Import-Module PSWindowsUpdate -ErrorAction Stop; Install-WindowsUpdate -AcceptAll -Verbose }
    catch { [System.Windows.Forms.MessageBox]::Show("PSWindowsUpdate not available.") }
})
$panelUpdate.Controls.Add($btnWUInstall)

$btnWUBack = New-Object System.Windows.Forms.Button
$btnWUBack.Text = "Back"
$btnWUBack.Size = '200,40'
$btnWUBack.Location = '30,300'
$btnWUBack.Add_Click({ Show-Panel $form $panelMain })
$panelUpdate.Controls.Add($btnWUBack)

# ============================
# Add Panels to Form
# ============================
$form.Controls.AddRange(@($panelMain,$panelNet,$panelPrint,$panelSys,$panelUpdate))

# Start with Main Panel
[System.Windows.Forms.Application]::EnableVisualStyles()
Show-Panel $form $panelMain
$form.ShowDialog()
