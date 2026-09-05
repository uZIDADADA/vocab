import 'package:flutter/services.dart';

class ReminderService {
  static const channel = MethodChannel('vocab/reminders');
  Future<Map<Object?, Object?>> load() async =>
      await channel.invokeMethod<Map<Object?, Object?>>('load') ?? {};
  Future<void> save(bool enabled, int hour, int minute) => channel.invokeMethod(
    'save',
    {'enabled': enabled, 'hour': hour, 'minute': minute},
  );
  Future<void> test() => channel.invokeMethod('test');
  Future<void> settings() => channel.invokeMethod('settings');
}
