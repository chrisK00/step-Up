# step_up

<img width="394" height="846" alt="image" src="https://github.com/user-attachments/assets/2a58a0dd-f7f1-4182-a47c-a0825c23b158" />

# Build

## Frontend Flutter
Requires a
- */android/app/google-services.json* from firebase
- */lib/firebase_options.dart* from firebase

### Android setup
The app uses background health syncing, so Android setup matters.

#### Required permissions
The app requests these permissions:
- Activity recognition
- Location
- Health Connect read access for steps
- Health data history
- Health data in background
- Internet
- Wake lock
- Boot completed

#### Battery optimization
For reliable background syncing, disable battery restrictions for:
- `Step Up`
- `Health`
- `Google Fit` or your health provider app
- `Health Connect` if it is installed separately on your device

If the device has aggressive power management, also allow:
- Unrestricted battery usage
- Background activity
- Auto-start, if the OEM exposes it

#### Health setup
When you sign in for the first time, the app asks for the required health permissions. If the health app still throws errors:
1. Open Health Connect or Google Fit.
2. Confirm step read access is granted.
3. Return to Step Up and try again.

#### Debug certificate
If you are installing a debug build, Android may treat it differently from the Play-signed version. If permissions or background access seem stuck:
- Uninstall the app
- Reinstall from a fresh debug build
- Re-grant the health permissions
- Re-check battery exemption after reinstall

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

### Troubleshooting
If something goes wrong, use the Settings page to share the app log file.

## Backend
- Adding migrations:
1. dotnet ef migrations add <MigrationName> -o Data/Migrations
2. dotnet ef database update
