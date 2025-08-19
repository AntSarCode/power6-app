import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  Future<void> _startCheckout(BuildContext context, String tier) async {
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
        },
      );

      if (response.isSuccess &&
          response.data != null &&
          response.data['checkout_url'] != null) {
        final String url = response.data['checkout_url'] as String;
        // Neutral approach: display checkout URL in snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout URL: $url')),
        );
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

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Your Current Tier: $displayTier',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
        const SizedBox(height: 12),
        _buildPlanCard(context, currentTier, 'plus', 'Access streak tracker and timeline'),
        const SizedBox(height: 16),
        _buildPlanCard(context, currentTier, 'pro', 'All Plus features + CSV export'),
        const SizedBox(height: 16),
        _buildPlanCard(context, currentTier, 'elite', 'Everything Pro offers + group features'),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    String currentTier,
    String planKey,
    String description,
  ) {
    final isCurrent = currentTier == planKey.toLowerCase();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              planKey.toUpperCase(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (isCurrent || _loading)
                  ? null
                  : () => _startCheckout(context, planKey),
              child: Text(isCurrent ? 'Current Plan' : 'Choose Plan'),
            ),
          ],
        ),
      ),
    );
  }
}
