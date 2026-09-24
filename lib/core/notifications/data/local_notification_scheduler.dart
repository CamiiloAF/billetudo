import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../error/result.dart';
import '../domain/entities/app_notification_channel.dart';
import '../domain/entities/notification_id.dart';
import '../domain/entities/scheduled_local_notification.dart';
import '../domain/repositories/notification_messages.dart';
import '../domain/repositories/notification_scheduler.dart';

/// `flutter_local_notifications` + `timezone` implementation of
/// [NotificationScheduler].
///
/// Uses `zonedSchedule` exclusively (never the deprecated absolute-time
/// `schedule`): it is the only API that pins a notification to a **local
/// wall-clock** time, so a reminder configured for 9:00 still arrives at 9:00
/// after the user changes timezone or the region shifts DST. Scheduling by
/// UTC instant would silently drift by hours.
@LazySingleton(as: NotificationScheduler)
class LocalNotificationScheduler implements NotificationScheduler {
  LocalNotificationScheduler(this._messages)
      : _plugin = FlutterLocalNotificationsPlugin();

  /// Seam for tests. Not a second injectable constructor: injectable only
  /// looks at the default one, and taking the plugin as an optional parameter
  /// there made it try (and fail) to resolve `FlutterLocalNotificationsPlugin`
  /// from the graph.
  @visibleForTesting
  LocalNotificationScheduler.withPlugin(this._messages, this._plugin);

  final NotificationMessages _messages;
  final FlutterLocalNotificationsPlugin _plugin;

  /// The Android drawable used as the status-bar icon. `@mipmap/ic_launcher`
  /// is what the project already ships; a dedicated monochrome drawable is a
  /// pending polish item, not a blocker.
  static const String _androidIcon = 'ic_launcher';

  static const MethodChannel _nativeReminderChannel =
      MethodChannel('com.billetudo.app/reminders');

  bool _initialized = false;

  @override
  FutureResult<Unit> initialize() async {
    if (_initialized) {
      return const Right(unit);
    }
    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(await _deviceTimezone()));

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(_androidIcon),
          // Permission is asked in context (when the first reminder is
          // configured), never at startup — so iOS must not prompt here.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      await _createAndroidChannels();
      _initialized = true;
      return const Right(unit);
    } on Object catch (error, stackTrace) {
      return Left(
        UnexpectedFailure(
          'could not initialize local notifications',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  FutureResult<bool> hasPermission() async {
    try {
      final status = await Permission.notification.status;
      if (kDebugMode) {
        debugPrint('BilletudoNotifications: permission=${status.name}');
      }
      return Right(status.isGranted);
    } on Object catch (error, stackTrace) {
      return Left(
        UnexpectedFailure(
          'could not read the notification permission',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  FutureResult<bool> requestPermission() async {
    try {
      final status = await Permission.notification.request();
      return Right(status.isGranted);
    } on Object catch (error, stackTrace) {
      return Left(
        UnexpectedFailure(
          'could not request the notification permission',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  FutureResult<Unit> openSystemSettings() async {
    try {
      await openAppSettings();
      return const Right(unit);
    } on Object catch (error, stackTrace) {
      return Left(
        UnexpectedFailure(
          'could not open the system settings',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  FutureResult<Unit> schedule(ScheduledLocalNotification notification) async {
    final initialized = await initialize();
    if (initialized case Left(value: final failure)) {
      return Left(failure);
    }

    final scheduledDate = tz.TZDateTime.from(
      notification.fireAt,
      tz.local,
    );
    if (!scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
      // A reminder for a moment that already passed is noise, and
      // `zonedSchedule` would deliver it immediately. Dropping it is the
      // correct outcome, not an error.
      return const Right(unit);
    }

    try {
      final details = _detailsFor(notification.channel);
      if (Platform.isAndroid) {
        await _nativeReminderChannel.invokeMethod<void>(
          'schedule',
          <String, Object?>{
            'id': notification.id,
            'channelId': notification.channel.id,
            'channelName': _messages.channelName(notification.channel),
            'channelDescription':
                _messages.channelDescription(notification.channel),
            'title': notification.title,
            'body': notification.body,
            'payload': notification.payload,
            'fireAt': scheduledDate.millisecondsSinceEpoch,
          },
        );
      } else {
        await _plugin.zonedSchedule(
          id: notification.id,
          title: notification.title,
          body: notification.body,
          payload: notification.payload,
          scheduledDate: scheduledDate,
          notificationDetails: details,
          // Not `exactAllowWhileIdle`: an exact alarm needs
          // SCHEDULE_EXACT_ALARM, which Google Play restricts to alarm/clock
          // apps. A reminder that lands a few minutes late is fine; an app
          // rejected from the store is not.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
      return const Right(unit);
    } on Object catch (error, stackTrace) {
      return Left(
        UnexpectedFailure(
          'could not schedule notification ${notification.id}',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  FutureResult<Unit> cancel(int id) async {
    try {
      if (Platform.isAndroid) {
        await _nativeReminderChannel.invokeMethod<void>(
          'cancel',
          <String, Object?>{'id': id},
        );
      } else {
        await _plugin.cancel(id: id);
      }
      return const Right(unit);
    } on Object catch (error, stackTrace) {
      return Left(
        UnexpectedFailure(
          'could not cancel notification $id',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  FutureResult<List<int>> pendingIds() async {
    try {
      if (Platform.isAndroid) {
        final ids = await _nativeReminderChannel.invokeMethod<List<Object?>>(
          'pendingIds',
        );
        return Right([
          for (final id in ids ?? const <Object?>[])
            if (id is int) id,
        ]);
      }
      final pending = await _plugin.pendingNotificationRequests();
      return Right(pending.map((request) => request.id).toList());
    } on Object catch (error, stackTrace) {
      return Left(
        UnexpectedFailure(
          'could not read pending notifications',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  FutureResult<Unit> cancelChannel(AppNotificationChannel channel) async {
    final pending = await pendingIds();
    return switch (pending) {
      Left(value: final failure) => Left(failure),
      Right(value: final ids) => await _cancelAll(
          ids.where((id) => NotificationId.belongsTo(id, channel)),
        ),
    };
  }

  Future<Result<Unit>> _cancelAll(Iterable<int> ids) async {
    for (final id in ids) {
      final result = await cancel(id);
      if (result case Left(value: final failure)) {
        return Left(failure);
      }
    }
    return const Right(unit);
  }

  NotificationDetails _detailsFor(AppNotificationChannel channel) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          _messages.channelName(channel),
          icon: _androidIcon,
          channelDescription: _messages.channelDescription(channel),
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  Future<void> _createAndroidChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return;
    }
    for (final channel in AppNotificationChannel.values) {
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          channel.id,
          _messages.channelName(channel),
          description: _messages.channelDescription(channel),
          importance: Importance.high,
        ),
      );
    }
  }

  Future<String> _deviceTimezone() async {
    // Widget/unit tests run without the platform channel; UTC keeps the
    // scheduler usable there instead of throwing on the first call.
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return 'UTC';
    }
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      return info.identifier;
    } on Object {
      return 'UTC';
    }
  }
}
