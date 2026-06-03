// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop_unsafe';

@JS()
external JSObject get globalThis;

void openRazorpayCheckout({
  required Map<String, dynamic> options,
  required void Function(String orderId, String paymentId, String signature) onSuccess,
  required void Function(String message) onError,
}) {
  final opts = JSObject();
  opts.setProperty('key'.toJS, (options['key'] as String).toJS);
  opts.setProperty('amount'.toJS, (options['amount'] as int).toJS);
  opts.setProperty('currency'.toJS, (options['currency'] as String).toJS);
  opts.setProperty('order_id'.toJS, (options['order_id'] as String).toJS);
  opts.setProperty('name'.toJS, (options['name'] as String).toJS);
  opts.setProperty('description'.toJS, (options['description'] as String).toJS);

  // Theme
  final theme = JSObject();
  final themeMap = options['theme'] as Map<String, dynamic>? ?? {};
  theme.setProperty('color'.toJS, (themeMap['color'] as String? ?? '#6C5CE7').toJS);
  opts.setProperty('theme'.toJS, theme);

  // Prefill
  final prefill = JSObject();
  final prefillMap = options['prefill'] as Map<String, dynamic>? ?? {};
  prefill.setProperty('contact'.toJS, (prefillMap['contact'] as String? ?? '').toJS);
  prefill.setProperty('email'.toJS, (prefillMap['email'] as String? ?? '').toJS);
  opts.setProperty('prefill'.toJS, prefill);

  // Payment success handler
  void handlePayment(JSAny? resp) {
    if (resp == null) return;
    final r = resp as JSObject;
    final orderId = (r.getProperty('razorpay_order_id'.toJS) as JSString?)?.toDart ?? '';
    final paymentId = (r.getProperty('razorpay_payment_id'.toJS) as JSString?)?.toDart ?? '';
    final signature = (r.getProperty('razorpay_signature'.toJS) as JSString?)?.toDart ?? '';
    onSuccess(orderId, paymentId, signature);
  }
  opts.setProperty('handler'.toJS, handlePayment.toJS);

  // Modal dismiss handler
  final modal = JSObject();
  void handleDismiss() => onError('Payment cancelled');
  modal.setProperty('ondismiss'.toJS, handleDismiss.toJS);
  opts.setProperty('modal'.toJS, modal);

  // Create Razorpay instance and open checkout
  final rzpConstructor = globalThis.getProperty('Razorpay'.toJS) as JSFunction;
  final rzp = rzpConstructor.callAsConstructor<JSObject>(opts);
  rzp.callMethod('open'.toJS);
}
