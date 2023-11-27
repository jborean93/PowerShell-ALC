@{
    RootModule = if ($PSEdition -eq 'core') { 'bin/net5.0/ALCResolver.dll' } else { 'bin/net472/ALCResolver.dll' }
    ModuleVersion = '1.0.0'
    GUID = '31bb040b-32c8-4c89-a65e-876222ec94bc'
    Author = 'Jordan Borean'
    CompanyName = 'Community'
    Copyright = '(c) 2023 Jordan Borean. All rights reserved.'
    Description = 'ALC Resolver example'
    PowerShellVersion = '5.1'
    DotNetFrameworkVersion = '4.7.2'
    TypesToProcess = @()
    FormatsToProcess = @()
    NestedModules = @()
    FunctionsToExport = @()
    CmdletsToExport = @(
        'ConvertTo-NewtonsoftJson'
        'ConvertTo-YamlDotNet'
    )
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{}
    }
}
