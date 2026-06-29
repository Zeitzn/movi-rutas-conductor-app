# Propuesta: Profile Fetch Post-Login

## Intención

Obtener el perfil del conductor inmediatamente después del login exitoso, fallando el login completo si el perfil no se puede recuperar. El perfil queda disponible en el estado de la app para uso en UI, tracking y lógica de negocio.

## Alcance

### Incluye
- Modelo `UserProfile` (Equatable, toJson/fromJson, copyWith, uuid, username, firstName, lastName, companyUuid, companyCode)
- `saveProfile`, `getProfile`, `clearProfile` en `IAuthRepository` + `SharedPrefsAuthRepository`
- `AuthService.fetchProfile(username)` → GET con `Authorization: Bearer` + timeout 10s
- `AuthAuthenticated` state con `UserProfile?` nullable
- BLoC: fetch + save profile en login; load desde repo en check/refresh
- `EnvConfig.profilesApiBaseUrl` getter + `PROFILES_API_BASE_URL` en `.env.example`

### Excluye
- UI de perfil o edición
- Sincronización offline
- Cache con TTL (se limpia en logout nomas)

## Capacidades

### Nuevas
- `user-profile`: modelo, fetch, persistencia y disponibilidad en estado BLoC del perfil del conductor

### Modificadas
- `env-config`: agregar `profilesApiBaseUrl` getter + key `PROFILES_API_BASE_URL`

## Enfoque

Fail-hard post-login: entre `saveToken` y `emit(AuthAuthenticated)`, el BLoC ejecuta `fetchProfile` → si falla, el login entero falla con error. En check/refresh se carga del repo (no fetch). Se limpia junto con `clearToken()`.

## Archivos Afectados

| Archivo | Impacto | Cambio |
|---------|---------|--------|
| `lib/features/auth/models/user_profile.dart` | Nuevo | Modelo Equatable |
| `lib/features/auth/repositories/auth_repository.dart` | Modificado | `saveProfile/getProfile/clearProfile` |
| `lib/features/auth/services/auth_service.dart` | Modificado | `fetchProfile()` |
| `lib/features/auth/bloc/auth_state.dart` | Modificado | `UserProfile?` en `AuthAuthenticated` |
| `lib/features/auth/bloc/auth_bloc.dart` | Modificado | fetch en login, load en check/refresh |
| `lib/core/services/env_config.dart` | Modificado | `profilesApiBaseUrl` getter |
| `.env.example` | Modificado | `PROFILES_API_BASE_URL` placeholder |

## Riesgos

| Riesgo | Prob. | Mitigación |
|--------|-------|------------|
| API de profiles caída | Baja | Fail-hard: login falla, error visible |
| Token expira entre login y fetch | Baja | Msg de por medio, mismo token |
| Estructura del profile cambia | Baja | Modelo versionado, nullable fields |

## Rollback

Revert commits tocando `auth_bloc`, `auth_service`, `auth_repository` y `user_profile.dart`. Remover `PROFILES_API_BASE_URL` de `EnvConfig` y `.env.example`.

## Dependencias

Ninguna (usa `http` y `shared_preferences` existentes).

## Criterios de Éxito

- [ ] Login exitoso → `UserProfile` disponible en `AuthAuthenticated`
- [ ] API de profiles caída → `AuthError` (fail-hard)
- [ ] Logout → perfil limpiado de SharedPreferences y memoria
- [ ] Refresh token → perfil cargado del repo, no fetch
- [ ] Check auth → perfil cargado del repo si existe
