import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/payment_model.dart';
import '../../providers/user_provider.dart';
import 'payment_provider.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  final List<PricingPlan> _selectedPlans = [];
  bool _isIndia = true;
  String _currencySymbol = '₹';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(paymentProvider.notifier).loadPlans();
      final country = ref.read(userProvider).profile?.country ?? 'IN';
      _setCountry(country);
    });
  }

  void _setCountry(String country) {
    final countryUpper = country.trim().toUpperCase();
    final isIndia = countryUpper == 'IN' || countryUpper == 'INDIA';
    setState(() {
      _isIndia = isIndia;
      _currencySymbol = isIndia ? '₹' : '\$';
    });
  }

  void _togglePlan(PricingPlan plan) {
    setState(() {
      final idx = _selectedPlans.indexWhere((p) => p.id == plan.id);
      if (idx >= 0) {
        _selectedPlans.removeAt(idx);
      } else {
        _selectedPlans.add(plan);
      }
    });
  }

  bool _isSelected(PricingPlan plan) =>
      _selectedPlans.any((p) => p.id == plan.id);

  void _onContinue() {
    if (_selectedPlans.isEmpty) return;
    context.push('/premium-checkout', extra: {
      'plans': _selectedPlans,
      'isIndia': _isIndia,
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0A3B), Color(0xFF2D1B6B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(child: _buildBody(state)),
              _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          const Text(
            'Choose Your Plan',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(PaymentState state) {
    if (state.status == PaymentStatus.loadingPlans) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final plans = state.plans.isEmpty ? _defaultPlans() : state.plans;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeroSection(),
          const SizedBox(height: 24),
          _buildFeaturesSection(),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Select one or more plans:',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          ...plans.map((plan) => _buildPlanCard(plan)),
          const SizedBox(height: 8),
          const Text(
            'Secure payment via Razorpay',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFFE4B500), Color(0xFFFF8C00)]),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE4B500).withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.star_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 14),
        const Text(
          'Unlock Full Premium Access',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Select the plans you want and continue to checkout',
          style: TextStyle(color: Colors.white60, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      ('All Premium Worksheets', Icons.assignment_rounded),
      ('Unlimited Practice Topics', Icons.school_rounded),
      ('Exclusive Olympiad Content', Icons.emoji_events_rounded),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: features.map((f) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(f.$2, color: const Color(0xFFE4B500), size: 18),
                const SizedBox(width: 10),
                Text(f.$1, style: const TextStyle(color: Colors.white, fontSize: 14)),
                const Spacer(),
                const Icon(Icons.check_circle_rounded, color: Color(0xFF25D366), size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlanCard(PricingPlan plan) {
    final selected = _isSelected(plan);
    final amount = plan.paymentAmountFor(_isIndia);
    final originalAmount = plan.originalAmountFor(_isIndia);
    final hasDiscount = plan.hasDiscount(_isIndia);

    return GestureDetector(
      onTap: () => _togglePlan(plan),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [Color(0xFFE4B500), Color(0xFFFF8C00)])
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFE4B500).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: selected ? Colors.transparent : Colors.white54,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 16, color: Color(0xFFE4B500))
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.description,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    '1 year access',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasDiscount && originalAmount != null)
                  Text(
                    '$_currencySymbol${(originalAmount / 100).toStringAsFixed(0)}',
                    style: TextStyle(
                      color: selected ? Colors.white54 : Colors.white38,
                      fontSize: 13,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: selected ? Colors.white54 : Colors.white38,
                    ),
                  ),
                Text(
                  '$_currencySymbol${(amount / 100).toStringAsFixed(0)}',
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    final hasSelection = _selectedPlans.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A3B),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: hasSelection ? const Color(0xFFE4B500) : Colors.white24,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed: hasSelection ? _onContinue : null,
          child: Text(
            hasSelection
                ? 'Continue (${_selectedPlans.length} plan${_selectedPlans.length > 1 ? 's' : ''} selected)'
                : 'Select a plan to continue',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  List<PricingPlan> _defaultPlans() => [
        PricingPlan(
          id: 'worksheet',
          description: 'Worksheet Subscription',
          priceInPaise: 49900,
          originalPriceInPaise: 59900,
          usdOriginalPrice: 10,
          usdDiscountPrice: 7,
        ),
        PricingPlan(
          id: 'olympiad',
          description: 'Olympiad Prep Classes',
          priceInPaise: 49900,
          usdDiscountPrice: 7,
        ),
      ];
}
