import 'package:flutter/material.dart';
import '../models/todo.dart';
import 'package:intl/intl.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback? onToggle; // Nullable callback
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final bool showEditButton;
  final bool showCheckbox; // 추가된 매개변수

  const TodoItem({
    Key? key,
    required this.todo,
    this.onToggle,
    required this.onDelete,
    required this.onEdit,
    this.showEditButton = true,
    this.showCheckbox = true, // 기본값 true
  }) : super(key: key);

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Todo'),
          content: Text('Are you sure you want to delete this todo?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                onDelete(); // Perform delete
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close the dialog
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showCheckbox) // showCheckbox가 true일 때만 체크박스를 표시
              Checkbox(
                value: todo.isDone,
                onChanged: onToggle != null
                    ? (value) => onToggle!()
                    : null, // Disable checkbox if onToggle is null
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration:
                          todo.isDone ? TextDecoration.lineThrough : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Due: ${DateFormat('yyyy/MM/dd').add_Hm().format(todo.dateTime)}', // 24-hour format
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Priority: ${todo.priority}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showEditButton)
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: onEdit,
                  ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () =>
                      _confirmDelete(context), // Call delete confirmation
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}