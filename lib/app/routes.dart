/// Every path in the app, in one place.
class Routes {
  const Routes._();

  // Customer
  static const String language = '/language';
  static const String home = '/home';
  static const String shop = '/shop';
  static const String emi = '/emi';
  static const String orders = '/orders';
  static const String account = '/account';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String login = '/login';
  static const String store = '/store';
  static const String calculator = '/emi-calculator';
  static const String exchange = '/exchange';
  static const String repair = '/repair';
  static const String wishlist = '/wishlist';
  static const String addresses = '/addresses';
  static const String help = '/help';
  static const String profile = '/profile';

  static String product(String id) => '/product/$id';
  static String order(String id) => '/order/$id';
  static String orderDone(String id) => '/order/$id/done';
  static String plan(String id) => '/plan/$id';
  static String repairTicket(String id) => '/repair/$id';
  static String address(String id) => '/addresses/$id';
  static String shopWith({String? category, String? group, String? brand, String? q, int? min, int? max, bool emi = false}) {
    final Map<String, String> p = <String, String>{
      'cat': ?category,
      'group': ?group,
      'brand': ?brand,
      if (q != null && q.isNotEmpty) 'q': q,
      if (min != null) 'min': '$min',
      if (max != null) 'max': '$max',
      if (emi) 'emi': '1',
    };
    return Uri(path: shop, queryParameters: p.isEmpty ? null : p).toString();
  }

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminOrders = '/admin/orders';
  static const String adminStock = '/admin/stock';
  static const String adminLeads = '/admin/leads';
  static const String adminMore = '/admin/more';
  static const String adminPos = '/admin/pos';
  static const String adminEmi = '/admin/emi';
  static const String adminRepairs = '/admin/repairs';
  static const String adminOffers = '/admin/offers';
  static const String adminCustomers = '/admin/customers';
  static const String adminStaff = '/admin/staff';
  static const String adminReports = '/admin/reports';
  static const String adminSettings = '/admin/settings';

  static String adminOrder(String id) => '/admin/order/$id';
  static String adminProduct(String id) => '/admin/product/$id';
  static String adminPlan(String id) => '/admin/plan/$id';
  static String adminCustomer(String id) => '/admin/customer/$id';
  static String adminRepair(String id) => '/admin/repair/$id';
  static String adminOffer(String id) => '/admin/offer/$id';
  static const String newId = 'new';
}
