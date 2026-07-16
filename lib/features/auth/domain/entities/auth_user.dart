import 'package:equatable/equatable.dart';

import 'auth_provider.dart';

/// The signed-in user, as far as this app cares: display identity, nothing
/// billetudo doesn't already need (no password, no phone number — auth is
/// social-only).
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.displayName,
    required this.provider,
    this.email,
    this.avatarUrl,
  });

  /// The provider's stable user id (Google `sub` / Apple `user` identifier).
  final String id;
  final String displayName;
  final AuthProvider provider;
  final String? email;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, displayName, provider, email, avatarUrl];
}
