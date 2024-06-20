import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class RemindersPlugin extends PlatformInterface {
  static final Object _token = Object();
  RemindersPlugin() : super(token: _token) {
    PlatformInterface.verifyToken(this, _token);
  }

  final channel = const MethodChannel('reminders_plugin');

  Future<String?> getPlatformVersion() async {
    final version = await channel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  Future<bool?> hasAccess() async =>
      await channel.invokeMethod<bool>('hasAccess');

  Future<bool?> requestAccess() async =>
      await channel.invokeMethod<bool>('requestAccess');

  Future<AppleCalendar?> getDefaultList() async {
    final list =
        await channel.invokeMapMethod<String, String>('getDefaultList');
    if (list case {'title': final title, 'id': final id}) {
      return AppleCalendar(title: title, id: id);
    }
    return null;
  }

  Future<List<AppleCalendar>> getReminderLists() async {
    final lists = await channel
        .invokeListMethod<Map<Object?, Object?>>('getReminderLists');
    if (lists == null) return [];
    return lists
        .map<AppleCalendar>((list) => AppleCalendar(
            title: list['title']! as String, id: list['id']! as String))
        .toList();
  }

  Future<List> getReminders(AppleCalendar list) async {
    print('getReminders: ${list.title}');
    final reminders = await channel.invokeListMethod<Map<Object?, Object?>>(
        'getReminders', {'id': list.id});
    print(reminders);
    return [];
  }
}

class AppleCalendar {
  final String title;
  final String id;
  AppleCalendar({required this.title, required this.id});
}
