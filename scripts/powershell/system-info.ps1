# Script : system-info.ps1
# Objectif : afficher des informations de base sur un poste Windows.
# Usage : ./system-info.ps1

Write-Host "=== Informations système ==="
Get-ComputerInfo | Select-Object CsName, WindowsProductName, WindowsVersion, OsArchitecture

Write-Host ""
Write-Host "=== Adresse IP ==="
Get-NetIPAddress | Where-Object {$_.AddressFamily -eq "IPv4"} | Select-Object InterfaceAlias, IPAddress, PrefixLength

Write-Host ""
Write-Host "=== Espace disque ==="
Get-PSDrive -PSProvider FileSystem | Select-Object Name, Used, Free

Write-Host ""
Write-Host "=== Utilisateurs locaux ==="
Get-LocalUser | Select-Object Name, Enabled, LastLogon
