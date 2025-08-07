# step_up


# Build

## Frontend Flutter
Requires a
- */android/app/google-services.json* from firebase
- */lib/firebase_options.dart* from firebase

## Backend .NET 8 Minimal Web API
- Requires a *secrets/firebase-service-account.json* from firebase
- Requires the following app configuration to be provided
dotnet user-secrets init
dotnet user-secrets set "testToken" "<password>"

# Developing
## Frontend


## Backend
- Adding migrations:
1. dotnet ef migrations add <MigrationName> -o Data/Migrations
2. dotnet ef database update