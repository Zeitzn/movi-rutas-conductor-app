# Apply Progress: App Rename

## Implementation Summary

Renamed Android package from `com.example.movi_rutas_example` to `com.movi.rutas.conductor` and app display name to "Movi Conductor".

## Completed Tasks

- [x] Android `build.gradle.kts`: namespace + applicationId → `com.movi.rutas.conductor`
- [x] Android Kotlin sources: moved to `com/movi/rutas/conductor/`, updated package declarations
- [x] Android Kotlin sources: updated hardcoded intent actions and method channel names
- [x] Android `AndroidManifest.xml`: app label → "Movi Conductor", STOP_TRACKING action updated
- [x] iOS `Info.plist`: CFBundleDisplayName + CFBundleName → "Movi Conductor"
- [x] iOS `project.pbxproj`: PRODUCT_BUNDLE_IDENTIFIER → `com.movi.rutas.conductor`

## Verification

- `fvm flutter analyze`: 0 issues
- `fvm flutter test`: 9/9 pass
- No remaining references to old `com.example.movi*` package
