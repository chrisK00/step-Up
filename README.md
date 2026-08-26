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
```bash
dotnet user-secrets init
dotnet user-secrets set "testToken" "<password>"
```

# Developing
## Frontend
Deploy:
```bash
flutter build apk --split-per-abi
```

Changing app icon:
```bash
dart run flutter_launcher_icons
```

### Debugging prod
Just run F5

### Troubleshooting
If something goes wrong, use the Settings page to share the app log file.

## Backend
- Adding migrations:
1. dotnet ef migrations add <MigrationName> -o Data/Migrations
2. dotnet ef database update

---

# 📋 Roadmap & Backlog (Ready to Pick)

### 1. Refactor Backend to Clean Architecture
- **Goal**: Separate concerns into decoupled class libraries adhering to Clean Architecture principles.
- **Reference**: [Clean Architecture & JWT Inspiration](https://www.youtube.com/watch?v=xBuLWaDcvu0)
- **Target Project Structure**:
  - `stepUp.Domain`: Pure domain entities (`AppUser`, `DailyStepEntry`, `Friendship`, `FriendRequest`, `FriendReaction`), domain exceptions, and enums (zero external dependencies).
  - `stepUp.Application`: Business logic contracts (`IStepsService`, `IFriendshipService`, `IUnitOfWork`), DTOs/request/response models, input validation, and command/query handlers.
  - `stepUp.Infrastructure`: Database context (`AppDbContext`), EF Core configurations & migrations, unit of work implementation, and external service clients (e.g. Firebase Admin).
  - `stepUp.Api`: Minimal API endpoints, dependency injection wiring (`Program.cs`, service extensions), Swagger configuration, and middleware.
- **Implementation Steps**:
  1. Create solution structure with `dotnet new classlib` for `Domain`, `Application`, and `Infrastructure`.
  2. Move entities and exceptions to `stepUp.Domain`.
  3. Move interfaces and DTO records to `stepUp.Application` (reference `Domain`).
  4. Move `AppDbContext`, migrations, and external services to `stepUp.Infrastructure` (reference `Application` & `Domain`).
  5. Keep minimal API endpoint mapping and DI container registrations in `stepUp.Api` (reference `Infrastructure` & `Application`).
  6. Verify EF Core CLI commands and migration pathways.

### 2. Standardize Authentication & Authorization via JWT Bearer Config
- **Goal**: Replace custom `FirebaseAuthMiddleware` and `TestTokenAuthMiddleware` with ASP.NET Core's built-in `JwtBearer` authentication pipeline.
- **Implementation Steps**:
  1. Add `Microsoft.AspNetCore.Authentication.JwtBearer` package to the backend.
  2. Configure JWT options in `Program.cs` / service extension:
     ```csharp
     builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
         .AddJwtBearer(options =>
         {
             options.Authority = $"https://securetoken.google.com/{firebaseProjectId}";
             options.TokenValidationParameters = new TokenValidationParameters
             {
                 ValidateIssuer = true,
                 ValidIssuer = $"https://securetoken.google.com/{firebaseProjectId}",
                 ValidateAudience = true,
                 ValidAudience = firebaseProjectId,
                 ValidateLifetime = true,
             };
             // Optional: Handle dev/test tokens via custom events or a separate dev scheme
         });
     builder.Services.AddAuthorization();
     ```
  3. Replace custom `app.UseWhen(...)` middleware invocations with standard `app.UseAuthentication()` and `app.UseAuthorization()`.
  4. Protect endpoints with `.RequireAuthorization()` and read identity directly from `ClaimsPrincipal` / `context.User`.
  5. Configure Swagger to include standard JWT Bearer token authorize button.

### 3. Add Comprehensive Tests (Frontend & Backend)
- **Goal**: Ensure reliability and prevent regressions across services, endpoints, and UI widgets.
- **Backend Testing Plan**:
  - **Unit Tests (`stepUp.UnitTests` with xUnit, FluentAssertions, Moq/NSubstitute)**:
    - `StepsServiceTests`: Verify step aggregation, single-entry updates, and monthly date filtering bounds.
    - `FriendshipServiceTests` & `FriendRequestServiceTests`: Validate friend request sending, accepting, duplicate prevention, and deletion.
  - **Integration Tests (`stepUp.IntegrationTests` with `WebApplicationFactory<Program>`, SQLite In-Memory / Testcontainers)**:
    - Test authenticated HTTP requests across minimal API route groups (`/steps`, `/friends`, `/friend-requests`).
    - Verify auth rejection on missing or invalid JWT tokens.
- **Frontend Testing Plan (Flutter `test/` & `testWidgets/`)**:
  - **Unit Tests**:
    - `StepUpApiService`: Mock HTTP responses and verify JSON serialization/deserialization for all models.
    - `AppSettings`: Verify secure storage read/write/fallback behaviors.
    - `AppLogger`: Test log trimming logic (ensuring files over 1MB truncate to 2000 lines).
  - **Widget Tests**:
    - `AchievementsPage`: Verify correct tier cards render and match expected monthly step thresholds.
    - `FriendsWidgetState`: Verify friend list rendering, search field input, copy-username clipboard action, and toast triggers.

### 4. Local Development & Multi-Account / Friend Testing Strategy
- **Connecting the Mobile App to Local Backend (`localhost` vs Android Emulator)**:
  - **In-App Settings**: Navigate to the **Settings** tab in the app to override the API URL:
    - **Android Emulator**: Use `http://10.0.2.2:5208` (maps to host machine's `localhost:5208`).
    - **Physical Android Device on same Wi-Fi**: Use `http://<YOUR_LAN_IP>:5208` (e.g. `http://192.168.1.100:5208`).
    - **Default Prod**: `https://stepup.racknerd.chrispys.top`.
  - **Ensure Backend Listens on All Interfaces**:
    In `Properties/launchSettings.json` or `appsettings.json`, ensure applicationUrl is set to `http://0.0.0.0:5208` (or `http://*:5208`) so mobile devices on LAN can connect.

- **Easily Testing Friendships & Interactions without multiple physical devices**:
  - **Strategy A: Dev Test Users & Seed Data (Recommended for Local Dev)**:
    - The backend already has `TestTokenAuthMiddleware` with a test user (`test` / `AuthConstants.TestUserId`).
    - Extend `DataSeed.cs` to seed 2-3 mock users (`alice`, `bob`, `charlie`) with pre-configured step entries and friendships in local SQLite `App.db`.
  - **Strategy B: Developer Mock Switch / Account Switcher (Debug Only)**:
    - Add an "Account Switcher" or "Mock User Sign-In" option in debug mode on the Sign In / Settings screen. This allows testing sending/receiving friend requests, thumbs-up reactions, and race leaderboards without having to register separate Google/Firebase accounts.
  - **Strategy C: Firebase Auth Emulator**:
    - Enable Firebase Authentication Emulator in `main.dart` with `FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099)` when running locally. This enables instant creation of fake test users without real Google sign-ins.

---

## 📌 Links, References & Context
* **Health Package**: https://pub.dev/packages/health
* **Clean Architecture & JWT Inspiration Video**: https://www.youtube.com/watch?v=xBuLWaDcvu0
