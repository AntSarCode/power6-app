import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _startCheckout(
    BuildContext context,
    String tier,
    String interval,
  ) async {
    final app = context.read<AppState>();
    final token = app.accessToken ?? '';
    final userId = app.user?.id.toString() ?? '';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to upgrade.')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService().post(
        '/stripe/create-checkout-session',
        token: token,
        body: {
          'user_id': userId,
          'tier': tier,
          'interval': interval,
        },
      );

      if (response.isSuccess && response.data != null && response.data?['checkout_url'] != null) {
        final String url = response.data?['checkout_url'] as String;
        final uri = Uri.parse(url);
        final ok = await canLaunchUrl(uri);
        if (ok) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Checkout URL: $url')),
          );
        }
      } else {
        final msg = response.error ?? 'Failed to start checkout (unexpected response).';
        setState(() => _error = msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final currentTier = (app.user?.tier ?? 'free').toString().toLowerCase();
    final displayTier = currentTier.isNotEmpty
        ? '${currentTier[0].toUpperCase()}${currentTier.substring(1)}'
        : 'Free';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Upgrade Your Plan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Unified dark gradient background
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
          // Decorative glow
          Positioned(
            top: -120,
            right: -70,
            child: SizedBox(
              width: 300,
              height: 300,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                  child: Container(color: const Color.fromRGBO(15, 179, 160, 0.32)),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      'Your Current Tier: $displayTier',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 8),

                  _PlanCard(
                    title: 'PLUS',
                    subtitle: 'Access streak tracker and timeline',
                    bullets: const [
                      'Daily streak tracker',
                      'Task timeline view',
                      'Priority badges and glow UI',
                    ],
                    isCurrent: currentTier == 'plus',
                    accent: const Color.fromRGBO(100, 255, 218, 1),
                    onMonthly: _loading ? null : () => _startCheckout(context, 'plus', 'monthly'),
                    onYearly: _loading ? null : () => _startCheckout(context, 'plus', 'yearly'),
                  ),

                  const SizedBox(height: 16),

                  _PlanCard(
                    title: 'PRO',
                    subtitle: 'All Plus features + CSV export',
                    bullets: const [
                      'Everything in Plus',
                      'CSV export & analytics',
                      'Priority support',
                    ],
                    isCurrent: currentTier == 'pro',
                    accent: const Color.fromRGBO(173, 216, 230, 1),
                    onMonthly: _loading ? null : () => _startCheckout(context, 'pro', 'monthly'),
                    onYearly: _loading ? null : () => _startCheckout(context, 'pro', 'yearly'),
                  ),

                  const SizedBox(height: 16),

                  _PlanCard(
                    title: 'ELITE',
                    subtitle: 'Everything Pro offers + group features',
                    bullets: const [
                      'Everything in Pro',
                      'Group budgets & leaderboards',
                      'Early feature access',
                    ],
                    isCurrent: currentTier == 'elite',
                    accent: const Color.fromRGBO(255, 215, 0, 1),
                    onMonthly: _loading ? null : () => _startCheckout(context, 'elite', 'monthly'),
                    onYearly: _loading ? null : () => _startCheckout(context, 'elite', 'yearly'),
                  ),

                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> bullets;
  final bool isCurrent;
  final Color accent;
  final VoidCallback? onMonthly;
  final VoidCallback? onYearly;

  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.isCurrent,
    required this.accent,
    required this.onMonthly,
    required this.onYearly,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(0, 0, 0, 0.35),
            border: Border.all(color: const Color.fromRGBO(0, 150, 136, 0.25)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              if (isCurrent)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Current', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.workspace_premium_outlined, color: accent),
                        const SizedBox(width: 8),
                        Text(title,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 10),
                    ...bullets.map((b) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 6.0),
                                child: Icon(Icons.circle, size: 6, color: Color.fromRGBO(100, 255, 218, 1)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(b, style: const TextStyle(color: Colors.white))),
                            ],
                          ),
                        )),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isCurrent ? null : onMonthly,
                            child: Text(isCurrent ? 'Current Plan' : 'Choose Monthly'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isCurrent ? null : onYearly,
                            child: const Text('Choose Yearly'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}