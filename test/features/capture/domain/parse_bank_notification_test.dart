import 'package:billetudo/features/capture/domain/entities/issuer_rules.dart';
import 'package:billetudo/features/capture/domain/entities/notification_message.dart';
import 'package:billetudo/features/capture/domain/entities/parsed_notification.dart';
import 'package:billetudo/features/capture/domain/usecases/parse_bank_notification.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import 'capture_rules_fixture.dart';

/// One row of the example battery: a literal notification and what the parser
/// must make of it.
///
/// Adding an issuer format is meant to be exactly two edits — a rule in
/// `assets/capture/issuer_rules.json` and a row here — and nothing else.
class CaseRow {
  const CaseRow({
    required this.description,
    required this.packageName,
    required this.title,
    required this.text,
    this.expectedAmountMinor,
    this.expectedType,
    this.expectedMerchant,
    this.expectedLast4,
    this.expectedCurrency,
    this.expectedRuleId,
    this.expectNoCapture = false,
  });

  final String description;
  final String packageName;
  final String title;
  final String text;
  final int? expectedAmountMinor;
  final TransactionType? expectedType;
  final String? expectedMerchant;
  final String? expectedLast4;
  final String? expectedCurrency;
  final String? expectedRuleId;
  final bool expectNoCapture;
}

