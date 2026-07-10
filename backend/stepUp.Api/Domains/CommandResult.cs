namespace stepUp.Api.Domains;

public class CommandResult
{
    public bool Success { get; set; }
    public string? Error { get; set; }

    public static CommandResult Ok() => new() { Success = true };
    public static CommandResult Fail(string error) => new() { Success = false, Error = error };
}

