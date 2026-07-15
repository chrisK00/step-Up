# step_up

<img width="394" height="846" alt="image" src="https://github.com/user-attachments/assets/2a58a0dd-f7f1-4182-a47c-a0825c23b158" />

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
Deploy:
flutter build apk --split-per-abi

Changing app icon:
dart run flutter_launcher_icons

### Debugging prod
Just run F5

## Backend
- Adding migrations:
1. dotnet ef migrations add <MigrationName> -o Data/Migrations
2. dotnet ef database update
