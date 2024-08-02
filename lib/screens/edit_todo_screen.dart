import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import '../models/todo.dart';

class EditTodoScreen extends StatefulWidget {
  final Todo todo;

  const EditTodoScreen({Key? key, required this.todo}) : super(key: key);

  @override
  _EditTodoScreenState createState() => _EditTodoScreenState();
}

class _EditTodoScreenState extends State<EditTodoScreen> {
  late TextEditingController _titleController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _priority;
  late bool _isRepeatingDaily;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _selectedDate = widget.todo.dateTime;
    _selectedTime = TimeOfDay.fromDateTime(widget.todo.dateTime);
    _priority = widget.todo.priority;
    _isRepeatingDaily = widget.todo.isRepeatingDaily;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _selectTime(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: MediaQuery.of(context).copyWith().size.height / 3,
          child: CupertinoTimerPicker(
            mode: CupertinoTimerPickerMode.hm,
            initialTimerDuration: Duration(hours: _selectedTime.hour, minutes: _selectedTime.minute),
            onTimerDurationChanged: (Duration newDuration) {
              setState(() {
                _selectedTime = TimeOfDay(hour: newDuration.inHours, minute: newDuration.inMinutes % 60);
              });
            },
          ),
        );
      },
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat.Hm(); // 24시간 형식
    return format.format(dt);
  }

  void _updateTodo() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Title cannot be empty'),
        ),
      );
      return;
    }

    final DateTime dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    Provider.of<TodoModel>(context, listen: false).updateTodo(
      widget.todo.id,
      _titleController.text,
      dateTime,
      _priority,
      isRepeatingDaily: _isRepeatingDaily,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Todo'),
      content: SingleChildScrollView( // 키보드가 올라올 때 스크롤 가능하도록 설정
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              width: double.infinity, // 가로 길이 설정 (화면 가득)
              height: 50.0, // 세로 길이 설정
              child: TextField(
                key: const Key('titleField'),
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 10.0),
            Row(
              children: <Widget>[
                Flexible(
                  flex: 3, // 연월일 텍스트 박스의 가로 길이를 늘림
                  child: GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Center(
                        child: Text(
                          DateFormat('yyyy/MM/dd').format(_selectedDate), // 년/월/일 형식으로 표시
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                Flexible(
                  flex: 2, // 시간 텍스트 박스의 가로 길이를 줄임
                  child: GestureDetector(
                    onTap: () => _selectTime(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Center(
                        child: Text(
                          _formatTimeOfDay(_selectedTime), // 24시간 형식으로 표시
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text('Priority', style: TextStyle(fontSize: 16.0)),
                      DropdownButton<String>(
                        value: _priority,
                        onChanged: (String? newValue) {
                          setState(() {
                            _priority = newValue!;
                          });
                        },
                        isExpanded: true, // DropdownButton의 너비를 최대화
                        alignment: Alignment.center, // 텍스트를 가운데 정렬
                        items: <String>['High', 'Medium', 'Low']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Center(child: Text(value)), // 가운데 정렬
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text('Repeat Daily', style: TextStyle(fontSize: 16.0)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Checkbox(
                            value: _isRepeatingDaily,
                            onChanged: (bool? newValue) {
                              setState(() {
                                _isRepeatingDaily = newValue!;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _updateTodo,
          child: Text('Update Todo'),
        ),
      ],
    );
  }
}