// app_database.dart
//
// Modelo de datos (Drift / SQLite) para la app de finanzas personales.
// Local-first: esta BD es la fuente de verdad. PowerSync la mantiene
// sincronizada con Supabase Postgres (mismo nombre de tabla y columnas).
//
// Convenciones clave:
//  - IDs: UUID en texto (clientDefault). Imprescindible para que PowerSync
//    sincronice filas creadas offline en varios dispositivos sin colisiones.
//  - Dinero: SIEMPRE en enteros = unidades menores (centavos). Nunca double,
//    para evitar errores de redondeo. Ej: $12.34 -> 1234.
//  - Timestamps: createdAt / updatedAt en todas las tablas. Actualiza
//    updatedAt en cada escritura (hazlo en el repositorio o con triggers).
//  - deletedAt: borrado lógico para "papelera / deshacer" (feature de UX).
//    Nota: PowerSync sincroniza los DELETE reales por su cuenta; deletedAt
//    es solo para la papelera del usuario, no para el sync.
//
// Dependencias (pubspec):
//   drift, sqlite3_flutter_libs, uuid  (+ drift_dev, build_runner en dev)
//   Para sync: powersync + integración drift (abrir Drift sobre la BD de PowerSync).
//
// Genera el código con:  dart run build_runner build

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

const _uuid = Uuid();

// ---------------------------------------------------------------------------
// Enums (se almacenan como texto -> legibles y con paridad en Postgres)
// ---------------------------------------------------------------------------

enum AccountType { cash, bank, card, savings, investment, other }

/// Naturaleza de una transacción.
enum EntryType { income, expense, transfer }

/// Para qué sirve una categoría.
enum CategoryKind { income, expense }

/// Cómo se creó la transacción. Sirve para medir el uso de IA y calibrar
/// límites: 'manual' e 'imported' no te cuestan; voice/ocr/notification sí.
enum TxSource { manual, voice, ocr, notification, imported, recurring }

enum BudgetPeriod { weekly, monthly, yearly, custom }

enum DebtDirection { iOwe, owedToMe }

enum RecurFrequency { daily, weekly, monthly, yearly }

/// Preferencia de cifra a resaltar en una tarjeta de crédito (HU-04):
/// 'debt' = mostrar la deuda actual como principal; 'available' = el cupo
/// disponible. Solo afecta presentación, nunca el cálculo del saldo.
/// Se guarda como texto (textEnum) para paridad legible con Postgres.
enum CardBalanceView { debt, available }

// ---------------------------------------------------------------------------
// Mixin con las columnas comunes de sync (id UUID + timestamps + borrado lógico)
// ---------------------------------------------------------------------------

mixin _SyncColumns on Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Borrado lógico para papelera/undo. null = activo.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Tablas
// ---------------------------------------------------------------------------

/// Cuentas: efectivo, banco, tarjeta, ahorros, inversión...
class Accounts extends Table with _SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => textEnum<AccountType>()();

  /// Código ISO-4217, ej. 'USD', 'COP', 'MXN'.
  TextColumn get currency => text().withLength(min: 3, max: 3)();

  /// Saldo inicial en centavos. El saldo actual se calcula sumando transacciones.
  IntColumn get initialBalanceMinor => integer().withDefault(const Constant(0))();

  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  // -- Identificación bancaria y datos de tarjeta (todas nullable para no
  //    romper cuentas existentes; ver docs/requirements/01-cuentas.md). --

  /// Nombre de la entidad bancaria (ej. 'Bancolombia', 'Nu'). Todos los tipos.
  TextColumn get institution => text().nullable().withLength(max: 100)();

  /// Número de cuenta completo CIFRADO a nivel app (Keychain/Keystore).
  /// EXCLUIR del sync de PowerSync — solo local, nunca viaja a Supabase.
  /// No aplica a tarjeta de crédito (regla de negocio a nivel app, HU-03).
  TextColumn get accountNumberEnc => text().nullable()();

  /// Últimos 4 dígitos, solo identificación. Único fragmento sincronizable.
  TextColumn get last4 => text().nullable().withLength(max: 4)();

  /// Tasa de interés anual en puntos básicos enteros (24,5% -> 2450).
  /// Nunca double: es un porcentaje escalado, no un monto.
  IntColumn get interestRateBps => integer().nullable()();

  /// Cupo máximo de tarjeta en centavos.
  IntColumn get creditLimitMinor => integer().nullable()();

  /// Día de corte de tarjeta (1-31).
  IntColumn get statementDay => integer().nullable()();

  /// Día de pago de tarjeta (1-31).
  IntColumn get paymentDueDay => integer().nullable()();

  /// Preferencia de cifra a resaltar en tarjeta ('debt'/'available', HU-04).
  /// Se guarda como texto vía textEnum para paridad con Postgres.
  TextColumn get cardBalancePrimary => textEnum<CardBalanceView>().nullable()();
}

