import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moyasar/moyasar.dart';
import 'package:moyasar/src/utils/card_utils.dart';
import 'package:moyasar/src/utils/input_formatters.dart';
import 'package:moyasar/src/utils/card_network_utils.dart';
import 'package:moyasar/src/widgets/network_icons.dart';
import 'package:moyasar/src/widgets/three_d_s_webview.dart';
import 'package:moyasar/src/models/payment_config.dart';

/// The widget that shows the Credit Card form and manages the 3DS step.
class CreditCard extends StatefulWidget {
  CreditCard(
      {super.key,
      required this.config,
      required this.onPaymentResult,
      this.locale = const Localization.en()})
      : textDirection =
            locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;

  final Function onPaymentResult;
  final PaymentConfig config;
  final Localization locale;
  final TextDirection textDirection;

  @override
  State<CreditCard> createState() => _CreditCardState();
}

class _CreditCardState extends State<CreditCard> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final _cardData = CardFormModel();

  AutovalidateMode _autoValidateMode = AutovalidateMode.onUserInteraction;

  bool _isSubmitting = false;
  bool _tokenizeCard = false;
  bool _manualPayment = false;

  // Network detection state
  CardNetwork? _detectedNetwork;
  bool _unsupportedNetwork = false;
  String _cardNumber = '';

  // Error state for each field
  String? _nameError;
  String? _cardNumberError;
  String? _expiryError;
  String? _cvcError;

  // Track if fields have been filled
  bool _nameFieldFilled = false;
  bool _cardNumberFieldFilled = false;
  bool _expiryFieldFilled = false;
  bool _cvcFieldFilled = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      _tokenizeCard = widget.config.creditCard?.saveCard ?? false;
      _manualPayment = widget.config.creditCard?.manual ?? false;
    });
  }

  // Check if button should be enabled
  bool get _isButtonEnabled {
    // Check if all fields are filled and there are no errors
    bool allFieldsFilled = _nameFieldFilled &&
        _cardNumberFieldFilled &&
        _expiryFieldFilled &&
        _cvcFieldFilled;

    bool noErrors = _nameError == null &&
        _cardNumberError == null &&
        _expiryError == null &&
        _cvcError == null;

    return allFieldsFilled && noErrors && !_isSubmitting;
  }

  void _saveForm() async {
    if (!_isButtonEnabled) return;

    closeKeyboard();

    bool isValidForm =
        _formKey.currentState != null && _formKey.currentState!.validate();

    if (!isValidForm) {
      setState(() => _autoValidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    _formKey.currentState?.save();

    final source = CardPaymentRequestSource(
        creditCardData: _cardData,
        tokenizeCard: _tokenizeCard,
        manualPayment: _manualPayment);
    final paymentRequest = PaymentRequest(widget.config, source);

    setState(() => _isSubmitting = true);

    final result = await Moyasar.pay(
        apiKey: widget.config.publishableApiKey,
        paymentRequest: paymentRequest);

    setState(() => _isSubmitting = false);

    if (result is! PaymentResponse ||
        result.status != PaymentStatus.initiated) {
      widget.onPaymentResult(result);
      return;
    }

    final String transactionUrl =
        (result.source as CardPaymentResponseSource).transactionUrl;

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            maintainState: false,
            builder: (context) => ThreeDSWebView(
                transactionUrl: transactionUrl,
                on3dsDone: (String status, String message) async {
                  if (status == PaymentStatus.paid.name) {
                    result.status = PaymentStatus.paid;
                  } else if (status == PaymentStatus.authorized.name) {
                    result.status = PaymentStatus.authorized;
                  } else {
                    result.status = PaymentStatus.failed;
                    (result.source as CardPaymentResponseSource).message =
                        message;
                  }
                  Navigator.pop(context);
                  widget.onPaymentResult(result);
                })),
      );
    }
  }

  // Validate name on change
  void _validateName(String? value) {
    setState(() {
      _nameError = CardUtils.validateName(value, widget.locale);
      _nameFieldFilled = value != null && value.trim().isNotEmpty;
    });
  }

  // Validate card number on change
  void _validateCardNumber(String? value) {
    setState(() {
      _cardNumberError = CardUtils.validateCardNum(value, widget.locale);
      _cardNumberFieldFilled =
          value != null && value.replaceAll(' ', '').length >= 13;
      
      // Network detection logic
      if (value != null && value.isNotEmpty) {
        final cleaned = value.replaceAll(RegExp(r'\D'), '');
        final detected = detectNetwork(cleaned);
        
        // Only update detected network if we have a valid detection
        if (detected != CardNetwork.unknown) {
          _detectedNetwork = detected;
        } else if (cleaned.isEmpty) {
          // Reset only if the field is completely empty
          _detectedNetwork = null;
        }
        
        // Update unsupported network flag
        _unsupportedNetwork = false;
        if (_detectedNetwork != null) {
          final supported = widget.config.supportedNetworks.map((e) => e.name).toSet();
          final detectedName = _detectedNetwork!.name;
          if (!supported.contains(detectedName)) {
            _unsupportedNetwork = true;
            _cardNumberError = 'Unsupported network';
          }
        }
      } else {
        _detectedNetwork = null;
        _unsupportedNetwork = false;
      }
    });
  }

  // Validate expiry date on change
  void _validateExpiry(String? value) {
    setState(() {
      final cleanValue = value?.replaceAll('\u200E', '') ?? '';
      _expiryError = CardUtils.validateDate(cleanValue, widget.locale);
      _expiryFieldFilled = cleanValue.length >= 5; // MM/YY format
    });
  }

  // Validate CVC on change
  void _validateCVC(String? value) {
    setState(() {
      _cvcError = CardUtils.validateCVC(value, widget.locale);
      _cvcFieldFilled = value != null && value.length >= 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      autovalidateMode: _autoValidateMode,
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_nameError ?? widget.locale.nameOnCard,
              style: TextStyle(
                fontSize: 16,
                color: _nameError != null ? Colors.red : Colors.black,
              )),
          SizedBox(
            height: 8,
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            child: CardFormField(
              inputDecoration: buildInputDecoration(
                  hintText: widget.locale.nameOnCard,
                  hideBorder: true,
                  hintTextDirection: widget.textDirection),
              keyboardType: TextInputType.text,
              onChanged: _validateName,
              onSaved: (value) => _cardData.name = value ?? '',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-zA-Z. ]')),
              ],
            ),
          ),
          SizedBox(
            height: 30,
          ),
          Text(
              _cardNumberError ??
                  _expiryError ??
                  _cvcError ??
                  widget.locale.cardInformation,
              style: TextStyle(
                fontSize: 16,
                color: (_cardNumberError != null ||
                        _expiryError != null ||
                        _cvcError != null)
                    ? Colors.red
                    : Colors.black,
              )),
          SizedBox(
            height: 8,
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardFormField(
                  inputDecoration: buildInputDecoration(
                      hintText: widget.locale.cardNumber,
                      hintTextDirection: widget.textDirection,
                      hideBorder: true,
                      addNetworkIcons: true,
                      config: widget.config,
                      detectedNetwork: _detectedNetwork,
                      unsupportedNetwork: _unsupportedNetwork),
                  onChanged: _validateCardNumber,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    CardNumberInputFormatter(),
                  ],
                  onSaved: (value) =>
                      _cardData.number = CardUtils.getCleanedNumber(value!),
                ),
                const Divider(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CardFormField(
                            inputDecoration: buildInputDecoration(
                              hintText: '${widget.locale.expiry} (MM / YY)',
                              hintTextDirection: widget.textDirection,
                              hideBorder: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                              CardMonthInputFormatter(),
                            ],
                            onChanged: _validateExpiry,
                            onSaved: (value) {
                              List<String> expireDate = CardUtils.getExpiryDate(
                                  value!.replaceAll('\u200E', ''));
                              _cardData.month =
                                  expireDate.first.replaceAll('\u200E', '');
                              _cardData.year =
                                  expireDate[1].replaceAll('\u200E', '');
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: VerticalDivider(
                        color: Colors.grey,
                        thickness: 1,
                        width: 2,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CardFormField(
                            inputDecoration: buildInputDecoration(
                              hintText: widget.locale.cvc,
                              hintTextDirection: widget.textDirection,
                              hideBorder: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            onChanged: _validateCVC,
                            onSaved: (value) => _cardData.cvc = value ?? '',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 8,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              child: ElevatedButton(
                style: ButtonStyle(
                  minimumSize:
                      const WidgetStatePropertyAll<Size>(Size.fromHeight(55)),
                  backgroundColor: WidgetStatePropertyAll<Color>(
                    _isButtonEnabled ? blueColor : lightBlueColor,
                  ),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                onPressed: _isButtonEnabled ? _saveForm : null,
                child: _isSubmitting
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Spacer(),
                          Text(
                            '${widget.locale.pay} ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textDirection: widget.textDirection,
                          ),
                          SizedBox(
                              width: 16,
                              child: Image.asset(
                                'assets/images/saudiriyal.png',
                                color: Colors.white, // Tint color
                                package: 'moyasar',
                              )),
                          const SizedBox(width: 4),
                          Text(
                            getAmount(widget.config.amount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textDirection: widget.textDirection,
                          ),
                          Spacer(),
                        ],
                      ),
              ),
            ),
          ),
          SaveCardNotice(tokenizeCard: _tokenizeCard, locale: widget.locale),
        ],
      ),
    );
  }
}

