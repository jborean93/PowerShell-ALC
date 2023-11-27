. $PSScriptRoot/../common.ps1

Write-Host "Getting build information"
$Build = Get-BuildInfo -Path $PSSCriptRoot

if (-not (Test-Path -LiteralPath $Build.BuildDir)) {
    New-Item -Path $Build.BuildDir -ItemType Directory -Force | Out-Null
}

Write-Host "Downloading assemblies"
$newtonsoftJson = Get-NugetAssembly -Name Newtonsoft.Json -Version 13.0.3
$yamlDotNet = Get-NugetAssembly -Name YamlDotNet 13.7.1

Write-Host "Build PowerShell module result"
Copy-Item -Path ([Path]::Combine($Build.PowerShellSource, "*")) -Destination $Build.BuildDir -Recurse

$binDir = [Path]::Combine($build.BuildDir, "bin")
if (-not (Test-Path -LiteralPath $binDir)) {
    New-Item -Path $binDir -ItemType Directory | Out-Null
}

$net45Bin = [Path]::Combine($binDir, "net45")
if (-not (Test-Path -LiteralPath $net45Bin)) {
    New-Item -Path $net45Bin -ItemType Directory | Out-Null
}
Copy-Item -Path ([Path]::Combine($newtonsoftJson, "net45", "*.dll")) -Destination $net45Bin
Copy-Item -Path ([Path]::Combine($yamlDotNet, "net45", "*.dll")) -Destination $net45Bin

$netstandard20Bin = [Path]::Combine($binDir, "netstandard2.0")
if (-not (Test-Path -LiteralPath $netstandard20Bin)) {
    New-Item -Path $netstandard20Bin -ItemType Directory | Out-Null
}
Copy-Item -Path ([Path]::Combine($newtonsoftJson, "netstandard2.0", "*.dll")) -Destination $netstandard20Bin
Copy-Item -Path ([Path]::Combine($yamlDotNet, "netstandard2.0", "*.dll")) -Destination $netstandard20Bin
