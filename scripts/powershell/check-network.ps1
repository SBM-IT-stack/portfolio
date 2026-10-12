# Script : check-network.ps1
# Objectif : diagnostic réseau simple sous Windows.

$Gateway = "192.168.1.1"
$PublicIP = "8.8.8.8"
$Domain = "google.com"

Write-Host "=== Configuration IP ==="
Get-NetIPConfiguration

Write-Host ""
Write-Host "=== Test passerelle locale ==="
Test-Connection $Gateway -Count 4

Write-Host ""
Write-Host "=== Test connectivité Internet ==="
Test-Connection $PublicIP -Count 4

Write-Host ""
Write-Host "=== Test DNS ==="
Resolve-DnsName $Domain

Write-Host ""
Write-Host "=== Diagnostic terminé ==="
