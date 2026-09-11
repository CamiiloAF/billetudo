import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';

/// Category tree used by the parser tests: roots plus the subcategories the
/// requirement's example table expects the parser to prefer.
List<Category> testCategories() => <Category>[
      _category(id: 'cat-food', name: 'Alimentación'),
      _category(id: 'cat-market', name: 'Mercado', parentId: 'cat-food'),
      _category(
          id: 'cat-restaurants', name: 'Restaurantes', parentId: 'cat-food'),
      _category(id: 'cat-transport', name: 'Transporte'),
      _category(id: 'cat-fuel', name: 'Gasolina', parentId: 'cat-transport'),
      _category(id: 'cat-home', name: 'Hogar'),
      _category(id: 'cat-rent', name: 'Arriendo', parentId: 'cat-home'),
      _category(
        id: 'cat-salary',
        name: 'Salario',
        kind: CategoryKind.income,
      ),
    ];

/// The same tree with English names, for the `en` lexicon tests.
List<Category> testCategoriesEn() => <Category>[
      _category(id: 'cat-food', name: 'Food'),
      _category(id: 'cat-transport', name: 'Transport'),
      _category(id: 'cat-home', name: 'Home'),
      _category(id: 'cat-rent', name: 'Rent', parentId: 'cat-home'),
    ];

List<Account> testAccounts() => <Account>[
      _account(id: 'acc-nequi', name: 'Nequi'),
      _account(id: 'acc-banco', name: 'Bancolombia'),
      _account(id: 'acc-cash', name: 'Efectivo', type: AccountType.cash),
    ];

Category _category({
  required String id,
  required String name,
  String? parentId,
  CategoryKind kind = CategoryKind.expense,
}) =>
    Category(
      id: id,
      name: name,
      kind: kind,
      parentId: parentId,
      sortOrder: 0,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026).millisecondsSinceEpoch,
    );

Account _account({
  required String id,
  required String name,
  AccountType type = AccountType.bank,
  bool archived = false,
}) =>
    Account(
      id: id,
      name: name,
      type: type,
      currency: 'COP',
      initialBalanceMinor: 0,
      archived: archived,
      sortOrder: 0,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026).millisecondsSinceEpoch,
    );

/// An archived account, to prove the matcher ignores it.
Account archivedAccount({required String id, required String name}) =>
    _account(id: id, name: name, archived: true);
