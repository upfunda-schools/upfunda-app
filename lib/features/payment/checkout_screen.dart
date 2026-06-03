import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/payment_model.dart';
import '../../providers/user_provider.dart';
import 'payment_provider.dart';
import 'razorpay_web_impl.dart' if (dart.library.io) 'razorpay_web_stub.dart' as rzp_web;

class CheckoutScreen extends ConsumerStatefulWidget {
  final List<PricingPlan> selectedPlans;
  final bool isIndia;

  const CheckoutScreen({
    super.key,
    required this.selectedPlans,
    required this.isIndia,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  Razorpay? _razorpay;
  final _couponController = TextEditingController();

  bool get _isIndia => widget.isIndia;
  String get _currencySymbol => _isIndia ? '₹' : '\$';
  String get _country => _isIndia ? 'IN' : 'US';

  // Whether the worksheet plan is in the selection (coupons only apply to it)
  bool get _hasWorksheetPlan => widget.selectedPlans
      .any((p) => p.description.toLowerCase().contains('worksheet'));

  int get _totalPrice => widget.selectedPlans
      .fold(0, (sum, p) => sum + p.paymentAmountFor(_isIndia));

  int get _worksheetPrice {
    final wp = widget.selectedPlans
        .where((p) => p.description.toLowerCase().contains('worksheet'))
        .fold(0, (sum, p) => sum + p.paymentAmountFor(_isIndia));
    return wp;
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    }
    Future.microtask(_calculatePrice);
  }

  @override
  void dispose() {
    _razorpay?.clear();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _calculatePrice({String? couponCode}) async {
    await ref.read(paymentProvider.notifier).calculatePrice(
          price: _totalPrice,
          discountablePrice: _worksheetPrice,
          country: _country,
          couponCode: couponCode,
        );
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    if (!_hasWorksheetPlan) {
      _showSnackBar('Coupons can only be applied to Worksheet Subscriptions', isError: true);
      return;
    }
    final ok = await ref.read(paymentProvider.notifier).validateAndApplyCoupon(
          code: code,
          price: _totalPrice,
          discountablePrice: _worksheetPrice,
          country: _country,
        );
    if (ok && mounted) {
      _showSnackBar('Coupon applied!');
      _couponController.clear();
    }
  }

  void _removeCoupon() {
    ref.read(paymentProvider.notifier).clearCoupon();
    _couponController.clear();
    _calculatePrice();
  }

  Future<void> _onPayNow() async {
    final payState = ref.read(paymentProvider);

    // Send original plan price — backend re-applies coupon and calculates final amount itself.
    // Sending the already-discounted finalAmount causes backend to treat coupon as 100% discount.
    final order = await ref.read(paymentProvider.notifier).createOrder(
          price: _totalPrice,
          discountablePrice: _worksheetPrice,
          country: _country,
          couponCode: payState.couponValid ? payState.couponCode : null,
        );
    if (!mounted || order == null) return;

    // 100% discount: backend already activated premium, skip Razorpay
    if (order.amount == 0) {
      await ref.read(userProvider.notifier).loadProfile();
      if (mounted) _showSuccessDialog();
      return;
    }

    // Use key from the order response (not from env)
    final key = order.key;
    if (key.isEmpty) {
      _showSnackBar('Payment not configured. Please contact support.', isError: true);
      return;
    }

    final profile = ref.read(userProvider).profile;
    final options = {
      'key': key,
      'amount': order.amount,
      'currency': order.currency,
      'order_id': order.razorpayOrderId,
      'name': 'Upfunda Premium',
      'description': widget.selectedPlans.map((p) => p.description).join(' + '),
      'prefill': {
        'contact': profile?.phone ?? '',
        'email': profile?.email ?? '',
      },
      'theme': {'color': '#6C5CE7'},
    };

    if (kIsWeb) {
      rzp_web.openRazorpayCheckout(
        options: options,
        onSuccess: (orderId, paymentId, signature) async {
          final ok = await ref.read(paymentProvider.notifier).verifyPayment(
                razorpayOrderId: orderId,
                razorpayPaymentId: paymentId,
                razorpaySignature: signature,
              );
          if (mounted && ok) _showSuccessDialog();
        },
        onError: (msg) {
          if (mounted) _showSnackBar(msg, isError: true);
        },
      );
    } else {
      try {
        _razorpay!.open(options);
      } catch (e) {
        if (!mounted) return;
        _showSnackBar('Payment error: ${e.toString()}', isError: true);
      }
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    final orderId = ref.read(paymentProvider).currentOrder?.razorpayOrderId ?? '';
    final success = await ref.read(paymentProvider.notifier).verifyPayment(
          razorpayOrderId: orderId,
          razorpayPaymentId: response.paymentId ?? '',
          razorpaySignature: response.signature ?? '',
        );
    if (!mounted) return;
    if (success) _showSuccessDialog();
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    _showSnackBar('Payment failed: ${response.message ?? 'Unknown error'}', isError: true);
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    _showSnackBar('External wallet: ${response.walletName}');
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFE4B500), size: 64),
            const SizedBox(height: 16),
            const Text(
              'Welcome to Premium!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'You now have access to all premium content.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/student-home');
                },
                child: const Text('Start Learning', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.incorrect : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentProvider);
    final pricing = state.priceBreakdown;
    final isCalculating = state.status == PaymentStatus.calculatingPrice;
    final isProcessing = state.status == PaymentStatus.creatingOrder ||
        state.status == PaymentStatus.processingPayment;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Order Review',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected plans
            _buildSelectedPlans(),
            const SizedBox(height: 16),

            // Coupon section
            _buildCouponSection(state),
            const SizedBox(height: 16),

            // Bill details
            _buildBillDetails(pricing, isCalculating),
            const SizedBox(height: 24),

            // Error
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            // Pay button
            _buildPayButton(pricing, isProcessing, isCalculating),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'For assistance: contact.upfunda@gmail.com',
                style: TextStyle(color: Colors.grey, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.selectedPlans.length} item${widget.selectedPlans.length > 1 ? 's' : ''}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 8),
        ...widget.selectedPlans.map((plan) {
          final amount = plan.paymentAmountFor(_isIndia);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: const Border(left: BorderSide(color: Color(0xFFE91E8C), width: 4)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.description,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const Text('1 year access',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  '$_currencySymbol${(amount / 100).toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCouponSection(PaymentState state) {
    final couponApplied = state.couponValid && state.couponCode != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: couponApplied ? Colors.green.shade300 : Colors.grey.shade200,
          style: BorderStyle.solid,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_hasWorksheetPlan)
            Row(
              children: [
                Icon(Icons.local_offer_outlined, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Coupons are only valid for Worksheet Subscription plans.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ),
              ],
            )
          else if (couponApplied)
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Coupon "${state.couponCode}" applied',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                ),
                GestureDetector(
                  onTap: _removeCoupon,
                  child: const Text('Remove',
                      style: TextStyle(color: Colors.red, fontSize: 13)),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE91E8C)),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                      prefixIcon:
                          const Icon(Icons.local_offer_outlined, size: 18, color: Colors.grey),
                    ),
                    onSubmitted: (_) => _applyCoupon(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E8C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: _applyCoupon,
                  child: const Text('Apply', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBillDetails(CalculatePriceResponse? pricing, bool isCalculating) {
    final baseAmount = pricing?.baseAmount ?? _totalPrice;
    final discountAmount = pricing?.discountAmount ?? 0;
    final amountAfterDiscount = pricing?.amountAfterDiscount ?? (baseAmount - discountAmount);
    final gstPct = pricing?.gstPercentage ?? 0;
    final gstAmount = pricing?.gstAmount ?? 0;
    final finalAmount = pricing?.finalAmount ?? baseAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bill Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 14),
          if (isCalculating)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            _billRow('Base Price', '$_currencySymbol${(baseAmount / 100).toStringAsFixed(0)}'),
            if (discountAmount > 0) ...[
              _billRow(
                'Discount',
                '-$_currencySymbol${(discountAmount / 100).toStringAsFixed(0)}',
                valueColor: Colors.green,
              ),
              _billRow(
                'Subtotal',
                '$_currencySymbol${(amountAfterDiscount / 100).toStringAsFixed(0)}',
              ),
            ],
            if (gstAmount > 0)
              _billRow(
                'GST ($gstPct%)',
                '+$_currencySymbol${(gstAmount / 100).toStringAsFixed(2)}',
              ),
            Divider(color: Colors.grey.shade200, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  '$_currencySymbol${(finalAmount / 100).toStringAsFixed(2)} ${pricing?.currency ?? (_isIndia ? 'INR' : 'USD')}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _billRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  color: valueColor ?? Colors.black87,
                  fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildPayButton(
      CalculatePriceResponse? pricing, bool isProcessing, bool isCalculating) {
    final finalAmount = pricing?.finalAmount ?? _totalPrice;
    final label =
        'Pay $_currencySymbol${(finalAmount / 100).toStringAsFixed(2)} Now';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE91E8C),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: (isProcessing || isCalculating) ? null : _onPayNow,
        child: isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
