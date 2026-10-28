import '../domain/emi_plan.dart';
import '../domain/localized_text.dart';
import '../domain/repair.dart';
import '../domain/store_settings.dart';

/// The shop, as far as the app knows it before the owner opens Settings.
///
/// Everything here comes from the Google Maps listing "Brandhoop Mobile Point"
/// (Abhay Colony, Neem Ka Thana, Rajasthan 332713, across the road from Study
/// Point Library). Anything the owner has not told us is left empty rather than
/// invented: the phone and WhatsApp numbers, the UPI id, the GSTIN and the exact
/// map pin. The app asks for them (Admin > Settings) and hides the buttons that
/// need them until they exist.
class ShopConfig {
  const ShopConfig._();

  static const String appName = 'Brandhoop';
  static const String appNameHi = 'ब्रांडहूप';

  static StoreSettings defaults() => StoreSettings(
        name: const LocalizedText('Brandhoop Mobile Point', 'ब्रांडहूप मोबाइल पॉइंट'),
        tagline: const LocalizedText(
          'Your own mobile shop in Neem Ka Thana, now in your pocket',
          'नीम का थाना की आपकी अपनी मोबाइल दुकान, अब आपकी जेब में',
        ),
        addressLine:
            const LocalizedText('Abhay Colony', 'अभय कॉलोनी'),
        landmark: const LocalizedText(
          'Across the road from Study Point Library',
          'स्टडी पॉइंट लाइब्रेरी के सामने, सड़क के उस पार',
        ),
        city: 'Neem Ka Thana',
        pincode: '332713',
        // Opening hours are a placeholder (10:00 to 21:00, every day).
        hours: StoreHours.everyDay(10 * 60, 21 * 60),
        localPincodes: const <String>['332713'],
        emiSchemes: defaultEmiSchemes(),
        repairPrices: const <String, int>{
          'screen': 1200,
          'battery': 600,
          'charging': 350,
          'water': 800,
          'speaker': 300,
          'camera': 700,
          'software': 200,
          'other': 300,
        },
      );

  /// PLACEHOLDER RATES. The owner must replace them with the rates Bajaj
  /// Finance and the card banks have actually agreed with the shop, then tick
  /// "rates confirmed" in Settings. Until then the app labels every EMI figure
  /// "indicative" and shows the owner a warning.
  static List<EmiScheme> defaultEmiSchemes() => <EmiScheme>[
        const EmiScheme(
          id: 'bajaj_nocost',
          provider: EmiProvider.bajaj,
          name: LocalizedText('Bajaj Finserv 0% EMI', 'बजाज फिनसर्व 0% ईएमआई'),
          tenures: <int>[3, 6, 9, 12],
          annualRatePct: 0,
          noCost: true,
          lenderRatePct: 15,
          minPrice: 8000,
          minDownPaymentPct: 10,
        ),
        const EmiScheme(
          id: 'bajaj_standard',
          provider: EmiProvider.bajaj,
          name: LocalizedText('Bajaj Finserv EMI', 'बजाज फिनसर्व ईएमआई'),
          tenures: <int>[6, 9, 12, 18, 24],
          annualRatePct: 16,
          minPrice: 5000,
          processingFee: 199,
          minDownPaymentPct: 10,
        ),
        const EmiScheme(
          id: 'card_nocost',
          provider: EmiProvider.bank,
          name: LocalizedText('Credit card no-cost EMI', 'क्रेडिट कार्ड नो-कॉस्ट ईएमआई'),
          tenures: <int>[3, 6],
          annualRatePct: 0,
          noCost: true,
          lenderRatePct: 15,
          minPrice: 10000,
        ),
        const EmiScheme(
          id: 'card_standard',
          provider: EmiProvider.bank,
          name: LocalizedText('Credit / debit card EMI', 'क्रेडिट / डेबिट कार्ड ईएमआई'),
          tenures: <int>[3, 6, 9, 12, 18, 24],
          annualRatePct: 15,
          minPrice: 5000,
        ),
      ];

  /// What a repair issue costs to *start* from when no owner price is set.
  static int fallbackRepairPrice(RepairIssue issue) => 300;
}
