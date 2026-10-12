# New-ADUsersFromCsv.ps1
# Cree des comptes Active Directory a partir d'un fichier CSV.
# Chaque utilisateur est range dans l'OU de son service et devra changer
# son mot de passe a la premiere connexion.
#
# Exemple :
#   .\New-ADUsersFromCsv.ps1 -CheminCsv .\utilisateurs.csv -OUBase "OU=Utilisateurs,DC=lab,DC=local" -Domaine "lab.local" -WhatIf

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$CheminCsv,

    [Parameter(Mandatory)]
    [string]$OUBase,

    [Parameter(Mandatory)]
    [string]$Domaine,

    [securestring]$MotDePasseInitial,

    [string]$CheminRapport = ".\rapport_creation.csv"
)

Import-Module ActiveDirectory -ErrorAction Stop

if (-not (Test-Path $CheminCsv)) {
    Write-Error "Fichier introuvable : $CheminCsv"
    exit 1
}

if (-not $MotDePasseInitial) {
    $MotDePasseInitial = Read-Host "Mot de passe initial des comptes" -AsSecureString
}

# enleve les accents et les caracteres speciaux pour fabriquer le login
function ConvertTo-Login {
    param([string]$Texte)
    $normalise = $Texte.Normalize([Text.NormalizationForm]::FormD)
    $sansAccent = -join ($normalise.ToCharArray() | Where-Object {
        [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne 'NonSpacingMark'
    })
    return ($sansAccent.ToLower() -replace '[^a-z0-9]', '')
}

$utilisateurs = Import-Csv -Path $CheminCsv -Delimiter ';' -Encoding UTF8
$rapport = @()

foreach ($u in $utilisateurs) {
    if ([string]::IsNullOrWhiteSpace($u.Prenom) -or [string]::IsNullOrWhiteSpace($u.Nom)) {
        Write-Warning "Ligne ignoree : prenom ou nom vide"
        $rapport += [pscustomobject]@{ Login = ''; Nom = "$($u.Prenom) $($u.Nom)"; Statut = 'ignore (ligne incomplete)' }
        continue
    }

    $login = "$(ConvertTo-Login $u.Prenom).$(ConvertTo-Login $u.Nom)"
    # sAMAccountName est limite a 20 caracteres
    if ($login.Length -gt 20) { $login = $login.Substring(0, 20) }

    $ou = "OU=$($u.Service),$OUBase"
    $nomComplet = "$($u.Prenom) $($u.Nom)"

    if (Get-ADUser -Filter "SamAccountName -eq '$login'" -ErrorAction SilentlyContinue) {
        Write-Warning "$login existe deja, je passe"
        $rapport += [pscustomobject]@{ Login = $login; Nom = $nomComplet; Statut = 'deja existant' }
        continue
    }

    $params = @{
        Name                  = $nomComplet
        GivenName             = $u.Prenom
        Surname               = $u.Nom
        SamAccountName        = $login
        UserPrincipalName     = "$login@$Domaine"
        DisplayName           = $nomComplet
        Department            = $u.Service
        Title                 = $u.Fonction
        Path                  = $ou
        AccountPassword       = $MotDePasseInitial
        ChangePasswordAtLogon = $true
        Enabled               = $true
    }

    if ($PSCmdlet.ShouldProcess($login, "Creation du compte dans $ou")) {
        try {
            New-ADUser @params -ErrorAction Stop
            Write-Host "OK : $login cree dans $ou"
            $rapport += [pscustomobject]@{ Login = $login; Nom = $nomComplet; Statut = 'cree' }
        }
        catch {
            Write-Warning "Echec pour $login : $($_.Exception.Message)"
            $rapport += [pscustomobject]@{ Login = $login; Nom = $nomComplet; Statut = "erreur : $($_.Exception.Message)" }
        }
    }
    else {
        $rapport += [pscustomobject]@{ Login = $login; Nom = $nomComplet; Statut = 'simulation' }
    }
}

# -WhatIf:$false pour avoir le rapport meme en simulation
$rapport | Export-Csv -Path $CheminRapport -Delimiter ';' -NoTypeInformation -Encoding UTF8 -WhatIf:$false
Write-Host ""
Write-Host "Termine : $(($rapport | Where-Object Statut -eq 'cree').Count) compte(s) cree(s). Rapport : $CheminRapport"
