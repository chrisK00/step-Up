namespace stepUp.Api.Domains.Users;

public record SearchUsersRequest(string Username);
public record SearchUsersResponse(string Id, string Username);