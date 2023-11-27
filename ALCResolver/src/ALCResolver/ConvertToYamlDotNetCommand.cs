using ALCResolver.Private;
using System;
using System.Collections.Generic;
using System.Management.Automation;

namespace ALCResolver;

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
        WriteObject(Yaml.ConvertToYaml(finalObj));
    }
}
