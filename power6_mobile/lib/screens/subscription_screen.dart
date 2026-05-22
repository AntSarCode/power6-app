import 'dart:ui';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_constants.dart';
import '../models/user.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';
import '../services/purchase_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Map<String, ProductDetails> _products = const {};
  bool _storeAvailable = false;
  bool _loadingProducts = false;
  bool _loading = false;
  String? _error;

  bool get _useAppleIap => PurchaseService.isAppleInAppPurchasePlatform;

  @override
  void initState() {
    super.initState();
    if (_useAppleIap) {
      _purchaseSubscription = _purchaseService.purchaseStream.listen(
        _handlePurchaseUpdates,
        onError: (Object error) {
          if (!mounted) return;
          setState(() => _error = error.toString());
        },
      );
      _loadStoreProducts();
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadStoreProducts() async {
    if (!_useAppleIap) return;
    setState(() {
      _loadingProducts = true;
      _error = null;
    });

    final available = await _purchaseService.isAvailable();
    if (!available) {
      if (!mounted) return;
      setState(() {
        _storeAvailable = false;
        _loadingProducts = false;
        _error = 'App Store purchases are not available on this device.';
      });
      return;
    }

    final response = await _purchaseService.loadProducts();
    if (!mounted) return;

    setState(() {
      _storeAvailable = true;
      _loadingProducts = false;
      _products = {
        for (final product in response.productDetails) product.id: product,
      };
      if (response.error != null) {
        _error = response.error!.message;
      } else if (response.notFoundIDs.isNotEmpty) {
        _error =
            'Some App Store products are not configured: ${response.notFoundIDs.join(', ')}';
      }
    });
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        if (mounted) setState(() => _loading = true);
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = purchase.error?.message ?? 'Purchase failed.';
          });
        }
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _activateApplePurchase(purchase);
      }

      if (purchase.pendingCompletePurchase) {
        await _purchaseService.completePurchase(purchase);
      }
    }
  }

  Future<void> _activateApplePurchase(PurchaseDetails purchase) async {
    final productId = purchase.productID;
    final tier = PurchaseService.tierForProductId(productId);
    final token = context.read<AppState>().accessToken ?? '';
    if (tier == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not activate purchase for this account.';
      });
      return;
    }

    final response = await ApiService(ApiConstants.baseUrl).post(
      ApiConstants.appleIapActivate,
      token: token,
      body: {
        'product_id': productId,
        'transaction_id': purchase.purchaseID,
        'purchase_id': purchase.purchaseID,
        'verification_data': purchase.verificationData.serverVerificationData,
        'source': 'ios_app_store',
      },
    );

    if (!mounted) return;

    if (response.isSuccess && response.data != null) {
      context.read<AppState>().setUser(User.fromJson(response.data!));
      setState(() {
        _loading = false;
        _error = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Your ${tier.toUpperCase()} purchase is active.')),
      );
      return;
    }

    setState(() {
      _loading = false;
      _error = response.error ?? 'Purchase completed, but activation failed.';
    });
  }

  Future<void> _startCheckout(
    BuildContext context,
    String tier,
    String interval,
  ) async {
    if (_useAppleIap) {
      await _startApplePurchase(tier, interval);
      return;
    }

    final app = context.read<AppState>();
    final token = app.accessToken ?? '';
    final user = app.user;
    final userId = user?.id.toString() ?? '';
    final messenger = ScaffoldMessenger.of(context);

    if (userId.isEmpty) {
      const msg = 'You must be logged in to upgrade.';
      if (mounted) {
        setState(() => _error = msg);
      }
      messenger.showSnackBar(
        const SnackBar(content: Text(msg)),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      debugPrint(
          'Stripe checkout start -> tier=$tier interval=$interval userId=$userId');

      final api = ApiService(ApiConstants.baseUrl, token);
      final payload = <String, dynamic>{
        'user_id': userId,
        'tier': tier,
        'interval': interval,
      };

      debugPrint('Stripe request payload -> $payload');

      final response = await api.post(
        ApiConstants.stripeCheckout,
        token: token,
        body: payload,
      );

      debugPrint(
          'Stripe response success=${response.isSuccess} data=${response.data} error=${response.error}');

      final data = response.data;
      final dynamic rawUrl =
          data is Map<String, dynamic> ? data['checkout_url'] : null;

      if (!response.isSuccess) {
        final msg = response.error ?? 'Failed to start checkout.';
        throw Exception(msg);
      }

      if (rawUrl is! String || rawUrl.isEmpty) {
        throw Exception('Backend did not return a valid checkout_url.');
      }

      final uri = Uri.tryParse(rawUrl);
      if (uri == null) {
        throw Exception('Checkout URL could not be parsed: $rawUrl');
      }

      debugPrint('Stripe redirect url -> $rawUrl');

      if (kIsWeb) {
        final launched = await launchUrl(uri, webOnlyWindowName: '_self');
        if (!launched) {
          throw Exception('Could not redirect browser to Stripe checkout.');
        }
      } else {
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          throw Exception('Could not open Stripe checkout.');
        }
      }
    } catch (e, st) {
      debugPrint('Stripe checkout error -> $e');
      debugPrintStack(stackTrace: st);
      final msg = e.toString();
      if (mounted) {
        setState(() => _error = msg);
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $msg')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _startApplePurchase(String tier, String interval) async {
    if (!_storeAvailable || _loadingProducts) {
      await _loadStoreProducts();
    }

    final productId = PurchaseService.productIdFor(tier, interval);
    final product = _products[productId];
    if (product == null) {
      setState(() => _error = 'App Store product is not available: $productId');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final started = await _purchaseService.buy(product);
    if (!started && mounted) {
      setState(() {
        _loading = false;
        _error = 'Could not start App Store purchase.';
      });
    }
  }

  ProductDetails? _storeProduct(String tier, String interval) {
    if (!_useAppleIap) return null;
    final productId = PurchaseService.productIdFor(tier, interval);
    return _products[productId];
  }

  String _purchaseLabel(String tier, String interval) {
    final cadence = interval == 'monthly' ? 'Monthly' : 'Yearly';
    if (!_useAppleIap) {
      return interval == 'monthly' ? 'Choose Monthly' : 'Choose Yearly';
    }
    final product = _storeProduct(tier, interval);
    if (product == null) return '$cadence unavailable';
    return '$cadence - ${product.price}';
  }

  VoidCallback? _purchaseAction(
    BuildContext context,
    String tier,
    String interval,
  ) {
    if (_loading || _loadingProducts) return null;
    if (_useAppleIap && _storeProduct(tier, interval) == null) return null;
    return () => _startCheckout(context, tier, interval);
  }

  Future<void> _restorePurchases() async {
    if (!_useAppleIap) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _purchaseService.restorePurchases();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/home');
          },
        ),
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
                  child: Container(
                      color: const Color.fromRGBO(15, 179, 160, 0.32)),
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
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
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
                  if (_useAppleIap)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _loading ? null : _restorePurchases,
                            icon: const Icon(Icons.restore),
                            label: const Text('Restore Purchases'),
                          ),
                          if (_loadingProducts)
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Loading App Store prices...',
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
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
                    monthlyLabel: _purchaseLabel('plus', 'monthly'),
                    yearlyLabel: _purchaseLabel('plus', 'yearly'),
                    onMonthly: _purchaseAction(context, 'plus', 'monthly'),
                    onYearly: _purchaseAction(context, 'plus', 'yearly'),
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
                    monthlyLabel: _purchaseLabel('pro', 'monthly'),
                    yearlyLabel: _purchaseLabel('pro', 'yearly'),
                    onMonthly: _purchaseAction(context, 'pro', 'monthly'),
                    onYearly: _purchaseAction(context, 'pro', 'yearly'),
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
                    monthlyLabel: _purchaseLabel('elite', 'monthly'),
                    yearlyLabel: _purchaseLabel('elite', 'yearly'),
                    onMonthly: _purchaseAction(context, 'elite', 'monthly'),
                    onYearly: _purchaseAction(context, 'elite', 'yearly'),
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
  final String monthlyLabel;
  final String yearlyLabel;
  final VoidCallback? onMonthly;
  final VoidCallback? onYearly;

  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.isCurrent,
    required this.accent,
    required this.monthlyLabel,
    required this.yearlyLabel,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Current',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
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
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle,
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 10),
                    ...bullets.map((b) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 6.0),
                                child: Icon(Icons.circle,
                                    size: 6,
                                    color: Color.fromRGBO(100, 255, 218, 1)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(b,
                                      style: const TextStyle(
                                          color: Colors.white))),
                            ],
                          ),
                        )),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isCurrent ? null : onMonthly,
                            child:
                                Text(isCurrent ? 'Current Plan' : monthlyLabel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isCurrent ? null : onYearly,
                            child: Text(yearlyLabel),
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