class SaveCardNotice extends StatelessWidget {
  const SaveCardNotice(
      {super.key, required this.tokenizeCard, required this.locale});

  final bool tokenizeCard;
  final Localization locale;

  @override
  Widget build(BuildContext context) {
    return tokenizeCard
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.info,
                  color: blueColor,
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 5),
                ),
                Text(
                  locale.saveCardNotice,
                  style: TextStyle(color: blueColor),
                ),
              ],
            ))
        : const SizedBox.shrink();
  }
}

class CardFormField extends StatelessWidget {
  final void Function(String?)? onSaved;
  final String? Function(String?)? validator;
  final void Function(String?)? onChanged;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final InputDecoration? inputDecoration;

  const CardFormField(
      {super.key,
      required this.onSaved,
      this.validator,
      this.onChanged,
      this.inputDecoration,
      this.keyboardType = TextInputType.number,
      this.textInputAction = TextInputAction.next,
      this.inputFormatters});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: TextFormField(
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          decoration: inputDecoration,
          validator: validator,
          onSaved: onSaved,
          onChanged: onChanged,
          inputFormatters: inputFormatters),
    );
  }
}

String showAmount(int amount, String currency, Localization locale) {
  final formattedAmount = (amount / 100).toStringAsFixed(2);
  return '${locale.pay} $currency $formattedAmount';
}

