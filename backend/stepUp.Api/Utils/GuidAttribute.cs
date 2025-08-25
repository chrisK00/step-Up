using System.ComponentModel.DataAnnotations;

namespace stepUp.Api.Utils;

public class GuidAttribute : ValidationAttribute
{
    public override bool IsValid(object value) =>
        value is string s && Guid.TryParse(s, out _);

}
