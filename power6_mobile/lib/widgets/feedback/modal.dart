import 'package:flutter/material.dart';

class FeedbackReportDialog extends StatefulWidget {
  final Future<void> Function(FeedbackReportPayload payload) onSubmit;

  const FeedbackReportDialog({
    super.key,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(FeedbackReportPayload payload) onSubmit,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FeedbackReportDialog(onSubmit: onSubmit),
    );
  }

  @override
  State<FeedbackReportDialog> createState() => _FeedbackReportDialogState();
}

class _FeedbackReportDialogState extends State<FeedbackReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _detailsController = TextEditingController();
  final _emailController = TextEditingController();

  FeedbackType _type = FeedbackType.bug;
  FeedbackPriority _priority = FeedbackPriority.medium;
  bool _includeDeviceContext = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _subjectController.dispose();
    _detailsController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final payload = FeedbackReportPayload(
        type: _type,
        priority: _priority,
        subject: _subjectController.text.trim(),
        details: _detailsController.text.trim(),
        contactEmail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        includeDeviceContext: _includeDeviceContext,
        createdAtUtc: DateTime.now().toUtc(),
      );

      await widget.onSubmit(payload);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: const Color(0xFF0E171A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.feedback_outlined, color: Colors.tealAccent, size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Send Feedback / Report a Bug',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use this form to report a bug, suggest a feature, or share general product feedback.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<FeedbackType>(
                          value: _type,
                          dropdownColor: const Color(0xFF132126),
                          decoration: _inputDecoration('Feedback type'),
                          items: FeedbackType.values
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item.label),
                                ),
                              )
                              .toList(),
                          onChanged: _submitting
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _type = value);
                                  }
                                },
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<FeedbackPriority>(
                          value: _priority,
                          dropdownColor: const Color(0xFF132126),
                          decoration: _inputDecoration('Priority'),
                          items: FeedbackPriority.values
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item.label),
                                ),
                              )
                              .toList(),
                          onChanged: _submitting
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _priority = value);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _subjectController,
                    enabled: !_submitting,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Subject'),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Enter a subject';
                      if (text.length < 4) return 'Subject is too short';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _detailsController,
                    enabled: !_submitting,
                    minLines: 5,
                    maxLines: 8,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Describe the issue or feedback'),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Enter some details';
                      if (text.length < 12) return 'Please provide more detail';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    enabled: !_submitting,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Contact email (optional)'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    value: _includeDeviceContext,
                    onChanged: _submitting ? null : (value) => setState(() => _includeDeviceContext = value),
                    contentPadding: EdgeInsets.zero,
                    activeColor: Colors.tealAccent,
                    title: const Text(
                      'Include device/app context',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Helpful for debugging browser, platform, and version-specific issues.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(244, 67, 54, 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color.fromRGBO(244, 67, 54, 0.35)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.2)),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0FB3A0),
                            foregroundColor: Colors.black,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'Submit',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color.fromRGBO(14, 22, 25, 0.9),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color.fromRGBO(0, 150, 136, 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color.fromRGBO(100, 255, 218, 0.9), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
    );
  }
}

enum FeedbackType {
  bug('Bug report'),
  feature('Feature request'),
  general('General feedback');

  const FeedbackType(this.label);
  final String label;
}

enum FeedbackPriority {
  low('Low'),
  medium('Medium'),
  high('High');

  const FeedbackPriority(this.label);
  final String label;
}

class FeedbackReportPayload {
  final FeedbackType type;
  final FeedbackPriority priority;
  final String subject;
  final String details;
  final String? contactEmail;
  final bool includeDeviceContext;
  final DateTime createdAtUtc;

  const FeedbackReportPayload({
    required this.type,
    required this.priority,
    required this.subject,
    required this.details,
    required this.contactEmail,
    required this.includeDeviceContext,
    required this.createdAtUtc,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'priority': priority.name,
      'subject': subject,
      'details': details,
      'contact_email': contactEmail,
      'include_device_context': includeDeviceContext,
      'created_at_utc': createdAtUtc.toIso8601String(),
    };
  }
}


