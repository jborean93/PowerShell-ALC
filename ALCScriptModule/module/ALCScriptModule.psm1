if ($IsCoreCLR) {
    <#
    This shows how the LoadContext.cs code can be defined in the psm1 which
    removes the need to compile the code. I would not recommend this as it
    increases the import time and complicates the code here.
    #>

    $binFolder = [System.IO.Path]::Combine($PSScriptRoot, "bin", "net5.0")
    $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)

    # Loading the ALC setup code through an assembly is the
    # recommended route. There's no import hit to compiling the code
    # and the psm1 is cleaner.
    if (-not ('ALCScriptModule.LoadContext' -as [type])) {
        $alcAssembly = [System.IO.Path]::Combine($binFolder, "$moduleName.dll")
        Add-Type -Path $alcAssembly
    }

    # Setup the OnRemove method to remove our custom loader
    $MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
        [ALCScriptModule.LoadContext]::OnRemove()
    }

    # Create an instance of our ALC defined in our C# assembly
    $loadContext = [ALCScriptModule.LoadContext]::OnImport()

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
    $binFolder = [System.IO.Path]::Combine($PSScriptRoot, "bin", "net472")

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
