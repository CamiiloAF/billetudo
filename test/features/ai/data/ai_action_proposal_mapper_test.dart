import 'package:billetudo/features/ai/data/mappers/ai_action_proposal_mapper.dart';
import 'package:billetudo/features/ai/domain/entities/ai_action_proposal.dart';
import 'package:billetudo/features/budgets/domain/entities/budget.dart'
    show BudgetPeriod;
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/transactions/domain/entities/transaction.dart'
    show TransactionType;
import 'package:flutter_test/flutter_test.dart';

import '../ai_fixtures.dart';

/// The trust boundary with the model: whatever arrives, `fromJson` answers with
/// a proposal and never throws. Every hostile payload below must degrade to an
/// [UnsupportedProposal] the user can read but not execute.
void main() {
  /// A `create_transaction` envelope whose payload can be broken field by
  /// field, so each test states only the thing that is wrong with it.
  Map<String, Object?> transactionJson({
    Map<String, Object?>? payload,
    Object? kind = 'create_transaction',
    Object? id = 'tc_0_0',
    Object? title = 'Registrar el almuerzo',
    Object? status,
    bool omitPayload = false,
  }) =>
      <String, Object?>{
        'id': id,
        'kind': kind,
        'title': title,
        if (status != null) 'status': status,
        if (!omitPayload)
          'payload': payload ??
              <String, Object?>{
                'accountId': 'acc-1',
                'amountMinor': 4500000,
                'currency': 'COP',
                'type': 'expense',
                'date': 1755100000,
              },
      };

  Map<String, Object?> transactionPayload({
    Object? accountId = 'acc-1',
    Object? amountMinor = 4500000,
    Object? currency = 'COP',
    Object? type = 'expense',
    Object? date = 1755100000,
  }) =>
      <String, Object?>{
        'accountId': accountId,
        'amountMinor': amountMinor,
        'currency': currency,
        'type': type,
        'date': date,
      };

  group('round trip', () {
    test('a budget proposal survives toJson followed by fromJson', () {
      final original = buildBudgetProposal(
        categoryIds: {'cat-1', 'cat-2'},
        accountIds: {'acc-1'},
        status: AiProposalStatus.confirmed,
      );

      final reparsed = AiActionProposalMapper.fromJson(
        AiActionProposalMapper.toJson(original),
      );

      expect(reparsed, original);
    });

    test('a goal proposal survives toJson followed by fromJson', () {
      final original = buildGoalProposal(
        targetDate: DateTime(2027, 3, 15),
        accountId: 'acc-9',
        status: AiProposalStatus.dismissed,
      );

      final reparsed = AiActionProposalMapper.fromJson(
        AiActionProposalMapper.toJson(original),
      );

      expect(reparsed, original);
    });

    test('a category proposal survives toJson followed by fromJson', () {
      final original = buildCategoryProposal(
        kind: CategoryKind.income,
        parentId: 'cat-root',
        status: AiProposalStatus.failed,
      );

      final reparsed = AiActionProposalMapper.fromJson(
        AiActionProposalMapper.toJson(original),
      );

      expect(reparsed, original);
    });

    test('a transaction proposal survives toJson followed by fromJson', () {
      final original = buildTransactionProposal(
        categoryId: 'cat-food',
        note: 'almuerzo con Ana',
        type: TransactionType.income,
      );

      final reparsed = AiActionProposalMapper.fromJson(
        AiActionProposalMapper.toJson(original),
      );

      expect(reparsed, original);
    });

    test('a transaction born linked to a debt keeps its debtId', () {
      final original = buildTransactionProposal(debtId: 'debt-1');

      final reparsed = AiActionProposalMapper.fromJson(
        AiActionProposalMapper.toJson(original),
      );

      expect(reparsed, original);
      expect((reparsed as CreateTransactionProposal).debtId, 'debt-1');
    });

    test('a debt-link proposal survives toJson followed by fromJson', () {
      final original = buildDebtLinkProposal();

      final reparsed = AiActionProposalMapper.fromJson(
        AiActionProposalMapper.toJson(original),
      );

      expect(reparsed, original);
    });

    test('an unsupported proposal keeps its raw kind through a round trip', () {
      final original = buildUnsupportedProposal(rawKind: 'create_spaceship');

      final json = AiActionProposalMapper.toJson(original);
      final reparsed = AiActionProposalMapper.fromJson(json);

      expect(json['kind'], 'create_spaceship');
      expect(json.containsKey('payload'), isFalse);
      expect(reparsed, original);
    });

    test('a status written by this app parses back as the same status', () {
      final confirmed = buildTransactionProposal(
        status: AiProposalStatus.confirmed,
      );

      final json = AiActionProposalMapper.toJson(confirmed);

      expect(json['status'], 'confirmed');
      expect(
        AiActionProposalMapper.fromJson(json).status,
        AiProposalStatus.confirmed,
      );
    });

    test('amounts stay integer minor units after a round trip', () {
      final json = AiActionProposalMapper.toJson(
        buildBudgetProposal(amountMinor: 45000000),
      );

      expect((json['payload']! as Map<String, Object?>)['amountMinor'], 45000000);
      expect(
        (json['payload']! as Map<String, Object?>)['amountMinor'],
        isA<int>(),
      );
    });

    test('dates travel as unix seconds, not milliseconds', () {
      final date = DateTime(2026, 8, 20, 12);

      final json = AiActionProposalMapper.toJson(
        buildTransactionProposal(date: date),
      );

      expect(
        (json['payload']! as Map<String, Object?>)['date'],
        date.millisecondsSinceEpoch ~/ 1000,
      );
    });
  });

  group('parsing the four supported kinds', () {
    test('create_budget reads its payload into the entity', () {
      final proposal = AiActionProposalMapper.fromJson(<String, Object?>{
        'id': 'tc_0_0',
        'kind': 'create_budget',
        'title': 'Comida',
        'payload': <String, Object?>{
          'name': 'Comida',
          'amountMinor': 45000000,
          'currency': 'COP',
          'period': 'monthly',
          'startDate': 1754006400,
          'recurring': false,
          'categoryIds': <Object?>['cat-1', 'cat-1', 'cat-2'],
          'accountIds': <Object?>['acc-1'],
        },
      });

      expect(
        proposal,
        isA<CreateBudgetProposal>()
            .having((p) => p.amountMinor, 'amountMinor', 45000000)
            .having((p) => p.period, 'period', BudgetPeriod.monthly)
            .having((p) => p.recurring, 'recurring', false)
            .having((p) => p.categoryIds, 'categoryIds', {'cat-1', 'cat-2'})
            .having((p) => p.accountIds, 'accountIds', {'acc-1'}),
      );
    });

    test('a budget with no startDate anchors on a stable date, not on drift',
        () {
      Map<String, Object?> json() => <String, Object?>{
            'id': 'tc_0_0',
            'kind': 'create_budget',
            'title': 'Comida',
            'payload': <String, Object?>{
              'name': 'Comida',
              'amountMinor': 45000000,
              'currency': 'COP',
              'period': 'monthly',
            },
          };

      final first =
          AiActionProposalMapper.fromJson(json()) as CreateBudgetProposal;
      final rewritten = AiActionProposalMapper.fromJson(
        AiActionProposalMapper.toJson(first),
      ) as CreateBudgetProposal;

      expect(rewritten.startDate, first.startDate);
      expect(first.recurring, isTrue);
    });

    test('create_goal keeps targetMinor and the optional account', () {
      final proposal = AiActionProposalMapper.fromJson(<String, Object?>{
        'id': 'tc_0_1',
        'kind': 'create_goal',
        'title': 'Viaje',
        'payload': <String, Object?>{
          'name': 'Viaje',
          'targetMinor': 600000000,
          'currency': 'COP',
          'accountId': 'acc-3',
        },
      });

      expect(
        proposal,
        isA<CreateGoalProposal>()
            .having((p) => p.targetMinor, 'targetMinor', 600000000)
            .having((p) => p.accountId, 'accountId', 'acc-3')
            .having((p) => p.targetDate, 'targetDate', isNull),
      );
    });

    test('a goal with an out-of-range targetDate keeps the goal, drops the date',
        () {
      final proposal = AiActionProposalMapper.fromJson(<String, Object?>{
        'id': 'tc_0_1',
        'kind': 'create_goal',
        'title': 'Viaje',
        'payload': <String, Object?>{
          'name': 'Viaje',
          'targetMinor': 600000000,
          'currency': 'COP',
          // Milliseconds where seconds belong.
          'targetDate': 1800000000000,
        },
      });

      expect(
        proposal,
        isA<CreateGoalProposal>()
            .having((p) => p.targetDate, 'targetDate', isNull),
      );
    });

    test('create_category reads its kind', () {
      final proposal = AiActionProposalMapper.fromJson(<String, Object?>{
        'id': 'tc_0_2',
        'kind': 'create_category',
        'title': 'Mascotas',
        'payload': <String, Object?>{'name': 'Mascotas', 'kind': 'income'},
      });

      expect(
        proposal,
        isA<CreateCategoryProposal>()
            .having((p) => p.kind, 'kind', CategoryKind.income),
      );
    });

    test('a whole double amount is accepted as minor units', () {
      final proposal = AiActionProposalMapper.fromJson(
        transactionJson(payload: transactionPayload(amountMinor: 4500.0)),
      );

      expect(
        proposal,
        isA<CreateTransactionProposal>()
            .having((p) => p.amountMinor, 'amountMinor', 4500),
      );
    });
  });

  group('link_transaction_to_debt', () {
    Map<String, Object?> linkJson(Map<String, Object?> payload) =>
        <String, Object?>{
          'id': 'tc_0_5',
          'kind': 'link_transaction_to_debt',
          'title': 'Atribuir ese pago a tu crédito de la moto',
          'payload': payload,
        };

    test('reads both ids into the entity', () {
      final proposal = AiActionProposalMapper.fromJson(
        linkJson(<String, Object?>{
          'transactionId': 'tx-1',
          'debtId': 'debt-1',
        }),
      );

      expect(
        proposal,
        isA<LinkTransactionToDebtProposal>()
            .having((p) => p.transactionId, 'transactionId', 'tx-1')
            .having((p) => p.debtId, 'debtId', 'debt-1'),
      );
    });

    for (final (description, payload) in <(String, Map<String, Object?>)>[
      ('a missing transactionId', <String, Object?>{'debtId': 'debt-1'}),
      ('a missing debtId', <String, Object?>{'transactionId': 'tx-1'}),
      (
        'an id of the wrong type',
        <String, Object?>{'transactionId': 42, 'debtId': 'debt-1'},
      ),
    ]) {
      test('$description yields an unexecutable card, never an exception', () {
        final proposal = AiActionProposalMapper.fromJson(linkJson(payload));

        expect(
          proposal,
          isA<UnsupportedProposal>().having(
            (p) => p.rawKind,
            'rawKind',
            'link_transaction_to_debt',
          ),
        );
      });
    }
  });

  group('unknown kinds degrade instead of throwing', () {
    test('an unknown kind becomes UnsupportedProposal keeping the raw kind', () {
      final proposal = AiActionProposalMapper.fromJson(<String, Object?>{
        'id': 'tc_9_9',
        'kind': 'create_spaceship',
        'title': 'Comprar una nave',
        'payload': <String, Object?>{'name': 'Nave'},
      });

      expect(
        proposal,
        isA<UnsupportedProposal>()
            .having((p) => p.rawKind, 'rawKind', 'create_spaceship')
            .having((p) => p.title, 'title', 'Comprar una nave')
            .having((p) => p.id, 'id', 'tc_9_9'),
      );
    });

    test('a missing kind becomes UnsupportedProposal with an empty raw kind',
        () {
      final proposal = AiActionProposalMapper.fromJson(<String, Object?>{
        'id': 'tc_9_9',
        'title': 'Sin kind',
      });

      expect(
        proposal,
        isA<UnsupportedProposal>().having((p) => p.rawKind, 'rawKind', ''),
      );
    });

    test('an unknown status on an unsupported proposal reads as pending', () {
      final proposal = AiActionProposalMapper.fromJson(<String, Object?>{
        'id': 'tc_9_9',
        'kind': 'create_spaceship',
        'title': 'Comprar una nave',
        'status': 'half_confirmed',
      });

      expect(proposal.status, AiProposalStatus.pending);
    });
  });

  group('hostile payloads degrade to UnsupportedProposal without throwing', () {
    final cases = <String, Map<String, Object?>>{
      'a negative amount':
          transactionJson(payload: transactionPayload(amountMinor: -4500000)),
      'an amount below the plausible minimum':
          transactionJson(payload: transactionPayload(amountMinor: 50)),
      'a fractional amount':
          transactionJson(payload: transactionPayload(amountMinor: 4500.5)),
      'a missing amount': transactionJson(
        payload: <String, Object?>{
          'accountId': 'acc-1',
          'currency': 'COP',
          'type': 'expense',
          'date': 1755100000,
        },
      ),
      'an amount sent as a string':
          transactionJson(payload: transactionPayload(amountMinor: '4500000')),
      'a four-letter currency':
          transactionJson(payload: transactionPayload(currency: 'USDT')),
      'a lowercase currency':
          transactionJson(payload: transactionPayload(currency: 'cop')),
      'a missing currency': transactionJson(
        payload: <String, Object?>{
          'accountId': 'acc-1',
          'amountMinor': 4500000,
          'type': 'expense',
          'date': 1755100000,
        },
      ),
      'a date in milliseconds':
          transactionJson(payload: transactionPayload(date: 1755100000000)),
      'a date sent as a string':
          transactionJson(payload: transactionPayload(date: '1755100000')),
      'an unsupported transfer type':
          transactionJson(payload: transactionPayload(type: 'transfer')),
      'a missing account id':
          transactionJson(payload: transactionPayload(accountId: null)),
      'an account id of the wrong type':
          transactionJson(payload: transactionPayload(accountId: 42)),
      'a payload that is a list instead of an object':
          <String, Object?>{
        'id': 'tc_0_0',
        'kind': 'create_transaction',
        'title': 'Registrar el almuerzo',
        'payload': <Object?>['acc-1', 4500000],
      },
      'a null payload': <String, Object?>{
        'id': 'tc_0_0',
        'kind': 'create_transaction',
        'title': 'Registrar el almuerzo',
        'payload': null,
      },
      'a missing payload': transactionJson(omitPayload: true),
      'a budget period the app cannot window': <String, Object?>{
        'id': 'tc_0_0',
        'kind': 'create_budget',
        'title': 'Comida',
        'payload': <String, Object?>{
          'name': 'Comida',
          'amountMinor': 45000000,
          'currency': 'COP',
          'period': 'custom',
        },
      },
      'a category kind outside the closed list': <String, Object?>{
        'id': 'tc_0_2',
        'kind': 'create_category',
        'title': 'Mascotas',
        'payload': <String, Object?>{'name': 'Mascotas', 'kind': 'savings'},
      },
      'an empty name': <String, Object?>{
        'id': 'tc_0_2',
        'kind': 'create_category',
        'title': 'Mascotas',
        'payload': <String, Object?>{'name': '', 'kind': 'expense'},
      },
    };

    cases.forEach((description, json) {
      test('$description yields an unexecutable card, never an exception', () {
        late AiActionProposal proposal;

        expect(
          () => proposal = AiActionProposalMapper.fromJson(json),
          returnsNormally,
        );
        expect(proposal, isA<UnsupportedProposal>());
        expect(
          (proposal as UnsupportedProposal).rawKind,
          json['kind'],
          reason: 'the raw kind is kept for diagnostics',
        );
        expect(proposal.title, json['title']);
      });
    });

    test('a degraded proposal round-trips as the same unexecutable card', () {
      final degraded = AiActionProposalMapper.fromJson(
        transactionJson(payload: transactionPayload(currency: 'USDT')),
      );

      final reparsed = AiActionProposalMapper.fromJson(
        AiActionProposalMapper.toJson(degraded),
      );

      expect(reparsed, degraded);
    });

    test('a map with dynamic values is re-keyed instead of rejected', () {
      final proposal = AiActionProposalMapper.fromJson(<String, Object?>{
        'id': 'tc_0_0',
        'kind': 'create_transaction',
        'title': 'Registrar el almuerzo',
        // What `jsonDecode` hands back.
        'payload': <dynamic, dynamic>{
          'accountId': 'acc-1',
          'amountMinor': 4500000,
          'currency': 'COP',
          'type': 'expense',
          'date': 1755100000,
        },
      });

      expect(proposal, isA<CreateTransactionProposal>());
    });
  });

  group('fromJsonList', () {
    test('a non-list yields no proposals so the bubble text still renders', () {
      expect(AiActionProposalMapper.fromJsonList('nope'), isEmpty);
      expect(AiActionProposalMapper.fromJsonList(null), isEmpty);
      expect(
        AiActionProposalMapper.fromJsonList(<String, Object?>{'id': 'x'}),
        isEmpty,
      );
    });

    test('non-object entries are skipped and the readable ones survive', () {
      final proposals = AiActionProposalMapper.fromJsonList(<Object?>[
        'garbage',
        42,
        null,
        transactionJson(),
      ]);

      expect(proposals, hasLength(1));
      expect(proposals.single, isA<CreateTransactionProposal>());
    });

    test('a mixed list keeps unknown kinds alongside known ones', () {
      final proposals = AiActionProposalMapper.fromJsonList(<Object?>[
        transactionJson(),
        <String, Object?>{
          'id': 'tc_0_5',
          'kind': 'create_spaceship',
          'title': 'Nave',
        },
      ]);

      expect(proposals, hasLength(2));
      expect(proposals.last, isA<UnsupportedProposal>());
    });
  });

  group('withStatus', () {
    test('a goal card keeps its target and deadline when it advances', () {
      final original = buildGoalProposal(
        targetDate: DateTime(2027, 3, 15),
        accountId: 'acc-9',
      );

      expect(
        original.withStatus(AiProposalStatus.failed),
        buildGoalProposal(
          targetDate: DateTime(2027, 3, 15),
          accountId: 'acc-9',
          status: AiProposalStatus.failed,
        ),
      );
    });

    test('a category card keeps its kind and parent when it advances', () {
      final original = buildCategoryProposal(
        kind: CategoryKind.income,
        parentId: 'cat-root',
      );

      expect(
        original.withStatus(AiProposalStatus.dismissed),
        buildCategoryProposal(
          kind: CategoryKind.income,
          parentId: 'cat-root',
          status: AiProposalStatus.dismissed,
        ),
      );
    });

    test('a transaction card keeps its account, amount and note', () {
      final original = buildTransactionProposal(
        categoryId: 'cat-food',
        note: 'almuerzo con Ana',
      );

      expect(
        original.withStatus(AiProposalStatus.confirmed),
        buildTransactionProposal(
          categoryId: 'cat-food',
          note: 'almuerzo con Ana',
          status: AiProposalStatus.confirmed,
        ),
      );
    });

    test('an unsupported card can be dismissed without losing its raw kind',
        () {
      final original = buildUnsupportedProposal(rawKind: 'create_spaceship');

      expect(
        original.withStatus(AiProposalStatus.dismissed),
        buildUnsupportedProposal(
          rawKind: 'create_spaceship',
          status: AiProposalStatus.dismissed,
        ),
      );
    });

    test('advances the card without touching any other field', () {
      final original = buildBudgetProposal(categoryIds: {'cat-1'});

      final confirmed = original.withStatus(AiProposalStatus.confirmed);

      expect(confirmed.status, AiProposalStatus.confirmed);
      expect(
        confirmed,
        buildBudgetProposal(
          categoryIds: {'cat-1'},
          status: AiProposalStatus.confirmed,
        ),
      );
    });
  });
}
