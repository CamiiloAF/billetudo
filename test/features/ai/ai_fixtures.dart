import 'package:billetudo/features/ai/domain/entities/ai_action_proposal.dart';
import 'package:billetudo/features/ai/domain/entities/ai_message.dart';
import 'package:billetudo/features/budgets/domain/entities/budget.dart'
    show BudgetPeriod;
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/transactions/domain/entities/transaction.dart'
    show TransactionType;

/// Shared builders so each AI test only states what it is actually about.
final DateTime aiTestInstant = DateTime(2026, 8, 25, 9, 30);

CreateBudgetProposal buildBudgetProposal({
  String id = 'tc_0_0',
  String title = 'Un presupuesto para Comida',
  AiProposalStatus status = AiProposalStatus.pending,
  String name = 'Comida',
  int amountMinor = 45000000,
  String currency = 'COP',
  BudgetPeriod period = BudgetPeriod.monthly,
  DateTime? startDate,
  bool recurring = true,
  Set<String> categoryIds = const <String>{},
  Set<String> accountIds = const <String>{},
}) =>
    CreateBudgetProposal(
      id: id,
      title: title,
      status: status,
      name: name,
      amountMinor: amountMinor,
      currency: currency,
      period: period,
      startDate: startDate ?? DateTime(2026, 8),
      recurring: recurring,
      categoryIds: categoryIds,
      accountIds: accountIds,
    );

CreateGoalProposal buildGoalProposal({
  String id = 'tc_0_1',
  String title = 'Una meta para el viaje',
  AiProposalStatus status = AiProposalStatus.pending,
  String name = 'Viaje',
  int targetMinor = 600000000,
  String currency = 'COP',
  DateTime? targetDate,
  String? accountId,
}) =>
    CreateGoalProposal(
      id: id,
      title: title,
      status: status,
      name: name,
      targetMinor: targetMinor,
      currency: currency,
      targetDate: targetDate,
      accountId: accountId,
    );

CreateCategoryProposal buildCategoryProposal({
  String id = 'tc_0_2',
  String title = 'Una categoría para mascotas',
  AiProposalStatus status = AiProposalStatus.pending,
  String name = 'Mascotas',
  CategoryKind kind = CategoryKind.expense,
  String? parentId,
}) =>
    CreateCategoryProposal(
      id: id,
      title: title,
      status: status,
      name: name,
      kind: kind,
      parentId: parentId,
    );

CreateTransactionProposal buildTransactionProposal({
  String id = 'tc_0_3',
  String title = 'Registrar el almuerzo',
  AiProposalStatus status = AiProposalStatus.pending,
  String accountId = 'acc-1',
  int amountMinor = 4500000,
  String currency = 'COP',
  TransactionType type = TransactionType.expense,
  DateTime? date,
  String? categoryId,
  String? note,
  String? debtId,
}) =>
    CreateTransactionProposal(
      id: id,
      title: title,
      status: status,
      accountId: accountId,
      amountMinor: amountMinor,
      currency: currency,
      type: type,
      date: date ?? DateTime(2026, 8, 20),
      categoryId: categoryId,
      note: note,
      debtId: debtId,
    );

LinkTransactionToDebtProposal buildDebtLinkProposal({
  String id = 'tc_0_5',
  String title = 'Atribuir ese pago a tu crédito de la moto',
  AiProposalStatus status = AiProposalStatus.pending,
  String transactionId = 'tx-1',
  String debtId = 'debt-1',
}) =>
    LinkTransactionToDebtProposal(
      id: id,
      title: title,
      status: status,
      transactionId: transactionId,
      debtId: debtId,
    );

UnsupportedProposal buildUnsupportedProposal({
  String id = 'tc_0_4',
  String title = 'Algo que esta versión no sabe hacer',
  AiProposalStatus status = AiProposalStatus.pending,
  String rawKind = 'create_spaceship',
}) =>
    UnsupportedProposal(
      id: id,
      title: title,
      status: status,
      rawKind: rawKind,
    );

AiMessage buildAiMessage({
  String id = 'msg-1',
  String conversationId = 'conv-1',
  AiMessageRole role = AiMessageRole.assistant,
  String content = 'Este mes gastaste menos en comida.',
  DateTime? createdAt,
  AiMessageStatus status = AiMessageStatus.sent,
  List<AiActionProposal> proposals = const <AiActionProposal>[],
}) =>
    AiMessage(
      id: id,
      conversationId: conversationId,
      role: role,
      content: content,
      createdAt: createdAt ?? aiTestInstant,
      status: status,
      proposals: proposals,
    );
