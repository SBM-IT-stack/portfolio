# 02-promotion-dc.ps1
# Installe le rôle AD DS et crée une nouvelle forêt avec le DNS intégré.
# A lancer en administrateur après 01-preparation.ps1. Le serveur redémarre seul.

param(
    [string]$Domaine = "sbm.lan",
    [string]$NetBIOS = "SBM"
)

# Vérification rapide : on ne promeut pas un serveur encore en DHCP
$dhcp = Get-NetIPInterface -AddressFamily IPv4 | Where-Object { $_.Dhcp -eq "Enabled" -and $_.ConnectionState -eq "Connected" }
if ($dhcp) {
    Write-Host "Une carte est encore en DHCP, lance d'abord 01-preparation.ps1." -ForegroundColor Red
    exit 1
}

Write-Host "Installation du rôle AD DS et des outils d'administration..."
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Mot de passe du mode restauration (DSRM), demandé à l'écran pour ne pas l'écrire dans le script
$motDePasseDSRM = Read-Host "Mot de passe DSRM" -AsSecureString

Import-Module ADDSDeployment

# WinThreshold = niveau fonctionnel Windows Server 2016 (le plus haut proposé sur 2022)
Install-ADDSForest `
    -DomainName $Domaine `
    -DomainNetbiosName $NetBIOS `
    -ForestMode "WinThreshold" `
    -DomainMode "WinThreshold" `
    -InstallDns `
    -SafeModeAdministratorPassword $motDePasseDSRM `
    -Force
