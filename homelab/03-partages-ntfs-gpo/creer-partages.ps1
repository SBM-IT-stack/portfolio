<#
    Cree les partages de fichiers d'un service selon la methode AGDLP :
    utilisateurs -> groupe global (GG) -> groupe domaine local (DL) -> droits NTFS.

    Pour chaque service du CSV :
      - GG_<Service>            groupe global, on y met les utilisateurs
      - DL_<Service>_Lecture    groupe domaine local, droit Lecture sur le dossier
      - DL_<Service>_Modif      groupe domaine local, droit Modification sur le dossier
      - GG_<Service> est ajoute dans DL_<Service>_Modif
      - dossier <Racine>\<Service>, partage en <Service>$ (cache)

    A lancer sur le serveur de fichiers (ou le DC du labo) en administrateur.
    Exemple : .\creer-partages.ps1 -Csv .\services.csv -Racine D:\Partages
#>

param(
    [Parameter(Mandatory)]
    [string]$Csv,

    [string]$Racine = "D:\Partages",

    # OU ou seront crees les groupes, a adapter au domaine du labo
    [string]$OuGroupes = "OU=Groupes,DC=labo,DC=local"
)

Import-Module ActiveDirectory

# SID connus : on les utilise plutot que les noms, qui changent selon la langue de Windows
$sidAdmins = "S-1-5-32-544"   # Administrateurs
$sidSystem = "S-1-5-18"       # SYSTEM
$sidAuth   = "S-1-5-11"       # Utilisateurs authentifies

function Get-NomDepuisSid($sid) {
    $objSid = New-Object System.Security.Principal.SecurityIdentifier($sid)
    return $objSid.Translate([System.Security.Principal.NTAccount]).Value
}

function New-GroupeSiAbsent($nom, $etendue, $description) {
    if (Get-ADGroup -Filter "Name -eq '$nom'") {
        Write-Host "  groupe $nom deja present"
    }
    else {
        New-ADGroup -Name $nom -GroupScope $etendue -GroupCategory Security `
            -Path $OuGroupes -Description $description
        Write-Host "  groupe $nom cree"
    }
}

function Set-DroitsNtfs($chemin, $groupeLecture, $groupeModif) {
    $acl = Get-Acl $chemin

    # On coupe l'heritage sans recopier les droits herites, puis on repart de zero
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($regle in @($acl.Access)) {
        $acl.RemoveAccessRule($regle) | Out-Null
    }

    $heritage = "ContainerInherit,ObjectInherit"
    $regles = @(
        @((Get-NomDepuisSid $sidAdmins), "FullControl"),
        @((Get-NomDepuisSid $sidSystem), "FullControl"),
        @($groupeModif, "Modify"),
        @($groupeLecture, "ReadAndExecute")
    )
    foreach ($r in $regles) {
        $regle = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $r[0], $r[1], $heritage, "None", "Allow")
        $acl.AddAccessRule($regle)
    }

    Set-Acl -Path $chemin -AclObject $acl
}

if (-not (Test-Path $Csv)) {
    Write-Host "Fichier introuvable : $Csv"
    exit 1
}

$domaine = (Get-ADDomain).NetBIOSName
$services = Import-Csv -Path $Csv -Delimiter ";"

foreach ($s in $services) {
    $nom = $s.Service
    Write-Host "Service $nom"

    $gg      = "GG_$nom"
    $dlLect  = "DL_${nom}_Lecture"
    $dlModif = "DL_${nom}_Modif"

    New-GroupeSiAbsent $gg      Global      "Utilisateurs du service $nom"
    New-GroupeSiAbsent $dlLect  DomainLocal "Lecture sur le partage $nom"
    New-GroupeSiAbsent $dlModif DomainLocal "Modification sur le partage $nom"

    # Le groupe global du service a le droit de modifier son dossier
    Add-ADGroupMember -Identity $dlModif -Members $gg

    $dossier = Join-Path $Racine $nom
    if (-not (Test-Path $dossier)) {
        New-Item -ItemType Directory -Path $dossier | Out-Null
        Write-Host "  dossier $dossier cree"
    }

    Set-DroitsNtfs $dossier "$domaine\$dlLect" "$domaine\$dlModif"
    Write-Host "  droits NTFS appliques"

    # Partage : droits larges cote partage, c'est NTFS qui filtre vraiment
    $partage = "$nom`$"
    if (Get-SmbShare -Name $partage -ErrorAction SilentlyContinue) {
        Write-Host "  partage $partage deja present"
    }
    else {
        New-SmbShare -Name $partage -Path $dossier -Description $s.Description `
            -ChangeAccess (Get-NomDepuisSid $sidAuth) `
            -FullAccess (Get-NomDepuisSid $sidAdmins) `
            -FolderEnumerationMode AccessBased | Out-Null
        Write-Host "  partage \\$env:COMPUTERNAME\$partage cree"
    }
}

Write-Host "Termine. Pensez a mettre les utilisateurs dans les groupes GG_."
