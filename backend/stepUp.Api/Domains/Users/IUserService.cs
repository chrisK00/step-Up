namespace stepUp.Api.Domains.Users;

public interface IUserService
{
    Task<IEnumerable<SearchUsersResponse>> SearchUsersAsync(SearchUsersRequest request, CancellationToken cancellation);
}
