import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:reminders_plugin/reminders_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  bool _hasAccess = false;
  final _remindersPlugin = RemindersPlugin();
  AppleCalendar? _defaultList;
  List<AppleCalendar> lists = [];
  List reminders = [];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _remindersPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    _hasAccess = await _remindersPlugin.hasAccess() ?? false;
    _defaultList = await _remindersPlugin.getDefaultList();
    lists = await _remindersPlugin.getReminderLists();

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> requestAccess() async {
    _hasAccess = await _remindersPlugin.requestAccess() ?? false;
    setState(() {});
  }

  Future<void> getReminders(AppleCalendar list) async {
    final results = await _remindersPlugin.getReminders(list);

    setState(() {
      reminders = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: _hasAccess
              ? Text('Default list: ${_defaultList?.title}')
              : TextButton(
                  onPressed: requestAccess,
                  child: const Text('Request access'),
                ),
          actions: [Text(_platformVersion)],
        ),
        body: Row(
          children: [
            Flexible(
                child: ListView(
                    shrinkWrap: true,
                    children: lists
                        .map((list) => ListTile(
                              title: Text(list.title),
                              subtitle: TextButton(
                                  onPressed: () => getReminders(list),
                                  child: Text(list.id)),
                            ))
                        .toList())),
            Flexible(child: ListView())
          ],
        ),
      ),
    );
  }
}
