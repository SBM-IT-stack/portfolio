# 01-preparation.ps1
# Prépare le serveur avant la promotion en contrôleur de domaine :
# nom de machine, IP fixe et DNS.
# A lancer en administrateur sur le futur DC. Le serveur redémarre à la fin.

param(
    [string]$NomServeur = "SRV-DC01",
    [string]$IP = "192.168.10.10",
    [int]$Prefixe = 24,
    [string]$Passerelle = "192.168.10.1",
    # Avant la promotion, le DC n'a pas encore de DNS : on pointe sur lui-même
    # pour qu'il soit son propre DNS une fois le rôle installé.
    [string]$DNS = "127.0.0.1"
)

# On prend la première carte réseau active
$carte = Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1
if (-not $carte) {
    Write-Host "Aucune carte réseau active trouvée." -ForegroundColor Red
    exit 1
}
Write-Host "Carte utilisée : $($carte.Name)"

# Suppression de l'ancienne config (DHCP ou IP déjà posée)
Set-NetIPInterface -InterfaceIndex $carte.ifIndex -Dhcp Disabled
Get-NetIPAddress -InterfaceIndex $carte.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Remove-NetIPAddress -Confirm:$false
Get-NetRoute -InterfaceIndex $carte.ifIndex -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue |
    Remove-NetRoute -Confirm:$false

# IP fixe + passerelle
New-NetIPAddress -InterfaceIndex $carte.ifIndex -IPAddress $IP -PrefixLength $Prefixe -DefaultGateway $Passerelle | Out-Null
Set-DnsClientServerAddress -InterfaceIndex $carte.ifIndex -ServerAddresses $DNS

Write-Host "IP fixe $IP/$Prefixe, passerelle $Passerelle, DNS $DNS" -ForegroundColor Green

# Renommage seulement si besoin
if ($env:COMPUTERNAME -ne $NomServeur) {
    Rename-Computer -NewName $NomServeur -Force
    Write-Host "Serveur renommé en $NomServeur, redémarrage dans 10 secondes..."
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    Write-Host "Le nom est déjà $NomServeur, pas de redémarrage nécessaire."
}
