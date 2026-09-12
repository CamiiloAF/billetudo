import 'package:billetudo/features/capture/domain/entities/spoken_transaction_draft.dart';
import 'package:billetudo/features/capture/domain/entities/spoken_transaction_input.dart';
import 'package:billetudo/features/capture/domain/usecases/parse_spoken_transaction.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../capture_fixtures.dart';

/// Miércoles 9 de septiembre de 2026: fija "hoy" para toda fecha relativa.
final DateTime _today = DateTime(2026, 9, 9);

void main() {
  const parse = ParseSpokenTransaction();

  SpokenTransactionDraft run(
    String transcript, {
    String languageCode = 'es',
    String currency = 'COP',
    bool withAccounts = true,
  }) =>
      withClock(
        Clock.fixed(_today),
        () => parse(
          SpokenTransactionInput(
            transcript: transcript,
            languageCode: languageCode,
            currency: currency,
            categories:
                languageCode == 'en' ? testCategoriesEn() : testCategories(),
            accounts: withAccounts ? testAccounts() : const [],
          ),
        ),
      );

  group('tabla de ejemplos de HU-04 (es-CO)', () {
    test('"gasté veinte mil en almuerzo"', () {
      final draft = run('gasté veinte mil en almuerzo');

      expect(draft.amountMinor, 2000000);
      expect(draft.amountIsUncertain, isFalse);
      expect(draft.type, TransactionType.expense);
      expect(draft.categoryId, 'cat-food');
      expect(draft.accountId, isNull);
      expect(draft.date, isNull);
      expect(draft.note, isNull);
    });

    test('"20 lucas de gasolina con Nequi"', () {
      final draft = run('20 lucas de gasolina con Nequi');

      expect(draft.amountMinor, 2000000);
      expect(draft.amountIsUncertain, isFalse);
      // La subcategoría gana sobre su raíz Transporte.
      expect(draft.categoryId, 'cat-fuel');
      expect(draft.accountId, 'acc-nequi');
      expect(draft.date, isNull);
      expect(draft.note, isNull);
    });

    test('"ayer pagué cien mil de arriendo"', () {
      final draft = run('ayer pagué cien mil de arriendo');

      expect(draft.amountMinor, 10000000);
      expect(draft.type, TransactionType.expense);
      expect(draft.categoryId, 'cat-rent');
      expect(draft.date, DateTime(2026, 9, 8));
      expect(draft.note, isNull);
    });

    test('"el lunes gasté 35.500 en el mercado"', () {
      final draft = run('el lunes gasté 35.500 en el mercado');

      expect(draft.amountMinor, 3550000);
      expect(draft.amountIsUncertain, isFalse);
      expect(draft.categoryId, 'cat-market');
      expect(draft.date, DateTime(2026, 9, 7));
      expect(draft.note, isNull);
    });

    test('"un palo del seguro del carro": monto sí, categoría no', () {
      final draft = run('un palo del seguro del carro');

      expect(draft.amountMinor, 100000000);
      expect(draft.categoryId, isNull, reason: 'sin match no se inventa una');
      expect(draft.accountId, isNull);
      // Los fillers interiores se conservan: la nota tiene que leerse como
      // algo que una persona escribiría.
      expect(draft.note, 'seguro del carro');
    });

    test('"me tomé un tinto": categoría sin monto', () {
      final draft = run('me tomé un tinto');

      expect(draft.amountMinor, isNull, reason: '"un" ahí es artículo');
      expect(draft.categoryId, 'cat-food');
      expect(draft.type, isNull);
      expect(draft.hasAmount, isFalse);
      expect(draft.isEmpty, isFalse);
    });
  });

  group('montos en palabras', () {
    test('"veinticinco mil quinientos"', () {
      expect(run('gasté veinticinco mil quinientos').amountMinor, 2550000);
    });

    test('"dos millones"', () {
      expect(run('gasté dos millones').amountMinor, 200000000);
    });

    test('"ciento cincuenta mil"', () {
      expect(run('gasté ciento cincuenta mil').amountMinor, 15000000);
    });

    test('"treinta y cinco mil" (conector "y")', () {
      expect(run('gasté treinta y cinco mil').amountMinor, 3500000);
    });

    test('"quinientos" con escala explícita ausente pero valor bajo', () {
      final draft = run('gasté quinientos');
      expect(draft.amountMinor, 50000000);
      expect(draft.amountIsUncertain, isTrue);
    });

    test('"mil quinientos" es 1.500 y no necesita confirmación', () {
      final draft = run('gasté mil quinientos');
      expect(draft.amountMinor, 150000);
      expect(draft.amountIsUncertain, isFalse);
    });

    test('"mil quinientos pesos" da lo mismo que sin la unidad', () {
      final draft = run('gasté mil quinientos pesos');
      expect(draft.amountMinor, 150000);
      expect(draft.amountIsUncertain, isFalse);
    });
  });

  group('coloquialismos es-CO', () {
    test('"veinte lucas" y "20 lucas" coinciden', () {
      expect(run('gasté veinte lucas').amountMinor, 2000000);
      expect(run('gasté 20 lucas').amountMinor, 2000000);
    });

    test('"una luca" es 1.000', () {
      expect(run('gasté una luca').amountMinor, 100000);
    });

    test('"20 barras" es 20.000', () {
      expect(run('gasté 20 barras').amountMinor, 2000000);
    });

    test('"un palo" es 1.000.000', () {
      expect(run('gasté un palo').amountMinor, 100000000);
    });

    test('"dos palos" es 2.000.000', () {
      expect(run('gasté dos palos').amountMinor, 200000000);
    });

    test('los coloquialismos es-CO no existen en el lexicón en', () {
      final draft = run('I spent twenty lucas', languageCode: 'en');
      expect(draft.amountMinor, 2000000, reason: 'queda "twenty" con elisión');
      expect(draft.amountIsUncertain, isTrue);
    });
  });

  group('montos en dígitos', () {
    test('miles con punto y con coma', () {
      expect(run('gasté 20.000').amountMinor, 2000000);
      expect(run('gasté 20,000').amountMinor, 2000000);
    });

    test('sin separador', () {
      expect(run('gasté 3500').amountMinor, 350000);
    });

    test('un grupo de 3 dígitos son miles, uno de 2 son centavos', () {
      expect(run('gasté 12.500').amountMinor, 1250000);
      expect(run('gasté 12,50').amountMinor, 1250);
    });

    test('nunca se representa el monto con double', () {
      expect(run('gasté 12,50').amountMinor, isA<int>());
    });
  });

  group('ambigüedad de magnitud', () {
    test('"gasté veinte" se resuelve a 20.000 pero queda marcado', () {
      final draft = run('gasté veinte');

      expect(draft.amountMinor, 2000000);
      expect(
        draft.amountIsUncertain,
        isTrue,
        reason: 'la heurística nunca se presenta como un hecho',
      );
    });

    test('"tres y medio" en contexto de miles son 3.500', () {
      final draft = run('gasté tres y medio');

      expect(draft.amountMinor, 350000);
      expect(draft.amountIsUncertain, isTrue);
    });

    test('"doce con cincuenta" son 12,50 y no dispara la heurística', () {
      final draft = run('gasté doce con cincuenta');

      expect(draft.amountMinor, 1250);
      expect(draft.amountIsUncertain, isFalse);
    });

    test('con una moneda sin elisión se respeta el valor literal', () {
      final draft = run('gasté veinte', currency: 'USD');

      expect(draft.amountMinor, 2000);
      expect(draft.amountIsUncertain, isFalse);
    });

    test('por encima del umbral no se multiplica nada', () {
      final draft = run('gasté 1500');

      expect(draft.amountMinor, 150000);
      expect(draft.amountIsUncertain, isFalse);
    });
  });

  group('polaridad por verbo', () {
    test('verbos de gasto', () {
      for (final phrase in <String>[
        'gasté 20 mil',
        'pagué 20 mil',
        'compré algo de 20 mil',
        'me costó 20 mil',
      ]) {
        expect(
          run(phrase).type,
          TransactionType.expense,
          reason: phrase,
        );
      }
    });

    test('verbos de ingreso', () {
      for (final phrase in <String>[
        'me pagaron dos millones',
        'recibí dos millones',
        'me entró dos millones',
        'me consignaron dos millones',
      ]) {
        expect(
          run(phrase).type,
          TransactionType.income,
          reason: phrase,
        );
      }
    });

    test('verbos de ingreso ampliados (es-CO)', () {
      for (final phrase in <String>[
        'me consignó cincuenta mil',
        'me depositó cincuenta mil',
        'me transfirió cincuenta mil',
        'me ingresaron cincuenta mil',
        'me cayó cincuenta mil',
        'me cayeron cincuenta mil',
        'me devolvieron cincuenta mil',
        'me devolvió cincuenta mil',
        'me reembolsaron cincuenta mil',
        'me reembolsó cincuenta mil',
        'me reintegraron cincuenta mil',
        'me dieron cincuenta mil',
        'me dio cincuenta mil',
        'me prestaron cincuenta mil',
        'cobramos cincuenta mil',
        'ganamos cincuenta mil',
        'vendí cincuenta mil',
        'vendimos cincuenta mil',
      ]) {
        expect(
          run(phrase).type,
          TransactionType.income,
          reason: phrase,
        );
      }
    });

    test(
      '"pagué" nunca se lee como ingreso solo porque el sustantivo lo sea',
      () {
        expect(
          run('pagué el ingreso del gimnasio').type,
          TransactionType.expense,
        );
        expect(
          run('pagué el depósito').type,
          TransactionType.expense,
        );
      },
    );

    test(
      '"me pagó" no está en el léxico: sin tilde colisiona con "me pago" '
      '(gasto reflexivo real, "me pago el gimnasio")',
      () {
        expect(
          run('me pago el gimnasio').type,
          isNot(TransactionType.income),
        );
      },
    );

    test(
      '"me ingresó" no está en el léxico: sin tilde colisiona con "me '
      'ingreso" (inscribirme, no dinero, "me ingreso al gimnasio")',
      () {
        expect(
          run('me ingreso al gimnasio').type,
          isNot(TransactionType.income),
        );
      },
    );

    test(
      '"me prestó" no está en el léxico: sin tilde colisiona con "me '
      'presto" (tomar prestado, dirección opuesta, "me presto el carro")',
      () {
        expect(
          run('me presto el carro').type,
          isNot(TransactionType.income),
        );
      },
    );

    test('"quincena" como sustantivo toma la polaridad del verbo', () {
      final draft = run('me llegó la quincena, dos millones');

      expect(draft.type, TransactionType.income);
      expect(draft.amountMinor, 200000000);
    });

    test('"me pagaron" nunca se lee como "pagué"', () {
      final draft = run('me pagaron dos millones');

      expect(draft.type, TransactionType.income);
      expect(draft.amountMinor, 200000000);
    });

    test('un ingreso resuelve categorías de ingreso', () {
      final draft = run('me pagaron el salario de dos millones');

      expect(draft.type, TransactionType.income);
      expect(draft.categoryId, 'cat-salary');
      expect(draft.categoryKind, CategoryKind.income);
    });

    test('sin verbo la polaridad queda vacía, no se inventa', () {
      expect(run('20 mil de gasolina').type, isNull);
    });

    test('nunca se produce una transferencia', () {
      final draft = run('pasé cien mil de Bancolombia a Nequi');

      expect(draft.type, isNot(TransactionType.transfer));
    });
  });

  group('fecha relativa', () {
    test('hoy, ayer, antier', () {
      expect(run('gasté 20 mil hoy').date, DateTime(2026, 9, 9));
      expect(run('ayer gasté 20 mil').date, DateTime(2026, 9, 8));
      expect(run('antier gasté 20 mil').date, DateTime(2026, 9, 7));
      expect(run('anteayer gasté 20 mil').date, DateTime(2026, 9, 7));
    });

    test('"anoche" cuenta como ayer', () {
      expect(run('anoche gasté 20 mil').date, DateTime(2026, 9, 8));
    });

    test('"hace tres días"', () {
      expect(run('hace tres días gasté 20 mil').date, DateTime(2026, 9, 6));
    });

    test('"hace 2 días" con dígitos', () {
      expect(run('hace 2 días gasté 20 mil').date, DateTime(2026, 9, 7));
    });

    test('la fecha se extrae antes que el monto', () {
      final draft = run('hace dos días gasté 20 mil');

      expect(draft.date, DateTime(2026, 9, 7));
      expect(
        draft.amountMinor,
        2000000,
        reason: '"dos" es de la fecha, no del monto',
      );
    });

    test('"el lunes" es el lunes más reciente ya pasado', () {
      expect(run('el lunes gasté 20 mil').date, DateTime(2026, 9, 7));
    });

    test('"el lunes pasado" también', () {
      expect(run('el lunes pasado gasté 20 mil').date, DateTime(2026, 9, 7));
    });

    test('"el 5" es el 5 de este mes', () {
      expect(run('el 5 gasté 20 mil').date, DateTime(2026, 9, 5));
    });

    test('"el 20" ya pasó este mes, así que es del mes anterior', () {
      expect(run('el 20 gasté 20 mil').date, DateTime(2026, 8, 20));
    });

    test('"el 5 mil" es plata detrás de un artículo, no una fecha', () {
      final draft = run('gasté el 5 mil');

      expect(draft.date, isNull);
      expect(draft.amountMinor, 500000);
    });

    test('sin fecha dictada queda vacía y el formulario pone hoy', () {
      expect(run('gasté 20 mil').date, isNull);
    });

    test('una fecha futura nunca se interpreta', () {
      // "el viernes" resolvería hacia adelante; el parser retrocede al viernes
      // ya pasado en vez de proponer un movimiento futuro.
      final draft = run('el viernes gasté 20 mil');

      expect(draft.date!.isAfter(DateTime(2026, 9, 9)), isFalse);
      expect(draft.date, DateTime(2026, 9, 4));
    });
  });

  group('cuenta', () {
    test('nombre completo, sin importar mayúsculas ni tildes', () {
      expect(run('gasté 20 mil con nequi').accountId, 'acc-nequi');
      expect(run('gasté 20 mil en efectivo').accountId, 'acc-cash');
    });

    test('un nombre parcial ambiguo no elige ninguna', () {
      final draft = withClock(
        Clock.fixed(_today),
        () => const ParseSpokenTransaction()(
          const SpokenTransactionInput(
            transcript: 'gasté 20 mil con banco',
          ),
        ),
      );

      expect(draft.accountId, isNull);
    });

    test('sin mención de cuenta se deja vacía para el default del form', () {
      expect(run('gasté 20 mil en almuerzo').accountId, isNull);
    });
  });

  group('categoría', () {
    test('el nombre del usuario gana sobre el diccionario', () {
      // "mercado" existe como subcategoría del usuario y también como sinónimo
      // de Alimentación: manda el nombre propio.
      expect(run('gasté 20 mil en mercado').categoryId, 'cat-market');
    });

    test('el diccionario solo actúa cuando no hay nombre propio', () {
      expect(run('gasté 20 mil en almuerzo').categoryId, 'cat-food');
      expect(run('gasté 20 mil en uber').categoryId, 'cat-transport');
    });

    test('sin coincidencia la categoría queda vacía', () {
      expect(run('gasté 20 mil en pañales').categoryId, isNull);
    });

    test('no se elige una categoría de otro tipo', () {
      // "salario" es de ingreso; en un gasto no debe colarse.
      expect(run('gasté 20 mil de salario').categoryId, isNull);
    });
  });

  group('nota', () {
    test('es lo que sobra, limpio de muletillas de borde', () {
      // "mercado" se fue a la categoría; "en el ... de la" son muletillas de
      // borde y solo sobrevive el contenido.
      expect(run('gasté 40 mil en el mercado de la semana').note, 'semana');
    });

    test('cuando no sobra nada la nota queda vacía', () {
      expect(run('gasté 20 mil en almuerzo').note, isNull);
    });

    test('las muletillas de comando no llegan a la nota', () {
      expect(run('apunta 20 mil de pañales').note, 'pañales');
    });

    test(
      '"gasté 1 millón de pesos en un mackbook pro": el conector y la '
      'moneda se van con el monto, no quedan sueltos ni duplicados',
      () {
        final draft = run(
          'gasté 1 millón de pesos en un mackbook pro',
          withAccounts: false,
        );

        expect(draft.amountMinor, 100000000);
        expect(draft.note, 'mackbook pro');
      },
    );

    test('"gasté veinte mil en almuerzo" ya no deja "de"/"mil" sueltos', () {
      expect(
        run('gasté veinte mil en almuerzo', withAccounts: false).note,
        isNull,
      );
    });

    test(
      '"recibí 500 mil pesos de salario": sin categorías que reclamen '
      '"salario", la nota es justo lo que sobra',
      () {
        final draft = withClock(
          Clock.fixed(_today),
          () => parse(
            const SpokenTransactionInput(
              transcript: 'recibí 500 mil pesos de salario',
              currency: 'COP',
            ),
          ),
        );

        expect(draft.amountMinor, 50000000);
        expect(draft.note, 'salario');
      },
    );
  });

  group('parseo parcial (HU-05)', () {
    test('solo monto sigue siendo un éxito parcial', () {
      final draft = run('gasté 20 mil');

      expect(draft.hasAmount, isTrue);
      expect(draft.filledFields, contains(SpokenField.amount));
      expect(draft.categoryId, isNull);
      expect(draft.isEmpty, isFalse);
    });

    test('sin monto no hay captura utilizable, pero sí borrador', () {
      final draft = run('me tomé un tinto');

      expect(draft.hasAmount, isFalse);
      expect(draft.isEmpty, isFalse);
    });

    test('cero campos entendidos sigue devolviendo un borrador', () {
      final draft = run('bla bla bla');

      expect(draft.isEmpty, isFalse, reason: 'queda la nota');
      expect(draft.hasAmount, isFalse);
      expect(draft.note, 'bla bla bla');
    });

    test('la transcripción siempre viaja en el borrador', () {
      expect(run('gasté 20 mil').transcript, 'gasté 20 mil');
    });

    test('una transcripción vacía no rompe nada', () {
      final draft = run('');

      expect(draft.isEmpty, isTrue);
      expect(draft.amountMinor, isNull);
      expect(draft.note, isNull);
    });
  });

  group('inglés', () {
    test('"I spent twenty thousand on lunch"', () {
      final draft = run('I spent twenty thousand on lunch', languageCode: 'en');

      expect(draft.amountMinor, 2000000);
      expect(draft.type, TransactionType.expense);
      expect(draft.categoryId, 'cat-food');
      expect(draft.note, isNull);
    });

    test('"yesterday I paid one hundred thousand for rent"', () {
      final draft = run(
        'yesterday I paid one hundred thousand for rent',
        languageCode: 'en',
      );

      expect(draft.amountMinor, 10000000);
      expect(draft.date, DateTime(2026, 9, 8));
      expect(draft.categoryId, 'cat-rent');
    });

    test('"three days ago"', () {
      final draft = run('three days ago I spent 20000', languageCode: 'en');

      expect(draft.date, DateTime(2026, 9, 6));
      expect(draft.amountMinor, 2000000);
    });

    test('"last monday"', () {
      final draft = run('last monday I spent 20000', languageCode: 'en');

      expect(draft.date, DateTime(2026, 9, 7));
    });

    test('"I got paid two million" es ingreso', () {
      final draft = run('I got paid two million', languageCode: 'en');

      expect(draft.type, TransactionType.income);
      expect(draft.amountMinor, 200000000);
    });
  });
}
