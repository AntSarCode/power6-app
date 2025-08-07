import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class SubscriptionScreen extends StatelessWidget {
  final tierOptions = const [
    {'name': 'Free', 'price': '\$0.00'},
    {'name': 'Plus', 'price': '\$3.99'},
    {'name': 'Pro', 'price': '\$9.99'},
    {'name': 'Elite', 'price': '\$19.99'},
    {'name': 'Admin', 'price': 'N/A'},
  ];

  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppState>(context).user;
    final String tier = user?.tier ?? 'free';
    final bool isPro = tier == 'pro' || tier == 'elite' || tier == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Tiers')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text("Your Current Tier: \$tier", style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          ...tierOptions.map((tierOption) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(
                    tierOption['name']!,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    tierOption['price']!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              )),
          const SizedBox(height: 20),
          if (!isPro)
            ElevatedButton(
              onPressed: () {
                // TODO: Hook to Stripe checkout logic
              },
              child: const Text('Upgrade to Pro'),
            )
          else
            const Text("You are already a Pro user 🎉"),
        ],
      ),
    );
  }
}