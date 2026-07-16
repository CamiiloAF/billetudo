import '../../../../core/database/app_database.dart' as db;

/// One entry of the onboarding seed set (HU-06), fixed data — not a domain
/// nor a presentation type. [icon] is a lucide icon name and [color] one of
/// the 7 decorative palette tokens defined in `billetudo.pen`
/// (`mint`/`sky`/`peach`/`coral`/`amber`/`teal`/`indigo`): both are resolved
/// against the design system's variables in `presentation/`, never
/// hardcoded hex here.
class SeedCategory {
  const SeedCategory({
    required this.name,
    this.icon,
    this.color,
    this.subcategories = const [],
  });

  final String name;
  final String? icon;
  final String? color;
  final List<SeedCategory> subcategories;
}

/// The 7 decorative palette tokens, cycled deterministically across the seed
/// set so every root gets a distinct-looking color without hand-picking one
/// per row.
const List<String> _paletteTokens = [
  'mint',
  'sky',
  'peach',
  'coral',
  'amber',
  'teal',
  'indigo',
];

String _colorAt(int index) => _paletteTokens[index % _paletteTokens.length];

/// Appendix of `docs/requirements/02-categorias.md` (HU-06): 17 expense
/// roots + subcategories, in document order (`sortOrder` follows it).
final List<SeedCategory> kSeedExpenseCategories = [
  SeedCategory(
    name: 'Comida y bebida',
    icon: 'utensils',
    color: _colorAt(0),
    subcategories: const [
      SeedCategory(name: 'Mercado'),
      SeedCategory(name: 'Restaurantes y domicilios'),
      SeedCategory(name: 'Café y snacks'),
    ],
  ),
  SeedCategory(
    name: 'Transporte',
    icon: 'bus',
    color: _colorAt(1),
    subcategories: const [
      SeedCategory(name: 'Transporte público'),
      SeedCategory(name: 'Taxi/App'),
    ],
  ),
  SeedCategory(
    name: 'Vehículo',
    icon: 'car',
    color: _colorAt(2),
    subcategories: const [
      SeedCategory(name: 'Combustible'),
      SeedCategory(name: 'Mantenimiento y reparaciones'),
      SeedCategory(name: 'Seguro del vehículo'),
      SeedCategory(name: 'Impuestos y matrícula (SOAT, revisión, etc.)'),
      SeedCategory(name: 'Parqueadero y peajes'),
    ],
  ),
  SeedCategory(
    name: 'Vivienda',
    icon: 'home',
    color: _colorAt(3),
    subcategories: const [
      SeedCategory(name: 'Arriendo/Hipoteca'),
      SeedCategory(name: 'Servicios públicos'),
      SeedCategory(name: 'Internet y telefonía'),
      SeedCategory(name: 'Mantenimiento del hogar'),
    ],
  ),
  SeedCategory(
    name: 'Salud',
    icon: 'heart-pulse',
    color: _colorAt(4),
    subcategories: const [
      SeedCategory(name: 'Medicina y farmacia'),
      SeedCategory(name: 'Consultas médicas'),
      SeedCategory(name: 'Seguro médico'),
    ],
  ),
  SeedCategory(
    name: 'Seguros',
    icon: 'shield',
    color: _colorAt(5),
    subcategories: const [
      SeedCategory(name: 'Seguro de vida'),
      SeedCategory(name: 'Seguro de hogar'),
    ],
  ),
  SeedCategory(
    name: 'Suscripciones',
    icon: 'refresh-cw',
    color: _colorAt(6),
    subcategories: const [
      SeedCategory(name: 'Streaming'),
      SeedCategory(name: 'Software y apps'),
      SeedCategory(name: 'Membresías'),
    ],
  ),
  SeedCategory(
    name: 'Compras personales',
    icon: 'shirt',
    color: _colorAt(0),
    subcategories: const [
      SeedCategory(name: 'Ropa y calzado'),
      SeedCategory(name: 'Cuidado personal'),
      SeedCategory(name: 'Tecnología'),
    ],
  ),
  SeedCategory(
    name: 'Ocio',
    icon: 'party-popper',
    color: _colorAt(1),
    subcategories: const [
      SeedCategory(name: 'Salidas y bares'),
      SeedCategory(name: 'Cine y eventos'),
      SeedCategory(name: 'Hobbies'),
      SeedCategory(name: 'Viajes'),
    ],
  ),
  SeedCategory(
    name: 'Educación',
    icon: 'graduation-cap',
    color: _colorAt(2),
    subcategories: const [
      SeedCategory(name: 'Matrícula y pensión'),
      SeedCategory(name: 'Cursos y libros'),
    ],
  ),
  SeedCategory(
    name: 'Familia y mascotas',
    icon: 'users',
    color: _colorAt(3),
    subcategories: const [
      SeedCategory(name: 'Hijos'),
      SeedCategory(name: 'Mascotas'),
    ],
  ),
  SeedCategory(
    name: 'Deudas',
    icon: 'credit-card',
    color: _colorAt(4),
    subcategories: const [
      SeedCategory(name: 'Pago tarjeta de crédito'),
      SeedCategory(name: 'Pago de préstamos'),
      SeedCategory(name: 'Intereses'),
    ],
  ),
  SeedCategory(
      name: 'Comisiones y cargos bancarios',
      icon: 'landmark',
      color: _colorAt(5)),
  SeedCategory(
      name: 'Impuestos y trámites', icon: 'file-text', color: _colorAt(6)),
  SeedCategory(name: 'Remesas enviadas', icon: 'send', color: _colorAt(0)),
  SeedCategory(name: 'Regalos y donaciones', icon: 'gift', color: _colorAt(1)),
  SeedCategory(name: 'Otros gastos', icon: 'ellipsis', color: _colorAt(2)),
];

/// Appendix of `docs/requirements/02-categorias.md` (HU-06): 9 income roots,
/// none with subcategories.
final List<SeedCategory> kSeedIncomeCategories = [
  SeedCategory(name: 'Salario', icon: 'banknote', color: _colorAt(0)),
  SeedCategory(
      name: 'Freelance / Independiente', icon: 'briefcase', color: _colorAt(1)),
  SeedCategory(name: 'Negocio propio', icon: 'building-2', color: _colorAt(2)),
  SeedCategory(name: 'Remesas recibidas', icon: 'send', color: _colorAt(3)),
  SeedCategory(
      name: 'Inversiones y rendimientos',
      icon: 'trending-up',
      color: _colorAt(4)),
  SeedCategory(
      name: 'Cobro de préstamos', icon: 'rotate-ccw', color: _colorAt(5)),
  SeedCategory(name: 'Reembolsos', icon: 'rotate-ccw', color: _colorAt(6)),
  SeedCategory(name: 'Regalos recibidos', icon: 'gift', color: _colorAt(0)),
  SeedCategory(name: 'Otros ingresos', icon: 'ellipsis', color: _colorAt(1)),
];

/// The full seed set, kind by kind.
Map<db.CategoryKind, List<SeedCategory>> get defaultCategorySeed => {
      db.CategoryKind.expense: kSeedExpenseCategories,
      db.CategoryKind.income: kSeedIncomeCategories,
    };
