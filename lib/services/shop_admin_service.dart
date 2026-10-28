import '../core/permissions.dart';
import '../data/repositories.dart';
import '../domain/app_user.dart';
import '../domain/offer.dart';
import '../domain/store_settings.dart';
import 'guard.dart';

/// Shop-wide settings and offers: owner and manager territory.
class ShopAdminService {
  ShopAdminService(this.repos);

  final Repositories repos;

  Future<void> saveSettings(AppUser? actor, StoreSettings settings) async {
    requirePermission(actor, Permission.manageSettings);
    if (settings.monthlyProfitTarget < 0 || settings.courierFee < 0 || settings.reserveToken < 0) {
      throw ShopException('badAmount');
    }
    await repos.settings.save(settings);
  }

  Future<void> saveOffer(AppUser? actor, Offer offer) async {
    requirePermission(actor, Permission.manageOffers);
    if (offer.isCoupon || offer.kind == OfferKind.coupon) {
      if (offer.code.trim().length < 3) throw ShopException('badCoupon');
      if (offer.value <= 0) throw ShopException('badAmount');
      if (offer.discountKind == DiscountKind.percent && offer.value > 100) {
        throw ShopException('badAmount');
      }
      // Two live coupons may not share a code.
      for (final Offer o in await repos.offers.all()) {
        if (o.id != offer.id && o.isCoupon && o.code.toUpperCase() == offer.code.toUpperCase()) {
          throw ShopException('badCoupon');
        }
      }
    }
    await repos.offers.save(offer);
  }

  Future<void> deleteOffer(AppUser? actor, String id) async {
    requirePermission(actor, Permission.manageOffers);
    await repos.offers.delete(id);
  }
}
