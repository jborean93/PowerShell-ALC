@{
    RootModule = 'ALCScriptModule.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'c54ad6bd-2e14-4768-9d80-6f8f2c28cd30'
    Author = 'Jordan Borean'
    CompanyName = 'Community'
    Copyright = '(c) 2023 Jordan Borean. All rights reserved.'
    Description = 'ALC with Script Module'
    PowerShellVersion = '5.1'
    DotNetFrameworkVersion = '4.7.2'
    TypesToProcess = @()
    FormatsToProcess = @()
    NestedModules = @()
    FunctionsToExport = @(
        'ConvertTo-NewtonsoftJson'
        'ConvertTo-YamlDotNet'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{}
    }
}
