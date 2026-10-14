// AssemblyLoadContext won't work in net472 so we conditionally compile this
// for net5.0 or greater.
#if NET5_0_OR_GREATER
using System;
using System.IO;
using System.Reflection;
using System.Runtime.Loader;

namespace ALCLoader.Loader;

public class LoadContext : AssemblyLoadContext
{
    private static LoadContext? s_instance;
    private static readonly object s_sync = new();

    private readonly Assembly _thisAssembly;
    private readonly AssemblyName _thisAssemblyName;
    private readonly Assembly _moduleAssembly;
    private readonly AssemblyDependencyResolver _resolver;

    private LoadContext(string name, string mainModulePathAssemblyPath)
        : base(name: name, isCollectible: false)
    {
        // Uses the module's .deps.json to find dependencies, including RID
        // specific and native assets under runtimes/. Only assemblies listed
        // in the .deps.json are loaded in this ALC, anything else like
        // System.Management.Automation falls back to the default ALC.
        _resolver = new AssemblyDependencyResolver(mainModulePathAssemblyPath);
        _thisAssembly = typeof(LoadContext).Assembly;
        _thisAssemblyName = _thisAssembly.GetName();
        _moduleAssembly = LoadFromAssemblyPath(mainModulePathAssemblyPath);
    }

    protected override Assembly? Load(AssemblyName assemblyName)
    {
        // Checks to see if we are trying to access our current assembly
        // (ALCLoader.Loader). If so return the already loaded assembly object
        // so there is only one copy of it in the process.
        if (AssemblyName.ReferenceMatchesDefinition(_thisAssemblyName, assemblyName))
        {
            return _thisAssembly;
        }

        // Returning null will fallback to the default loading behaviour.
        string? asmPath = _resolver.ResolveAssemblyToPath(assemblyName);
        return asmPath is null ? null : LoadFromAssemblyPath(asmPath);
    }

    protected override IntPtr LoadUnmanagedDll(string unmanagedDllName)
    {
        string? libPath = _resolver.ResolveUnmanagedDllToPath(unmanagedDllName);
        return libPath is null ? IntPtr.Zero : LoadUnmanagedDllFromPath(libPath);
    }

    public static Assembly Initialize(string alcName)
    {
        lock (s_sync)
        {
            if (s_instance is null)
            {
                string assemblyPath = typeof(LoadContext).Assembly.Location;
                string assemblyName = Path.GetFileNameWithoutExtension(assemblyPath);

                // Removes the '.Loader' from the assembly name to refer to our
                // main module.
                string moduleName = assemblyName[..assemblyName.LastIndexOf('.')];
                string modulePath = Path.Combine(
                    Path.GetDirectoryName(assemblyPath)!,
                    $"{moduleName}.dll"
                );

                // Creates the ALC which loads our module in the ALC and
                // returns the loaded Assembly object for the psm1 to load.
                s_instance = new LoadContext(alcName, modulePath);
            }

            return s_instance._moduleAssembly;
        }
    }
}
#endif
