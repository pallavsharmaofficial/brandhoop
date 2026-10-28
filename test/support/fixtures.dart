import 'package:brandhoop/config/shop_config.dart';
import 'package:brandhoop/domain/localized_text.dart';
import 'package:brandhoop/domain/product.dart';
import 'package:brandhoop/domain/store_settings.dart';

final DateTime t0 = DateTime(2026, 10, 15, 12);

StoreSettings settings() => ShopConfig.defaults();

Product phone({
  String id = 'p1',
  int price = 15000,
  int mrp = 17000,
  int stock = 5,
  bool emi = true,
  bool noCost = true,
}) =>
    Product(
      id: id,
      name: const LocalizedText('Test Phone', 'टेस्ट फोन'),
      brand: 'Test',
      category: ProductCategory.smartphone,
      variants: <ProductVariant>[
        ProductVariant(
          id: '$id-v1',
          label: '6 GB + 128 GB',
          price: price,
          mrp: mrp,
          stock: stock,
        ),
      ],
      emiEligible: emi,
      noCostEmi: noCost,
      createdAt: t0,
    );

Product accessory({
  String id = 'a1',
  int price = 500,
  int mrp = 700,
  int stock = 10,
  ProductCategory category = ProductCategory.caseCover,
}) =>
    Product(
      id: id,
      name: const LocalizedText('Test Case'),
      brand: 'Test',
      category: category,
      variants: <ProductVariant>[
        ProductVariant(
          id: '$id-v1',
          label: 'Black',
          price: price,
          mrp: mrp,
          stock: stock,
        ),
      ],
      createdAt: t0,
    );
