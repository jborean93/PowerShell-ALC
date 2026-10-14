using namespace System.IO
using namespace System.Management.Automation
using namespace System.Reflection

# Resolve the cmdlet through $ExecutionContext to ensure we don't load a
# shadowed version of Import-Module.
$importModule = $ExecutionContext.InvokeCommand.GetCommand(
    'Microsoft.PowerShell.Core\Import-Module',
    [CommandTypes]::Cmdlet)

$moduleName = [Path]::GetFileNameWithoutExtension($PSCommandPath)

if (-not $IsCoreClr) {
    # PowerShell 5.1 has no concept of an Assembly Load Context so it will
    # just load the module assembly directly.

    # The type can be any type within our ALCLoader project
    $innerMod = if ('ALCLoader.ConvertToNewtonsoftJsonCommand' -as [type]) {
        $modAssembly = [ALCLoader.ConvertToNewtonsoftJsonCommand].Assembly
        & $importModule -Assembly $modAssembly -Force -PassThru
    }
    else {
        $modPath = [Path]::Combine($PSScriptRoot, 'bin', 'net472', "$moduleName.dll")
        & $importModule -Name $modPath -ErrorAction Stop -PassThru
    }
}
else {
    # This is used to load the loader assembly in the Default ALC which then
    # creates an ALC for the module and any dependencies of that module to be
    # loaded in that ALC.
    $loaderName = "$moduleName.Loader.LoadContext"
    $loaderPath = [Path]::Combine($PSScriptRoot, 'bin', 'net5.0', "$moduleName.Loader.dll")

    $isReload = $true
    $loaderType = $loaderName -as [type]
    if (-not $loaderType) {
        $isReload = $false

        $null = [Assembly]::LoadFrom($loaderPath)
        $loaderType = $loaderName -as [type]
    }
    elseif ($loaderType.Assembly.Location -ne $loaderPath) {
        # Assemblies cannot be unloaded so once a version of this module is
        # loaded in the process it is the only one that can be used.
        $msg = "Cannot import $moduleName from '$PSScriptRoot' as a different copy is already loaded in this process " +
        "from '$($loaderType.Assembly.Location)'. Start a new PowerShell process to use this copy."
        $err = [ErrorRecord]::new(
            [InvalidOperationException]::new($msg),
            'ModuleAlreadyLoadedFromDifferentPath',
            [ErrorCategory]::ResourceExists,
            $PSScriptRoot)
        throw $err
    }

    $mainModule = $loaderType::Initialize($moduleName)
    $innerMod = & $importModule -Assembly $mainModule -PassThru:$isReload
}

if ($innerMod) {
    # Bug in pwsh, Import-Module in an assembly will pick up a cached instance
    # and not call the same path to set the nested module's cmdlets to the
    # current module scope. This is only technically needed if someone is
    # calling 'Import-Module -Name ALCLoader -Force' a second time. The first
    # import is still fine.
    # https://github.com/PowerShell/PowerShell/issues/20710
    $addExportedCmdlet = [PSModuleInfo].GetMethod(
        'AddExportedCmdlet',
        [BindingFlags]'Instance, NonPublic')
    $addExportedAlias = [PSModuleInfo].GetMethod(
        'AddExportedAlias',
        [BindingFlags]'Instance, NonPublic')
    foreach ($cmd in $innerMod.ExportedCmdlets.Values) {
        $addExportedCmdlet.Invoke($ExecutionContext.SessionState.Module, @(, $cmd))
    }
    foreach ($alias in $innerMod.ExportedAliases.Values) {
        $addExportedAlias.Invoke($ExecutionContext.SessionState.Module, @(, $alias))
    }
}