/// Real notifications captured from the user's own device (2026-09-09).
const List<CaseRow> realCases = <CaseRow>[
  // ---------------------------------------------------------------- Nu ----
  CaseRow(
    description: 'Nu — incoming transfer names the sender',
    packageName: 'com.nu.production',
    title: 'Recibiste 128.920,00 en tu cuenta',
    text: 'Te llegó dinero de DANIELA TORO VALENCIA',
    expectedAmountMinor: 12892000,
    expectedType: TransactionType.income,
    expectedMerchant: 'DANIELA TORO VALENCIA',
    expectedRuleId: 'nu.income.with_counterparty',
  ),
  CaseRow(
    description: 'Nu — incoming transfer with the "llave" tail',
    packageName: 'com.nu.production',
    title: 'Recibiste 1,00 en tu cuenta',
    text: 'Te llegó dinero de JUAN CAMILO AGUDELO FRANCO con tu llave.',
    expectedAmountMinor: 100,
    expectedType: TransactionType.income,
    expectedMerchant: 'JUAN CAMILO AGUDELO FRANCO',
    expectedRuleId: 'nu.income.with_counterparty',
  ),
  CaseRow(
    description: 'Nu — card purchase',
    packageName: 'com.nu.production',
    title: r'Compra aprobada por $58.470,00',
    text: 'Tu compra en TIENDA D1 SANTA ROSA HELADERIA',
    expectedAmountMinor: 5847000,
    expectedType: TransactionType.expense,
    expectedMerchant: 'TIENDA D1 SANTA ROSA HELADERIA',
    expectedRuleId: 'nu.purchase.with_merchant',
  ),
  CaseRow(
    description: 'Nu — card purchase, second merchant',
    packageName: 'com.nu.production',
    title: r'Compra aprobada por $115.250,00',
    text: 'Tu compra en GRANERO Y SUPERM LA ESQUINA',
    expectedAmountMinor: 11525000,
    expectedType: TransactionType.expense,
    expectedMerchant: 'GRANERO Y SUPERM LA ESQUINA',
  ),
  CaseRow(
    description: 'Nu — card purchase, third merchant',
    packageName: 'com.nu.production',
    title: r'Compra aprobada por $50.500,00',
    text: 'Tu compra en DOLLARCITY LA GUARDIOLA',
    expectedAmountMinor: 5050000,
    expectedType: TransactionType.expense,
    expectedMerchant: 'DOLLARCITY LA GUARDIOLA',
  ),
  CaseRow(
    description: 'Nu — P2P transfer keeps the issuer masking untouched',
    packageName: 'com.nu.production',
    title: r'Enviaste $5.500,00',
    text: 'Le enviaste a Aur*** Cri******* Sep*******',
    expectedAmountMinor: 550000,
    expectedType: TransactionType.expense,
    expectedMerchant: 'Aur*** Cri******* Sep*******',
    expectedRuleId: 'nu.sent.with_counterparty',
  ),
  CaseRow(
    description: 'Nu — P2P transfer to a Nequi account',
    packageName: 'com.nu.production',
    title: r'Enviaste $1,00',
    text: 'Le enviaste a Jua*** Cam***** Agu****** Fra***** en su cuenta de '
        'Nequi.',
    expectedAmountMinor: 100,
    expectedType: TransactionType.expense,
    expectedMerchant: 'Jua*** Cam***** Agu****** Fra*****',
  ),

  // ------------------------------------------------------------- Nequi ----
  CaseRow(
    description: 'Nequi — incoming, the amount is only in the body',
    packageName: 'com.nequi.MobileApp',
    title: 'Te enviaron plata por Bre-B',
    text: 'Te enviaron \$1. Entra a tu app y revisa tu saldo.',
    expectedAmountMinor: 100,
    expectedType: TransactionType.income,
    expectedMerchant: null,
    expectedRuleId: 'nequi.income',
  ),
  CaseRow(
    description: 'Nequi — outgoing, the amount sits mid-sentence',
    packageName: 'com.nequi.MobileApp',
    title: 'Envío de plata exitoso',
    text: 'Te contamos que el envío de plata por \$1 fue exitoso. Puedes '
        'revisar en tus movimientos el detalle del envío.',
    expectedAmountMinor: 100,
    expectedType: TransactionType.expense,
    expectedRuleId: 'nequi.sent',
  ),

  // ------------------------------------------------------ Google Wallet ----
  CaseRow(
    description: 'Wallet — merchant in the title, amount+currency+card in body',
    packageName: 'com.google.android.apps.walletnfcrel',
    title: 'DROGUERIA LAS 24',
    text: '38.000,00 COP con Visa ••5615',
    expectedAmountMinor: 3800000,
    expectedType: TransactionType.expense,
    expectedMerchant: 'DROGUERIA LAS 24',
    expectedLast4: '5615',
    expectedCurrency: 'COP',
    expectedRuleId: 'google_wallet.tap_payment',
  ),
  CaseRow(
    description: 'Wallet — second real payment',
    packageName: 'com.google.android.apps.walletnfcrel',
    title: 'AYUDAS DGNOSTICAS SURA',
    text: '24.800,00 COP con Visa ••5615',
    expectedAmountMinor: 2480000,
    expectedType: TransactionType.expense,
    expectedMerchant: 'AYUDAS DGNOSTICAS SURA',
    expectedLast4: '5615',
  ),
  CaseRow(
    description: 'Wallet — third real payment',
    packageName: 'com.google.android.apps.walletnfcrel',
    title: 'IPS SALUD SURA PEREIRA',
    text: '40.100,00 COP con Visa ••5615',
    expectedAmountMinor: 4010000,
    expectedType: TransactionType.expense,
    expectedMerchant: 'IPS SALUD SURA PEREIRA',
    expectedLast4: '5615',
  ),
  CaseRow(
    description: 'Wallet — fourth real payment',
    packageName: 'com.google.android.apps.walletnfcrel',
    title: 'EDS EXITO NUEVO BOSQUE',
    text: '36.012,00 COP con Visa ••5615',
    expectedAmountMinor: 3601200,
    expectedType: TransactionType.expense,
    expectedMerchant: 'EDS EXITO NUEVO BOSQUE',
    expectedLast4: '5615',
  ),

  // ---------------------------------------------------- must be ignored ----
  CaseRow(
    description: 'Wallet — bookkeeping reminder is not a movement',
    packageName: 'com.google.android.apps.walletnfcrel',
    title: 'Recordatorio de Wallet',
    text: '¡No olvides registrar tus gastos!',
    expectNoCapture: true,
  ),
];

/// Notifications that must never produce a capture. Some are inferred, but the
/// behaviour they pin down (ignore before capture) is not.
const List<CaseRow> ignoredCases = <CaseRow>[
  CaseRow(
    description: 'one-time password, even though it carries a figure',
    packageName: 'com.nu.production',
    title: 'Nu',
    text: 'Tu código de seguridad es 483920. No lo compartas con nadie.',
    expectNoCapture: true,
  ),
  CaseRow(
    description: 'security notice',
    packageName: 'com.nu.production',
    title: 'Alerta de seguridad',
    text: 'Nunca te pediremos tus claves por este medio.',
    expectNoCapture: true,
  ),
  CaseRow(
    description: 'statement is ready',
    packageName: 'com.nu.production',
    title: 'Tu extracto está listo',
    text: 'Ya puedes consultar el extracto de septiembre.',
    expectNoCapture: true,
  ),
  CaseRow(
    description: 'payment reminder',
    packageName: 'com.nu.production',
    title: 'Recuerda pagar tu tarjeta',
    text: 'Tu pago mínimo vence el 15 de septiembre.',
    expectNoCapture: true,
  ),
  CaseRow(
    description: 'promotion',
    packageName: 'com.nequi.MobileApp',
    title: 'Aprovecha',
    text: 'Aprovecha esta promoción y gana con tus compras.',
    expectNoCapture: true,
  ),
  CaseRow(
    description: 'a catalogued issuer saying nothing the rules understand',
    packageName: 'com.nequi.MobileApp',
    title: 'Nequi',
    text: 'Actualizamos nuestros términos y condiciones.',
    expectNoCapture: true,
  ),
];

