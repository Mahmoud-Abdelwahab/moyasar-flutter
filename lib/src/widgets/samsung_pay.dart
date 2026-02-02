import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moyasar/moyasar.dart';

/// The widget that shows the Samsung Pay button.
class SamsungPay extends StatefulWidget {
  SamsungPay({
    super.key,
    required this.config,
    required this.onPaymentResult,
  }) : assert(config.samsungPay != null,
            "Please add samsungPayConfig when instantiating the paymentConfig.");

  final PaymentConfig config;
  final Function onPaymentResult;
  final MethodChannel channel =
      const MethodChannel('flutter.moyasar.com/samsung_pay');

  @override
  State<SamsungPay> createState() => _SamsungPayState();
}

class _SamsungPayState extends State<SamsungPay> {
  bool isSamsungPayAvailable = false;
  bool isCheckingAvailability = true;

  @override
  void initState() {
    super.initState();
    _checkSamsungPayAvailability();
  }

  void _checkSamsungPayAvailability() {
    widget.channel
        .invokeMethod<bool>("isSamsungPayAvailable")
        .then((isAvailable) {
      setState(() {
        isSamsungPayAvailable = isAvailable ?? false;
        isCheckingAvailability = false;
      });
    }).catchError((error) {
      debugPrint("Samsung Pay availability check failed: $error");
      setState(() {
        isSamsungPayAvailable = false;
        isCheckingAvailability = false;
      });
    });
  }

  void onSamsungPayError() {
    widget.onPaymentResult(PaymentCanceledError());
  }

  void onSamsungPayResult(paymentResult) async {
    final token = paymentResult['token'];

    if (((token ?? '') == '')) {
      widget.onPaymentResult(UnprocessableTokenError());
      return;
    }

    final source = SamsungPayPaymentRequestSource(
        token, widget.config.samsungPay!.manual, widget.config.samsungPay!.saveCard);
    final paymentRequest = PaymentRequest(widget.config, source);

    final result = await Moyasar.pay(
        apiKey: widget.config.publishableApiKey,
        paymentRequest: paymentRequest);

    widget.onPaymentResult(result);
  }

  void _initiateSamsungPay() {
    final config = {
      "merchantId": widget.config.samsungPay?.merchantId,
      "label": widget.config.samsungPay?.label,
      "amount": (widget.config.amount / 100).toStringAsFixed(2),
      "currencyCode": widget.config.samsungPay?.currencyCode ?? "SAR",
      "countryCode": widget.config.samsungPay?.countryCode ?? "SA",
    };

    widget.channel.setMethodCallHandler((call) async {
      if (call.method == 'onSamsungPayResult') {
        onSamsungPayResult(call.arguments);
      } else if (call.method == 'onSamsungPayError') {
        onSamsungPayError();
      }
    });

    widget.channel.invokeMethod("presentSamsungPay", config);
  }

  @override
  Widget build(BuildContext context) {
    if (isCheckingAvailability) {
      return const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!isSamsungPayAvailable) {
      return const SizedBox.shrink();
    }

    return Container(
      width: MediaQuery.of(context).size.width,
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: _initiateSamsungPay,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Samsung Pay',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
