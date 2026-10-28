# Get-ComptesInactifs.ps1
# Liste les comptes utilisateurs AD actives qui ne se sont pas connectes
# depuis X jours, et peut les desactiver et les ranger dans une OU a part.
#
# Exemples :
#   .\Get-ComptesInactifs.ps1 -Jours 90
#   .\Get-ComptesInactifs.ps1 -Jours 90 -Desactiver -OUDesactives "OU=Desactives,DC=lab,DC=local" -WhatIf

[CmdletBinding(SupportsShouldProcess)]
param(
    [int]$Jours = 90,

    # OU a analyser (par defaut tout le domaine)
    [string]$SearchBase,

    # logins a ne jamais toucher (comptes de service par exemple)
    [string[]]$Exclure = @(),

    [switch]$Desactiver,

    [string]$OUDesactives,

    [string]$Fichier = ".\comptes-inactifs-$(Get-Date -Format 'yyyy-MM-dd').csv"
)

Import-Module ActiveDirectory -ErrorAction Stop

# comptes integres qu'on ne desactive jamais
$exclusDeBase = @('Administrator', 'Administrateur', 'Guest', 'Invite', 'krbtgt')
$exclus = $exclusDeBase + $Exclure

$maintenant = Get-Date
$limite = $maintenant.AddDays(-$Jours)

$params = @{
    Filter     = 'Enabled -eq $true'
    Properties = 'LastLogonDate', 'whenCreated', 'Description'
}
if ($SearchBase) { $params.SearchBase = $SearchBase }

$comptes = Get-ADUser @params
$resultats = @()

foreach ($c in $comptes) {
    if ($exclus -contains $c.SamAccountName) { continue }

    # un compte cree recemment n'a pas encore eu le temps de se connecter
    if ($c.whenCreated -gt $limite) { continue }

    if ($c.LastLogonDate -and $c.LastLogonDate -gt $limite) { continue }

    if ($c.LastLogonDate) {
        $derniere = $c.LastLogonDate.ToString('dd/MM/yyyy')
        $joursInactif = ($maintenant - $c.LastLogonDate).Days
    }
    else {
        $derniere = 'jamais'
        $joursInactif = ($maintenant - $c.whenCreated).Days
    }

    # on retire le "CN=...," du debut pour garder l'OU (\, = virgule dans le nom)
    $ou = $c.DistinguishedName -replace '^CN=(\\,|[^,])+,', ''

    $action = 'a verifier'

    if ($Desactiver) {
        if ($PSCmdlet.ShouldProcess($c.SamAccountName, 'Desactiver le compte')) {
            try {
                Disable-ADAccount -Identity $c.DistinguishedName -ErrorAction Stop
                $note = "Desactive le $($maintenant.ToString('dd/MM/yyyy')) (inactif depuis $joursInactif jours)"
                Set-ADUser -Identity $c.DistinguishedName -Description $note -ErrorAction Stop
                $action = 'desactive'

                if ($OUDesactives) {
                    Move-ADObject -Identity $c.DistinguishedName -TargetPath $OUDesactives -ErrorAction Stop
                    $action = 'desactive et deplace'
                }
            }
            catch {
                $action = "erreur : $($_.Exception.Message)"
            }
        }
        else {
            $action = 'simulation'
        }
    }

    $resultats += [pscustomobject]@{
        Login             = $c.SamAccountName
        Nom               = $c.Name
        DerniereConnexion = $derniere
        JoursInactif      = $joursInactif
        Creation          = $c.whenCreated.ToString('dd/MM/yyyy')
        OU                = $ou
        Action            = $action
    }
}

# le rapport est ecrit meme avec -WhatIf, c'est justement utile pour verifier
$resultats | Sort-Object JoursInactif -Descending |
    Export-Csv -Path $Fichier -Delimiter ';' -NoTypeInformation -Encoding UTF8 -WhatIf:$false

Write-Host "$($comptes.Count) comptes actives analyses, $($resultats.Count) inactifs depuis plus de $Jours jours."
Write-Host "Rapport : $Fichier"
