#if NET5_0_OR_GREATER
using System;
using System.IO;
using System.Reflection;
using System.Runtime.Loader;

namespace ALCScriptModule
{
    public class LoadContext : AssemblyLoadContext
    {
        private static LoadContext _instance;

        private readonly string _assemblyPath;

        private LoadContext(string assemblyPath)
            : base(name: "ALCScriptModule", isCollectible: false)
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
        )
        {
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

        public static LoadContext OnImport()
        {
            string assemblyPath = typeof(LoadContext).Assembly.Location;
            _instance = new LoadContext(Path.GetDirectoryName(assemblyPath));
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
#endif