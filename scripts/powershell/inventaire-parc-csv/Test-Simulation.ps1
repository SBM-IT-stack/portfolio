# Test hors domaine : on remplace les cmdlets reseau par de fausses fonctions
# (une fonction a priorite sur une cmdlet du meme nom), puis on lance le script.

function Test-Connection { param($ComputerName, $Count, [switch]$Quiet) $ComputerName -ne "PC-ETEINT" }

function New-CimSession {
    param($ComputerName, $Credential, $ErrorAction)
    if ($ComputerName -eq "PC-SANS-WINRM") { throw "Le client ne peut pas se connecter a la destination." }
    [pscustomobject]@{ Nom = $ComputerName }
}

function Remove-CimSession { param($CimSession) }

function Get-CimInstance {
    param($CimSession, $ClassName, $Filter)
    switch ($ClassName) {
        "Win32_ComputerSystem" { [pscustomobject]@{ UserName = "CORP\j.martin"; Manufacturer = "Dell Inc."; Model = "OptiPlex 7090"; TotalPhysicalMemory = 17045651456 } }
        "Win32_OperatingSystem" { [pscustomobject]@{ Caption = "Microsoft Windows 11 Professionnel"; Version = "10.0.22631"; LastBootUpTime = [datetime]"2026-10-14 08:02" } }
        "Win32_BIOS" { [pscustomobject]@{ SerialNumber = "7XK2M93" } }
        "Win32_Processor" { [pscustomobject]@{ Name = "  Intel(R) Core(TM) i5-11500 @ 2.70GHz" } }
        "Win32_LogicalDisk" { [pscustomobject]@{ Size = 255465615360; FreeSpace = 98784247808 } }
        "Win32_NetworkAdapterConfiguration" { [pscustomobject]@{ IPAddress = @("192.168.10.21", "fe80::1c2b:3d4e:5f60:7a8b"); MACAddress = "A4:BB:6D:12:34:56" } }
    }
}

$dossier = Split-Path $PSScriptRoot
& (Join-Path $dossier "Get-InventaireParc.ps1") -ListePostes (Join-Path $PSScriptRoot "postes-test.txt") -Fichier (Join-Path $PSScriptRoot "resultat-test.csv")
Get-Content (Join-Path $PSScriptRoot "resultat-test.csv")
