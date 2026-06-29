# UserProfile Specification

## Purpose

Fetch, persist, and expose the driver's profile (UUID, name, company) immediately after login. The profile is available in the BLoC state for UI, tracking, and business logic. Fail-hard: if fetch fails, the entire login fails.

## Requirements

### R1: UserProfile MUST be an Equatable model

The model MUST include `uuid`, `username`, `firstName`, `lastName`, `companyUuid`, `companyCode` (all `String`). MUST implement `copyWith`, `toJson`/`fromJson`, `props`, `toString` following `TokenResponse` pattern.

#### Scenario: Roundtrip JSON deserialization

- GIVEN a valid JSON with all 6 fields
- WHEN `UserProfile.fromJson()` is called
- THEN `toJson()` produces identical JSON

#### Scenario: Equatable equality

- GIVEN two `UserProfile` instances with identical fields
- WHEN compared via `==`
- THEN they are equal

### R2: AuthService.fetchProfile MUST fetch via HTTP GET

The method MUST GET `{profilesApiBaseUrl}/api/profiles?username={username}` with `Authorization: Bearer {accessToken}`. Timeout SHALL be 10s. 200 response SHALL parse `data` object. Non-200 SHALL throw `ServerFailure`.

#### Scenario: Happy path — profile fetched

- GIVEN the profiles API returns 200 with valid JSON
- WHEN `fetchProfile(username, accessToken)` is called
- THEN a `UserProfile` is returned with all fields from `data`

#### Scenario: Timeout > 10s

- GIVEN the API does not respond within 10 seconds
- WHEN `fetchProfile()` is called
- THEN `ServerFailure` with connection error message is thrown

#### Scenario: Server error 5xx

- GIVEN the API returns status 500
- WHEN `fetchProfile()` is called
- THEN `ServerFailure` with server error message is thrown

#### Scenario: Unauthorized 401

- GIVEN the API returns status 401
- WHEN `fetchProfile()` is called
- THEN `ServerFailure` with credentials error message is thrown

#### Scenario: Empty or malformed base URL

- GIVEN `PROFILES_API_BASE_URL` is empty
- WHEN `fetchProfile()` is called
- THEN `ServerFailure` is thrown

### R3: IAuthRepository SHALL persist UserProfile

Repository MUST implement `saveProfile(UserProfile)`, `getProfile()` → `UserProfile?`, `clearProfile()` (void). `SharedPrefsAuthRepository` SHALL use key `auth_profile`, JSON encode/decode, with in-memory cache. `clearProfile()` MUST be called inside `clearToken()`.

#### Scenario: Save and retrieve

- GIVEN a `UserProfile` instance
- WHEN `saveProfile()` then `getProfile()` are called
- THEN the same profile is returned

#### Scenario: No saved profile

- GIVEN no profile was saved
- WHEN `getProfile()` is called
- THEN `null` is returned

#### Scenario: Cleared on logout

- GIVEN a profile was saved
- WHEN `clearToken()` is called
- THEN `getProfile()` returns `null`

### R4: AuthAuthenticated MUST carry nullable profile

State MUST accept `UserProfile? profile = null` as named optional parameter. `props` MUST include profile.

#### Scenario: Profile present

- GIVEN login completed with profile fetch
- WHEN `AuthAuthenticated` is emitted
- THEN `state.profile` is a `UserProfile`

#### Scenario: No profile available

- GIVEN checkAuthStatus found no saved profile
- WHEN `AuthAuthenticated` is emitted
- THEN `state.profile` is `null`

### R5: BLoC MUST fetch profile on login

`_onLoginSubmitted`: login → saveToken → fetchProfile → saveProfile → emit `AuthAuthenticated(profile)`. If fetchProfile fails, emit `AuthError`.

#### Scenario: Full login with profile

- GIVEN valid credentials and working profiles API
- WHEN `LoginSubmitted` is dispatched
- THEN `AuthAuthenticated` is emitted with `UserProfile`

#### Scenario: Fail-hard on profile error

- GIVEN valid credentials but profiles API returns error
- WHEN `LoginSubmitted` is dispatched
- THEN `AuthError` is emitted
- AND token is NOT stored

### R6: BLoC MUST load profile from repo on check/refresh

`_onCheckAuthStatus` and `_onRefreshTokenRequested` SHALL call `getProfile()`. If exists, include in state. If null, emit with `profile: null`.

#### Scenario: CheckAuthStatus with saved profile

- GIVEN a saved token and saved profile in repo
- WHEN `CheckAuthStatus` is dispatched
- THEN `AuthAuthenticated` is emitted with both token and profile

#### Scenario: CheckAuthStatus without profile

- GIVEN a saved token but no saved profile
- WHEN `CheckAuthStatus` is dispatched
- THEN `AuthAuthenticated` is emitted with `profile: null`

#### Scenario: Refresh loads profile from repo

- GIVEN refresh succeeds and profile exists in repo
- WHEN `RefreshTokenRequested` is dispatched
- THEN `AuthAuthenticated` is emitted with new token and existing profile

#### Scenario: Refresh without profile

- GIVEN refresh succeeds but no profile in repo
- WHEN `RefreshTokenRequested` is dispatched
- THEN `AuthAuthenticated` is emitted with `profile: null`

### R7: Logout MUST clear profile

`_onLogoutRequested` calls `clearToken()` which includes `clearProfile()`.

#### Scenario: Profile cleared on logout

- GIVEN the user is authenticated with profile
- WHEN `LogoutRequested` is dispatched
- THEN `AuthUnauthenticated` is emitted
- AND `getProfile()` returns `null`

## API Contract

### Request

`GET {profilesApiBaseUrl}/api/profiles?username={usernameToUpperCase}`

**Headers:** `Authorization: Bearer {accessToken}`, `Content-Type: application/json`

### Response (200)

```json
{
    "data": {
        "uuid": "…",
        "username": "ABC-333",
        "firstName": "toyota",
        "lastName": "hilux",
        "companyUuid": "…",
        "companyCode": "00001"
    }
}
```