String getAmount(int amount) {
  final formattedAmount = (amount / 100).toStringAsFixed(2);
  return formattedAmount;
}

InputDecoration buildInputDecoration(
    {required String hintText,
    required TextDirection hintTextDirection,
    bool addNetworkIcons = false,
    bool hideBorder = false,
    PaymentConfig? config,
    CardNetwork? detectedNetwork,
    bool unsupportedNetwork = false}) {
  Widget? suffixIcon;
  if (addNetworkIcons && config != null) {
    if (detectedNetwork != null) {
      final supported = config.supportedNetworks.map((e) => e.name).toSet();
      final detectedName = detectedNetwork.name;
      if (supported.contains(detectedName)) {
        // Show only the detected network icon when it's supported
        suffixIcon = NetworkIcons(
          config: PaymentConfig(
            publishableApiKey: config.publishableApiKey,
            amount: config.amount,
            currency: config.currency,
            description: config.description,
            supportedNetworks: [PaymentNetwork.values.firstWhere((e) => e.name == detectedName)],
          ),
        );
      } else {
        // Show all configured networks when detected network is not supported
        suffixIcon = NetworkIcons(config: config);
      }
    } else {
      // Show all configured networks when no network is detected or there are errors
      suffixIcon = NetworkIcons(config: config);
    }
  }
  return InputDecoration(
    suffixIcon: suffixIcon,
    hintText: hintText,
    border: hideBorder ? InputBorder.none : defaultEnabledBorder,
    hintTextDirection: hintTextDirection,
    contentPadding: const EdgeInsets.all(8.0),
  );
}

void closeKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

BorderRadius defaultBorderRadius = const BorderRadius.all(Radius.circular(8));

OutlineInputBorder defaultEnabledBorder = OutlineInputBorder(
    borderSide: BorderSide(color: Colors.grey[400]!),
    borderRadius: defaultBorderRadius);

OutlineInputBorder defaultFocusedBorder = OutlineInputBorder(
    borderSide: BorderSide(color: Colors.grey[600]!),
    borderRadius: defaultBorderRadius);

OutlineInputBorder defaultErrorBorder = OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.red),
    borderRadius: defaultBorderRadius);

Color blueColor = Colors.blue[700]!;
Color lightBlueColor = Colors.blue[100]!;
