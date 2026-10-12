# Clear-Poste.ps1
# Nettoie un poste Windows : fichiers temporaires anciens, et liste les profils
# utilisateurs pas utilises depuis longtemps (suppression seulement si demandee).
#
# Exemples :
#   .\Clear-Poste.ps1 -WhatIf                      # simulation, rien n'est supprime
#   .\Clear-Poste.ps1 -JoursTemp 7                 # supprime les temp de plus de 7 jours
#   .\Clear-Poste.ps1 -SupprimerProfils -JoursProfil 180

[CmdletBinding(SupportsShouldProcess)]
param(
    [int]$JoursTemp = 7,

    [string[]]$Dossiers = @($env:TEMP, "C:\Windows\Temp"),

    [int]$JoursProfil = 90,

    [switch]$SupprimerProfils,

    [string]$CheminLog = ".\nettoyage_$(Get-Date -Format 'yyyy-MM-dd_HH-mm').log"
)

function Write-Log {
    param([string]$Message)
    $ligne = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    Write-Host $ligne
    Add-Content -Path $CheminLog -Value $ligne -WhatIf:$false
}

Write-Log "Debut du nettoyage sur $env:COMPUTERNAME"

# --- 1. fichiers temporaires ---
$limite = (Get-Date).AddDays(-$JoursTemp)
$totalOctets = 0
$nbFichiers = 0

foreach ($dossier in $Dossiers) {
    if ([string]::IsNullOrWhiteSpace($dossier) -or -not (Test-Path $dossier)) {
        Write-Log "Dossier absent, je passe : $dossier"
        continue
    }

    $fichiers = Get-ChildItem -Path $dossier -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $limite }

    foreach ($f in $fichiers) {
        if ($PSCmdlet.ShouldProcess($f.FullName, "Suppression")) {
            try {
                $taille = $f.Length
                Remove-Item -Path $f.FullName -Force -ErrorAction Stop
                $totalOctets += $taille
                $nbFichiers++
            }
            catch {
                # fichier utilise par un programme, c'est normal, on continue
                Write-Verbose "Impossible de supprimer $($f.FullName)"
            }
        }
    }
}

$totalMo = [math]::Round($totalOctets / 1MB, 2)
Write-Log "Temp : $nbFichiers fichier(s) supprime(s), $totalMo Mo liberes"

# --- 2. vieux profils ---
# Get-CimInstance ne marche que sous Windows
if ($IsLinux -or $IsMacOS) {
    Write-Log "Pas sous Windows, je saute la partie profils"
}
else {
    $limiteProfil = (Get-Date).AddDays(-$JoursProfil)

    # Special = comptes systeme, Loaded = profil en cours d'utilisation
    $vieuxProfils = Get-CimInstance -ClassName Win32_UserProfile |
        Where-Object { -not $_.Special -and -not $_.Loaded -and $_.LastUseTime -lt $limiteProfil }

    if (-not $vieuxProfils) {
        Write-Log "Aucun profil inutilise depuis plus de $JoursProfil jours"
    }

    foreach ($p in $vieuxProfils) {
        Write-Log "Profil inutilise depuis le $($p.LastUseTime) : $($p.LocalPath)"

        if ($SupprimerProfils -and $PSCmdlet.ShouldProcess($p.LocalPath, "Suppression du profil")) {
            try {
                # supprime le dossier ET la cle de registre, contrairement a un simple Remove-Item
                Remove-CimInstance -InputObject $p -ErrorAction Stop
                Write-Log "Profil supprime : $($p.LocalPath)"
            }
            catch {
                Write-Log "Echec suppression $($p.LocalPath) : $($_.Exception.Message)"
            }
        }
    }

    if ($vieuxProfils -and -not $SupprimerProfils) {
        Write-Log "Profils listes seulement. Relancer avec -SupprimerProfils pour les supprimer."
    }
}

Write-Log "Fin du nettoyage. Log : $CheminLog"
