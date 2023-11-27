using namespace System.IO
using namespace System.Reflection

param (
    [Parameter(Mandatory)]
    [string]
    $Name
)

$ErrorActionPreference = 'Stop'

. $PSScriptRoot/common.ps1

#########
# SETUP #
#########

# Comes with Newtonsoft.Json 12
$pwsh_7_1 = Get-PowerShell -Version 7.1.7

# Comes with Newtonsoft.Json 13
$pwsh_7_4 = Get-PowerShell -Version 7.4.0

Get-NugetAssembly -Name YamlDotNet -Version 12.3.1 | Out-Null
Get-NugetAssembly -Name YamlDotNet -Version 13.7.1 | Out-Null
$newtonsoft_12 = Get-NugetAssembly -Name Newtonsoft.Json -Version 12.0.3
$newtonsoft_13 = Get-NugetAssembly -Name Newtonsoft.Json -Version 13.0.3

# Build our module
& $pwsh_7_4 -File ([Path]::Combine($PSScriptRoot, $Name, "build.ps1"))

#########
# TESTS #
#########

Push-Location -LiteralPath $PSScriptRoot/$Name
try {
    Write-Host "Test: PS - Loading with assembly not loaded"
    & $pwsh_7_4 {
        Import-Module (Get-Item -Path ./output/ALC*).FullName

        # Newtonsoft.Json is always loaded in pwsh so we are just testing YamlDotNet
        ConvertTo-YamlDotNet foo

        @(
            foreach ($asm in [System.AppDomain]::CurrentDomain.GetAssemblies()) {
                if (-not (
                        $asm.GetName().Name -like "*newtonsoft*" -or
                        $asm.GetName().Name -like "*yaml*"
                    )
                ) {
                    continue
                }

                $alc = [Runtime.Loader.AssemblyLoadContext]::GetLoadContext($asm)
                [PSCustomObject]@{
                    Name = $asm.FullName
                    Location = $asm.Location
                    ALC = $alc
                }
            }
        ) | Format-List
    } | Out-Host

    Write-Host "Test: PS - Loading with older assembly already loaded"
    & $pwsh_7_1 {
        Import-Module (Get-Item -Path ./output/ALC*).FullName

        Add-Type -Path "../bin/YamlDotNet.12.3.1/netstandard2.0/YamlDotNet.dll"

        ConvertTo-NewtonsoftJson foo
        ConvertTo-YamlDotNet foo

        @(
            foreach ($asm in [System.AppDomain]::CurrentDomain.GetAssemblies()) {
                if (-not (
                        $asm.GetName().Name -like "*newtonsoft*" -or
                        $asm.GetName().Name -like "*yaml*"
                    )
                ) {
                    continue
                }

                $alc = [Runtime.Loader.AssemblyLoadContext]::GetLoadContext($asm)
                [PSCustomObject]@{
                    Name = $asm.FullName
                    Location = $asm.Location
                    ALC = $alc
                }
            }
        ) | Format-List
    } | Out-Host

    Write-Host "Test: PS - Loading with same assembly version already loaded"
    & $pwsh_7_4 {
        Import-Module (Get-Item -Path ./output/ALC*).FullName

        Add-Type -Path "../bin/YamlDotNet.13.7.1/netstandard2.0/YamlDotNet.dll"

        ConvertTo-NewtonsoftJson foo
        ConvertTo-YamlDotNet foo

        @(
            foreach ($asm in [System.AppDomain]::CurrentDomain.GetAssemblies()) {
                if (-not (
                        $asm.GetName().Name -like "*newtonsoft*" -or
                        $asm.GetName().Name -like "*yaml*"
                    )
                ) {
                    continue
                }

                $alc = [Runtime.Loader.AssemblyLoadContext]::GetLoadContext($asm)
                [PSCustomObject]@{
                    Name = $asm.FullName
                    Location = $asm.Location
                    ALC = $alc
                }
            }
        ) | Format-List
    } | Out-Host

    if ($IsCoreCLR -and -not $IsWindows) {
        return
    }

    Write-Host "Test: WinPS - Assembly not already loaded"
    powershell.exe {
        Import-Module (Get-Item -Path ./output/ALC*).FullName

        ConvertTo-NewtonsoftJson foo
        ConvertTo-YamlDotNet foo

        @(
            foreach ($asm in [System.AppDomain]::CurrentDomain.GetAssemblies()) {
                if (-not (
                        $asm.GetName().Name -like "*newtonsoft*" -or
                        $asm.GetName().Name -like "*yaml*"
                    )
                ) {
                    continue
                }

                [PSCustomObject]@{
                    Name = $asm.FullName
                    Location = $asm.Location
                }
            }
        ) | Format-List
    } | Out-Host

    Write-Host "Test: WinPS - Older assembly already loaded"
    powershell.exe {
        Add-Type -Path "../bin/Newtonsoft.Json.12.0.3/net45/Newtonsoft.Json.dll"
        Add-Type -Path "../bin/YamlDotNet.12.3.1/net45/YamlDotNet.dll"

        Import-Module (Get-Item -Path ./output/ALC*).FullName

        ConvertTo-NewtonsoftJson foo
        ConvertTo-YamlDotNet foo

        @(
            foreach ($asm in [System.AppDomain]::CurrentDomain.GetAssemblies()) {
                if (-not (
                        $asm.GetName().Name -like "*newtonsoft*" -or
                        $asm.GetName().Name -like "*yaml*"
                    )
                ) {
                    continue
                }

                [PSCustomObject]@{
                    Name = $asm.FullName
                    Location = $asm.Location
                }
            }
        ) | Format-List
    } | Out-Host

    Write-Host "Test: WinPS - Same assembly already loaded"
    powershell.exe {
        Add-Type -Path "../bin/Newtonsoft.Json.13.0.3/net45/Newtonsoft.Json.dll"
        Add-Type -Path "../bin/YamlDotNet.13.7.1/net45/YamlDotNet.dll"

        Import-Module (Get-Item -Path ./output/ALC*).FullName

        ConvertTo-NewtonsoftJson foo
        ConvertTo-YamlDotNet foo

        @(
            foreach ($asm in [System.AppDomain]::CurrentDomain.GetAssemblies()) {
                if (-not (
                        $asm.GetName().Name -like "*newtonsoft*" -or
                        $asm.GetName().Name -like "*yaml*"
                    )
                ) {
                    continue
                }

                [PSCustomObject]@{
                    Name = $asm.FullName
                    Location = $asm.Location
                }
            }
        ) | Format-List
    } | Out-Host

    # We need to be running as admin to add/remove from the GAC
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not
    (([System.Security.Principal.WindowsPrincipal]$currentUser).IsInRole(
            [System.Security.Principal.WindowsBuiltinRole]::Administrator
        ))
    ) {
        return
    }

    $newton12Assembly = "$newtonsoft_12\net45\Newtonsoft.Json.dll"
    $newton13Assembly = "$newtonsoft_13\net45\Newtonsoft.Json.dll"

    Add-GacAssembly -Path $newton12Assembly
    try {
        Write-Host "Test: WinPS GAC - Older assembly version"
        powershell.exe {
            Import-Module (Get-Item -Path ./output/ALC*).FullName

            ConvertTo-NewtonsoftJson foo
        } | Out-Host
    }
    finally {
        Remove-GacAssembly -Path $newton12Assembly
    }

    Add-GacAssembly -Path $newton13Assembly
    try {
        Write-Host "Test: WinPS GAC - Same assembly version"
        powershell.exe {
            Import-Module (Get-Item -Path ./output/ALC*).FullName

            ConvertTo-NewtonsoftJson foo
        } | Out-Host
    }
    finally {
        Remove-GacAssembly -Path $newton13Assembly
    }
}
finally {
    Pop-Location
}
