import 'package:flutter/material.dart';

/// Badge view model used by the screen regardless of backend shape.
class BadgeVM {
  final String title;
  final String description;
  final String icon; // file name like 'starter.png'
  BadgeVM({required this.title, required this.description, required this.icon});

  factory BadgeVM.fromDynamic(dynamic b) {
    try {
      // Try typed properties first
      final t = (b.title ?? b['title']).toString();
      final d = (b.description ?? b['description']).toString();
      final i = ((b.iconUri ?? b.icon_uri ?? b['icon_uri'] ?? b['icon']).toString());
      return BadgeVM(title: t, description: d, icon: i);
    } catch (_) {
      return BadgeVM(title: b['title']?.toString() ?? '', description: b['description']?.toString() ?? '', icon: b['icon_uri']?.toString() ?? '');
    }
  }
}

class BadgeScreen extends StatefulWidget {
  const BadgeScreen({super.key});
  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> {
  late Future<List<BadgeVM>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadBadges();
  }

  Future<List<BadgeVM>> _loadBadges() async {
    // For now, load from local seed. TODO: wire backend BadgeService once available.
    const local = [
      {'title': 'Starter', 'description': 'Complete your first task', 'icon_uri': 'starter.png'},
      {'title': 'Disciplined', 'description': 'Complete tasks 5 days in a row', 'icon_uri': 'disciplined.png'},
      {'title': 'Night Owl', 'description': 'Finish a task after midnight', 'icon_uri': 'night_owl.png'},
      {'title': 'Early Bird', 'description': 'Finish a task before 7am', 'icon_uri': 'early_bird.png'},
      {'title': 'Weekend Warrior', 'description': 'Complete a task on the weekend', 'icon_uri': 'weekend_warrior.png'},
      {'title': 'Veteran', 'description': 'Complete 100 tasks', 'icon_uri': 'veteran.png'},
      {'title': 'Overachiever', 'description': 'Complete 500 tasks', 'icon_uri': 'overachiever.png'},
      {'title': 'Task Master', 'description': 'Complete 1000 tasks', 'icon_uri': 'task_master.png'},
      {'title': 'Social Butterfly', 'description': 'Share a task on social media', 'icon_uri': 'social_butterfly.png'},
      {'title': 'Feedback Guru', 'description': 'Give feedback on 10 tasks', 'icon_uri': 'feedback_guru.png'},
      {'title': 'Goal Getter', 'description': 'Set and achieve 5 goals', 'icon_uri': 'goal_getter.png'},
      {'title': 'Community Builder', 'description': 'Invite 10 friends to join', 'icon_uri': 'community_builder.png'},
      {'title': 'Challenge Champion', 'description': 'Complete 5 weekly challenges', 'icon_uri': 'challenge_champion.png'},
      {'title': 'Devout', 'description': 'Complete tasks for 30 days straight', 'icon_uri': 'devout.png'},
      {'title': 'Feedback Fanatic', 'description': 'Receive feedback on 20 tasks', 'icon_uri': 'feedback_fanatic.png'},
    ];
    return local.map(BadgeVM.fromDynamic).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Your Badges')),
      backgroundColor: cs.surface,
      body: FutureBuilder<List<BadgeVM>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load badges. Please try again later.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface)),
              ),
            );
          }
          final items = snap.data ?? const <BadgeVM>[];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // How it works
                _BadgesHowItWorks(),
                const SizedBox(height: 16),

                // Grid of badges
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final b = items[i];
                    return _BadgeTile(vm: b);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeVM vm;
  const _BadgeTile({required this.vm});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Try asset first, otherwise allow network if your backend serves icons
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/badges/${vm.icon}',
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) {
                    return Icon(Icons.emoji_events, size: 40, color: cs.onSurface.withValues(alpha: 0.6));
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(vm.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              vm.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.75)),
            )
          ],
        ),
      ),
    );
  }
}

class _BadgesHowItWorks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_outlined),
                const SizedBox(width: 8),
                Text('Badges', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Earn badges by completing tasks consistently and hitting key milestones. Each badge has a unique condition—tap a badge to learn more.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}