import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as html;
import '../state/app_state.dart';
import '../services/api_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _loading = false;

  Future<void> _startCheckout(BuildContext context, String tier) async {
    final token = context.read<AppState>().accessToken ?? '';
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to upgrade.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await ApiService().post(
        '/stripe/checkout',
        token: token,
        body: { 'tier': tier },
      );

      if (response.isSuccess && response.data != null && response.data['checkout_url'] != null) {
        final url = response.data['checkout_url'] as String;
        // Open Stripe checkout in a new tab (web)
        html.window.open(url, '_blank');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error ?? 'Failed to start checkout.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unexpected error starting checkout.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final currentTier = user?.tier ?? 'free';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade Plan'),
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
                  Text(
                    'Your Current Tier: $currentTier',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildPlanCard(context, 'plus', 'Access streak tracker and timeline'),
                  const SizedBox(height: 16),
                  _buildPlanCard(context, 'pro', 'All Plus features + CSV export'),
                  const SizedBox(height: 16),
                  _buildPlanCard(context, 'elite', 'Everything Pro offers + group features'),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, String tier, String description) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tier.toUpperCase(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : () => _startCheckout(context, tier),
              child: const Text('Choose Plan'),
            )
          ],
        ),
      ),
    );
  }
}