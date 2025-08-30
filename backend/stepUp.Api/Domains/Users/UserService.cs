using Microsoft.EntityFrameworkCore;
using stepUp.Api.Data;

namespace stepUp.Api.Domains.Users;

internal class UserService(AppDbContext dbContext) : IUserService
{
    public async Task<IEnumerable<SearchUsersResponse>> SearchUsersAsync(SearchUsersRequest request, CancellationToken cancellation)
    {
        return await dbContext.Users.AsNoTracking()
            .Where(u => u.FirstName.StartsWith(request.Username))
            .Select(u => new SearchUsersResponse(u.UserId, u.FirstName))
            .ToListAsync(cancellation);
    }
}
