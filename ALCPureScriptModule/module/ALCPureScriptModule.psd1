@{
    RootModule = 'ALCPureScriptModule.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'e77b5490-ff5b-4d71-9c0c-e33d32ceb82b'
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
