import 'dart:math';

import '../core/emi.dart';
import '../core/ids.dart';
import '../core/permissions.dart';
import '../domain/address.dart';
import '../domain/app_user.dart';
import '../domain/emi_plan.dart';
import '../domain/finance.dart';
import '../domain/lead.dart';
import '../domain/localized_text.dart';
import '../domain/offer.dart';
import '../domain/order.dart';
import '../domain/payment.dart';
import '../domain/product.dart';
import '../domain/repair.dart';
import '../domain/store_settings.dart';
import '../services/emi_service.dart';
import '../services/finance_calc.dart';
import 'repositories.dart';

/// Sample data so the app can be explored the moment it is installed.
///
/// Everything here is made up: product names are brand + series (not exact
/// models), prices are plausible placeholders, customers and their numbers are
/// fictional. The owner replaces the catalogue in Admin > Stock and the demo
/// goes away with "Reset demo data". The sales history is generated through the
/// same profit calculator the live app uses, scaled to look like the shop's
/// current monthly profit (the owner's figure of about 30 to 40 thousand rupees),
/// so the "road to 5 lakh" panel starts from an honest baseline.
class DemoSeed {
  const DemoSeed._();

  static const String seededKey = 'bh.seeded';

  /// Demo accounts. Sign in with any of these numbers and the code 123456.
  static const String ownerPhone = '9000000001';
  static const String managerPhone = '9000000002';
  static const String staffPhone = '9000000003';
  static const String customerPhone = '9000000011';

  static Future<bool> populate(Repositories r, DateTime now) async {
    if (r.prefs.getBool(seededKey) ?? false) return false;
    await _write(r, now);
    await r.prefs.setBool(seededKey, true);
    return true;
  }

  /// Wipes everything and seeds again.
  static Future<void> reset(Repositories r, DateTime now) async {
    await r.wipeLocal();
    await r.prefs.remove('bh.session');
    await _write(r, now);
    await r.prefs.setBool(seededKey, true);
  }

