#!/usr/bin/env bash
# Compila el IPA de release (prod) para subir a App Store Connect. Igual que en
# Android, el punto crítico es pasar el env:
#
#   --dart-define-from-file=.env.prod  — sin esto SUPABASE_URL/POWERSYNC_URL
#   quedan vacíos y la app arranca directo al gate offline ("Conéctate para
#   continuar"), aunque el teléfono tenga internet.
#
# TRAMPA iOS: NO archives desde Xcode (Product → Archive) sin correr esto antes.
# Xcode lee ios/Flutter/Generated.xcconfig, que es AUTOGENERADO y refleja los
# defines del último comando `flutter`. Si está viejo/vacío, el archive sale con
# env equivocado y no avisa. Compilar por el CLI garantiza los defines correctos.
#
# Si necesitas firmar/archivar desde Xcode de todas formas, corre primero:
#   flutter build ipa --config-only --flavor prod --release --dart-define-from-file=.env.prod
# para dejar Generated.xcconfig con los DART_DEFINES correctos, y luego archiva.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> flutter pub get"
flutter pub get

echo "==> flutter build ipa --flavor prod --release"
flutter build ipa --flavor prod --release --dart-define-from-file=.env.prod

echo
echo "Listo: build/ios/ipa/*.ipa"
echo "Súbelo con Transporter o el Organizer de Xcode."
echo "Antes de subir: sube CFBundleVersion (version: x.y.z+N en pubspec.yaml)."
