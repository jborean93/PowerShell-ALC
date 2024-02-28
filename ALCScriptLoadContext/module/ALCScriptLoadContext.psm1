if ($IsCoreCLR) {
    # As the Assembly Load code is run in a separate thread we need to use
    # Add-Type to define the class. This class simply creates the
    # AssemblyLoadContext for our module and has it load any assemblies into
    # the ALC and not the main app domain.
    Add-Type -TypeDefinition @'
#nullable enable
using System.IO;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.Loader;

namespace MyModuleAlc;

public class LoadContext : AssemblyLoadContext
{
    private readonly string _assemblyDir;

    public LoadContext(string alcName, string assemblyDir)
        : base (name: alcName, isCollectible: false)
    {
        _assemblyDir = assemblyDir;
    }

    protected override Assembly? Load(AssemblyName assemblyName)
    {
        // Checks to see if the assembly exists in our path, if so load it in
        // the ALC. Otherwise fallback to the default loading behaviour.
        string asmPath = Path.Join(_assemblyDir, $"{assemblyName.Name}.dll");
        if (File.Exists(asmPath))
        {
            return LoadFromAssemblyPath(asmPath);
        }
        else
        {
            return null;
        }
    }
}
'@

    # This example uses netstandard2.0 as the target framework deps, this can
    # be set to whatever is relevant for your module setup.
    $binDir = [System.IO.Path]::Combine($PSSCriptRoot, "bin", "netstandard2.0")

    # Create an instance of the AssemblyLoadContext. We call it 'MyAlc' but you
    # cal call it whatever you want as long as it's unique (use your module
    # name). We also provide the assembly directory to find assemblies from,
    # this allows the ALC to find the dependencies and use that.
    $loadContext = [MyModuleAlc.LoadContext]::new("MyAlc", $binDir)

    # We use LoadFromAssemblyPath to load our direct dependency and get the
    # Assembly object back. From this object we can get the types used in our
    # module (see after the else branch).
    $miClientAssembly = $loadContext.LoadFromAssemblyPath((Join-Path $binDir "Microsoft.Identity.Client.dll"))
}
else {
    # This is code run on WinPS (5.1), the bin dir is the same because this
    # example uses netstandard2.0, this will be different if you use separate
    # frameworks for your assemblies.
    $binDir = [System.IO.Path]::Combine($PSSCriptRoot, "bin", "netstandard2.0")

    # There is no AssemblyLoadContext on .NET Framework so we just load
    # directly and hope for the best. You can of course add more complex logic
    # if you wish but I recommend just leaving as is and tell people to use
    # pwsh 7+ or run inside a job to avoid conflicts.
    Add-Type -LiteralPath (Join-Path $binDir "Microsoft.Identity.Client.dll")

    # As the type is loaded directly we can reference it like normal. We save
    # the assembly only for this dll for the next step.
    $miClientAssembly = [Microsoft.Identity.Client.ConfidentialClientApplicationOptions].Assembly
}

# We store the types in our assembly in a hashtable to make it easier to
# retrieve after. This example just stores it under the full type name but you
# can add whatever logic to shorten or alias the name. Any types that were not
# found will be raised as an error later on.
$script:ALCTypes = @{}
$unknownTypes = foreach ($typeName in @(
        'Microsoft.Identity.Client.ConfidentialClientApplicationOptions'
        'Microsoft.Identity.Client.ConfidentialClientApplicationBuilder'
    )) {

    # GetType returns $null if the Assembly.GetType(string name) can't find
    # the assembly. We output that into $unknownTypes for erroring later.
    # Otherwise we add it to our hashtable for referencing later in our module.
    $foundType = $miClientAssembly.GetType($typeName)
    if ($foundType) {
        $ALCTypes[$typeName] = $foundType
    }
    else {
        $typeName
    }
}
if ($unknownTypes) {
    $msg = "Failed to find the following types in Microsoft.Identity.Client: '$($unknownTypes -join "', '")'"
    Write-Error -Message $msg -ErrorAction Stop
}

Function Get-MsalToken {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ClientID,
        [Parameter(Mandatory)][string]$TenantID,
        [Parameter(Mandatory)][string]$ClientSecret
    )

    # We cannot refer to the type using the normal [TypeName] syntax as it's
    # loaded in the ALC and PowerShell doesn't know about it. Use our $ALCTypes
    # hashtable which stores the type object under the type name instead. The
    # Type object acts the same way as [TypeName], it's just retrieved
    # differently.
    $Options = $ALCTypes['Microsoft.Identity.Client.ConfidentialClientApplicationOptions']::new()
    $Options.ClientId = $ClientID
    $Options.TenantId = $TenantID
    $Options.ClientSecret = $ClientSecret

    # Same deal here, we need to get the type from the $ALCTypes hashtable.
    $authApp = $ALCTypes['Microsoft.Identity.Client.ConfidentialClientApplicationBuilder']::CreateWithApplicationOptions(
        $Options).Build()

    # From here the code is as per usual.
    $authTask = $authApp.AcquireTokenForClient(
        [string[]]@('https://graph.microsoft.com/.default')).ExecuteAsync([System.Threading.CancellationToken]::None)
    while (-not $authTask.AsyncWaitHandle.WaitOne(200)) {}
    $authTask.GetAwaiter().GetResult()
}
