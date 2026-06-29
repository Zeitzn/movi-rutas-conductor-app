# Delta for EnvConfig

## ADDED Requirements

### R10: EnvConfig MUST expose profilesApiBaseUrl getter

The service MUST provide a typed getter `profilesApiBaseUrl` reading `PROFILES_API_BASE_URL` from `.env`. Fallback default SHALL be `'http://localhost:8080'`. `.env.example` MUST include this key.

#### Scenario: Getter returns configured value

- GIVEN `.env` contains `PROFILES_API_BASE_URL=https://profiles.movi.com`
- WHEN `EnvConfig.instance.profilesApiBaseUrl` is accessed
- THEN it returns `'https://profiles.movi.com'`

#### Scenario: Missing key falls back to default

- GIVEN `.env` has no `PROFILES_API_BASE_URL` key
- WHEN `EnvConfig.instance.profilesApiBaseUrl` is accessed
- THEN it returns `'http://localhost:8080'`
