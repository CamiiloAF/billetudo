import 'capture_lexicon.dart';
import 'spoken_tokens.dart';

/// A relative date found in the transcription plus the span it occupied.
class SpokenDateMatch {
  const SpokenDateMatch({
    required this.date,
    required this.start,
    required this.end,
  });

  /// Date-only, at midnight local time.
  final DateTime date;
  final int start;
  final int end;
}

/// Resolves the relative dates people actually say: "ayer", "antier", "el
/// lunes", "hace tres días", "el 5" (HU-04d).
///
/// Runs **before** the amount parser on purpose: "hace **dos** días" and "el
/// **5**" contain numbers that would otherwise be eaten as the amount.
///
/// A dictated date is never in the future. A future date means a scheduled
/// payment, not a transaction, and the bridge for that already exists in
/// Pagos Programados — so anything resolving forward is dropped rather than
/// guessed backwards.
class SpokenDateParser {
  const SpokenDateParser();

  SpokenDateMatch? parse(
    SpokenTokens tokens, {
    required CaptureLexicon lexicon,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    for (var index = 0; index < tokens.length; index++) {
      if (!tokens.isFree(index)) {
        continue;
      }
      final match = _matchAt(tokens, index, lexicon, today);
      if (match != null && !match.date.isAfter(today)) {
        return match;
      }
    }
    return null;
  }

  SpokenDateMatch? _matchAt(
    SpokenTokens tokens,
    int index,
    CaptureLexicon lexicon,
    DateTime today,
  ) {
    final isSpanish = lexicon.languageCode == 'es';
    final word = tokens.normalized[index];

    // Fixed offsets, longest phrase first so "antes de ayer" wins over "ayer".
    for (final entry in (isSpanish ? _spanishOffsets : _englishOffsets)) {
      if (tokens.matchesAt(index, entry.words)) {
        return SpokenDateMatch(
          date: today.subtract(Duration(days: entry.days)),
          start: index,
          end: index + entry.words.length,
        );
      }
    }

    // "hace N días" / "N days ago".
    final ago = isSpanish
        ? _spanishDaysAgo(tokens, index, lexicon)
        : _englishDaysAgo(tokens, index, lexicon);
    if (ago != null) {
      return SpokenDateMatch(
        date: today.subtract(Duration(days: ago.days)),
        start: index,
        end: ago.end,
      );
    }

    // Weekday, with or without a leading article and a trailing "pasado".
    final weekdayStart = _skipArticle(tokens, index, isSpanish);
    if (weekdayStart != null) {
      final weekday = lexicon.weekdays[tokens.normalized[weekdayStart]];
      if (weekday != null) {
        var end = weekdayStart + 1;
        // "last Monday" marks the past from the front, "el lunes pasado" from
        // the back; both mean the same thing.
        var forcePreviousWeek =
            (isSpanish ? _spanishPast : _englishPast).contains(word);
        if (end < tokens.length &&
            tokens.isFree(end) &&
            (isSpanish ? _spanishPast : _englishPast)
                .contains(tokens.normalized[end])) {
          forcePreviousWeek = true;
          end++;
        }
        return SpokenDateMatch(
          date: _mostRecentWeekday(
            today,
            weekday,
            strictlyBefore: forcePreviousWeek,
          ),
          start: index,
          end: end,
        );
      }
    }

    // "el 5": a bare day of the month behind an article.
    if (isSpanish && (word == 'el' || word == 'los')) {
      final day = _dayOfMonthAt(tokens, index + 1, lexicon);
      if (day != null) {
        return SpokenDateMatch(
          date: _mostRecentDayOfMonth(today, day),
          start: index,
          end: index + 2,
        );
      }
    }

    return null;
  }

  /// The index of the word after an optional article, or `null` when the token
  /// there is not free.
  int? _skipArticle(SpokenTokens tokens, int index, bool isSpanish) {
    final articles = isSpanish ? _spanishArticles : _englishArticles;
    if (articles.contains(tokens.normalized[index])) {
      return tokens.isFree(index + 1) ? index + 1 : null;
    }
    return index;
  }

  _DaysAgo? _spanishDaysAgo(
    SpokenTokens tokens,
    int index,
    CaptureLexicon lexicon,
  ) {
    if (tokens.normalized[index] != 'hace') {
      return null;
    }
    final count = _countAt(tokens, index + 1, lexicon);
    if (count == null) {
      return null;
    }
    final unitIndex = index + 2;
    if (unitIndex >= tokens.length || !tokens.isFree(unitIndex)) {
      return null;
    }
    final unit = tokens.normalized[unitIndex];
    if (unit == 'dia' || unit == 'dias') {
      return _DaysAgo(count, unitIndex + 1);
    }
    if (unit == 'semana' || unit == 'semanas') {
      return _DaysAgo(count * 7, unitIndex + 1);
    }
    return null;
  }

  _DaysAgo? _englishDaysAgo(
    SpokenTokens tokens,
    int index,
    CaptureLexicon lexicon,
  ) {
    final count = _countAt(tokens, index, lexicon);
    if (count == null) {
      return null;
    }
    final unitIndex = index + 1;
    final agoIndex = index + 2;
    if (agoIndex >= tokens.length ||
        !tokens.isFree(unitIndex) ||
        !tokens.isFree(agoIndex) ||
        tokens.normalized[agoIndex] != 'ago') {
      return null;
    }
    final unit = tokens.normalized[unitIndex];
    if (unit == 'day' || unit == 'days') {
      return _DaysAgo(count, agoIndex + 1);
    }
    if (unit == 'week' || unit == 'weeks') {
      return _DaysAgo(count * 7, agoIndex + 1);
    }
    return null;
  }

  /// A small count written as digits or as a word.
  int? _countAt(SpokenTokens tokens, int index, CaptureLexicon lexicon) {
    if (index >= tokens.length || !tokens.isFree(index)) {
      return null;
    }
    final word = tokens.normalized[index];
    final asWord = lexicon.numberWords[word];
    if (asWord != null && asWord > 0) {
      return asWord;
    }
    final asDigits = int.tryParse(word);
    return asDigits != null && asDigits > 0 ? asDigits : null;
  }

  /// A day of the month (1..31) that is not immediately followed by a scale
  /// word — "el 5 mil" is money behind an article, not the fifth.
  int? _dayOfMonthAt(SpokenTokens tokens, int index, CaptureLexicon lexicon) {
    final value = _countAt(tokens, index, lexicon);
    if (value == null || value > 31) {
      return null;
    }
    final next = index + 1;
    if (next < tokens.length &&
        (lexicon.scaleWords.containsKey(tokens.normalized[next]) ||
            lexicon.currencyWords.contains(tokens.normalized[next]))) {
      return null;
    }
    return value;
  }

  /// The most recent [weekday] (ISO, Monday = 1) at or before [today]. With
  /// [strictlyBefore] ("el lunes pasado") a match on today jumps a week back.
  DateTime _mostRecentWeekday(
    DateTime today,
    int weekday, {
    required bool strictlyBefore,
  }) {
    // Dart's `%` is non-negative for a positive divisor, so this already
    // lands in 0..6 without a manual wrap.
    var delta = (today.weekday - weekday) % 7;
    if (delta == 0 && strictlyBefore) {
      delta = 7;
    }
    return today.subtract(Duration(days: delta));
  }

  /// Day [day] of the current month, or of the previous one when that day has
  /// not happened yet this month.
  DateTime _mostRecentDayOfMonth(DateTime today, int day) {
    if (day <= today.day) {
      return DateTime(today.year, today.month, day);
    }
    final previousMonth = DateTime(today.year, today.month - 1);
    final daysInPreviousMonth =
        DateTime(previousMonth.year, previousMonth.month + 1, 0).day;
    return DateTime(
      previousMonth.year,
      previousMonth.month,
      day > daysInPreviousMonth ? daysInPreviousMonth : day,
    );
  }

  static const Set<String> _spanishArticles = <String>{'el', 'este', 'esta'};
  static const Set<String> _englishArticles = <String>{'last', 'this', 'on'};
  static const Set<String> _spanishPast = <String>{'pasado', 'pasada'};
  static const Set<String> _englishPast = <String>{'last'};

  static const List<_FixedOffset> _spanishOffsets = <_FixedOffset>[
    _FixedOffset(<String>['antes', 'de', 'ayer'], 2),
    _FixedOffset(<String>['esta', 'manana'], 0),
    _FixedOffset(<String>['esta', 'tarde'], 0),
    _FixedOffset(<String>['anteayer'], 2),
    _FixedOffset(<String>['antier'], 2),
    _FixedOffset(<String>['anoche'], 1),
    _FixedOffset(<String>['ayer'], 1),
    _FixedOffset(<String>['hoy'], 0),
  ];

  static const List<_FixedOffset> _englishOffsets = <_FixedOffset>[
    _FixedOffset(<String>['the', 'day', 'before', 'yesterday'], 2),
    _FixedOffset(<String>['last', 'night'], 1),
    _FixedOffset(<String>['this', 'morning'], 0),
    _FixedOffset(<String>['yesterday'], 1),
    _FixedOffset(<String>['today'], 0),
  ];
}

class _FixedOffset {
  const _FixedOffset(this.words, this.days);

  final List<String> words;
  final int days;
}

class _DaysAgo {
  const _DaysAgo(this.days, this.end);

  final int days;
  final int end;
}
