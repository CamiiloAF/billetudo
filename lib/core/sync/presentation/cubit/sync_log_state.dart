import 'package:equatable/equatable.dart';

import '../../domain/entities/sync_log_entry.dart';

class SyncLogState extends Equatable {
  const SyncLogState({this.entries = const [], this.isLoading = true});

  /// Newest first, exactly as the repository emits them.
  final List<SyncLogEntry> entries;
  final bool isLoading;

  SyncLogState copyWith({List<SyncLogEntry>? entries, bool? isLoading}) =>
      SyncLogState(
        entries: entries ?? this.entries,
        isLoading: isLoading ?? this.isLoading,
      );

  @override
  List<Object?> get props => [entries, isLoading];
}
