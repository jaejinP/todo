import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class Todo {
  final String id;
  final String title;
  final DateTime dateTime;
  final String priority;
  final bool isDone;
  final bool isRepeatingDaily;

  Todo({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.priority,
    this.isDone = false,
    this.isRepeatingDaily = false,
  });

  Todo copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    String? priority,
    bool? isDone,
    bool? isRepeatingDaily,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      isRepeatingDaily: isRepeatingDaily ?? this.isRepeatingDaily,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dateTime': dateTime.toIso8601String(),
      'priority': priority,
      'isDone': isDone,
      'isRepeatingDaily': isRepeatingDaily,
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      dateTime: DateTime.parse(json['dateTime']),
      priority: json['priority'],
      isDone: json['isDone'],
      isRepeatingDaily: json['isRepeatingDaily'],
    );
  }
}

class TodoModel extends ChangeNotifier {
  final List<Todo> _todos = [];
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final SharedPreferences prefs;

  TodoModel(this.flutterLocalNotificationsPlugin, this.prefs) {
    tz.initializeTimeZones();
    _loadTodos();
    _initializeRepeatingTodos();
  }

  List<Todo> get todos => _todos;

  void addTodo(String title, DateTime dateTime, String priority, {bool isRepeatingDaily = false}) {
    final todo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      dateTime: dateTime,
      priority: priority,
      isRepeatingDaily: isRepeatingDaily,
    );
    _todos.add(todo);
    _saveTodos();

    if (dateTime.isAfter(DateTime.now())) {
      _scheduleNotification(todo); // 현재 시간 이후인 경우에만 알람 설정
    }

    notifyListeners();
  }

  void deleteTodo(String id) {
    _cancelNotification(id);
    _todos.removeWhere((todo) => todo.id == id);
    _saveTodos();
    notifyListeners();
  }

  void toggleTodoStatus(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final todo = _todos[index];
      _todos[index] = todo.copyWith(isDone: !todo.isDone);
      if (todo.isDone && todo.isRepeatingDaily) {
        final newDateTime = todo.dateTime.add(Duration(days: 1));
        _todos[index] = todo.copyWith(dateTime: newDateTime, isDone: false);
        _scheduleNotification(_todos[index], isNew: true);
      }
      _saveTodos();
      notifyListeners();
    }
  }

  void updateTodo(String id, String title, DateTime dateTime, String priority, {bool isRepeatingDaily = false}) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final oldTodo = _todos[index];
      _cancelNotification(oldTodo.id); // 기존 알람 취소
      _todos[index] = oldTodo.copyWith(
        title: title,
        dateTime: dateTime,
        priority: priority,
        isRepeatingDaily: isRepeatingDaily,
      );

      if (dateTime.isAfter(DateTime.now())) {
        _scheduleNotification(_todos[index]); // 현재 시간 이후인 경우에만 새로운 알람 예약
      }

      _saveTodos();
      notifyListeners();
    }
  }

  List<Todo> getFilteredTodos(bool Function(Todo) filter) {
    return _todos.where(filter).toList()
      ..sort((a, b) {
        const priorityOrder = {'High': 1, 'Medium': 2, 'Low': 3};
        return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
      });
  }

  void _initializeRepeatingTodos() {
    Timer.periodic(Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      for (final todo in _todos) {
        if (todo.isRepeatingDaily && todo.dateTime.isBefore(now) && !todo.isDone) {
          final newDateTime = todo.dateTime.add(Duration(days: 1));
          _todos[_todos.indexOf(todo)] = todo.copyWith(dateTime: newDateTime, isDone: false);
          _scheduleNotification(_todos[_todos.indexOf(todo)], isNew: true);
        }
      }
      _saveTodos();
      notifyListeners();
    });
  }

  Future<void> requestNotificationPermissions() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
        );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _scheduleNotification(Todo todo, {bool isNew = false}) async {
    final notificationId = todo.id.hashCode & 0x7FFFFFFF;
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(todo.dateTime, tz.local);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'todo_channel', // channel ID
      'Todo Notifications', // channel name
      channelDescription: 'Notification channel for todo reminders',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      ongoing: true, // 알림이 지속적으로 유지되도록 설정
      playSound: true,
      enableVibration: true,
      autoCancel: false,
    );

    const IOSNotificationDetails iOSPlatformChannelSpecifics =
    IOSNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId, // Unique ID for the notification
      'Todo Notification',
      '${todo.title}',
      scheduledDate,
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  void _cancelNotification(String id) async {
    final notificationId = id.hashCode & 0x7FFFFFFF;
    await flutterLocalNotificationsPlugin.cancel(notificationId);
  }

  void _saveTodos() {
    final List<String> todosJson = _todos.map((todo) => jsonEncode(todo.toJson())).toList();
    prefs.setStringList('todos', todosJson);
  }

  void _loadTodos() {
    final List<String>? todosJson = prefs.getStringList('todos');
    if (todosJson != null) {
      _todos.clear();
      for (final jsonString in todosJson) {
        final Map<String, dynamic> json = Map<String, dynamic>.from(jsonDecode(jsonString));
        _todos.add(Todo.fromJson(json));
      }
    }
  }
}