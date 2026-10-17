# 03-post-installation.ps1
# Après la promotion : arborescence d'OU, zone DNS inversée et redirecteur DNS.
# A lancer en administrateur du domaine sur le DC.

param(
    [string]$OURacine = "SBM",
    [string]$Reseau = "192.168.10.0/24",
    # DNS vers lequel le DC envoie ce qu'il ne connaît pas (box ou DNS public)
    [string]$Redirecteur = "1.1.1.1"
)

Import-Module ActiveDirectory
Import-Module DnsServer

$dnDomaine = (Get-ADDomain).DistinguishedName

# Petite fonction pour ne pas planter si l'OU existe déjà
function New-OUSiAbsente {
    param([string]$Nom, [string]$Parent)
    $dn = "OU=$Nom,$Parent"
    if (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$dn'") {
        Write-Host "  OU déjà présente : $dn"
    } else {
        New-ADOrganizationalUnit -Name $Nom -Path $Parent -ProtectedFromAccidentalDeletion $true
        Write-Host "  OU créée : $dn" -ForegroundColor Green
    }
}

Write-Host "Création des OU..."
New-OUSiAbsente -Nom $OURacine -Parent $dnDomaine
$dnRacine = "OU=$OURacine,$dnDomaine"
foreach ($ou in "Utilisateurs", "Ordinateurs", "Serveurs", "Groupes") {
    New-OUSiAbsente -Nom $ou -Parent $dnRacine
}

# Zone inversée : permet de retrouver un nom à partir d'une IP (nslookup 192.168.10.10)
Write-Host "Zone DNS inversée..."
$zoneExiste = Get-DnsServerZone | Where-Object { $_.IsReverseLookupZone -and -not $_.IsAutoCreated }
if ($zoneExiste) {
    Write-Host "  Une zone inversée existe déjà : $($zoneExiste.ZoneName)"
} else {
    Add-DnsServerPrimaryZone -NetworkId $Reseau -ReplicationScope Forest
    Write-Host "  Zone inversée créée pour $Reseau" -ForegroundColor Green
}

# Enregistrement PTR du DC lui-même (sinon la zone inversée reste vide)
ipconfig /registerdns | Out-Null

Write-Host "Redirecteur DNS vers $Redirecteur..."
Set-DnsServerForwarder -IPAddress $Redirecteur

# Les nouveaux postes joints au domaine iront dans la bonne OU au lieu de "Computers"
redircmp "OU=Ordinateurs,$dnRacine"

Write-Host "Post-installation terminée. Lance verifier-dc.ps1 pour contrôler." -ForegroundColor Green
