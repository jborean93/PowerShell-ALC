# ALC Resolver
This is an example module that uses the `ALC Resolver` setup.
The `ALC Resolver` example has two assemblies in the module:

+ `ALCResolver.dll`
  + Contains the cmdlets and ALC setup code
+ `ALCResolver.Private.dll`
  + Will be loaded into the ALC and contains the code calling the deps that should be loaded in the ALC

Some pros and cons using this method over the [ALC Loader](../ALCLoader/README.md) example are:

|Pros|Cons|
|-|-|
|No need for a `.psm1`|No guarantees deps will be loaded in the ALC, existing loaded assemblies will be used if present|
|Works find with second `Import-Module -Force`, no reflection needed|Need to explicitly structure cmdlets to call methods in the private assembly to use deps|

Due to the edge cases of this setup I would highly recommend avoiding it in favour of the [ALCLoader](../ALCLoader/README.md) example.
`ALCLoader` will ensure all the module's dependencies are loaded in the ALC and the structure of the code is easier to deal with.

## Structure
The module consists of 3 components:

+ PowerShell module [ALCResolver.psd1](./module/ALCResolver.psd1) and [ALCResolver.psm1](./module/ALCResolver.psm1)`
+ Binary module assembly [ALCResolver](./src/ALCResolver/)
+ ALC'd Assembly [ALCResolver.Private](./src/ALCResolver.Private/)

The names of the C# projects used here don't have to be exactly the same, the key part is the `ALCResolver` contains the `OnModuleImportAndRemove` handler to setup the `ALC` and `ALCResolver.Private` contains deps that should be placed in the ALC.

When PowerShell loads `ALCResolver` it will run the import the `ALCResolver` assembly and load any cmdlets inside that in the module.
It will also find the [OnImportAndRemove](./src/ALCResolver/OnImportAndRemove.cs) instance and call the `OnImport()` method during the import.
This method sets up the `ALC` and then loads `ALCResolver.Private` into that ALC.
Any assemblies `ALCResolver.Private` needs during runtime will either use what is already available or if that fails will load the assembly from the bin directory of the module into the ALC.
This is a big different between this setup and `ALCLoader` as `ALCLoader` will always load the assembly inside the ALC alongside all of its dependencies whereas this only does so if the assembly is not already loaded.
