@{
    RootModule = 'ALCLoader.psm1'
    ModuleVersion = '1.0.0'
    GUID = '7b99120d-e9cc-4808-a607-871fd42d376c'
    Author = 'Jordan Borean'
    CompanyName = 'Community'
    Copyright = '(c) 2023 Jordan Borean. All rights reserved.'
    Description = 'ALC Loader example'
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
