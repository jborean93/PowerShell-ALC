using ALCLoader.Shared;
using System;
using System.Collections.Generic;
using System.Management.Automation;
// We can reference our ALC dependency directly
using YamlDotNet.Serialization;

namespace ALCLoader;

[Cmdlet(VerbsData.ConvertTo, "YamlDotNet")]
[OutputType(typeof(string))]
public sealed class ConvertToYamlDotNetCommand : PSCmdlet
{
    private List<object> _objs = new();

    [Parameter(
        Mandatory = true,
        ValueFromPipeline = true,
        Position = 0
    )]
    public object[] InputObject { get; set; } = Array.Empty<object>();

    protected override void ProcessRecord()
    {
        foreach (object obj in InputObject)
        {
            _objs.Add(obj);
        }
    }

    protected override void EndProcessing()
    {
        Dictionary<string, object> finalObj = new()
        {
            {
                "Object", _objs
            }
        };
        SharedUtil.AddAssemblyInfo(typeof(SerializerBuilder), finalObj);

        SerializerBuilder builder = new SerializerBuilder();
        ISerializer serializer = builder.Build();
        string outString = serializer.Serialize(finalObj);

        WriteObject(outString);
    }
}
