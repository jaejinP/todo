import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../widgets/todo_item.dart';

class CompletedTodoScreen extends StatelessWidget {
  const CompletedTodoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Todos'),
      ),
      body: Consumer<TodoModel>(
        builder: (context, todoModel, child) {
          final completedTodos = todoModel.todos.where((todo) => todo.isDone).toList();

          return ListView.builder(
            itemCount: completedTodos.length,
            itemBuilder: (context, index) {
              final todo = completedTodos[index];
              return TodoItem(
                todo: todo,
                onToggle: () => todoModel.toggleTodoStatus(todo.id),
                onDelete: () => todoModel.deleteTodo(todo.id),
                onEdit: () {},
                showEditButton: false,
              );
            },
          );
        },
      ),
    );
  }
}
