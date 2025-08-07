import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskInputScreen extends StatefulWidget {
  const TaskInputScreen({super.key});

  @override
  State<TaskInputScreen> createState() => _TaskInputScreenState();
}

class _TaskInputScreenState extends State<TaskInputScreen> {
  final TextEditingController _controller = TextEditingController();
  String _priority = 'Normal';
  bool _streakBound = false;
  bool _isSaving = false;
  final List<String> _priorities = ['Low', 'Normal', 'High'];

  void _saveTask() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);

    final newTask = Task(
      id: 0,
      userId: 0,
      title: title,
      notes: '',
      completed: false,
      priority: _priorities.indexOf(_priority),
      streakBound: _streakBound,
      scheduledFor: DateTime.now(),
      completedAt: null,
    );

    await TaskService.addTask(newTask);

    setState(() {
      _isSaving = false;
      _controller.clear();
      _priority = 'Normal';
      _streakBound = false;
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task saved successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a New Task'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Enter your task',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: _priorities.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(priority),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _priority = value!),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Streak Bound'),
                    value: _streakBound,
                    onChanged: (value) => setState(() => _streakBound = value!),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveTask,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save Task',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}