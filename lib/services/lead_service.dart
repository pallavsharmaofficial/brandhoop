import '../core/ids.dart';
import '../core/permissions.dart';
import '../data/repositories.dart';
import '../domain/app_user.dart';
import '../domain/lead.dart';
import 'clock.dart';
import 'guard.dart';

/// Captures anyone who shows interest, and lets the shop work through them.
class LeadService {
  LeadService(this.repos, {this.clock = systemClock});

  final Repositories repos;
  final Clock clock;

  /// Adds a lead, or, if this person already has an open lead of the same kind
  /// for the same product, adds a note to that one instead of a second row.
  Future<Lead> capture({
    required LeadType type,
    required String name,
    required String phone,
    String? userId,
    String? productId,
    String productName = '',
    String message = '',
    Map<String, String> details = const <String, String>{},
  }) async {
    final DateTime now = clock();
    for (final Lead l in await repos.leads.all()) {
      if (l.isOpen &&
          l.phone == phone &&
          l.type == type &&
          l.productId == productId) {
        final Lead next = l.copyWith(
          updatedAt: now,
          notes: <LeadNote>[
            ...l.notes,
            LeadNote(text: message.isEmpty ? '(again)' : message, at: now),
          ],
        );
        await repos.leads.save(next);
        return next;
      }
    }
    final Lead lead = Lead(
      id: newId('lead'),
      type: type,
      name: name,
      phone: phone,
      userId: userId,
      productId: productId,
      productName: productName,
      message: message,
      details: details,
      createdAt: now,
      updatedAt: now,
    );
    await repos.leads.save(lead);
    return lead;
  }

  Future<Lead> setStatus(AppUser? actor, Lead lead, LeadStatus status) async {
    requirePermission(actor, Permission.manageLeads);
    final Lead next = lead.copyWith(status: status, updatedAt: clock());
    await repos.leads.save(next);
    return next;
  }

  Future<Lead> addNote(AppUser? actor, Lead lead, String text) async {
    requirePermission(actor, Permission.manageLeads);
    final DateTime now = clock();
    final Lead next = lead.copyWith(
      updatedAt: now,
      notes: <LeadNote>[...lead.notes, LeadNote(text: text, at: now, by: actor!.id)],
    );
    await repos.leads.save(next);
    return next;
  }

  Future<Lead> setFollowUp(AppUser? actor, Lead lead, DateTime? at) async {
    requirePermission(actor, Permission.manageLeads);
    final Lead next = at == null
        ? lead.copyWith(clearFollowUp: true, updatedAt: clock())
        : lead.copyWith(followUpAt: at, updatedAt: clock());
    await repos.leads.save(next);
    return next;
  }

  Future<Lead> assign(AppUser? actor, Lead lead, String staffId) async {
    requirePermission(actor, Permission.manageLeads);
    final Lead next = lead.copyWith(assignedTo: staffId, updatedAt: clock());
    await repos.leads.save(next);
    return next;
  }
}
