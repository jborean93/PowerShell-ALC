# ALC ScriptModule LoadContext
This is similar to [ALCPureScriptModule](../ALCPureScriptModule/README.md) but shows how an assembly and its dependencies can be loaded in an Assembly Load Context and used in a script module.
While it does have a `csproj` this is only used to download the dependencies for the module, it is a completly optional step if downloading them another way.

It can be further expanded to put any common helper code in the C# project like callbacks or anything else that might need access to the assemblies that are being depended on.
This might make things clearer or easier to do if you are comfortable doing it in C#.

This approach has some benefits over the other ScriptModule examples as:

+ All dependencies of the assembly is loaded into the ALC, no sharing with whatever PowerShell might have already loaded
+ It can be easily expanded with your own custom C# code if needed (callbacks/helper code to simplify things)

Some downsides:

+ The PowerShell cannot refer to the types in the assemblies in the ALC - they need to be retrieved through the assembly (see `$ALCTypes`)
+ It uses an inline `Add-Type` which can be problematic with some AVs and adds some slight import delays
  + This can certainly be built into another assembly to save runtime or to share it with other modules

In this example module we have a `.psm1` that loads the dependencies `Microsoft.Identity.Client` and its dependencies.
In Windows PowerShell (5.1) the dependencies will just be loaded directly while in PowerShell (7+) the dependencies will be loaded inside an ALC.

You can run the following code after running the `Get-MsalToken` function to see how the `Microsoft.Identity.Client` assembly is loaded into the ALC

```powershell
[System.AppDomain]::CurrentDomain.GetAssemblies() |
    ForEach-Object {
        $alc = [Runtime.Loader.AssemblyLoadContext]::GetLoadContext($_)
        [PSCustomObject]@{
            Name = $_.GetName().Name
            ALC = $alc.Name
            Location = $_.Location
        }
    } | Sort-Object Name
```

## Structure
The module consists of 4 parts:

+ [ALCScriptLoadContext.psd1](./module/ALCScriptLoadContext.psd1)
  + Module manifest, no difference from normal
+ [ALCScriptLoadContext.psm1](./module/ALCScriptLoadContext.psm1)
  + Module that sets up the ALC and defines the functions needed
+ [ALCScriptLoadContext.csproj](./src/ALCScriptLoadContext/ALCScriptLoadContext.csproj)
  + Our C# project file, this is completely optional and is used to gather the assembly dlls and its dependencies

As with all script modules the module can either define the public/private functions in-line or load them from another file.
How it chooses to do this is outside the scope of this example.

The ALC logic is all contained in [ALCScriptLoadContext.psm1](./module/ALCScriptLoadContext.psm1) and consists of three main parts:

+ Setting up the ALC and loading the assemblies
  + PowerShell (7+) sets up the ALC and loads the dependencies inside it
  + Windows PowerShell (5.1) just loads the assemblies
+ Setting up the static type mapping for the module functions to reference
+ Defines the module functions.
