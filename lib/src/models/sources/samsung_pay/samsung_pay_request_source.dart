import 'package:moyasar/src/models/payment_type.dart';
import 'package:moyasar/src/models/sources/payment_request_source.dart';

/// Required data to setup a Samsung Pay payment.
///
/// Use only when you need to customize the UI.
class SamsungPayPaymentRequestSource implements PaymentRequestSource {
  @override
  PaymentType type = PaymentType.samsungpay;

  late String token;
  late String manual;
  late String saveCard;

  SamsungPayPaymentRequestSource(
      this.token, bool manualPayment, bool shouldSaveCard) {
    manual = manualPayment ? 'true' : 'false';
    saveCard = shouldSaveCard ? 'true' : 'false';
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'token': token,
        'manual': manual,
        'save_card': saveCard
      };
}
