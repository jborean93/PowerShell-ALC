# PowerShell Assembly Load Contexts
This repo is designed to go through the various ways to use an Assembly Load Context (`ALC`) in a PowerShell module.
An ALC is a new mechanism introduced with .NET 5 that provides a way to load multiple versions of the same assembly into the same process.
It can be used in PowerShell to build a module with a dependency that might conflict with something provided by PowerShell or another module that has already been imported.

I found that the guides online didn't cover all the mechanisms or showed real working examples of it all setup.
I would like to call out the following links which do cover a lot of the ground here and are great fundamentals for understanding the concept behind an ALC:

+ https://learn.microsoft.com/en-us/powershell/scripting/dev-cross-plat/resolving-dependency-conflicts?view=powershell-7.4
+ https://pipe.how/get-assemblyloadcontext/

There are two ways I know how to use an ALC in PowerShell modules:

+ [ALC Loader](./ALCLoader/README.md) - loads our binary module in a ALC directly
+ [ALC Resolver](./ALCLoader/README.md) - loads our binary module normally and the deps with an ALC resolver

These are not official names but how I will refer to these methods going forward.
I personally recommend the [ALC Loader](./ALCLoader/README.md) method when starting a new project as:

+ It ensures all deps are placed in the ALC and nothing is missed
+ Cmdlets can interact directly with the deps without a wrapper assembly making the code simpler

An ALC typically needs to be used as a binary module but it is technically possible to use it in a pure PowerShell script module.
See [ALC ScriptModule](./ALCScriptModule/README.md), [ALC Pure ScriptModule](./ALCPureScriptModule/README.md), or [ALC Script LoadContext](./ALCScriptLoadContext/README.md) for more details on this approach.

## Testing
The `./test.ps1` script can be used to build an example module and run through some basic scenarios.

```powershell
pwsh.exe -File ./test.ps1 -Name ALCLoader
pwsh.exe -File ./test.ps1 -Name ALCResolver
pwsh.exe -File ./test.ps1 -Name ALCScriptModule
pwsh.exe -File ./test.ps1 -Name ALCPureScriptModule
```
These scenarios are all the same in each example and show how the assemblies are loaded and that the code actually works.
Please note the `GAC` tests require you to be running as admin.
The tests go through 6 different scenarios:

|Scenario|Outcome|
|-|-|
|WinPS|Loads the module's assembly|
|WinPS Same version already loaded|Already loaded assembly|
|WinPS Older version already loaded|Loads the module's assembly|
|PS|Loads the module's assembly in an ALC|
|PS Same version already loaded|Loads the module's assembly in an ALC*|
|PS Older version already loaded|Loads the module's assembly in an ALC|

_*: `ALCResolver` will use the existing loaded assembly rather than load a new one in the ALC._

The main difference between WinPS and PS here is that PS will always load our dependencies in the ALC while WinPS only load our assembly if there is not an existing assembly that matches the name/version.
WinPS can load the same assembly at different versions so this should avoid any version conflicts in the majority of cases.

## Things to Avoid
When using an ALC you should avoid:

+ Use an ALC type as your cmdlet's parameters or outputs

It is possible to output an object of a type from an assembly loaded in an ALC but it should be avoided as much as possible.
This won't cause PowerShell to then load the assembly but it will be unable to reference the type.
For example this won't work because `[Assembly.In.Alc.Type]` is not resolvable in PowerShell and if it was the type won't match the type loaded in the ALC.

```ps
$obj = Test-Function
$obj -is [Assembly.In.Alc.Type]
```

This will also be problematic if you try to create a function with a parameter of a type in the ALC

```ps
Function Test-Function {
    [CmdletBinding()]
    param (
        [Assembly.In.Alc.Type]$Object
    )
}

$obj = Get-ModuleItem
Test-Function -Object $obj
```

The same problem applies where the type may not be resolvable in PowerShell and if it was will be for a different assembly than the one from the ALC that created the type giving you the confusing error:

```
The type 'Assembly.In.Alc.Type' cannot be casted to the type 'Assembly.In.Alc.Type'
```

## Real World Examples
Some real world examples of modules that use an ALC are:

+ [OpenAuthenticode](https://github.com/jborean93/PowerShell-OpenAuthenticode)
+ [PowerShellEditorServices](https://github.com/PowerShell/PowerShellEditorServices)
+ [PSOpenAD](https://github.com/jborean93/PSOpenAD)
+ [PSToml](https://github.com/jborean93/PSToml)
+ [SecretManagement.DpapiNG](https://github.com/jborean93/SecretManagement.DpapiNG)
  + This also is a [SecretManagement](https://github.com/PowerShell/SecretManagement) implementation
+ [Yayaml](https://github.com/jborean93/PowerShell-Yayaml)

Thanks to

+ @seeminglyscience who came up with the `ALC Loader` example and helped me through some questions I had
+ @JustinGrote who came up with some ideas to try out and talk through some scenarios to test
+ @mdgrs-mei for finding a bug in my `ALCResolver` example and working through some of the edge cases
