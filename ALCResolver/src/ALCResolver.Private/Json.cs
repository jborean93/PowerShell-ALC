using System;
using System.Collections.Generic;
// We can reference our ALC dependency directly
using Newtonsoft.Json;

namespace ALCResolver.Private;

internal static class Json
{
    public static string ConvertToJson(Dictionary<string, object> data)
    {
        SharedUtil.AddAssemblyInfo(typeof(JsonConvert), data);

        return JsonConvert.SerializeObject(
            data,
            Formatting.Indented);
    }
}
