import 'dart:convert';

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';

Future<dynamic> handleRemindersOnNewSession(context, Users users) async {
  final userId = context.req.bodyJson['userId'];
  if (userId == null || userId.isEmpty) {
    return context.res.text('userId is empty', 400);
  }
  late User user;
  try {
    user = await users.get(userId: userId);
  } on Exception catch (e) {
    return context.res.text(e.toString(), 400);
  }

  final messaging = Messaging(users.client);
  context.log('processing user ${user.name}');
  // Retrieve user's timezone offset
  final timezoneOffset = user.prefs.data['timezone'];

  if (timezoneOffset != null) {
    context.log('retrieved timezone offset: $timezoneOffset');
    // Parse timezone offset
    context.log('Original timezone offset: $timezoneOffset');
    final isOffsetNegative = timezoneOffset.startsWith('-');
    final pureOffsetDuration =
        timezoneOffset.replaceAll('-', '').split('.').first;
    context.log('Pure offset duration: $pureOffsetDuration');
    final offsetHour = int.parse(pureOffsetDuration.split(':')[0]);
    final offsetMin = int.parse(pureOffsetDuration.split(':')[1]);
    final offsetSec = int.parse(pureOffsetDuration.split(':')[2]);
    final offsetDuration = Duration(
      hours: offsetHour,
      minutes: offsetMin,
      seconds: offsetSec,
    );
    context.log('Offset duration: $offsetDuration');

    // Calculate next 9 PM in user's local time
    final now = DateTime.now().toUtc();
    context.log('Current UTC time: $now');
    final userTime = isOffsetNegative
        ? now.subtract(offsetDuration)
        : now.add(offsetDuration);
    context.log('Current user time: $userTime');
    DateTime next9PM =
        DateTime(userTime.year, userTime.month, userTime.day, 21);
    if (userTime.isAfter(next9PM)) {
      next9PM = next9PM.add(Duration(days: 1));
    }
    context.log('Next 9 PM user time: $next9PM');

    // Convert next9PM to UTC
    final next9PMUtc = next9PM.subtract(Duration(hours: offsetHour));

    final messageId = _generateMessageId(user, next9PMUtc);
    try {
      context.log('deleting existing message');
      // cancel if message already scheduled
      await messaging.delete(messageId: messageId);
      context.log('deleted existing message');
    } catch (e) {
      context.log(e.toString());
    }
    // Schedule push notification
    context.log('scheduling push notification');
    final userPushTargets = user.targets
        .where((element) => element.providerType == "push")
        .toList();
    context.log('user push targets: ${jsonEncode(userPushTargets.map(
          (e) => e.toMap(),
        ).toList())}');
    try {
      final result = await messaging.createPush(
        messageId: messageId,
        title: 'Time to Code! 🚀',
        body:
            "Hey there! 🌟 It's 9 PM—have you coded or contributed to your GitHub today? Even a small commit can make a big difference. Keep the streak alive and let your ideas shine! 💻✨",
        scheduledAt: next9PMUtc
            .subtract(Duration(
                minutes:
                    30)) // the 30-min subtraction is due to a bug on appwrite which delays the notification by 30 minutes
            .toIso8601String(),
        targets: userPushTargets
            .map(
              (e) => e.$id,
            )
            .toList(),
      );
      context.log('scheduled push notification!: $result');
      return context.res.text('success', 200);
    } catch (e) {
      context.log(e.toString());
      return context.res.text(e.toString(), 400);
    }
  }
}

// message id containing user id and date (only year, month, day)
String _generateMessageId(User user, DateTime next9PMUtc) =>
    '${user.$id}-${next9PMUtc.year}-${next9PMUtc.month}-${next9PMUtc.day}';
