if ($IsCoreCLR) {
    <#
    Loads the assembly using an ALC that is defined in the psm1 using Add-Type.
    A future improvement could try and define all this using a Linq Expression
    to avoid the compilation hit but that will make things harder to maintain.
    #>

    $binFolder = [System.IO.Path]::Combine($PSScriptRoot, "bin", "netstandard2.0")

    Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Reflection;
using System.Runtime.Loader;

namespace ALCPureScriptModule
{
    public class LoadContext : AssemblyLoadContext
    {
        private static LoadContext _instance;

        private readonly string _assemblyPath;

        private LoadContext(string assemblyPath)
            : base(name: "ALCPureScriptModule", isCollectible: false)
        {
            _assemblyPath = assemblyPath;
        }

        protected override Assembly Load(AssemblyName assemblyName)
        {
            string asmPath = null;
            if (IsOurAssembly(assemblyName, out asmPath))
            {
                return LoadFromAssemblyPath(asmPath);
            }
            else
            {
                return null;
            }
        }

        internal Assembly ResolveAssembly(
            AssemblyLoadContext defaultAlc,
            AssemblyName assemblyName
        ) {
            string asmPath = null;
            if (IsOurAssembly(assemblyName, out asmPath))
            {
                return LoadFromAssemblyName(assemblyName);
            }
            else
            {
                return null;
            }
        }

        private bool IsOurAssembly(AssemblyName name, out string assemblyToLoad)
        {
            string asmPath = Path.Join(_assemblyPath, $"{name.Name}.dll");
            if (File.Exists(asmPath))
            {
                assemblyToLoad = asmPath;
                return true;
            }
            else
            {
                assemblyToLoad = null;
                return false;
            }
        }

        public static LoadContext OnImport(string assemblyPath)
        {
            _instance = new LoadContext(assemblyPath);
            AssemblyLoadContext.Default.Resolving += _instance.ResolveAssembly;

            return _instance;
        }

        public static void OnRemove()
        {
            if (_instance != null)
            {
                AssemblyLoadContext.Default.Resolving -= _instance.ResolveAssembly;
            }
        }
    }
}
'@

    # Setup the OnRemove method to remove our custom loader
    $MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
        [ALCPureScriptModule.LoadContext]::OnRemove()
    }

    # Create an instance of our ALC
    $loadContext = [ALCPureScriptModule.LoadContext]::OnImport($binFolder)

    # Load our desired deps into the ALC. Any deps of this library will be
    # resolved inside the ALC as well as long as the assembly is present. It is
    # important to load the assembly through the ALC method or else PowerShell
    # might attempt to use an existing assembly that has been loaded.
    $newtonAssemblyName = [System.Reflection.AssemblyName]::GetAssemblyName(
        [System.IO.Path]::Combine($binFolder, "Newtonsoft.Json.dll"))
    $NewtonsoftAssembly = $loadContext.LoadFromAssemblyName($newtonAssemblyName)

    $yamlAssemblyName = [System.Reflection.AssemblyName]::GetAssemblyName(
        [System.IO.Path]::Combine($binFolder, "YamlDotNet.dll"))
    $YamlDotNetAssembly = $loadContext.LoadFromAssemblyName($yamlAssemblyName)
}
else {
    <#
    For .NET Framework we just load as normal. There are three scenarios here:

    1. The assembly is in the GAC

        The GAC version is always favoured, we cannot do anything about this

    2. The assembly is already loaded elsewhere

        The already loaded assembly is used

    3. The assembly is not loaded

        The AppDomain will load it using the filepath in the $assemblyName

    If the same assembly is loaded but at a different version that is
    incompatible with the one we are trying to load, .NET Framework will
    load our own assembly.
    #>
    $binFolder = [System.IO.Path]::Combine($PSScriptRoot, "bin", "net45")

    $newtonAssemblyName = [System.Reflection.AssemblyName]::GetAssemblyName(
        [System.IO.Path]::Combine($binFolder, "Newtonsoft.Json.dll"))
    $NewtonsoftAssembly = [System.Reflection.Assembly]::Load($newtonAssemblyName)

    $yamlAssemblyName = [System.Reflection.AssemblyName]::GetAssemblyName(
        [System.IO.Path]::Combine($binFolder, "YamlDotNet.dll"))
    $YamlDotNetAssembly = [System.Reflection.Assembly]::Load($yamlAssemblyName)
}

# As PowerShell cannot safely reference the type by name we need to save an
# instance of the types we use in the module. We use a script scoped variable
# as an easy way to reference it later.
$script:Newtonsoft = @{
    Json = @{
        JsonConvert = $NewtonsoftAssembly.GetType("Newtonsoft.Json.JsonConvert")
        Formatting = $NewtonsoftAssembly.GetType("Newtonsoft.Json.Formatting")
    }
}
$script:YamlDotNet = @{
    Serialization = @{
        SerializerBuilder = $YamlDotNetAssembly.GetType("YamlDotNet.Serialization.SerializerBuilder")
    }
}

Function ConvertTo-NewtonsoftJson {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [object[]]
        $InputObject
    )

    begin {
        $objs = [System.Collections.Generic.List[object]]::new()
    }

    process {
        $InputObject | ForEach-Object { $objs.Add($_) }
    }

    end {
        $finalObj = [Ordered]@{
            AssemblyInfo = [Ordered]@{
                Name = $NewtonsoftAssembly.GetName().FullName
                Location = $NewtonsoftAssembly.Location
            }
            Object = $objs
        }

        <#
        When refering to the type loaded in our ALC we need to refer to the
        type from the assembly rather than use PowerShell to look it up. There
        are many ways of doing this, this is just one example.
        #>
        $Newtonsoft.Json.JsonConvert::SerializeObject(
            $finalObj,
            $Newtonsoft.Json.Formatting::Indented)
    }
}

Function ConvertTo-YamlDotNet {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [object[]]
        $InputObject
    )

    begin {
        $objs = [System.Collections.Generic.List[object]]::new()
    }

    process {
        $InputObject | ForEach-Object { $objs.Add($_) }
    }

    end {
        $finalObj = [Ordered]@{
            AssemblyInfo = [Ordered]@{
                Name = $YamlDotNetAssembly.GetName().FullName
                Location = $YamlDotNetAssembly.Location
            }
            Object = $objs
        }

        <#
        When refering to the type loaded in our ALC we need to refer to the
        type from the assembly rather than use PowerShell to look it up. There
        are many ways of doing this, this is just one example.
        #>
        $builder = $YamlDotNet.Serialization.SerializerBuilder::new()
        $serializer = $builder.Build()

        $serializer.Serialize($finalObj)
    }
}

Export-ModuleMember -Function ConvertTo-NewtonsoftJson, ConvertTo-YamlDotNet
