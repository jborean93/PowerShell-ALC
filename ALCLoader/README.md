# ALC Loader
This is an example module that uses the `ALC Loader` setup.
The `ALC Loader` example has two assemblies in the module:

+ `ALCLoader.dll`
  + Contains the cmdlets and any dep references inside the ALC
+ `ALCLoader.Shared.dll`
  + Shared code and where the ALC setup code is located

Some pros and cons using this method over the [ALC Resolver](../ALCResolver/README.md) example are:

|Pros|Cons|
|-|-|
|Assembly deps can be used by the cmdlet directly|Requires an internal method to support force importing a module a 2nd time|
|No need for an OnImport or OnRemove to cleanup the ALC|Still requires a `.psm1` to load the assembly|
|Can still share data type with the caller using the shared assembly||
|The exact dependency is loaded, it won't use any existing loaded assemblies||

## Structure
The module consists of 3 components:

+ PowerShell module [ALCLoader.psd1](./module/ALCLoader.psd1) and [ALCLoader.psm1](./module/ALCLoader.psm1)`
+ Shared Assembly util [ALCLoader.Shared](./src/ALCLoader.Shared/)
+ Binary module assembly [ALCLoader](./src/ALCLoader/)

The names of the C# projects used here don't have to be exactly the same, the key part is the `ALCLoader.Shared` contains the `AssemblyLoadContext` setup code and `ALCLoader` contains the cmdlets and code that calls the deps which are contained in the ALC.

When PowerShell loads `ALCLoader` it will run the code in [ALCLoader.psm1](./module/ALCLoader.psm1) which on PowerShell 7 will create the ALC.
This is done by calling [ALCLoader.Shared.LoadContext](./src/ALCLoader.Shared/LoadContext.cs) to create the ALC, load our binary module, and return the loaded assembly inside that ALC.
Finally the `psm1` will then load the assembly as normal and export the cmdlets within that assembly.
