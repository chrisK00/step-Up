namespace stepUp.Api.Domains.Authentication;

public interface ILoginService
{
    Task SignUpAsync(SignUpRequest request, CancellationToken cancellation);
}
