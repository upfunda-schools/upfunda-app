void openRazorpayCheckout({
  required Map<String, dynamic> options,
  required void Function(String orderId, String paymentId, String signature) onSuccess,
  required void Function(String message) onError,
}) =>
    throw UnsupportedError('openRazorpayCheckout is only available on web');