  static Future<void> _write(Repositories r, DateTime now) async {
    final StoreSettings settings = await r.settings.get();
    final Random rng = Random(7);

    // ---- People ----------------------------------------------------------
    AppUser user(String id, String phone, String name, AppRole role, int daysAgo,
            {List<Address> addresses = const <Address>[], int coins = 0}) =>
        AppUser(
          id: id,
          phone: phone,
          name: name,
          role: role,
          createdAt: now.subtract(Duration(days: daysAgo)),
          referralCode: 'BH${id.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '').padRight(4, 'X').substring(0, 4)}',
          addresses: addresses,
          coins: coins,
        );

    Address home(String name, String phone, String area) => Address(
          id: newId('addr'),
          label: 'Home',
          name: name,
          phone: phone,
          line1: 'House 12',
          area: area,
          city: 'Neem Ka Thana',
          district: 'Neem Ka Thana',
          pincode: '332713',
        );

    final List<AppUser> staff = <AppUser>[
      user('u_owner', ownerPhone, 'Owner (demo)', AppRole.owner, 400),
      user('u_manager', managerPhone, 'Manager (demo)', AppRole.manager, 300),
      user('u_staff', staffPhone, 'Counter staff (demo)', AppRole.staff, 200),
    ];
    const List<String> names = <String>[
      'Ravi Meena', 'Sunita Yadav', 'Mahesh Saini', 'Pooja Sharma', 'Deepak Gurjar',
      'Kavita Jangid', 'Rajesh Choudhary', 'Anita Verma', 'Sanjay Khandelwal',
      'Neha Rathore', 'Mohit Agarwal', 'Rekha Sain', 'Vikas Tanwar', 'Babita Kumawat',
    ];
    final List<AppUser> customers = <AppUser>[
      for (int i = 0; i < names.length; i++)
        user(
          'u_c$i',
          '90000000${(11 + i).toString().padLeft(2, '0')}',
          names[i],
          AppRole.customer,
          20 + rng.nextInt(300),
          addresses: <Address>[
            home(names[i], '90000000${(11 + i).toString().padLeft(2, '0')}', i.isEven ? 'Abhay Colony' : 'Subhash Nagar'),
          ],
          coins: i == 0 ? 240 : 0,
        ),
    ];
    for (final AppUser u in <AppUser>[...staff, ...customers]) {
      await r.users.save(u);
    }

    // ---- Catalogue -------------------------------------------------------
    final List<_Seed> catalogue = _catalogue(now);
    for (final _Seed s in catalogue) {
      await r.catalog.save(s.product);
      await r.finance.saveCost(CostEntry(productId: s.product.id, costs: s.costs));
    }

    // ---- Offers ----------------------------------------------------------
    final DateTime start = now.subtract(const Duration(days: 3));
    final DateTime end = now.add(const Duration(days: 40));
    final List<Offer> offers = <Offer>[
      Offer(
        id: 'o_festive',
        kind: OfferKind.banner,
        title: const LocalizedText('Festive season: 0% EMI on top phones', 'त्योहार का मौसम: टॉप फोन पर 0% ईएमआई'),
        subtitle: const LocalizedText('Bajaj Finserv EMI, minimal paperwork, same day', 'बजाज फिनसर्व ईएमआई, कम कागज़, उसी दिन'),
        startsAt: start,
        endsAt: end,
        colorSeed: 1,
      ),
      Offer(
        id: 'o_exchange',
        kind: OfferKind.banner,
        title: const LocalizedText('Exchange your old phone, get instant value', 'पुराना फोन दें, तुरंत कीमत पाएं'),
        subtitle: const LocalizedText('Check the value in the app, finish in the shop', 'ऐप में कीमत देखें, दुकान पर पूरा करें'),
        startsAt: start,
        endsAt: end,
        colorSeed: 2,
      ),
      Offer(
        id: 'o_combo',
        kind: OfferKind.banner,
        title: const LocalizedText('Phone + glass + case combo, flat 15% off accessories', 'फोन + ग्लास + कवर कॉम्बो, एक्सेसरीज़ पर फ्लैट 15% छूट'),
        startsAt: start,
        endsAt: end,
        colorSeed: 3,
      ),
      Offer(
        id: 'c_welcome',
        kind: OfferKind.coupon,
        title: const LocalizedText('Welcome: ₹100 off accessories', 'स्वागत: एक्सेसरीज़ पर ₹100 की छूट'),
        code: 'WELCOME100',
        discountKind: DiscountKind.flat,
        value: 100,
        minOrder: 499,
        groups: const <ProductGroup>[ProductGroup.accessories],
        startsAt: start,
        endsAt: end,
      ),
      Offer(
        id: 'c_acc15',
        kind: OfferKind.coupon,
        title: const LocalizedText('15% off accessories', 'एक्सेसरीज़ पर 15% छूट'),
        code: 'ACC15',
        value: 15,
        minOrder: 699,
        maxDiscount: 300,
        groups: const <ProductGroup>[ProductGroup.accessories],
        startsAt: start,
        endsAt: end,
      ),
    ];
    for (final Offer o in offers) {
      await r.offers.save(o);
    }

    // ---- 45 days of delivered sales -------------------------------------
    final List<Product> phones = catalogue
        .map((_Seed s) => s.product)
        .where((Product p) => p.category == ProductCategory.smartphone)
        .toList();
    final List<Product> accessories = catalogue
        .map((_Seed s) => s.product)
        .where((Product p) => p.category.group == ProductGroup.accessories)
        .toList();
    final Product protection = catalogue
        .map((_Seed s) => s.product)
        .firstWhere((Product p) => p.id == 'pr_screen');

    final Map<String, CostEntry> costMap = <String, CostEntry>{
      for (final _Seed s in catalogue) s.product.id: CostEntry(productId: s.product.id, costs: s.costs),
    };
    int seq = 0;
    final Map<String, int> monthSeq = <String, int>{};
    String nextNumber(DateTime d) {
      final String yy = (d.year % 100).toString().padLeft(2, '0');
      final String mm = d.month.toString().padLeft(2, '0');
      final String key = '$yy$mm';
      monthSeq[key] = (monthSeq[key] ?? 0) + 1;
      return 'BH-$key-${monthSeq[key].toString().padLeft(4, '0')}';
    }

    OrderLine lineOf(Product p, {int qty = 1, List<String> imeis = const <String>[]}) {
      final ProductVariant v = p.variants[rng.nextInt(p.variants.length)];
      return OrderLine(
        productId: p.id,
        variantId: v.id,
        name: p.name.en,
        nameHi: p.name.hi,
        variantLabel: v.label,
        category: p.category,
        qty: qty,
        unitPrice: v.price,
        unitMrp: v.mrp,
        imeis: imeis,
        gstRatePct: p.gstRatePct,
        warrantyMonths: p.warrantyMonths,
      );
    }

    final List<Order> history = <Order>[];
    for (int daysAgo = 45; daysAgo >= 1; daysAgo--) {
      final DateTime day = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysAgo));
      // A phone sale every day or two, a few accessory sales, the odd bundle.
      final int phoneSales = rng.nextDouble() < 0.55 ? 1 : 0;
      final int accSales = rng.nextInt(3);
      final List<List<OrderLine>> baskets = <List<OrderLine>>[
        for (int i = 0; i < phoneSales; i++)
          <OrderLine>[
            lineOf(phones[rng.nextInt(phones.length)], imeis: <String>[_imei(rng)]),
            if (rng.nextDouble() < 0.55) lineOf(accessories.firstWhere((Product p) => p.id == 'ac_glass')),
            if (rng.nextDouble() < 0.4) lineOf(accessories.firstWhere((Product p) => p.id == 'ac_case')),
            if (rng.nextDouble() < 0.15) lineOf(protection),
          ],
        for (int i = 0; i < accSales; i++)
          <OrderLine>[
            lineOf(accessories[rng.nextInt(accessories.length)]),
            if (rng.nextDouble() < 0.3) lineOf(accessories[rng.nextInt(accessories.length)]),
          ],
      ];
      for (final List<OrderLine> lines in baskets) {
        final AppUser c = customers[rng.nextInt(customers.length)];
        final DateTime at = day.add(Duration(hours: 10 + rng.nextInt(10), minutes: rng.nextInt(60)));
        final int total = lines.fold(0, (int s, OrderLine l) => s + l.total);
        final double pick = rng.nextDouble();
        final PaymentMethod method = pick < 0.45
            ? PaymentMethod.cash
            : pick < 0.85
                ? PaymentMethod.upi
                : PaymentMethod.card;
        final Order o = Order(
          id: 'ord_seed_${seq++}',
          number: nextNumber(at),
          customerId: c.id,
          customerName: c.name,
          customerPhone: c.phone,
          source: OrderSource.pos,
          lines: lines,
          fulfilment: Fulfilment.walkIn,
          subtotal: total,
          total: total,
          payments: <PaymentRecord>[
            PaymentRecord(
              id: newId('pr'),
              method: method,
              amount: total,
              status: PaymentStatus.paid,
              at: at,
            ),
          ],
          paymentMode: method == PaymentMethod.cash ? PaymentMode.cashAtStore : PaymentMode.full,
          status: OrderStatus.delivered,
          events: <OrderEvent>[OrderEvent(status: OrderStatus.delivered, at: at)],
          createdAt: at,
          updatedAt: at,
          pickupCode: newPickupCode(),
          deliveredAt: at,
        );
        history.add(o);
        await r.orders.save(o);
        await r.finance.saveEntry(ProfitCalculator.forOrder(
          order: o,
          costs: costMap,
          settings: settings,
          at: at,
        ));
      }
      // Repairs bring people in and pay well.
      if (rng.nextDouble() < 0.35) {
        final DateTime at = day.add(Duration(hours: 11 + rng.nextInt(8)));
        final int price = <int>[350, 600, 800, 1200, 1500][rng.nextInt(5)];
        final int cost = (price * (0.3 + rng.nextDouble() * 0.2)).round();
        final String id = 'rep_seed_${seq++}';
        await r.finance.saveEntry(ProfitCalculator.forRepair(
          ticketId: id,
          price: price,
          partsCost: cost,
          at: at,
          settings: settings,
        ));
      }
    }

    // ---- Open orders, an EMI plan with Autopay, leads, repairs ----------
    final Product hero = phones.firstWhere((Product p) => p.id == 'ph_redmi');
    final ProductVariant hv = hero.variants.first;
    final AppUser demoCustomer = customers.first;

    // 1) A live Bajaj plan with Autopay, five months to go.
    final DateTime delivered = now.subtract(const Duration(days: 40));
    final EmiScheme noCost = settings.scheme('bajaj_nocost')!;
    final int principal = hv.price - 2000;
    final EmiQuote q = Emi.quote(principal: principal, months: 6, annualRatePct: 0);
    final List<Instalment> schedule = EmiService.buildSchedule(q, delivered)
        .map((Instalment i) => i.dueDate.isBefore(now)
            ? i.copyWith(status: InstalmentStatus.paid, paidOn: i.dueDate)
            : i)
        .toList();
    const String emiOrderId = 'ord_seed_emi';
    final EmiPlan plan = EmiPlan(
      id: 'emi_seed_1',
      orderId: emiOrderId,
      orderNumber: nextNumber(delivered),
      customerId: demoCustomer.id,
      customerName: demoCustomer.name,
      customerPhone: demoCustomer.phone,
      provider: EmiProvider.bajaj,
      schemeId: noCost.id,
      productSummary: hero.name.en,
      price: hv.price,
      downPayment: 2000,
      principal: principal,
      months: 6,
      annualRatePct: 0,
      emi: q.emi,
      noCost: true,
      status: EmiPlanStatus.active,
      instalments: schedule,
      lenderRef: 'BFL-DEMO-0001',
      mandate: AutopayMandate(
        id: 'mnd_seed_1',
        method: AutopayMethod.upiAutopay,
        status: AutopayStatus.active,
        maskedInstrument: 'ravi.meena@okaxis',
        maxAmount: q.emi,
        createdAt: delivered,
        gatewayRef: 'mnd_demo_ref',
      ),
      createdAt: delivered,
    );
    await r.plans.save(plan);
    final Order emiOrder = Order(
      id: emiOrderId,
      number: plan.orderNumber,
      customerId: demoCustomer.id,
      customerName: demoCustomer.name,
      customerPhone: demoCustomer.phone,
      source: OrderSource.pos,
      lines: <OrderLine>[
        OrderLine(
          productId: hero.id,
          variantId: hv.id,
          name: hero.name.en,
          nameHi: hero.name.hi,
          variantLabel: hv.label,
          category: hero.category,
          qty: 1,
          unitPrice: hv.price,
          unitMrp: hv.mrp,
          imeis: <String>[_imei(rng)],
        ),
      ],
      fulfilment: Fulfilment.walkIn,
      subtotal: hv.price,
      total: hv.price,
      payments: <PaymentRecord>[
        PaymentRecord(
          id: newId('pr'),
          method: PaymentMethod.upi,
          amount: 2000,
          status: PaymentStatus.paid,
          at: delivered,
        ),
        PaymentRecord(
          id: newId('pr'),
          kind: PaymentKind.lenderDisbursement,
          method: PaymentMethod.bajajEmi,
          amount: principal,
          status: PaymentStatus.paid,
          reference: 'BFL-DEMO-0001',
          at: delivered,
        ),
      ],
      paymentMode: PaymentMode.bajajEmi,
      status: OrderStatus.delivered,
      events: <OrderEvent>[OrderEvent(status: OrderStatus.delivered, at: delivered)],
      createdAt: delivered,
      updatedAt: delivered,
      pickupCode: newPickupCode(),
      deliveredAt: delivered,
      emiPlanId: plan.id,
    );
    await r.orders.save(emiOrder);
    await r.finance.saveEntry(ProfitCalculator.forOrder(
      order: emiOrder,
      costs: costMap,
      settings: settings,
      plan: plan,
      at: delivered,
    ));

    // 2) Orders in flight for the demo customer and others.
    Future<void> openOrder(AppUser c, List<OrderLine> lines, OrderStatus s, Fulfilment f,
        PaymentMode mode, PaymentMethod method, {bool paid = true, int minutesAgo = 90}) async {
      final DateTime at = now.subtract(Duration(minutes: minutesAgo));
      final int total = lines.fold(0, (int sum, OrderLine l) => sum + l.total);
      final List<OrderStatus> path = <OrderStatus>[
        OrderStatus.placed, OrderStatus.confirmed, OrderStatus.packed,
        if (f == Fulfilment.delivery) OrderStatus.outForDelivery else OrderStatus.readyForPickup,
      ];
      final List<OrderEvent> events = <OrderEvent>[];
      for (final OrderStatus st in path) {
        events.add(OrderEvent(status: st, at: at));
        if (st == s) break;
      }
      await r.orders.save(Order(
        id: newId('ord'),
        number: nextNumber(at),
        customerId: c.id,
        customerName: c.name,
        customerPhone: c.phone,
        lines: lines,
        fulfilment: f,
        address: f == Fulfilment.delivery ? c.defaultAddress : null,
        subtotal: total,
        total: total,
        payments: <PaymentRecord>[
          PaymentRecord(
            id: newId('pr'),
            method: method,
            amount: total,
            status: paid ? PaymentStatus.paid : PaymentStatus.pending,
            at: at,
          ),
        ],
        paymentMode: mode,
        status: s,
        events: events,
        createdAt: at,
        updatedAt: at,
        pickupCode: newPickupCode(),
      ));
    }

    await openOrder(demoCustomer, <OrderLine>[lineOf(accessories.firstWhere((Product p) => p.id == 'ac_tws'))],
        OrderStatus.outForDelivery, Fulfilment.delivery, PaymentMode.full, PaymentMethod.upi, minutesAgo: 240);
    await openOrder(customers[3], <OrderLine>[lineOf(phones[2]), lineOf(accessories.firstWhere((Product p) => p.id == 'ac_glass'))],
        OrderStatus.placed, Fulfilment.delivery, PaymentMode.cashOnDelivery, PaymentMethod.cash,
        paid: false, minutesAgo: 25);
    await openOrder(customers[5], <OrderLine>[lineOf(phones[5])],
        OrderStatus.confirmed, Fulfilment.pickup, PaymentMode.full, PaymentMethod.card, minutesAgo: 60);

    // 3) Leads.
    Lead lead(LeadType t, AppUser c, String product, String msg, int minutesAgo, {LeadStatus st = LeadStatus.fresh}) {
      final DateTime at = now.subtract(Duration(minutes: minutesAgo));
      return Lead(
        id: newId('lead'),
        type: t,
        status: st,
        name: c.name,
        phone: c.phone,
        userId: c.id,
        productName: product,
        message: msg,
        createdAt: at,
        updatedAt: at,
      );
    }

    for (final Lead l in <Lead>[
      lead(LeadType.emiApplication, customers[2], phones[1].name.en, '12 months', 30),
      lead(LeadType.callback, customers[4], phones[6].name.en, 'Call me after 6 pm', 75),
      lead(LeadType.exchange, customers[7], 'Old phone exchange', 'Expected around ₹6,000', 180),
      lead(LeadType.enquiry, customers[8], phones[0].name.en, 'Is it in stock in blue?', 400),
      lead(LeadType.reserve, customers[9], phones[4].name.en, 'Will visit tomorrow', 1300, st: LeadStatus.contacted),
      lead(LeadType.repair, customers[10], 'Screen replacement', 'Cracked screen', 2000),
    ]) {
      await r.leads.save(l);
    }

    // 4) Repairs.
    RepairTicket ticket(int i, AppUser c, String brand, String model, RepairIssue issue, RepairStatus st,
        {int? price}) {
      final DateTime at = now.subtract(Duration(days: i + 1));
      return RepairTicket(
        id: 'rep_demo_$i',
        number: 'RP-${(now.year % 100).toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}-000${i + 1}',
        userId: c.id,
        name: c.name,
        phone: c.phone,
        brand: brand,
        model: model,
        issue: issue,
        status: st,
        estimate: settings.repairPrice(issue),
        finalPrice: price,
        events: <RepairEvent>[RepairEvent(status: RepairStatus.booked, at: at)],
        createdAt: at,
        updatedAt: at,
      );
    }

    await r.repairs.save(ticket(0, demoCustomer, 'Vivo', 'Y-series', RepairIssue.screen, RepairStatus.inRepair, price: 1400));
    await r.repairs.save(ticket(1, customers[1], 'Samsung', 'M-series', RepairIssue.battery, RepairStatus.awaitingApproval, price: 650));
    await r.repairs.save(ticket(2, customers[6], 'Realme', 'Narzo', RepairIssue.charging, RepairStatus.received));
  }

  /// A valid 15-digit IMEI (Luhn) from the generator.
  static String _imei(Random rng) {
    final List<int> d = List<int>.generate(14, (_) => rng.nextInt(10));
    d[0] = 3;
    int sum = 0;
    for (int i = 0; i < 14; i++) {
      int n = d[13 - i];
      if (i.isEven) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
    }
    final int check = (10 - sum % 10) % 10;
    return '${d.join()}$check';
  }

  static List<_Seed> _catalogue(DateTime now) {
    const Map<String, String> display = <String, String>{'display': '6.6" FHD+ 120 Hz', 'battery': '5000 mAh', 'camera': '50 MP + 2 MP', 'chip': 'Octa-core', 'os': 'Android'};
    _Seed phone(
      String id,
      String en,
      String hi,
      String brand,
      List<(String, int, int, int, int)> vs, {
      bool noCost = false,
      bool featured = false,
      Map<String, String> specs = display,
    }) {
      return _Seed(
        Product(
          id: id,
          name: LocalizedText(en, hi),
          brand: brand,
          category: ProductCategory.smartphone,
          description: const LocalizedText(
            'Sample listing. Genuine product with GST bill and brand warranty.',
            'नमूना लिस्टिंग। जीएसटी बिल और ब्रांड वारंटी के साथ असली प्रोडक्ट।',
          ),
          highlights: const <LocalizedText>[
            LocalizedText('GST bill and brand warranty', 'जीएसटी बिल और ब्रांड वारंटी'),
            LocalizedText('Free setup and data transfer in store', 'दुकान पर मुफ्त सेटअप और डेटा ट्रांसफर'),
          ],
          specs: specs,
          variants: <ProductVariant>[
            for (int i = 0; i < vs.length; i++)
              ProductVariant(id: '$id-v${i + 1}', label: vs[i].$1, price: vs[i].$2, mrp: vs[i].$3, stock: vs[i].$4),
          ],
          emiEligible: true,
          noCostEmi: noCost,
          featured: featured,
          tags: const <String>['sample'],
          createdAt: now.subtract(const Duration(days: 120)),
        ),
        <String, int>{for (int i = 0; i < vs.length; i++) '$id-v${i + 1}': vs[i].$5},
      );
    }

    _Seed acc(
      String id,
      String en,
      String hi,
      ProductCategory cat,
      String brand,
      List<(String, int, int, int, int)> vs, {
      bool featured = false,
      bool emi = false,
      int warranty = 6,
    }) =>
        _Seed(
          Product(
            id: id,
            name: LocalizedText(en, hi),
            brand: brand,
            category: cat,
            description: const LocalizedText(
              'Sample listing. Tested in the shop before it reaches you.',
              'नमूना लिस्टिंग। आप तक पहुँचने से पहले दुकान पर जाँचा गया।',
            ),
            variants: <ProductVariant>[
              for (int i = 0; i < vs.length; i++)
                ProductVariant(id: '$id-v${i + 1}', label: vs[i].$1, price: vs[i].$2, mrp: vs[i].$3, stock: vs[i].$4),
            ],
            warrantyMonths: warranty,
            featured: featured,
            emiEligible: emi,
            tags: const <String>['sample'],
            createdAt: now.subtract(const Duration(days: 120)),
          ),
          <String, int>{for (int i = 0; i < vs.length; i++) '$id-v${i + 1}': vs[i].$5},
        );

    return <_Seed>[
      phone('ph_samsung', 'Samsung Galaxy M Series 5G', 'सैमसंग गैलेक्सी M सीरीज़ 5G', 'Samsung',
          <(String, int, int, int, int)>[('6 GB + 128 GB', 13999, 17999, 8, 13300), ('8 GB + 128 GB', 15999, 19999, 5, 15150)],
          noCost: true, featured: true),
      phone('ph_redmi', 'Redmi Note 5G Series', 'रेडमी नोट 5G सीरीज़', 'Xiaomi',
          <(String, int, int, int, int)>[('6 GB + 128 GB', 14499, 18999, 9, 13800), ('8 GB + 256 GB', 17999, 22999, 4, 17100)],
          noCost: true, featured: true),
      phone('ph_realme', 'Realme Narzo 5G Series', 'रियलमी नार्ज़ो 5G सीरीज़', 'Realme',
          <(String, int, int, int, int)>[('6 GB + 128 GB', 12499, 16999, 7, 11900)], noCost: true),
      phone('ph_vivo', 'Vivo Y Series', 'विवो Y सीरीज़', 'Vivo',
          <(String, int, int, int, int)>[('6 GB + 128 GB', 13499, 17999, 6, 12850)], noCost: true),
      phone('ph_oppo', 'Oppo A Series', 'ओपो A सीरीज़', 'Oppo',
          <(String, int, int, int, int)>[('6 GB + 128 GB', 12999, 17499, 5, 12350)]),
      phone('ph_iqoo', 'iQOO Z Series 5G', 'आईक्यूओओ Z सीरीज़ 5G', 'iQOO',
          <(String, int, int, int, int)>[('8 GB + 128 GB', 17999, 24999, 4, 17000), ('8 GB + 256 GB', 19999, 26999, 3, 18900)],
          noCost: true, featured: true),
      phone('ph_moto', 'Motorola G Series', 'मोटोरोला G सीरीज़', 'Motorola',
          <(String, int, int, int, int)>[('4 GB + 128 GB', 10999, 14999, 6, 10450)]),
      phone('ph_poco', 'POCO M Series', 'पोको M सीरीज़', 'POCO',
          <(String, int, int, int, int)>[('4 GB + 64 GB', 8499, 11999, 10, 8100), ('6 GB + 128 GB', 9999, 13999, 6, 9500)]),
      phone('ph_oneplus', 'OnePlus Nord CE', 'वनप्लस नॉर्ड CE', 'OnePlus',
          <(String, int, int, int, int)>[('8 GB + 128 GB', 21999, 26999, 3, 20800)], noCost: true, featured: true),
      phone('ph_itel', 'itel A Series', 'आईटेल A सीरीज़', 'itel',
          <(String, int, int, int, int)>[('3 GB + 64 GB', 6299, 8499, 12, 5850)]),
      phone('ph_lava', 'Lava Blaze 5G', 'लावा ब्लेज़ 5G', 'Lava',
          <(String, int, int, int, int)>[('4 GB + 128 GB', 9499, 12999, 5, 8950)]),
      _Seed(
        Product(
          id: 'ph_feature',
          name: const LocalizedText('Feature phone (keypad)', 'कीपैड फोन'),
          brand: 'itel',
          category: ProductCategory.featurePhone,
          description: const LocalizedText('Long battery, dual SIM, loud speaker.', 'लंबी बैटरी, डुअल सिम, तेज़ आवाज़।'),
          variants: const <ProductVariant>[
            ProductVariant(id: 'ph_feature-v1', label: 'Black', price: 1399, mrp: 1699, stock: 15),
          ],
          tags: const <String>['sample'],
          createdAt: now.subtract(const Duration(days: 120)),
        ),
        const <String, int>{'ph_feature-v1': 1250},
      ),
      acc('ac_charger20', '20W Fast Charger (Type-C)', '20W फास्ट चार्जर (टाइप-C)', ProductCategory.charger, 'Brandhoop',
          <(String, int, int, int, int)>[('White', 499, 799, 25, 230)], featured: true),
      acc('ac_charger65', '65W GaN Charger', '65W GaN चार्जर', ProductCategory.charger, 'Brandhoop',
          <(String, int, int, int, int)>[('Black', 1499, 2499, 8, 760)]),
      acc('ac_cable', 'Type-C Braided Cable 1 m', 'टाइप-C ब्रेडेड केबल 1 मी', ProductCategory.cable, 'Brandhoop',
          <(String, int, int, int, int)>[('1 m', 249, 399, 40, 90)]),
      acc('ac_tws', 'Wireless Earbuds (TWS)', 'वायरलेस ईयरबड्स (TWS)', ProductCategory.earphones, 'Brandhoop',
          <(String, int, int, int, int)>[('Black', 1299, 2499, 14, 620)], featured: true, warranty: 12),
      acc('ac_neckband', 'Bluetooth Neckband', 'ब्लूटूथ नेकबैंड', ProductCategory.earphones, 'Brandhoop',
          <(String, int, int, int, int)>[('Blue', 799, 1499, 18, 380)], warranty: 12),
      acc('ac_case', 'Silicone Back Cover', 'सिलिकॉन बैक कवर', ProductCategory.caseCover, 'Brandhoop',
          <(String, int, int, int, int)>[('Black', 199, 399, 60, 55), ('Transparent', 199, 399, 60, 50)], featured: true),
      acc('ac_flip', 'Flip Cover', 'फ्लिप कवर', ProductCategory.caseCover, 'Brandhoop',
          <(String, int, int, int, int)>[('Brown', 399, 699, 20, 140)]),
      acc('ac_glass', 'Tempered Glass 9H', 'टेम्पर्ड ग्लास 9H', ProductCategory.screenGuard, 'Brandhoop',
          <(String, int, int, int, int)>[('Standard', 149, 299, 80, 25), ('Privacy', 249, 499, 40, 55)], featured: true),
      acc('ac_powerbank', 'Power Bank 10000 mAh', 'पावर बैंक 10000 mAh', ProductCategory.powerBank, 'Brandhoop',
          <(String, int, int, int, int)>[('Black', 999, 1799, 12, 520)], warranty: 12),
      acc('ac_watch', 'Smartwatch', 'स्मार्टवॉच', ProductCategory.smartwatch, 'Brandhoop',
          <(String, int, int, int, int)>[('Black', 1799, 3999, 9, 1000)], warranty: 12, emi: true),
      acc('ac_speaker', 'Bluetooth Speaker', 'ब्लूटूथ स्पीकर', ProductCategory.speaker, 'Brandhoop',
          <(String, int, int, int, int)>[('Black', 899, 1499, 10, 450)], warranty: 12),
      acc('ac_sd64', 'microSD Card 64 GB', 'माइक्रोSD कार्ड 64 GB', ProductCategory.memory, 'Brandhoop',
          <(String, int, int, int, int)>[('64 GB', 449, 799, 22, 260)], warranty: 24),
      acc('pr_screen', 'Screen Protection Plan (1 year)', 'स्क्रीन प्रोटेक्शन प्लान (1 साल)', ProductCategory.protection, 'Brandhoop',
          <(String, int, int, int, int)>[('1 year', 499, 699, 999, 200)], featured: true, warranty: 12),
      acc('pr_warranty', 'Extended Warranty (+1 year)', 'एक्सटेंडेड वारंटी (+1 साल)', ProductCategory.protection, 'Brandhoop',
          <(String, int, int, int, int)>[('+1 year', 799, 1099, 999, 350)], warranty: 12),
    ];
  }
}

class _Seed {
  const _Seed(this.product, this.costs);
  final Product product;
  final Map<String, int> costs;
}
