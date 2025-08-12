
using Microsoft.EntityFrameworkCore;
using stepUp.Api.Data;
using stepUp.Api.Data.Entities;

namespace stepUp.Api.Domains.Authentication;

internal class LoginService(AppDbContext dbContext, IUnitOfWork unitOfWork) : ILoginService
{
    public async Task SignUpAsync(SignUpRequest request, CancellationToken cancellation)
    {
        var userExists = await dbContext.Users.AnyAsync(u => u.UserId == request.UserId || u.Email == request.Email, cancellation);
        if (userExists)
        {
            throw new UserExistsException();
        }

        dbContext.Users.Add(new AppUser
        {
            Email = request.Email,
            FirstName = request.FirstName,
            UserId = request.UserId
        });
        await unitOfWork.SaveChangesAsync(cancellation);
    }
}
