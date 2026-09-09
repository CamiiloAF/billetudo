#!/usr/bin/env ruby
# frozen_string_literal: true

# Crea (o repara) el target de WidgetKit "QuickCaptureWidget" dentro de
# Runner.xcodeproj — el widget de captura rápida de
# docs/requirements/fase-2/20-widget-captura-rapida.md.
#
# Por qué un script y no "lo hice a mano en Xcode": el .xcodeproj es un
# archivo generado y enorme; un target creado a mano no es reproducible ni
# revisable en un diff. Esto sí: se corre, se ve qué cambió, y si mañana hay
# que rehacer el proyecto se vuelve a correr.
#
#   cd ios && ruby add_quick_capture_widget_target.rb
#
# Es IDEMPOTENTE: si el target ya existe, no hace nada.
#
# La gema `xcodeproj` viene con CocoaPods, así que no hay que instalar nada.
#
# Lo que NO hace, a propósito:
# - No crea App Group ni entitlements: el widget es un atajo puro, no comparte
#   datos entre procesos (decisión 3 del requisito).
# - No toca el Podfile: la extensión no usa ningún pod.

require 'xcodeproj'

PROJECT_PATH = File.expand_path('Runner.xcodeproj', __dir__)
TARGET_NAME = 'QuickCaptureWidget'
GROUP_PATH = 'QuickCaptureWidget'
DEPLOYMENT_TARGET = '15.0'
DEVELOPMENT_TEAM = '2977ZR336A'

# Mismo bundle id que el Runner de cada configuración, más el sufijo del
# widget: dev y prod pueden convivir instaladas.
BUNDLE_ID_BY_CONFIG = lambda do |config_name|
  base = config_name.end_with?('-dev') ? 'com.camiloagudelo.billetudo.dev' : 'com.camiloagudelo.billetudo'
  "#{base}.#{TARGET_NAME}"
end

SOURCE_FILES = %w[
  QuickCaptureShortcut.swift
  QuickCaptureWidget.swift
  QuickCaptureWidgetBundle.swift
  QuickCaptureWidgetSupport.swift
].freeze

RESOURCE_FILES = %w[
  Assets.xcassets
  PlusJakartaSans-SemiBold.ttf
].freeze

LOCALIZATIONS = %w[es en].freeze

RUNNER_BRIDGE_FILE = 'QuickCaptureWidgetBridge.swift'

project = Xcodeproj::Project.open(PROJECT_PATH)
runner = project.targets.find { |t| t.name == 'Runner' }
abort('[x] No se encontró el target Runner.') if runner.nil?

# El puente vive en el target Runner (es quien recibe la URL que abre el
# widget), así que se añade aparte del target de la extensión.
already_bridged = runner.source_build_phase.files_references.any? do |ref|
  ref.path&.end_with?(RUNNER_BRIDGE_FILE)
end
unless already_bridged
  runner_group = project.main_group.find_subpath('Runner', true)
  bridge_ref = runner_group.new_reference(RUNNER_BRIDGE_FILE)
  runner.add_file_references([bridge_ref])
  project.save
  puts "[ok] #{RUNNER_BRIDGE_FILE} añadido al target Runner."
end

# Ordena las fases de Runner: embeber la extensión ANTES del "Thin Binary" de
# Flutter. Al revés, Xcode detecta un ciclo de dependencias ("Cycle inside
# Runner") y el build falla — pasa siempre que se mete una app extension en un
# proyecto Flutter. Idempotente: si ya está en orden, no toca nada.
def fix_phase_order(runner)
  embed = runner.copy_files_build_phases.find { |p| p.symbol_dst_subfolder_spec == :plug_ins }
  thin = runner.shell_script_build_phases.find { |p| p.name == 'Thin Binary' }
  return false if embed.nil? || thin.nil?

  embed_index = runner.build_phases.index(embed)
  thin_index = runner.build_phases.index(thin)
  return false if embed_index < thin_index

  runner.build_phases.delete(embed)
  runner.build_phases.insert(runner.build_phases.index(thin), embed)
  true
end

