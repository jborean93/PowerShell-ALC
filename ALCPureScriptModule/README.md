# ALC Pure ScriptModule
This is an example module that shows how to use an ALC with a Script based module in PowerShell without any csproj or `dotnet publish` step.
I would highly recommend using [ALCScriptModule](../ALCScriptModule/README.md) over this method as it greatly simplifies the build process and ALC setup.

In this example module we have a `.psm1` that loads the dependencies `Newtonsoft.Json` and `YamlDotNet`.
In Windows PowerShell (5.1) the dependencies will just be loaded directly while in PowerShell (7+) the dependencies will be loaded inside an ALC.

Some pros and cons for a script module using an ALC over a binary one are:

|Pros|Cons|
|-|-|
|No need to code in C#|Syntax to refer to ALC types is verbose and uncommon|
|Can migrate only certain parts of the code to an ALC|Build process may be slightly more complicated|

## Structure
The module consists of 2 parts:

+ [ALCPureScriptModule.psd1](./module/ALCPureScriptModule.psd1)
  + Module manifest, no difference from normal
+ [ALCPureScriptModule.psm1](./module/ALCPureScriptModule.psm1)
  + Module that sets up the ALC and defines the functions needed

As with all script modules the module can either define the public/private functions in-line or load them from another file.
How it chooses to do this is outside the scope of this example.

The ALC logic is all contained in [ALCPureScriptModule.psm1](./module/ALCPureScriptModule.psm1) and consists of three main parts:

+ Setting up the ALC and loading the assemblies
  + PowerShell (7+) sets up the ALC and loads the dependencies inside it
  + Windows PowerShell (5.1) just loads the assemblies
+ Setting up the static type mapping for the module functions to reference
+ Defines the module functions.
