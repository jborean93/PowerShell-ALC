# ALC ScriptModule
This is an example module that shows how to use an ALC with a Script based module in PowerShell when combined with a `.csroj`.
While this does require `dotnet` to publish the assembly it is beneficial over [ALCPureScriptModule](../ALCPureScriptModule/README.md) for a few reasons:

+ No need to manually download the assembly dependencies, dotnet will do this for you
+ The complex ALC code is moved out of the `psm1` into the C# assembly generated
+ Importing the module no longer has to compile the ALC code, it will be quicker this way
+ The `psm1` is simplified by moving the complex code out
+ It is now possible to re-use the binary assembly to embed other C# code your module may need

The core module is still written in PowerShell so it will still have the same disadvantages as `ALCPureScriptModule` when it comes to referencing the ALC type.
In this example module we have a `.psm1` that loads the dependencies `Newtonsoft.Json` and `YamlDotNet`.
In Windows PowerShell (5.1) the dependencies will just be loaded directly while in PowerShell (7+) the dependencies will be loaded inside an ALC.

Some pros and cons for a script module using an ALC over a binary one are:

|Pros|Cons|
|-|-|
|No need to code in C#|Syntax to refer to ALC types is verbose and uncommon|
|Can migrate only certain parts of the code to an ALC|Build process may be slightly more complicated|

## Structure
The module consists of 4 parts:

+ [ALCScriptModule.psd1](./module/ALCScriptModule.psd1)
  + Module manifest, no difference from normal
+ [ALCScriptModule.psm1](./module/ALCScriptModule.psm1)
  + Module that sets up the ALC and defines the functions needed
+ [ALCScriptModule.csproj](./src/ALCScriptModule/ALCScriptModule.csproj)
  + Our C# project file, defines the frameworks we want to work with
+ [LoadContext.cs](./src/ALCScriptModule/LoadContext.cs)
  + Our `AssemblyLoadContext` implementation that will be used in the psm1

As with all script modules the module can either define the public/private functions in-line or load them from another file.
How it chooses to do this is outside the scope of this example.

The ALC logic is all contained in [ALCScriptModule.psm1](./module/ALCScriptModule.psm1) and consists of three main parts:

+ Setting up the ALC and loading the assemblies
  + PowerShell (7+) sets up the ALC and loads the dependencies inside it
  + Windows PowerShell (5.1) just loads the assemblies
+ Setting up the static type mapping for the module functions to reference
+ Defines the module functions.
