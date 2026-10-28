# Test hors domaine : on remplace les cmdlets AD par de fausses fonctions
# (une fonction a priorite sur une cmdlet du meme nom), puis on lance le script.

function Import-Module { param($Name, $ErrorAction) }

$aujourdhui = Get-Date

function Get-ADUser {
    param($Filter, $Properties, $SearchBase)
    $j = $aujourdhui
    @(
        [pscustomobject]@{ SamAccountName = 'Administrateur'; Name = 'Administrateur'; LastLogonDate = $null; whenCreated = $j.AddDays(-900); DistinguishedName = 'CN=Administrateur,CN=Users,DC=lab,DC=local' }
        [pscustomobject]@{ SamAccountName = 'jean.martin'; Name = 'Jean Martin'; LastLogonDate = $j.AddDays(-3); whenCreated = $j.AddDays(-400); DistinguishedName = 'CN=Jean Martin,OU=Compta,OU=Utilisateurs,DC=lab,DC=local' }
        [pscustomobject]@{ SamAccountName = 'claire.dubois'; Name = 'Dubois, Claire'; LastLogonDate = $j.AddDays(-140); whenCreated = $j.AddDays(-600); DistinguishedName = 'CN=Dubois\, Claire,OU=RH,OU=Utilisateurs,DC=lab,DC=local' }
        [pscustomobject]@{ SamAccountName = 'stagiaire.01'; Name = 'Stagiaire 01'; LastLogonDate = $null; whenCreated = $j.AddDays(-200); DistinguishedName = 'CN=Stagiaire 01,OU=Informatique,OU=Utilisateurs,DC=lab,DC=local' }
        [pscustomobject]@{ SamAccountName = 'nouveau.arrivant'; Name = 'Nouveau Arrivant'; LastLogonDate = $null; whenCreated = $j.AddDays(-5); DistinguishedName = 'CN=Nouveau Arrivant,OU=Compta,OU=Utilisateurs,DC=lab,DC=local' }
        [pscustomobject]@{ SamAccountName = 'svc.sauvegarde'; Name = 'svc.sauvegarde'; LastLogonDate = $j.AddDays(-300); whenCreated = $j.AddDays(-800); DistinguishedName = 'CN=svc.sauvegarde,OU=Services,DC=lab,DC=local' }
        [pscustomobject]@{ SamAccountName = 'paul.verrou'; Name = 'Paul Verrou'; LastLogonDate = $j.AddDays(-95); whenCreated = $j.AddDays(-700); DistinguishedName = 'CN=Paul Verrou,OU=RH,OU=Utilisateurs,DC=lab,DC=local' }
    )
}

function Disable-ADAccount {
    param($Identity, $ErrorAction)
    if ($Identity -like 'CN=Paul Verrou*') { throw "Acces refuse" }
    Write-Host "  [faux AD] desactivation de $Identity"
}
function Set-ADUser { param($Identity, $Description, $ErrorAction) Write-Host "  [faux AD] description : $Description" }
function Move-ADObject { param($Identity, $TargetPath, $ErrorAction) Write-Host "  [faux AD] deplacement vers $TargetPath" }

$script = Join-Path $PSScriptRoot 'Get-ComptesInactifs.ps1'
$csv = Join-Path $PSScriptRoot 'resultat-test.csv'

Write-Host "=== 1. Rapport seul ==="
& $script -Jours 90 -Exclure 'svc.sauvegarde' -Fichier $csv
Get-Content $csv

Write-Host "`n=== 2. Desactivation en simulation (-WhatIf) ==="
& $script -Jours 90 -Exclure 'svc.sauvegarde' -Desactiver -OUDesactives 'OU=Desactives,DC=lab,DC=local' -Fichier $csv -WhatIf
Get-Content $csv

Write-Host "`n=== 3. Desactivation pour de vrai ==="
& $script -Jours 90 -Exclure 'svc.sauvegarde' -Desactiver -OUDesactives 'OU=Desactives,DC=lab,DC=local' -Fichier $csv
Get-Content $csv

Remove-Item $csv
