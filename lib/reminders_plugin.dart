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

  Future<bool> hasAccess() async =>
      (await channel.invokeMethod<bool>('hasAccess')) ?? false;

  Future<bool?> requestAccess() async =>
      await channel.invokeMethod<bool>('requestAccess');

  Future<AppleList?> getDefaultList() async {
    final list =
        await channel.invokeMapMethod<String, String>('getDefaultList');
    if (list case {'title': final title, 'id': final id}) {
      return AppleList(title: title, id: id);
    }
    return null;
  }

  Future<List<AppleList>> getReminderLists() async {
    final lists = await channel
        .invokeListMethod<Map<Object?, Object?>>('getReminderLists');
    if (lists == null) return [];
    return lists
        .map<AppleList>((list) => AppleList(
            title: list['title']! as String, id: list['id']! as String))
        .toList();
  }

  Future<List> getReminders(AppleList list) async {
    final reminders = await channel.invokeListMethod<Map<Object?, Object?>>(
        'getReminders', {'id': list.id});
    if (reminders == null) return [];
    return reminders
        .map<Reminder>((reminder) => Reminder.fromJson(reminder))
        .toList();
  }

  Future<Map<String, String>> addReminder(Reminder reminder) async {
    final result = await channel.invokeMapMethod<String, String>(
        'addReminder', reminder.toJson());
    if (result == null) return {'error': 'unknown error'};
    return result;
  }

  Future<String?> deleteReminder(Reminder reminder) async =>
      await channel.invokeMethod('deleteReminder', {'id': reminder.id});
}

class Reminder {
  String list;
  final String id;
  final String title;
  DateTime? dueDate;
  int priority;
  bool isCompleted;
  String notes;
  final String? url;
  Reminder({
    required this.list,
    required this.title,
    required this.notes,
    this.dueDate,
  })  : id = '',
        priority = 0,
        isCompleted = false,
        url = null;

  Reminder.fromJson(Map<Object?, Object?> json)
      : list = json['list'] as String,
        id = json['id'] as String,
        title = json['title'] as String,
        dueDate = json['dueDate'] != ''
            ? DateTime.parse(json['dueDate'] as String).toLocal()
            : null,
        priority = int.tryParse(json['priority'] as String) ?? 0,
        isCompleted = json['isCompleted'] == 'true',
        notes = json['notes'] as String,
        url = json['url'] as String;

  @override
  String toString() =>
      '$title is due $dueDate and is done: $isCompleted\n$url\t$notes';

  Map<String, Object?> toJson() => {
        'list': list,
        'id': id,
        'title': title,
        'dueDate': dueDate?.toMap(),
        'priority': priority.toString(),
        'isCompleted': isCompleted.toString(),
        'notes': notes,
        'url': url
      };
}

extension ToMap on DateTime {
  toMap() => {
        'year': year,
        'month': month,
        'day': day,
        'hour': hour == 0 && minute == 0 && second == 0 ? null : hour,
        'minute': hour == 0 && minute == 0 && second == 0 ? null : minute,
        'second': hour == 0 && minute == 0 && second == 0 ? null : second
      };
}

class AppleList {
  final String title;
  final String id;
  AppleList({required this.title, required this.id});
  @override
  String toString() => title;
}
