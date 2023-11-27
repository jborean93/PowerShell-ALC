using System;
using System.Collections.Generic;
// We can reference our ALC dependency directly
using YamlDotNet.Serialization;

namespace ALCResolver.Private;

internal static class Yaml
{
    public static string ConvertToYaml(Dictionary<string, object> data)
    {
        SharedUtil.AddAssemblyInfo(typeof(SerializerBuilder), data);

        SerializerBuilder builder = new SerializerBuilder();
        ISerializer serializer = builder.Build();
        return serializer.Serialize(data);
    }
}
