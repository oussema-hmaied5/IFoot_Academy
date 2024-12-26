import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> _sendNotification(String groupName, DateTime startDateTime, DateTime endDateTime) async {
    var androidDetails = const AndroidNotificationDetails(
      'training_session_channel_id',  // Channel ID
      'Training Sessions',  // Channel Name
      channelDescription: 'Notifications for scheduled training sessions',
      importance: Importance.max,
      priority: Priority.high,
    );

    var platformDetails = NotificationDetails(android: androidDetails);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'Séance d\'Entraînement Planifiée',  // Notification Title
        'Le groupe $groupName s\'entraîne de ${startDateTime.hour}:${startDateTime.minute.toString().padLeft(2, '0')} à ${endDateTime.hour}:${endDateTime.minute.toString().padLeft(2, '0')}',  // Notification Body
        tz.TZDateTime.from(startDateTime, tz.local),  // Schedule notification at the session start time
        platformDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: DateTimeComponents.time, // Schedule notifications by time
      );

      print('Notification successfully scheduled!');
    } catch (e) {
      print('Failed to schedule notification: $e');
      // Handle the failure appropriately (e.g., show an error message to the user)
    }
  }
}
