import '../core/permissions.dart';
import '../data/repositories.dart';
import '../domain/app_user.dart';
import '../domain/finance.dart';
import '../domain/product.dart';
import 'guard.dart';

/// Product and stock changes from the back office.
class CatalogService {
  CatalogService(this.repos);

  final Repositories repos;

  /// Saves a product. [costs] (variant id to what the shop paid) is saved only
  /// by someone allowed to see and edit costs.
  Future<void> saveProduct(
    AppUser? actor,
    Product product, {
    Map<String, int>? costs,
  }) async {
    requirePermission(actor, Permission.manageCatalog);
    if (product.variants.isEmpty) throw ShopException('needVariant');
    for (final ProductVariant v in product.variants) {
      if (v.price <= 0 || v.mrp < v.price || v.stock < 0) {
        throw ShopException('badPrice');
      }
    }
    await repos.catalog.save(product);
    if (costs != null) {
      requirePermission(actor, Permission.editCosts);
      await repos.finance.saveCost(CostEntry(productId: product.id, costs: costs));
    }
  }

  Future<void> setActive(AppUser? actor, Product product, bool active) async {
    requirePermission(actor, Permission.manageCatalog);
    await repos.catalog.save(product.copyWith(active: active));
  }

  /// Staff may correct stock without being able to touch prices.
  Future<void> adjustStock(
    AppUser? actor,
    String productId,
    String variantId,
    int delta,
  ) async {
    requirePermission(actor, Permission.adjustStock);
    await repos.catalog.adjustStock(productId, variantId, delta);
  }
}