if project.targets.any? { |t| t.name == TARGET_NAME }
  if fix_phase_order(runner)
    project.save
    puts '[ok] Fase "Embed Foundation Extensions" movida antes de "Thin Binary".'
  end
  puts "[=] El target #{TARGET_NAME} ya existe. Nada más que hacer."
  exit 0
end

target = project.new_target(:app_extension, TARGET_NAME, :ios, DEPLOYMENT_TARGET)

# `new_target` crea una build configuration por cada una del proyecto (9 acá:
# Debug/Release/Profile x sin sabor/-dev/-prod). Si faltara una, xcodebuild
# fallaría al construir Runner con ese nombre de configuración.
generated_xcconfig = project.files.find { |f| f.path == 'Flutter/Generated.xcconfig' }

target.build_configurations.each do |config|
  # Hereda FLUTTER_BUILD_NAME/NUMBER para que la versión de la extensión
  # coincida con la de la app (la App Store lo exige). No se hereda
  # Flutter/Debug.xcconfig porque ese arrastra los pods del Runner.
  config.base_configuration_reference = generated_xcconfig if generated_xcconfig

  config.build_settings.merge!(
    'PRODUCT_NAME' => TARGET_NAME,
    'PRODUCT_BUNDLE_IDENTIFIER' => BUNDLE_ID_BY_CONFIG.call(config.name),
    'INFOPLIST_FILE' => "#{GROUP_PATH}/Info.plist",
    'GENERATE_INFOPLIST_FILE' => 'NO',
    'IPHONEOS_DEPLOYMENT_TARGET' => DEPLOYMENT_TARGET,
    'TARGETED_DEVICE_FAMILY' => '1,2',
    'SWIFT_VERSION' => '5.0',
    'CODE_SIGN_STYLE' => 'Automatic',
    'DEVELOPMENT_TEAM' => DEVELOPMENT_TEAM,
    'SKIP_INSTALL' => 'YES',
    'CLANG_ENABLE_MODULES' => 'YES',
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO',
    'MARKETING_VERSION' => '$(FLUTTER_BUILD_NAME)',
    'CURRENT_PROJECT_VERSION' => '$(FLUTTER_BUILD_NUMBER)'
  )
end

group = project.main_group.find_subpath(GROUP_PATH, true)
group.set_source_tree('SOURCE_ROOT')
group.set_path(GROUP_PATH)

source_refs = SOURCE_FILES.map { |name| group.new_reference(name) }
target.add_file_references(source_refs)

resource_refs = RESOURCE_FILES.map { |name| group.new_reference(name) }
target.add_resources(resource_refs)

# Localizable.strings como variant group: es la forma en que Xcode reconoce
# los .lproj, y sin ella las cadenas del widget no llegarían localizadas
# (HU-09).
variant = project.new(Xcodeproj::Project::Object::PBXVariantGroup)
variant.name = 'Localizable.strings'
variant.source_tree = '<group>'
LOCALIZATIONS.each do |locale|
  ref = project.new(Xcodeproj::Project::Object::PBXFileReference)
  ref.path = "#{locale}.lproj/Localizable.strings"
  ref.name = locale
  ref.source_tree = '<group>'
  ref.last_known_file_type = 'text.plist.strings'
  variant.children << ref
end
group.children << variant
target.resources_build_phase.add_file_reference(variant)

known = project.root_object.known_regions || []
project.root_object.known_regions = (known + LOCALIZATIONS + ['Base']).uniq

# Embeber la extensión en la app: sin esto compila pero no se instala.
runner.add_dependency(target)
embed_phase = runner.copy_files_build_phases.find do |phase|
  phase.symbol_dst_subfolder_spec == :plug_ins
end
if embed_phase.nil?
  embed_phase = runner.new_copy_files_build_phase('Embed Foundation Extensions')
  embed_phase.symbol_dst_subfolder_spec = :plug_ins
  embed_phase.dst_path = ''
end
build_file = embed_phase.add_file_reference(target.product_reference)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
fix_phase_order(runner)

project.save

puts "[ok] Target #{TARGET_NAME} creado y embebido en Runner."
puts '     Revisa el diff de Runner.xcodeproj/project.pbxproj antes de commitear.'
