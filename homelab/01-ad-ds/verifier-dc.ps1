# verifier-dc.ps1
# Contrôles de base sur le contrôleur de domaine.
# Affiche OK ou PROBLEME pour chaque point, sans rien modifier.

function Show-Resultat {
    param([string]$Test, [bool]$Ok, [string]$Detail = "")
    if ($Ok) {
        Write-Host "[OK]       $Test $Detail" -ForegroundColor Green
    } else {
        Write-Host "[PROBLEME] $Test $Detail" -ForegroundColor Red
    }
}

# 1. Services indispensables à l'AD
foreach ($service in "NTDS", "DNS", "Netlogon", "KDC") {
    $s = Get-Service -Name $service -ErrorAction SilentlyContinue
    Show-Resultat "Service $service" ($s -and $s.Status -eq "Running")
}

# 2. Le domaine répond
try {
    $domaine = Get-ADDomain
    Show-Resultat "Domaine" $true "($($domaine.DNSRoot), mode $($domaine.DomainMode))"
} catch {
    Show-Resultat "Domaine" $false "(Get-ADDomain ne répond pas)"
    exit 1
}

# 3. Partages SYSVOL et NETLOGON (les GPO et scripts de connexion passent par là)
$partages = (Get-SmbShare).Name
Show-Resultat "Partage SYSVOL" ($partages -contains "SYSVOL")
Show-Resultat "Partage NETLOGON" ($partages -contains "NETLOGON")

# 4. Enregistrement SRV : c'est grâce à lui que les postes trouvent le DC
$srv = Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.$($domaine.DNSRoot)" -Type SRV -ErrorAction SilentlyContinue
Show-Resultat "Enregistrement SRV LDAP" ($null -ne $srv)

# 5. Résolution d'un nom externe (teste le redirecteur)
$externe = Resolve-DnsName -Name "www.microsoft.com" -ErrorAction SilentlyContinue
Show-Resultat "Résolution DNS externe" ($null -ne $externe)

# 6. Résumé de dcdiag (seulement les tests en échec)
Write-Host ""
Write-Host "dcdiag /q (rien affiché = aucun test en échec) :"
dcdiag /q
