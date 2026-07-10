using System.ComponentModel.DataAnnotations;

namespace stepUp.Api.Utils;

public static class ValidationUtil
{
    public static void Validate<T>(T instance)
    {
        Validator.ValidateObject(instance, new ValidationContext(instance), validateAllProperties: true);
    }

    public static bool TryValidate<T>(T instance, out ICollection<ValidationResult> results)
    {
        results = [];
        return Validator.TryValidateObject(instance, new ValidationContext(instance), results, validateAllProperties: true);
    }
}
