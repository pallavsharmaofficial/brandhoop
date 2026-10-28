import '../core/emi.dart';
import '../core/ids.dart';
import '../core/permissions.dart';
import '../data/repositories.dart';
import '../domain/app_user.dart';
import '../domain/emi_plan.dart';
import '../domain/store_settings.dart';
import 'clock.dart';
import 'guard.dart';
import 'payment_gateway.dart';

/// A customer's choice of financing scheme, tenure and down payment.
class EmiSelection {
  const EmiSelection({
    required this.schemeId,
    required this.months,
    this.downPayment = 0,
  });

  final String schemeId;
  final int months;
  final int downPayment;
}

class EmiService {
  EmiService({
    required this.repos,
    required this.gateway,
    this.clock = systemClock,
  });

  final Repositories repos;
  final PaymentGateway gateway;
  final Clock clock;

  /// Instalment dates and amounts, one month apart from [first].
  static List<Instalment> buildSchedule(EmiQuote q, DateTime first) => <Instalment>[
        for (int i = 0; i < q.instalments.length; i++)
          Instalment(
            index: i + 1,
            dueDate: Emi.addMonths(DateTime(first.year, first.month, first.day), i + 1),
            amount: q.instalments[i],
          ),
      ];

  /// A plan as the customer asked for it. Bajaj plans start as "applied" and
  /// have no dates until the lender approves; card plans are activated by the
  /// caller once the bank has taken the charge.
  Future<EmiPlan> create({
    required StoreSettings settings,
    required EmiSelection selection,
    required String orderId,
    required String orderNumber,
    required AppUser customer,
    required String productSummary,
    required int price,
    required int principal,
  }) async {
    final EmiScheme? s = settings.scheme(selection.schemeId);
    if (s == null || !s.tenures.contains(selection.months)) {
      throw ShopException('badEmiScheme');
    }
    final EmiQuote q = Emi.quote(
      principal: principal,
      months: selection.months,
      annualRatePct: s.annualRatePct,
    );
    final EmiPlan plan = EmiPlan(
      id: newId('emi'),
      orderId: orderId,
      orderNumber: orderNumber,
      customerId: customer.id,
      customerName: customer.displayName,
      customerPhone: customer.phone,
      provider: s.provider,
      schemeId: s.id,
      productSummary: productSummary,
      price: price,
      downPayment: price - principal,
      principal: principal,
      months: selection.months,
      annualRatePct: s.annualRatePct,
      emi: q.emi,
      processingFee: s.processingFee,
      noCost: s.noCost,
      createdAt: clock(),
    );
    await repos.plans.save(plan);
    return plan;
  }

  EmiQuote _quoteOf(EmiPlan p) => Emi.quote(
        principal: p.principal,
        months: p.months,
        annualRatePct: p.annualRatePct,
      );

  /// The lender (or the bank) has said yes: the schedule starts.
  Future<EmiPlan> approve(
    AppUser? actor,
    EmiPlan plan, {
    String lenderRef = '',
    DateTime? firstFrom,
  }) async {
    requirePermission(actor, Permission.manageEmi);
    return _activate(plan, lenderRef: lenderRef, firstFrom: firstFrom);
  }

  /// Used for card EMI, where the bank's approval is the successful charge.
  Future<EmiPlan> activateAfterCharge(EmiPlan plan, {String ref = ''}) =>
      _activate(plan, lenderRef: ref);

  Future<EmiPlan> _activate(
    EmiPlan plan, {
    String lenderRef = '',
    DateTime? firstFrom,
  }) async {
    final EmiPlan next = plan.copyWith(
      status: EmiPlanStatus.active,
      lenderRef: lenderRef.isEmpty ? plan.lenderRef : lenderRef,
      instalments: buildSchedule(_quoteOf(plan), firstFrom ?? clock()),
    );
    await repos.plans.save(next);
    return next;
  }

  Future<EmiPlan> reject(AppUser? actor, EmiPlan plan, {String reason = ''}) async {
    requirePermission(actor, Permission.manageEmi);
    final EmiPlan next =
        plan.copyWith(status: EmiPlanStatus.rejected, note: reason);
    await repos.plans.save(next);
    return next;
  }

  Future<EmiPlan> cancel(EmiPlan plan, {String reason = ''}) async {
    final EmiPlan next = plan.copyWith(
      status: EmiPlanStatus.cancelled,
      note: reason,
      mandate: plan.mandate?.copyWith(status: AutopayStatus.cancelled),
    );
    await repos.plans.save(next);
    return next;
  }

