import 'package:billetudo/core/notifications/domain/entities/app_notification_channel.dart';
import 'package:billetudo/core/notifications/domain/entities/notification_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el mismo key y canal siempre dan el mismo id', () {
    final first =
        NotificationId.forKey('sp-1', AppNotificationChannel.reminders);
    final second =
        NotificationId.forKey('sp-1', AppNotificationChannel.reminders);

    expect(first, second);
  });

  test('keys distintos dan ids distintos', () {
    expect(
      NotificationId.forKey('sp-1', AppNotificationChannel.reminders),
      isNot(NotificationId.forKey('sp-2', AppNotificationChannel.reminders)),
    );
  });

  test('cada canal vive en su propio bloque de ids', () {
    for (final channel in AppNotificationChannel.values) {
      final id = NotificationId.forKey('sp-1', channel);
      expect(NotificationId.belongsTo(id, channel), isTrue);
      for (final other in AppNotificationChannel.values) {
        if (other == channel) {
          continue;
        }
        expect(NotificationId.belongsTo(id, other), isFalse);
      }
    }
  });

  test('los ids caben en el rango de 32 bits con signo de Android', () {
    final maxId =
        NotificationId.blockStart(AppNotificationChannel.values.last) +
            NotificationId.blockSize;

    expect(maxId, lessThan(2147483647));
  });
}