void main() {
  final IssuerRuleSet ruleSet = loadRealRuleSet();
  const ParseBankNotification parse = ParseBankNotification();
  final DateTime postedAt = DateTime(2026, 9, 9, 14, 30);

  ParsedNotification? run(CaseRow row, {Set<String>? enabled}) => parse(
        NotificationMessage(
          packageName: row.packageName,
          title: row.title,
          text: row.text,
          postedAt: postedAt,
        ),
        ruleSet: ruleSet,
        enabledIssuers: enabled ?? allIssuers,
      );

  group('ParseBankNotification — real notifications', () {
    for (final CaseRow row in realCases) {
      test(row.description, () {
        final ParsedNotification? result = run(row);
        if (row.expectNoCapture) {
          expect(result, isNull);
          return;
        }
        expect(result, isNotNull, reason: 'expected a capture');
        expect(result!.amountMinor, row.expectedAmountMinor);
        expect(result.entryType, row.expectedType);
        expect(result.merchantRaw, row.expectedMerchant);
        if (row.expectedLast4 != null) {
          expect(result.accountHint, row.expectedLast4);
        }
        if (row.expectedCurrency != null) {
          expect(result.currency, row.expectedCurrency);
        }
        if (row.expectedRuleId != null) {
          expect(result.ruleId, row.expectedRuleId);
        }
        expect(result.postedAt, postedAt);
      });
    }
  });

  group('ParseBankNotification — never a capture', () {
    for (final CaseRow row in ignoredCases) {
      test(row.description, () {
        expect(run(row), isNull);
      });
    }
  });

  group('ParseBankNotification — issuer gate', () {
    test('an uncatalogued app never reaches the rules', () {
      final ParsedNotification? result = parse(
        NotificationMessage(
          packageName: 'com.whatsapp',
          title: 'Mamá',
          // Even a message that looks exactly like a bank's must be dropped.
          text: r'Compra aprobada por $58.470,00',
          postedAt: postedAt,
        ),
        ruleSet: ruleSet,
        enabledIssuers: allIssuers,
      );
      expect(result, isNull);
    });

    test('an uncatalogued app is dropped WITHOUT its content being read', () {
      // The notification shade of the target device also holds WhatsApp,
      // LinkedIn and SMS one-time codes. Reading them at all — even to decide
      // they are uninteresting — is the failure this ordering prevents
      // (HU-08). The message explodes if title/text are touched.
      expect(
        () => parse(
          ExplodingMessage(packageName: 'com.google.android.apps.messaging'),
          ruleSet: ruleSet,
          enabledIssuers: allIssuers,
        ),
        returnsNormally,
      );
    });

    test('a catalogued but DISABLED issuer is dropped without being read', () {
      expect(
        () => parse(
          ExplodingMessage(packageName: 'com.nu.production'),
          ruleSet: ruleSet,
          // Nothing enabled: granting the system permission alone captures
          // nothing.
          enabledIssuers: const <String>{},
        ),
        returnsNormally,
      );
    });

    test('an enabled issuer DOES read the content (the guard is real)', () {
      expect(
        () => parse(
          ExplodingMessage(packageName: 'com.nu.production'),
          ruleSet: ruleSet,
          enabledIssuers: const <String>{'nu'},
        ),
        throwsStateError,
      );
    });
  });

  group('ParseBankNotification — no amount, no capture', () {
    test('a rule shape without a usable figure produces nothing', () {
      final ParsedNotification? result = parse(
        NotificationMessage(
          packageName: 'com.nu.production',
          title: r'Compra aprobada por $0,00',
          text: 'Tu compra en TIENDA D1',
          postedAt: postedAt,
        ),
        ruleSet: ruleSet,
        enabledIssuers: allIssuers,
      );
      expect(result, isNull);
    });
  });
}

/// A message whose content cannot be read without blowing up. Used to prove
/// the issuer filter runs BEFORE anything looks at the title or the body.
class ExplodingMessage extends NotificationMessage {
  ExplodingMessage({required super.packageName})
      : super(postedAt: DateTime(2026, 9, 9));

  @override
  String get title => throw StateError('the notification content was read');

  @override
  String get text => throw StateError('the notification content was read');
}
