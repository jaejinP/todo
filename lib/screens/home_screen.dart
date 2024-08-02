import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../widgets/todo_item.dart';
import 'add_todo_screen.dart';
import 'completed_todo_screen.dart';
import 'edit_todo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // _requestPermissionsOnce();
    // 주기적으로 상태 업데이트
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  // Future<void> _requestPermissionsOnce() async {
  //   await Provider.of<TodoModel>(context, listen: false).requestNotificationPermissions();
  // }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
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
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const AddTodoScreen();
                },
              );
            },
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
              showCheckbox: false, // 체크박스를 숨김
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
  final bool showCheckbox; // 추가된 매개변수
  final ScrollController _scrollController = ScrollController();

  TodoCategory({Key? key, required this.title, required this.filter, this.showCheckbox = true}) : super(key: key); // 기본값 true

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
                        showCheckbox: showCheckbox, // 전달된 매개변수 사용
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