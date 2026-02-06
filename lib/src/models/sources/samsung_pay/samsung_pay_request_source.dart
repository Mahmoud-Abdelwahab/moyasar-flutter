import 'package:moyasar/src/models/payment_type.dart';
import 'package:moyasar/src/models/sources/payment_request_source.dart';

/// Required data to setup a Samsung Pay payment.
///
/// Matches the React Native SDK - sends token and manual to Moyasar API.
class SamsungPayPaymentRequestSource implements PaymentRequestSource {
  @override
  PaymentType type = PaymentType.samsungpay;

  final String samsungPayToken;
  final String manualPayment;

  SamsungPayPaymentRequestSource({
    required this.samsungPayToken,
    bool manualPayment = false,
  }) : manualPayment = manualPayment ? 'true' : 'false';

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'token': samsungPayToken,
        'manual': manualPayment,
      };
}
