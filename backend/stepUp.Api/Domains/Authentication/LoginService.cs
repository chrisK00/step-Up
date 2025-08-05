
namespace stepUp.Api.Domains.Authentication;

internal class LoginService : ILoginService
{
    public Task SignUpAsync(SignUpRequest request)
    {
        // TODO guard clauses
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.FirstName))
        {
            // TODO exception
        }

        // TODO create new user: id, email, firstname
        throw new NotImplementedException();
    }
}
