using ALCResolver.Private;
using System;
using System.Collections.Generic;
using System.Management.Automation;

namespace ALCResolver;

[Cmdlet(VerbsData.ConvertTo, "NewtonsoftJson")]
[OutputType(typeof(string))]
public sealed class ConvertToNewtonsoftJsonCommand : PSCmdlet
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
        WriteObject(Json.ConvertToJson(finalObj));
    }
}
