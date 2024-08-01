import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../widgets/todo_item.dart';
import 'add_todo_screen.dart';
import 'completed_todo_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'edit_todo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _requestAlarmPermission(BuildContext context) async {
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
    if (await Permission.scheduleExactAlarm.isGranted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return const AddTodoScreen();
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text("Permission Needed"),
          content: const Text("This app needs alarm permissions to schedule reminders."),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now(); // 현재 시간을 변수에 저장

    return Scaffold(
      appBar: AppBar(
        title: const Text('TODO List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _requestAlarmPermission(context),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CompletedTodoScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: TodoCategory(
              title: 'Daily repeat',
              filter: (todo) => todo.isRepeatingDaily && !todo.isDone,
            ),
          ),
          Expanded(
            child: TodoCategory(
              title: 'In progress',
              filter: (todo) => !todo.isDone && todo.dateTime.isAfter(now) && !todo.isRepeatingDaily,
            ),
          ),
          Expanded(
            child: TodoCategory(
              title: 'Overdue',
              filter: (todo) => !todo.isDone && todo.dateTime.isBefore(now) && !todo.isRepeatingDaily,
            ),
          ),
        ],
      ),
    );
  }
}

class TodoCategory extends StatelessWidget {
  final String title;
  final bool Function(Todo) filter;
  final ScrollController _scrollController = ScrollController();

  TodoCategory({Key? key, required this.title, required this.filter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoModel>(
      builder: (context, todoModel, child) {
        final todos = todoModel.getFilteredTodos(filter);

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      final todo = todos[index];
                      return TodoItem(
                        todo: todo,
                        onToggle: () => todoModel.toggleTodoStatus(todo.id),
                        onDelete: () => todoModel.deleteTodo(todo.id),
                        onEdit: () => showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return EditTodoScreen(todo: todo);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
