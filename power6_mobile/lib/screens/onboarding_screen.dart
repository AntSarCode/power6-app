import 'package:flutter/material.dart';

import '../ui/launch_ui.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: LaunchBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Spacer(),
                Icon(Icons.bolt_rounded, size: 56, color: cs.secondary),
                const SizedBox(height: 16),
                Text(
                  'Your first Power6 day',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Pick six meaningful tasks, finish what matters, and let the streak build from real progress.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                const GlassPanel(
                  child: Column(
                    children: <Widget>[
                      _Step(icon: Icons.looks_one_outlined, text: 'Add up to six focus tasks.'),
                      _Step(icon: Icons.done_all_outlined, text: 'Complete the next task before chasing more.'),
                      _Step(icon: Icons.local_fire_department_outlined, text: 'Finish streak-bound work to build momentum.'),
                    ],
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Start planning'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Step({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Icon(icon, color: cs.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
