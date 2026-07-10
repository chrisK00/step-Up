namespace stepUp.Api.Domains.Authentication;

[Serializable]
public class UserExistsException : Exception
{
    public UserExistsException() : base("Invalid Email or Username") { }
}
