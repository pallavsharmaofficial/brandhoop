import 'package:brandhoop/data/demo_seed.dart';
import 'package:brandhoop/domain/order.dart';
import 'package:brandhoop/domain/emi_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';

void main() {
  testWidgets('first run asks for a language, then opens the shop in it', (WidgetTester tester) async {
    await AppUnderTest.pump(tester, onboarded: false, language: 'en');
    expect(find.textContaining('Choose language'), findsOneWidget);
    await tester.tapText('हिन्दी');
    // The screen switches to Hindi as soon as it is picked.
    expect(find.text('आगे बढ़ें'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, 'आगे बढ़ें'));
    await AppUnderTest.settle(tester);
    expect(find.text('ब्रांडहूप'), findsWidgets);
    expect(find.textContaining('हमारी दुकान पर आएं'), findsWidgets);
  });

  testWidgets('home shows the shop, its address and EMI phones', (WidgetTester tester) async {
    await AppUnderTest.pump(tester);
    expect(find.text('Brandhoop'), findsWidgets);
    expect(find.text('Brandhoop Mobile Point'), findsOneWidget);
    expect(find.textContaining('Abhay Colony'), findsWidgets);
    expect(find.textContaining('Across the road from Study Point Library'), findsWidgets);
    // No phone number has been entered, so no Call button is shown.
    expect(find.text('Call'), findsNothing);
    expect(find.text('Directions'), findsWidgets);
    await tester.reveal('0% EMI phones');
    expect(find.text('0% EMI phones'), findsOneWidget);
  });

  testWidgets('the language toggle flips the whole screen', (WidgetTester tester) async {
    await AppUnderTest.pump(tester);
    await tester.tap(find.text('हिं').first);
    await AppUnderTest.settle(tester);
    await tester.reveal('0% ईएमआई वाले फोन');
    expect(find.text('0% ईएमआई वाले फोन'), findsOneWidget);
    expect(find.text('0% EMI phones'), findsNothing);
  });

  testWidgets('a guest cannot reach checkout or the back office', (WidgetTester tester) async {
    await AppUnderTest.pump(tester);
    await tester.tapText('Orders');
    expect(find.text('Sign in to see your orders'), findsOneWidget);
    await tester.tapText('Account');
    expect(find.text('Welcome to Brandhoop'), findsOneWidget);
    expect(find.text('Open admin panel'), findsNothing);
  });

  testWidgets('browse, add to cart and check out with cash at the store', (WidgetTester tester) async {
    final AppUnderTest app = await AppUnderTest.pump(tester);
    // Open a product from the home screen.
    await tester.tapText('Shop');
    await tester.tap(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, 'tempered');
    await AppUnderTest.settle(tester);
    await tester.tapText('Tempered Glass 9H');
    expect(find.text('Add to cart'), findsOneWidget);
    expect(find.text('₹149'), findsWidgets);
    await tester.tapText('Add to cart');
    expect(find.text('Added to your cart'), findsOneWidget);

    // Cart, then checkout: a guest is sent to sign in first.
    await tester.tap(find.byIcon(Icons.shopping_cart_outlined).first);
    await AppUnderTest.settle(tester);
    expect(find.text('Your cart'), findsOneWidget);
    await tester.tapText('Checkout');
    expect(find.text('Sign in to Brandhoop'), findsOneWidget);
    await tester.tapText('Customer');
    expect(find.text('How would you like to receive it?'), findsOneWidget);

    await tester.tapText('Pick up at the store');
    await tester.tapText('Pay cash at the store');
    await tester.reveal('Order summary');
    expect(find.text('Order summary'), findsOneWidget);
    await tester.tapText('Place order');
    expect(find.text('Order placed'), findsOneWidget);
    expect(find.text('Show this code at the store'), findsOneWidget);

    final List<Order> mine = await app.repos.orders.all();
    final Order placed = mine.firstWhere((Order o) => o.customerName == 'Ravi Meena' && o.lines.any((OrderLine l) => l.productId == 'ac_glass') && o.status == OrderStatus.placed);
    expect(placed.paymentMode, PaymentMode.cashAtStore);
    expect(placed.balanceDue, 149);
  });

  testWidgets('a customer signed in sees their EMI plan and Autopay status', (WidgetTester tester) async {
    await AppUnderTest.pump(tester);
    await tester.tapText('Account');
    await tester.tapText('Sign in');
    await tester.tapText('Customer');
    await tester.tapText('EMI');
    expect(find.text('Next EMI due'), findsOneWidget);
    expect(find.text('Autopay is on'), findsWidgets);
    await tester.tapText('Redmi Note 5G Series');
    expect(find.text('Autopay settings'), findsOneWidget);
    expect(find.text('Pause Autopay'), findsOneWidget);
    expect(find.text('ravi.meena@okaxis'), findsOneWidget);
  });

  testWidgets('staff land in the back office and can switch to the customer view', (WidgetTester tester) async {
    await AppUnderTest.pump(tester);
    await tester.tapText('Account');
    await tester.tapText('Sign in');
    await tester.tapText('Counter staff');
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Needs your attention'), findsOneWidget);
    // Staff never see profit or the target.
    expect(find.textContaining('Road to'), findsNothing);
    expect(find.text('Sales today'), findsOneWidget);
    await tester.tapText('More');
    expect(find.text('New sale'), findsOneWidget);
    expect(find.text('Staff and roles'), findsNothing);
    expect(find.text('Shop settings'), findsNothing);
    expect(find.text('EMI desk'), findsNothing);
    await tester.tapText('View as customer');
    expect(find.text('Brandhoop Mobile Point'), findsOneWidget);
  });

  testWidgets('the owner sees the road to 5 lakh, the people and the settings', (WidgetTester tester) async {
    await AppUnderTest.pump(tester);
    await tester.tapText('Account');
    await tester.tapText('Sign in');
    await tester.tapText('Owner');
    expect(find.textContaining('Road to ₹5 L a month'), findsOneWidget);
    expect(find.text('Profit this month'), findsOneWidget);
    expect(find.text('Finish setting up your shop'), findsOneWidget);
    await tester.reveal('Growth scorecard (last 30 days)');
    expect(find.text('Growth scorecard (last 30 days)'), findsOneWidget);
    await tester.tapText('More');
    for (final String t in <String>['New sale', 'EMI desk', 'Offers and coupons', 'Customers', 'Reports', 'Staff and roles', 'Shop settings']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
  });

  testWidgets('Hindi back office labels', (WidgetTester tester) async {
    await AppUnderTest.pump(tester, language: 'hi');
    await tester.tapText('खाता');
    await tester.tapText('साइन इन करें');
    await tester.tapText('मालिक');
    expect(find.textContaining('हर महीने ₹5 लाख की राह'), findsOneWidget);
    expect(find.text('इस महीने का मुनाफ़ा'), findsOneWidget);
  });

  testWidgets('demo accounts exist with the roles the sign-in chips promise', (WidgetTester tester) async {
    final AppUnderTest app = await AppUnderTest.pump(tester);
    expect((await app.repos.users.byPhone(DemoSeed.ownerPhone))!.role.name, 'owner');
    expect((await app.repos.users.byPhone(DemoSeed.staffPhone))!.role.name, 'staff');
    final List<EmiPlan> plans = await app.repos.plans.all();
    expect(plans, hasLength(2));
    expect(plans.firstWhere((EmiPlan p) => p.status == EmiPlanStatus.active).mandate!.isActive, isTrue);
    expect(plans.where((EmiPlan p) => p.status == EmiPlanStatus.applied), hasLength(1));
  });
}