/// Categorías con jerarquía (parentId apunta a otra categoría = subcategoría).
class Categories extends Table with _SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get kind => textEnum<CategoryKind>()();

  /// null = categoría raíz; si no, es subcategoría de parentId.
  TextColumn get parentId =>
      text().nullable().references(Categories, #id)();

  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Transacciones (ingresos, gastos y transferencias entre cuentas).
class Transactions extends Table with _SyncColumns {
  @ReferenceName('transactionsAsAccount')
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get categoryId =>
      text().nullable().references(Categories, #id)();

  /// Monto en centavos, siempre positivo. El signo lo determina [type].
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text().withLength(min: 3, max: 3)();

  TextColumn get type => textEnum<EntryType>()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();

  /// Origen de la captura (para medir uso de IA). Por defecto manual.
  TextColumn get source =>
      textEnum<TxSource>().withDefault(Constant(TxSource.manual.name))();

  /// Solo para type == transfer: cuenta destino.
  @ReferenceName('transactionsAsTransferAccount')
  TextColumn get transferAccountId =>
      text().nullable().references(Accounts, #id)();

  /// Enlaces opcionales.
  TextColumn get recurringId =>
      text().nullable().references(Recurrings, #id)();
  TextColumn get goalId => text().nullable().references(Goals, #id)();
  TextColumn get debtId => text().nullable().references(Debts, #id)();
}

/// Presupuestos. categoryId null = presupuesto global (todos los gastos).
class Budgets extends Table with _SyncColumns {
  TextColumn get categoryId =>
      text().nullable().references(Categories, #id)();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text().withLength(min: 3, max: 3)();
  TextColumn get period => textEnum<BudgetPeriod>()();
  DateTimeColumn get startDate => dateTime()();

  /// Si el sobrante/exceso se arrastra al siguiente periodo (estilo base-cero).
  BoolColumn get rollover => boolean().withDefault(const Constant(false))();
}

/// Metas de ahorro.
class Goals extends Table with _SyncColumns {
  TextColumn get name => text()();
  IntColumn get targetMinor => integer()();

  /// Ahorrado hasta ahora (opcional: puede calcularse de transacciones con goalId).
  IntColumn get savedMinor => integer().withDefault(const Constant(0))();
  TextColumn get currency => text().withLength(min: 3, max: 3)();

  /// Meta vinculada a una cuenta específica (queja resuelta vs. Wallet).
  TextColumn get accountId => text().nullable().references(Accounts, #id)();
  DateTimeColumn get targetDate => dateTime().nullable()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
}

/// Deudas y préstamos (yo debo / me deben).
class Debts extends Table with _SyncColumns {
  TextColumn get name => text()();
  TextColumn get direction => textEnum<DebtDirection>()();
  IntColumn get principalMinor => integer()();
  TextColumn get currency => text().withLength(min: 3, max: 3)();
  RealColumn get interestRate => real().nullable()(); // % anual, opcional
  TextColumn get counterparty => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
}

/// Plantillas de transacciones recurrentes / pagos planeados.
class Recurrings extends Table with _SyncColumns {
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get categoryId =>
      text().nullable().references(Categories, #id)();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text().withLength(min: 3, max: 3)();
  TextColumn get type => textEnum<EntryType>()();
  TextColumn get note => text().nullable()();

  TextColumn get frequency => textEnum<RecurFrequency>()();

  /// Cada cuántas [frequency] se repite. Ej: interval=2 + weekly = cada 2 semanas.
  IntColumn get interval => integer().withDefault(const Constant(1))();
  DateTimeColumn get nextDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
}

/// Etiquetas libres (complemento de categorías).
class Tags extends Table with _SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get color => text().nullable()();
}

/// Relación N:N entre transacciones y etiquetas.
/// Lleva id propio (del mixin) porque PowerSync necesita PK de una columna.
class TransactionTags extends Table with _SyncColumns {
  TextColumn get transactionId => text().references(Transactions, #id)();
  TextColumn get tagId => text().references(Tags, #id)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {transactionId, tagId},
      ];
}

// ---------------------------------------------------------------------------
// Base de datos
// ---------------------------------------------------------------------------

@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Transactions,
    Budgets,
    Goals,
    Debts,
    Recurrings,
    Tags,
    TransactionTags,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // v1 -> v2: columnas de identificación bancaria y datos de tarjeta
          // en Accounts (todas nullable). Ver docs/requirements/01-cuentas.md.
          if (from < 2) {
            await m.addColumn(accounts, accounts.institution);
            await m.addColumn(accounts, accounts.accountNumberEnc);
            await m.addColumn(accounts, accounts.last4);
            await m.addColumn(accounts, accounts.interestRateBps);
            await m.addColumn(accounts, accounts.creditLimitMinor);
            await m.addColumn(accounts, accounts.statementDay);
            await m.addColumn(accounts, accounts.paymentDueDay);
            await m.addColumn(accounts, accounts.cardBalancePrimary);
          }
        },
      );

  // Al integrar PowerSync, en vez de abrir un NativeDatabase propio abres
  // Drift sobre la base de datos de PowerSync, y defines un Schema de PowerSync
  // que refleje estas mismas tablas/columnas. PowerSync se encarga del sync
  // bidireccional con Supabase Postgres.
}
