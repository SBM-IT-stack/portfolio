<#
.SYNOPSIS
    Inventaire materiel et systeme de plusieurs postes Windows, exporte en CSV.

.DESCRIPTION
    Lit une liste de postes (un nom par ligne), interroge chacun en CIM (WinRM)
    et ecrit une ligne par poste dans un fichier CSV lisible dans Excel.
    Un poste eteint ou qui refuse la connexion apparait quand meme dans le CSV,
    avec son statut, pour savoir ce qui reste a verifier.

.EXAMPLE
    .\Get-InventaireParc.ps1 -ListePostes .\postes.txt

.EXAMPLE
    .\Get-InventaireParc.ps1 -Postes PC-COMPTA01,PC-ACCUEIL -Credential (Get-Credential)
#>
[CmdletBinding()]
param(
    [string]$ListePostes = ".\postes.txt",
    [string[]]$Postes,
    [string]$Fichier = ".\inventaire-$(Get-Date -Format 'yyyy-MM-dd').csv",
    [System.Management.Automation.PSCredential]$Credential
)

# Liste des postes : soit passee en parametre, soit lue dans le fichier
if (-not $Postes) {
    if (-not (Test-Path $ListePostes)) {
        Write-Error "Fichier introuvable : $ListePostes"
        exit 1
    }
    # On ignore les lignes vides et les commentaires (#)
    $Postes = Get-Content $ListePostes |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne "" -and -not $_.StartsWith("#") }
}
$Postes = $Postes | Sort-Object -Unique

function Get-InfosPoste {
    param([string]$Nom)

    # Ligne vide par defaut, remplie au fur et a mesure
    $ligne = [ordered]@{
        Poste        = $Nom
        Statut       = ""
        Utilisateur  = ""
        Fabricant    = ""
        Modele       = ""
        NumeroSerie  = ""
        Processeur   = ""
        RAM_Go       = ""
        OS           = ""
        VersionOS    = ""
        DernierBoot  = ""
        DisqueC_Go   = ""
        LibreC_Go    = ""
        AdresseIP    = ""
        AdresseMAC   = ""
        DateReleve   = Get-Date -Format "yyyy-MM-dd HH:mm"
    }

    # Ping d'abord : permet de distinguer "eteint" de "WinRM refuse"
    if (-not (Test-Connection -ComputerName $Nom -Count 1 -Quiet)) {
        $ligne.Statut = "Injoignable (ping)"
        return [pscustomobject]$ligne
    }

    try {
        $options = @{ ComputerName = $Nom; ErrorAction = "Stop" }
        if ($Credential) { $options.Credential = $Credential }
        $session = New-CimSession @options
    }
    catch {
        $ligne.Statut = "Erreur WinRM : $($_.Exception.Message)"
        return [pscustomobject]$ligne
    }

    try {
        $cs   = Get-CimInstance -CimSession $session -ClassName Win32_ComputerSystem
        $os   = Get-CimInstance -CimSession $session -ClassName Win32_OperatingSystem
        $bios = Get-CimInstance -CimSession $session -ClassName Win32_BIOS
        $cpu  = Get-CimInstance -CimSession $session -ClassName Win32_Processor | Select-Object -First 1
        $disk = Get-CimInstance -CimSession $session -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
        $net  = Get-CimInstance -CimSession $session -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" |
            Select-Object -First 1

        $ligne.Utilisateur = $cs.UserName
        $ligne.Fabricant   = $cs.Manufacturer
        $ligne.Modele      = $cs.Model
        $ligne.NumeroSerie = $bios.SerialNumber
        $ligne.Processeur  = $cpu.Name.Trim()
        $ligne.RAM_Go      = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
        $ligne.OS          = $os.Caption
        $ligne.VersionOS   = $os.Version
        $ligne.DernierBoot = $os.LastBootUpTime.ToString("yyyy-MM-dd HH:mm")

        if ($disk) {
            $ligne.DisqueC_Go = [math]::Round($disk.Size / 1GB, 1)
            $ligne.LibreC_Go  = [math]::Round($disk.FreeSpace / 1GB, 1)
        }
        if ($net) {
            # IPAddress contient aussi l'IPv6, on garde seulement l'IPv4
            $ligne.AdresseIP  = $net.IPAddress | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' } | Select-Object -First 1
            $ligne.AdresseMAC = $net.MACAddress
        }
        $ligne.Statut = "OK"
    }
    catch {
        $ligne.Statut = "Erreur collecte : $($_.Exception.Message)"
    }
    finally {
        Remove-CimSession -CimSession $session
    }

    return [pscustomobject]$ligne
}

$resultats = @()
$i = 0
foreach ($poste in $Postes) {
    $i++
    Write-Progress -Activity "Inventaire du parc" -Status $poste -PercentComplete ($i / $Postes.Count * 100)
    $resultats += Get-InfosPoste -Nom $poste
}
Write-Progress -Activity "Inventaire du parc" -Completed

# Point-virgule et UTF-8 pour qu'Excel en francais ouvre le fichier directement
$resultats | Export-Csv -Path $Fichier -Delimiter ";" -NoTypeInformation -Encoding UTF8

$ok = @($resultats | Where-Object { $_.Statut -eq "OK" }).Count
Write-Host "$ok poste(s) sur $($Postes.Count) inventorie(s). Fichier : $Fichier"
foreach ($r in $resultats | Where-Object { $_.Statut -ne "OK" }) {
    Write-Host "  A verifier : $($r.Poste) -> $($r.Statut)" -ForegroundColor Yellow
}
