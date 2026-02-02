/// Required configuration to setup Samsung Pay.
class SamsungPayConfig {
  /// The merchant ID configured in the Samsung Pay Developer Console.
  String merchantId;

  /// The store name to be displayed in the Samsung Pay payment session.
  String label;

  /// An option to enable the manual auth and capture.
  bool manual;

  /// An option to save (tokenize) the card for later charging.
  bool saveCard;

  /// The currency code (e.g., "SAR", "USD").
  /// Default is "SAR".
  String currencyCode;

  /// The country code (e.g., "SA", "US").
  /// Default is "SA".
  String countryCode;

  SamsungPayConfig({
    required this.merchantId,
    required this.label,
    required this.manual,
    required this.saveCard,
    this.currencyCode = 'SAR',
    this.countryCode = 'SA',
  });
}