  Future<EmiPlan> markInstalmentPaid(
    AppUser? actor,
    EmiPlan plan,
    int index, {
    DateTime? at,
  }) async {
    requirePermission(actor, Permission.manageEmi);
    return _markPaid(plan, index, at ?? clock());
  }

  Future<EmiPlan> _markPaid(EmiPlan plan, int index, DateTime at) async {
    final List<Instalment> list = <Instalment>[
      for (final Instalment i in plan.instalments)
        if (i.index == index)
          i.copyWith(status: InstalmentStatus.paid, paidOn: at)
        else
          i,
    ];
    final bool done =
        list.isNotEmpty && list.every((Instalment i) => i.status == InstalmentStatus.paid);
    final EmiPlan next = plan.copyWith(
      instalments: list,
      status: done ? EmiPlanStatus.closed : plan.status,
    );
    await repos.plans.save(next);
    return next;
  }

  // ---- Autopay -----------------------------------------------------------

  /// Registers a standing instruction through the gateway and keeps it on the
  /// plan. The limit is the largest instalment with a little headroom.
  Future<EmiPlan> setupAutopay(
    EmiPlan plan, {
    required AutopayMethod method,
    required PayInstrument instrument,
  }) async {
    if (!plan.isLive) throw ShopException('planNotLive');
    final int maxAmount = plan.instalments.isEmpty
        ? plan.emi
        : plan.instalments
            .map((Instalment i) => i.amount)
            .reduce((int a, int b) => a > b ? a : b);
    final GatewayResult r = await gateway.registerMandate(MandateRequest(
      planId: plan.id,
      method: method,
      maxAmount: maxAmount,
      instrument: instrument,
      customerPhone: plan.customerPhone,
    ));
    if (!r.ok) throw ShopException('mandateFailed', r.failure!.name);
    final EmiPlan next = plan.copyWith(
      mandate: AutopayMandate(
        id: newId('mnd'),
        method: method,
        status: AutopayStatus.active,
        maskedInstrument: r.instrumentLabel,
        maxAmount: maxAmount,
        createdAt: clock(),
        gatewayRef: r.reference,
        remindDaysBefore: plan.mandate?.remindDaysBefore ?? 2,
      ),
    );
    await repos.plans.save(next);
    return next;
  }

  Future<EmiPlan> setAutopayStatus(EmiPlan plan, AutopayStatus status) async {
    final AutopayMandate? m = plan.mandate;
    if (m == null) return plan;
    final EmiPlan next = plan.copyWith(mandate: m.copyWith(status: status));
    await repos.plans.save(next);
    return next;
  }

  Future<EmiPlan> setReminderDays(EmiPlan plan, int days) async {
    final AutopayMandate? m = plan.mandate;
    if (m == null) return plan;
    final EmiPlan next = plan.copyWith(
      mandate: m.copyWith(remindDaysBefore: days.clamp(0, 7)),
    );
    await repos.plans.save(next);
    return next;
  }

  /// Debits every instalment that has fallen due on an active mandate. In
  /// production the gateway or the lender does this on its own and tells us by
  /// webhook; this is the same step run on the device so the demo shows it.
  /// Returns how many instalments were collected.
  Future<int> runAutopay() async {
    final DateTime now = clock();
    final DateTime today = DateTime(now.year, now.month, now.day);
    int collected = 0;
    for (final EmiPlan plan in await repos.plans.all()) {
      EmiPlan current = plan;
      final AutopayMandate? m = current.mandate;
      if (m == null || !m.isActive || current.status != EmiPlanStatus.active) {
        continue;
      }
      for (final Instalment i in plan.instalments) {
        if (i.status == InstalmentStatus.paid) continue;
        if (i.dueDate.isAfter(today)) break;
        final GatewayResult r = await gateway.debitMandate(
          mandateRef: m.gatewayRef,
          amount: i.amount,
          description: '${plan.orderNumber} #${i.index}',
        );
        if (r.ok) {
          current = await _markPaid(current, i.index, now);
          collected++;
        } else {
          current = current.copyWith(
            mandate: m.copyWith(status: AutopayStatus.failed),
          );
          await repos.plans.save(current);
          break;
        }
      }
    }
    return collected;
  }
}
