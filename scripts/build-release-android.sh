#!/usr/bin/env bash
# Compila el appbundle de release (prod) firmado con la upload key, listo para
# subir a Play Console. Hornea los dos flags que ya se nos olvidaron una vez:
#
#   1. --dart-define-from-file=.env.prod  — sin esto SUPABASE_URL/POWERSYNC_URL
#      quedan vacíos y la app arranca directo al gate offline
#      ("Conéctate para continuar"), aunque el teléfono tenga internet.
#      `flutter run` lo pasa vía launch.json; `flutter build` NO — hay que darlo.
#
#   2. `flutter pub get` primero — regenera GeneratedPluginRegistrant.java sin
#      las dev-dependencies (patrol / integration_test), que no existen en
#      release y rompen la compilación si el registrant quedó sucio.
#
# La firma la resuelve android/app/build.gradle.kts leyendo android/key.properties
# (upload key). Play App Signing re-firma con su propia llave al publicar.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> flutter pub get (limpia el plugin registrant de dev-deps)"
flutter pub get

echo "==> flutter build appbundle --flavor prod --release"
flutter build appbundle --flavor prod --release --dart-define-from-file=.env.prod

echo
echo "Listo: build/app/outputs/bundle/prodRelease/app-prod-release.aab"
echo "Antes de subir a Play: sube el versionCode en pubspec.yaml (version: x.y.z+N)."
