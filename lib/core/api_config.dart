class ApiConfig {
  // URL base da API
  static const String baseUrl = 'https://api.elostupi.pt/api';

  // Endpoints
  static const String products = '/products';
  static const String pendingOrders = '/pending-orders';
  static const String members = '/members';
  static const String payments = '/payments';
  static const String consulentes = '/consulentes';
  static const String attendance = '/attendance';
  static const String recados = '/recados';
  static const String electricity = '/electricity-readings';
  static const String electricitySettings = '/electricity-settings';
  static const String finance = '/finance';
  static const String admin = '/admin';

  // Headers padrão
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    // 'Authorization': 'Bearer $token', // Para futuras implementações de autenticação
  };

  // Timeout padrão para requisições
  static const Duration defaultTimeout = Duration(seconds: 10);

  // URLs completas
  static String get productsUrl => '$baseUrl$products';
  static String get pendingOrdersUrl => '$baseUrl$pendingOrders';
  static String get membersUrl => '$baseUrl$members';
  static String get paymentsUrl => '$baseUrl$payments';
  static String get consulentesUrl => '$baseUrl$consulentes';
  static String get attendanceUrl => '$baseUrl$attendance';
  static String get recadosUrl => '$baseUrl$recados';
  static String get electricityUrl => '$baseUrl$electricity';
  static String get electricitySettingsUrl => '$baseUrl$electricitySettings';
  static String get financeUrl => '$baseUrl$finance';
  static String get adminUrl => '$baseUrl$admin';
}
