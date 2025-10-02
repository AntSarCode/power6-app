import 'dart:ui';
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
  final List<String> _priorities = ['Low', 'Normal', 'High'];
  String _priority = 'Normal';
  bool _streakBound = false;
  bool _isSaving = false;
  String? _error;

  Future<void> _saveTask() async {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Please enter a task');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

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

    try {
      await TaskService.addTask(newTask);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task "$title" saved successfully!')),
      );
      setState(() {
        _isSaving = false;
        _controller.clear();
        _priority = 'Normal';
        _streakBound = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save task: $e')),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Create a New Task'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Unified dark gradient background (same as other screens)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A0F12),
                  Color.fromRGBO(15, 31, 36, 0.95),
                  Color(0xFF0A0F12),
                ],
              ),
            ),
          ),

          // Decorative teal glow
          Positioned(
            top: -110,
            right: -60,
            child: SizedBox(
              width: 280,
              height: 280,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                  child: Container(color: const Color.fromRGBO(15, 179, 160, 0.32)),
                ),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 32, maxWidth: 800),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(0, 0, 0, 0.35),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color.fromRGBO(0, 150, 136, 0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.add_task_rounded, color: Colors.tealAccent),
                                  const SizedBox(width: 8),
                                  Text('New Task', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Keep it simple: up to six tasks. Prioritize, toggle streak binding, and save.',
                                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 16),

                              // Task title
                              TextField(
                                controller: _controller,
                                style: const TextStyle(color: Colors.white),
                                maxLines: 3,
                                decoration: _inputDecoration(
                                  hint: 'Enter your task',
                                  icon: Icons.edit_outlined,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Priority segmented chips
                              Text('Priority', style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: _priorities.map((p) {
                                  final selected = _priority == p;
                                  return ChoiceChip(
                                    label: Text(p),
                                    selected: selected,
                                    onSelected: (_) => setState(() => _priority = p),
                                    labelStyle: TextStyle(
                                      color: selected ? Colors.black : Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    selectedColor: const Color.fromRGBO(100, 255, 218, 0.9),
                                    backgroundColor: const Color.fromRGBO(255, 255, 255, 0.08),
                                    shape: StadiumBorder(side: BorderSide(color: selected ? const Color.fromRGBO(100, 255, 218, 0.9) : const Color.fromRGBO(255, 255, 255, 0.12))),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 16),

                              // Streak bound switch tile
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(255, 255, 255, 0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color.fromRGBO(0, 150, 136, 0.25)),
                                ),
                                child: SwitchListTile.adaptive(
                                  title: const Text('Streak Bound', style: TextStyle(color: Colors.white)),
                                  subtitle: const Text('Counts toward your daily 6 for streaks', style: TextStyle(color: Colors.white70)),
                                  value: _streakBound,
                                  onChanged: (v) => setState(() => _streakBound = v),
                                  activeColor: Colors.black,
                                  activeTrackColor: const Color.fromRGBO(100, 255, 218, 0.9),
                                ),
                              ),

                              if (_error != null) ...[
                                const SizedBox(height: 10),
                                Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                              ],

                              const SizedBox(height: 20),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveTask,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    child: _isSaving
                                        ? const SizedBox(
                                            key: ValueKey('loading'),
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                          )
                                        : const Text(
                                            key: ValueKey('text'),
                                            'Save Task',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.teal.shade200),
      filled: true,
      isDense: true,
      fillColor: const Color.fromRGBO(14, 22, 25, 0.9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: const TextStyle(color: Colors.white54),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color.fromRGBO(0, 150, 136, 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color.fromRGBO(100, 255, 218, 0.9), width: 1.2),
      ),
    );
  }
}
