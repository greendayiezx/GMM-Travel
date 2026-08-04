class MidtransConfig {
  static const bool isProduction = bool.fromEnvironment(
    'MIDTRANS_IS_PRODUCTION',
    defaultValue: false,
  );

  static const String clientKey = String.fromEnvironment(
    'MIDTRANS_CLIENT_KEY',
    defaultValue: 'Mid-client-3nJ1mdOpefgybowt',
  );

  static String get cardRegisterBaseUrl =>
      isProduction ? 'https://api.midtrans.com' : 'https://api.sandbox.midtrans.com';
}
