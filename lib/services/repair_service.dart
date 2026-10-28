import '../core/ids.dart';
import '../core/permissions.dart';
import '../data/repositories.dart';
import '../domain/app_user.dart';
import '../domain/lead.dart';
import '../domain/repair.dart';
import '../domain/store_settings.dart';
import 'clock.dart';
import 'finance_service.dart';
import 'guard.dart';
import 'lead_service.dart';

/// Phone repair: booked from the app, tracked by the customer, run by staff.
class RepairService {
  RepairService({
    required this.repos,
    required this.leads,
    required this.finance,
    this.clock = systemClock,
  });

  final Repositories repos;
  final LeadService leads;
  final FinanceService finance;
  final Clock clock;

  Future<RepairTicket> book(
    AppUser user, {
    required String brand,
    required String model,
    required RepairIssue issue,
    String description = '',
  }) async {
    final DateTime now = clock();
    final StoreSettings s = await repos.settings.get();
    final RepairTicket t = RepairTicket(
      id: newId('rep'),
      number: await repos.repairs.nextNumber(now),
      userId: user.id,
      name: user.displayName,
      phone: user.phone,
      brand: brand.trim(),
      model: model.trim(),
      issue: issue,
      description: description.trim(),
      estimate: s.repairPrice(issue),
      events: <RepairEvent>[RepairEvent(status: RepairStatus.booked, at: now)],
      createdAt: now,
      updatedAt: now,
    );
    await repos.repairs.save(t);
    await leads.capture(
      type: LeadType.repair,
      name: user.displayName,
      phone: user.phone,
      userId: user.id,
      productName: '${t.brand} ${t.model}'.trim(),
      message: '${issue.name}: ${t.description}',
      details: <String, String>{'ticket': t.number},
    );
    return t;
  }

  Future<RepairTicket> cancelByCustomer(RepairTicket t) async {
    if (t.status != RepairStatus.booked && t.status != RepairStatus.received) {
      throw ShopException('cannotCancel');
    }
    return _move(t, RepairStatus.cancelled);
  }

  Future<RepairTicket> _move(
    RepairTicket t,
    RepairStatus to, {
    int? finalPrice,
    String? imei,
    String note = '',
  }) async {
    final DateTime now = clock();
    final RepairTicket next = t.copyWith(
      status: to,
      finalPrice: finalPrice,
      imei: imei,
      updatedAt: now,
      events: <RepairEvent>[...t.events, RepairEvent(status: to, at: now, note: note)],
    );
    await repos.repairs.save(next);
    return next;
  }

  /// Moves a ticket on. [finalPrice] is the quote after diagnosis. When the
  /// repaired phone is handed back, [partsCost] (what the shop spent) books the
  /// profit.
  Future<RepairTicket> advance(
    AppUser? actor,
    RepairTicket t,
    RepairStatus to, {
    int? finalPrice,
    int? partsCost,
    String? imei,
    String note = '',
  }) async {
    requirePermission(actor, Permission.manageRepairs);
    if (to == RepairStatus.awaitingApproval && finalPrice == null && t.finalPrice == null) {
      throw ShopException('quoteRequired');
    }
    if (to == RepairStatus.delivered) {
      final int? price = finalPrice ?? t.finalPrice;
      if (price == null) throw ShopException('quoteRequired');
      final RepairTicket done = await _move(t, to,
          finalPrice: price, imei: imei, note: note);
      await finance.recordRepair(
        ticketId: t.id,
        price: price,
        partsCost: partsCost ?? 0,
        at: clock(),
      );
      return done;
    }
    return _move(t, to, finalPrice: finalPrice, imei: imei, note: note);
  }

  /// The customer agrees to the quote.
  Future<RepairTicket> approveQuote(RepairTicket t) {
    if (t.status != RepairStatus.awaitingApproval) {
      throw ShopException('badTransition');
    }
    return _move(t, RepairStatus.inRepair);
  }
}
