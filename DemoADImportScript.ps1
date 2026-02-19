Import-Module ActiveDirectory

# ===== CONFIG =====
$DomainDN = (Get-ADDomain).DistinguishedName
$RootOU = "OU=DemoCorp,$DomainDN"
$Password = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force

# ===== CREATE ROOT OU =====
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'DemoCorp'" -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name "DemoCorp" -Path $DomainDN
}

# ===== DEPARTMENTS =====
$Departments = @("IT","HR","Finance","Sales","Marketing")

foreach ($Dept in $Departments) {
    $ou = "OU=$Dept,$RootOU"
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$Dept'" -SearchBase $RootOU -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $Dept -Path $RootOU
    }

    # Create security group for department
    if (-not (Get-ADGroup -Filter "Name -eq '$Dept Users'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name "$Dept Users" -GroupScope Global -Path $RootOU
    }
}

# ===== USER GENERATOR =====
$FirstNames = @("Liam","Noah","Olivia","Emma","Ava","Isabella","Sophia","Lucas","Mason","Ethan")
$LastNames  = @("Hansen","Johansen","Olsen","Larsen","Andersen","Nilsen","Berg","Hagen","Solberg","Dahl")

$UserCount = 40
$Counter = 1

foreach ($i in 1..$UserCount) {

    $First = Get-Random $FirstNames
    $Last  = Get-Random $LastNames
    $Dept  = Get-Random $Departments

    $Sam = "$($First.Substring(0,1))$Last$Counter".ToLower()
    $UPN = "$Sam@$(Get-ADDomain).DNSRoot"
    $OUPath = "OU=$Dept,$RootOU"

    if (-not (Get-ADUser -Filter "SamAccountName -eq '$Sam'" -ErrorAction SilentlyContinue)) {

        New-ADUser `
            -Name "$First $Last" `
            -GivenName $First `
            -Surname $Last `
            -SamAccountName $Sam `
            -UserPrincipalName $UPN `
            -Path $OUPath `
            -AccountPassword $Password `
            -Enabled $true `
            -ChangePasswordAtLogon $false `
            -Department $Dept

        Add-ADGroupMember -Identity "$Dept Users" -Members $Sam
    }

    $Counter++
}

Write-Host "Demo Active Directory environment created successfully." -ForegroundColor Green
