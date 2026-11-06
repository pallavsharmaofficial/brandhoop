// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Brandhoop';

  @override
  String get appTagline => 'Your own mobile shop, now in your pocket';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get chooseLanguageHint =>
      'You can change it any time from the top of the screen.';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageShortHi => 'हिं';

  @override
  String get languageShortEn => 'EN';

  @override
  String get switchLanguage => 'Switch language';

  @override
  String get continueLabel => 'Continue';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get remove => 'Remove';

  @override
  String get retry => 'Try again';

  @override
  String get close => 'Close';

  @override
  String get done => 'Done';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get search => 'Search';

  @override
  String get apply => 'Apply';

  @override
  String get applied => 'Applied';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get share => 'Share';

  @override
  String get call => 'Call';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get directions => 'Directions';

  @override
  String get viewAll => 'View all';

  @override
  String get confirm => 'Confirm';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get loading => 'Loading…';

  @override
  String get optional => 'Optional';

  @override
  String get required => 'Required';

  @override
  String get noResults => 'Nothing found';

  @override
  String get tryAgainLater => 'Please try again in a moment.';

  @override
  String get somethingWrong => 'Something went wrong';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get perMonth => '/month';

  @override
  String get perMonthShort => '/mo';

  @override
  String get freeLabel => 'Free';

  @override
  String get inclGst => 'Incl. GST';

  @override
  String get sample => 'Sample';

  @override
  String get demoMode => 'Demo mode';

  @override
  String get demoBanner =>
      'Demo mode: sample products, simulated payments, no real money moves.';

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String monthsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String hoursCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navShop => 'Shop';

  @override
  String get navEmi => 'EMI';

  @override
  String get navOrders => 'Orders';

  @override
  String get navAccount => 'Account';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navStock => 'Stock';

  @override
  String get navLeads => 'Leads';

  @override
  String get navMore => 'More';

  @override
  String get catSmartphone => 'Smartphones';

  @override
  String get catFeaturePhone => 'Feature phones';

  @override
  String get catTablet => 'Tablets';

  @override
  String get catEarphones => 'Earphones and buds';

  @override
  String get catCharger => 'Chargers';

  @override
  String get catCable => 'Cables';

  @override
  String get catCase => 'Cases and covers';

  @override
  String get catScreenGuard => 'Screen guards';

  @override
  String get catPowerBank => 'Power banks';

  @override
  String get catSmartwatch => 'Smartwatches';

  @override
  String get catSpeaker => 'Speakers';

  @override
  String get catMemory => 'Memory cards';

  @override
  String get catProtection => 'Protection plans';

  @override
  String get groupPhones => 'Phones';

  @override
  String get groupAccessories => 'Accessories';

  @override
  String get groupProtection => 'Protection';

  @override
  String get groupAll => 'All';

  @override
  String get specRam => 'RAM';

  @override
  String get specStorage => 'Storage';

  @override
  String get specDisplay => 'Display';

  @override
  String get specBattery => 'Battery';

  @override
  String get specCamera => 'Camera';

  @override
  String get specChip => 'Processor';

  @override
  String get specOs => 'Operating system';

  @override
  String get statusPendingPayment => 'Waiting for payment';

  @override
  String get statusPlaced => 'Order placed';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusPacked => 'Packed';

  @override
  String get statusOutForDelivery => 'Out for delivery';

  @override
  String get statusReadyForPickup => 'Ready to collect';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusReturnRequested => 'Return requested';

  @override
  String get statusReturned => 'Returned';

  @override
  String get fulfilDelivery => 'Home delivery';

  @override
  String get fulfilPickup => 'Pick up at the store';

  @override
  String get fulfilWalkIn => 'Bought in the store';

  @override
  String get payMethodUpi => 'UPI';

  @override
  String get payMethodCard => 'Card';

  @override
  String get payMethodNetbanking => 'Net banking';

  @override
  String get payMethodCash => 'Cash';

  @override
  String get payMethodBajaj => 'Bajaj Finserv EMI';

  @override
  String get payMethodCardEmi => 'Card EMI';

  @override
  String get payModeFull => 'Paid in full';

  @override
  String get payModeToken => 'Reserved with a token';

  @override
  String get payModeCod => 'Cash on delivery';

  @override
  String get payModeCashStore => 'Cash at the store';

  @override
  String get payModeBajaj => 'Bajaj Finserv EMI';

  @override
  String get payModeCardEmi => 'Card EMI';

  @override
  String get payModeMixed => 'Part payments';

  @override
  String get payStatusPending => 'Pending';

  @override
  String get payStatusPaid => 'Paid';

  @override
  String get payStatusFailed => 'Failed';

  @override
  String get payKindRefund => 'Refund';

  @override
  String get payKindLender => 'Paid by lender';

  @override
  String get planApplied => 'Application sent';

  @override
  String get planApproved => 'Approved';

  @override
  String get planActive => 'Active';

  @override
  String get planClosed => 'Fully paid';

  @override
  String get planRejected => 'Not approved';

  @override
  String get planCancelled => 'Cancelled';

  @override
  String get instUpcoming => 'Upcoming';

  @override
  String get instPaid => 'Paid';

  @override
  String get instOverdue => 'Overdue';

  @override
  String get autopayNotSet => 'Autopay is off';

  @override
  String get autopayPending => 'Setting up';

  @override
  String get autopayActive => 'Autopay is on';

  @override
  String get autopayPaused => 'Autopay paused';

  @override
  String get autopayCancelled => 'Autopay cancelled';

  @override
  String get autopayFailed => 'Autopay failed';

  @override
  String get autopayUpi => 'UPI Autopay';

  @override
  String get autopayCard => 'Card standing instruction';

  @override
  String get autopayBank => 'Bank mandate (e-NACH)';

  @override
  String get providerBajaj => 'Bajaj Finserv';

  @override
  String get providerBank => 'Your bank';

  @override
  String get providerShop => 'Brandhoop';

  @override
  String get leadEnquiry => 'Enquiry';

  @override
  String get leadCallback => 'Call back';

  @override
  String get leadEmi => 'EMI application';

  @override
  String get leadExchange => 'Exchange';

  @override
  String get leadRepair => 'Repair';

  @override
  String get leadReserve => 'Reserved phone';

  @override
  String get leadVisit => 'Store visit';

  @override
  String get leadFresh => 'New';

  @override
  String get leadContacted => 'Contacted';

  @override
  String get leadVisited => 'Visited';

  @override
  String get leadConverted => 'Bought';

  @override
  String get leadLost => 'Lost';

  @override
  String get issueScreen => 'Cracked or dead screen';

  @override
  String get issueBattery => 'Battery';

  @override
  String get issueCharging => 'Charging problem';

  @override
  String get issueWater => 'Water damage';

  @override
  String get issueSpeaker => 'Speaker or mic';

  @override
  String get issueCamera => 'Camera';

  @override
  String get issueSoftware => 'Software, hang or virus';

  @override
  String get issueOther => 'Something else';

  @override
  String get repairBooked => 'Booked';

  @override
  String get repairReceived => 'Received in the shop';

  @override
  String get repairDiagnosing => 'Being checked';

  @override
  String get repairAwaiting => 'Waiting for your approval';

  @override
  String get repairInRepair => 'Being repaired';

  @override
  String get repairReady => 'Ready to collect';

  @override
  String get repairDelivered => 'Handed over';

  @override
  String get repairCancelled => 'Cancelled';

  @override
  String get roleCustomer => 'Customer';

  @override
  String get roleStaff => 'Counter staff';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleOwner => 'Owner';

  @override
  String get dayMon => 'Monday';

  @override
  String get dayTue => 'Tuesday';

  @override
  String get dayWed => 'Wednesday';

  @override
  String get dayThu => 'Thursday';

  @override
  String get dayFri => 'Friday';

  @override
  String get daySat => 'Saturday';

  @override
  String get daySun => 'Sunday';

  @override
  String get errBadPhone => 'Enter a 10-digit mobile number.';

  @override
  String get errBadOtp => 'That code is not right. Please check and try again.';

  @override
  String get errAccountDisabled =>
      'This account has been switched off. Please contact the shop.';

  @override
  String get errBadAddress =>
      'Please complete the delivery address with name, phone and a 6-digit pincode.';

  @override
  String get errEmptyCart => 'Your cart is empty.';

  @override
  String get errStockChanged => 'Stock has changed. Please review your cart.';

  @override
  String get errBadCoupon => 'That coupon cannot be used on this order.';

  @override
  String get errPayNotAllowed =>
      'That way of paying is not available for this order.';

  @override
  String get errNeedInstrument => 'Please enter your payment details.';

  @override
  String get errBadEmiScheme =>
      'That EMI option is not available for this amount.';

  @override
  String get errNothingToPay => 'There is nothing to pay on this order.';

  @override
  String get errCannotCancel =>
      'This can no longer be cancelled. Please call the shop.';

  @override
  String get errReturnWindowClosed => 'The 7-day return window has closed.';

  @override
  String get errBadTransition =>
      'That step is not allowed for this order right now.';

  @override
  String get errBadImei => 'That IMEI is not valid. It must be 15 digits.';

  @override
  String get errDupImei => 'The same IMEI is entered twice.';

  @override
  String get errImeiRequired =>
      'Enter the IMEI of every phone before handing it over.';

  @override
  String get errEmiNotApproved =>
      'The EMI is not approved yet. Do not hand the phone over.';

  @override
  String get errBalanceDue => 'There is still money to collect on this order.';

  @override
  String get errBadAmount => 'That amount is not right.';

  @override
  String get errDiscountTooHigh =>
      'Counter staff can give at most 5% off. Ask a manager.';

  @override
  String get errPlanNotLive => 'Autopay can be set once the EMI is approved.';

  @override
  String get errMandateFailed =>
      'Could not set up Autopay. Check the details and try again.';

  @override
  String get errRefundFailed => 'The refund could not be sent. Try again.';

  @override
  String get errQuoteRequired => 'Enter the repair price first.';

  @override
  String get errNeedVariant => 'Add at least one variant with a price.';

  @override
  String get errBadPrice =>
      'Check the prices: MRP cannot be below the selling price.';

  @override
  String get errLastOwner => 'There must always be at least one active owner.';

  @override
  String get errBadRole => 'That role cannot be given.';

  @override
  String get errNoPermission => 'Your role does not allow this.';

  @override
  String get errGatewayDeclined =>
      'The payment was declined. Try another card, UPI ID or bank.';

  @override
  String get errGatewayInvalid =>
      'Those payment details do not look right. Please check them.';

  @override
  String get errGatewayCancelled => 'The payment was cancelled.';

  @override
  String get errGatewayTimeout =>
      'The payment timed out. You have not been charged twice; check your orders.';

  @override
  String get payChoiceUpi => 'UPI (GPay, PhonePe, Paytm)';

  @override
  String get payChoiceUpiHint => 'Instant. Pay from any UPI app.';

  @override
  String get payChoiceCard => 'Credit or debit card';

  @override
  String get payChoiceCardHint => 'Visa, Mastercard, RuPay.';

  @override
  String get payChoiceNetbankingHint => 'Pay from your bank account.';

  @override
  String get payChoiceCod => 'Cash on delivery';

  @override
  String get payChoiceCodHint =>
      'Pay in cash when it reaches your door. Available in town.';

  @override
  String get payChoiceCashStore => 'Pay cash at the store';

  @override
  String get payChoiceCashStoreHint =>
      'We keep it ready. Pay when you collect.';

  @override
  String get payChoiceReserve => 'Reserve now, pay at the store';

  @override
  String payChoiceReserveHint(String token) {
    return 'Pay $token now to hold the phone for you. Pay the rest when you visit.';
  }

  @override
  String get payChoiceBajajHint =>
      'Down payment now, easy monthly instalments. Quick approval in the store.';

  @override
  String get payChoiceCardEmiHint =>
      'Convert the bill into EMIs on your credit or debit card.';

  @override
  String get openAdmin => 'Open admin panel';

  @override
  String get openAdminHint => 'Orders, stock, billing, EMI and reports';

  @override
  String get viewAsCustomer => 'View as customer';

  @override
  String get visitStore => 'Visit our store';

  @override
  String get visitUsAnytime => 'Visit us any time we are open';

  @override
  String get searchHint => 'Search phones, chargers, cases…';

  @override
  String get shopByCategory => 'Shop by category';

  @override
  String get shopByBudget => 'Shop by budget';

  @override
  String get budgetUnder10 => 'Under ₹10,000';

  @override
  String get budget10to15 => '₹10,000 - ₹15,000';

  @override
  String get budget15to20 => '₹15,000 - ₹20,000';

  @override
  String get budgetAbove20 => 'Above ₹20,000';

  @override
  String get zeroEmiPhones => '0% EMI phones';

  @override
  String get ourServices => 'Our services';

  @override
  String get serviceRepair => 'Phone repair';

  @override
  String get serviceExchange => 'Exchange old phone';

  @override
  String get serviceEmiCalc => 'EMI calculator';

  @override
  String get accessoryPicks => 'Popular accessories';

  @override
  String get whyBrandhoop => 'Why buy from Brandhoop';

  @override
  String get whyGenuineTitle => 'Genuine, with a GST bill';

  @override
  String get whyGenuineBody =>
      'Every phone is sealed with brand warranty. No second-hand surprises.';

  @override
  String get whyLocalTitle => 'A shop you can walk into';

  @override
  String get whyLocalBody =>
      'Order from home, then visit, collect or ask anything at the counter, any time we are open.';

  @override
  String get whyPayTitle => 'Pay your way';

  @override
  String get whyPayBody =>
      'Cash, UPI, cards, Bajaj Finserv EMI and Autopay, all in one place.';

  @override
  String get whySupportTitle => 'Local support after you buy';

  @override
  String get whySupportBody =>
      'Setup, data transfer, repair and warranty help from the same people you bought from.';

  @override
  String get trustGenuine => 'Genuine';

  @override
  String get trustGstBill => 'GST bill';

  @override
  String get trustLocal => 'Local shop';

  @override
  String get trustService => 'Repair and service';

  @override
  String get whyBuyFromUs => 'Why buy from us';

  @override
  String get storeOpenNow => 'Open now';

  @override
  String get storeClosedNow => 'Closed now';

  @override
  String storeClosesAt(String time) {
    return 'closes $time';
  }

  @override
  String storeOpensAt(String time) {
    return 'opens $time';
  }

  @override
  String storeOpensDay(String day, String time) {
    return 'opens $day, $time';
  }

  @override
  String resultsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n products',
      one: '1 product',
    );
    return '$_temp0';
  }

  @override
  String get filters => 'Filters';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortPopular => 'Popular';

  @override
  String get sortPriceLow => 'Price: low to high';

  @override
  String get sortPriceHigh => 'Price: high to low';

  @override
  String get sortDiscount => 'Biggest discount';

  @override
  String get noResultsHint => 'Try a different word or clear the filters.';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get priceRange => 'Price';

  @override
  String priceBelow(String price) {
    return 'Below $price';
  }

  @override
  String priceAbove(String price) {
    return 'Above $price';
  }

  @override
  String get brand => 'Brand';

  @override
  String get zeroEmiOnly => '0% EMI only';

  @override
  String get inStockOnly => 'In stock only';

  @override
  String get off => 'off';

  @override
  String get outOfStock => 'Out of stock';

  @override
  String emiFrom(String amount) {
    return 'EMI from $amount/month';
  }

  @override
  String emiFromZero(String amount) {
    return '0% EMI from $amount/month';
  }

  @override
  String get productNotFound => 'This product is not available';

  @override
  String get wishlist => 'Wishlist';

  @override
  String shareProductText(String shop, String product, String price) {
    return 'Look at this on $shop: $product for $price.';
  }

  @override
  String get sampleListing => 'Sample listing';

  @override
  String get chooseVariant => 'Choose a variant';

  @override
  String onlyFewLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Only $n left',
      one: 'Only 1 left',
    );
    return '$_temp0';
  }

  @override
  String get inStockAtStore => 'In stock at the store';

  @override
  String inStockCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n in stock',
      one: '1 in stock',
      zero: 'Out of stock',
    );
    return '$_temp0';
  }

  @override
  String get emiPartners =>
      'With Bajaj Finserv and card EMI. Tap to see plans.';

  @override
  String reserveTitle(String token) {
    return 'Reserve this phone for $token';
  }

  @override
  String reserveBody(String hours) {
    return 'We hold it for you for $hours. Pay the rest when you visit the store.';
  }

  @override
  String get reserveCta => 'Reserve now';

  @override
  String get deliveryTitle => 'Delivery and pickup';

  @override
  String deliveryLocal(String city) {
    return 'Same-day home delivery in $city and nearby areas we serve.';
  }

  @override
  String get pickupAnytime => 'Or collect from our store any time it is open.';

  @override
  String get enterPincode => 'Enter your pincode';

  @override
  String get check => 'Check';

  @override
  String get deliverySameDay => 'Same-day delivery to this pincode.';

  @override
  String deliveryCourier(String fee, String free) {
    return 'Courier delivery: $fee, free above $free.';
  }

  @override
  String get completeYourPhone => 'Complete your phone';

  @override
  String get aboutProduct => 'About this product';

  @override
  String get specifications => 'Specifications';

  @override
  String get warranty => 'Warranty';

  @override
  String warrantyMonths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String get similarProducts => 'Similar products';

  @override
  String get errBadPincode => 'Enter a valid 6-digit pincode.';

  @override
  String get addToCart => 'Add to cart';

  @override
  String get addedToCart => 'Added to your cart';

  @override
  String get buyNow => 'Buy now';

  @override
  String get notifyMe => 'Ask us about it';

  @override
  String get askAboutThis => 'Ask about this';

  @override
  String enquiryText(String product, String variant, String price) {
    return 'Hello! I am interested in $product ($variant) at $price. Is it available?';
  }

  @override
  String get weWillCallYou => 'Thank you. We will call you shortly.';

  @override
  String get yourDetails => 'Your details';

  @override
  String get yourName => 'Your name';

  @override
  String get mobileNumber => 'Mobile number';

  @override
  String get send => 'Send';

  @override
  String get cartTitle => 'Your cart';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get cartEmptyHint =>
      'Add a phone or an accessory and it will show up here.';

  @override
  String get startShopping => 'Start shopping';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get proceedToCheckout => 'Checkout';

  @override
  String get youSave => 'You save';

  @override
  String get deliveryCalculatedAtCheckout =>
      'Delivery and offers are worked out at checkout.';

  @override
  String get itemNoLongerAvailable => 'This item is no longer available';

  @override
  String get viewCart => 'View cart';

  @override
  String get openingHours => 'Opening hours';

  @override
  String get closed => 'Closed';

  @override
  String get planYourVisit => 'Plan your visit';

  @override
  String get planYourVisitBody =>
      'Tell us when you are coming and we will have your phone, bill and EMI papers ready.';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get closedThatDay => 'The store is closed that day. Pick another day.';

  @override
  String get tellShopIAmComing => 'Tell the shop I am coming';

  @override
  String get visitNoted => 'Noted. We will see you then.';

  @override
  String get inTheShop => 'In the shop';

  @override
  String get shopLine1 => 'New phones from every major brand';

  @override
  String get shopLine2 =>
      'Cash, UPI, cards and Bajaj Finserv EMI at the counter';

  @override
  String get shopLine3 => 'Exchange your old phone on the spot';

  @override
  String get shopLine4 => 'Screen, battery and charging repair';

  @override
  String get shopLine5 => 'SIM, recharge and free setup help';

  @override
  String get signInTitle => 'Sign in to Brandhoop';

  @override
  String get signInBody =>
      'Enter your mobile number. We will send a 6-digit code.';

  @override
  String get sendCode => 'Send code';

  @override
  String get enterCode => 'Enter the code';

  @override
  String codeSentTo(String phone) {
    return 'Code sent to +91 $phone';
  }

  @override
  String get sixDigitCode => '6-digit code';

  @override
  String demoCodeHint(String code) {
    return 'Demo mode: the code is $code';
  }

  @override
  String get referralCode => 'Referral code';

  @override
  String get verifyAndContinue => 'Verify and continue';

  @override
  String get changeNumber => 'Change number';

  @override
  String get tryAs => 'Demo: try the app as';

  @override
  String demoAccountsHint(String owner, String customer) {
    return 'Or sign in with owner $owner or customer $customer, code 123456.';
  }

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get orderTotal => 'Order total';

  @override
  String get howToReceive => 'How would you like to receive it?';

  @override
  String get addAddress => 'Add address';

  @override
  String get offersAndCoins => 'Offers and coins';

  @override
  String get payWith => 'Pay with';

  @override
  String get orderSummary => 'Order summary';

  @override
  String get couponCode => 'Coupon code';

  @override
  String get coupon => 'Coupon';

  @override
  String get couponNotFound => 'This coupon code does not exist.';

  @override
  String get couponNotActive => 'This coupon has expired or is switched off.';

  @override
  String get couponMinOrder => 'Add more to your cart to use this coupon.';

  @override
  String get couponNotApplicable =>
      'This coupon does not apply to the items in your cart.';

  @override
  String couponApplied(String code, String amount) {
    return '$code applied: you save $amount';
  }

  @override
  String get coinsUsed => 'Brandhoop Coins';

  @override
  String useCoins(int coins) {
    String _temp0 = intl.Intl.pluralLogic(
      coins,
      locale: localeName,
      other: 'Use my $coins Brandhoop Coins',
      one: 'Use my 1 Brandhoop Coin',
    );
    return '$_temp0';
  }

  @override
  String get coinsRule =>
      'One coin is one rupee off accessories, up to a share of the accessory bill.';

  @override
  String reserveExplain(String token, String hours, String rest) {
    return 'Pay $token now. We hold the phone for $hours. Pay the remaining $rest when you visit.';
  }

  @override
  String get chooseTenure => 'Choose how many months';

  @override
  String get zeroInterest => '0% interest';

  @override
  String get downPayment => 'Down payment';

  @override
  String downPaymentMin(String amount) {
    return 'Minimum down payment: $amount';
  }

  @override
  String downPaymentFrom(String amount) {
    return 'Down payment from $amount';
  }

  @override
  String get amountFinanced => 'Amount financed';

  @override
  String get interestRate => 'Interest rate';

  @override
  String get perYear => 'a year';

  @override
  String get totalInterest => 'Total interest';

  @override
  String get processingFeeLabel => 'Processing fee';

  @override
  String processingFee(String fee) {
    return 'Processing fee $fee';
  }

  @override
  String get totalYouPay => 'Total you pay';

  @override
  String totalPayable(String amount) {
    return 'Total $amount';
  }

  @override
  String get noExtraCost => 'No extra cost';

  @override
  String get emiIndicative =>
      'These figures are indicative. The final amount, rate and approval are decided by the lender.';

  @override
  String get emiRatesUnconfirmed =>
      'The shop is still confirming its EMI rates, so treat these as estimates.';

  @override
  String get noEmiForThis => 'EMI is not available for this amount or product.';

  @override
  String get emiOptions => 'EMI options';

  @override
  String get openCalculator => 'Open EMI calculator';

  @override
  String payDownHow(String amount) {
    return 'Pay $amount now';
  }

  @override
  String get payOnlineNow => 'Pay online now';

  @override
  String get payAtStoreLater => 'Pay at the store';

  @override
  String get whatHappensNext => 'What happens next';

  @override
  String get bajajStep1 =>
      'You send this application and pay the down payment.';

  @override
  String get bajajStep2 =>
      'Visit the store with your Aadhaar, PAN and bank details. We complete the Bajaj Finserv check with you.';

  @override
  String get bajajStep3 =>
      'Once Bajaj Finserv approves, your phone is handed over with the bill and IMEI.';

  @override
  String get bajajStep4 =>
      'You pay the monthly EMI. Turn on Autopay in this app so you never miss a date.';

  @override
  String applyAndPay(String amount) {
    return 'Apply and pay $amount';
  }

  @override
  String get applyForEmi => 'Apply for EMI';

  @override
  String get placeOrder => 'Place order';

  @override
  String payAmount(String amount) {
    return 'Pay $amount';
  }

  @override
  String reserveFor(String amount) {
    return 'Reserve for $amount';
  }

  @override
  String get deliveryFee => 'Delivery';

  @override
  String totalSavings(String amount) {
    return 'You save $amount on this order';
  }

  @override
  String get orEnterUpiId => 'Or enter a UPI ID';

  @override
  String get errBadUpi => 'That UPI ID does not look right.';

  @override
  String get cardNumber => 'Card number';

  @override
  String get errBadCard => 'That card number is not valid.';

  @override
  String get cardExpiry => 'Expiry';

  @override
  String get errBadExpiry => 'That expiry date is not valid.';

  @override
  String get nameOnCard => 'Name on card';

  @override
  String get testPaymentHint =>
      'Test mode: no real money moves. Use card 4111 1111 1111 1111 with any future date and CVV. UPI ID fail@upi shows a failed payment.';

  @override
  String get activeOrders => 'Active';

  @override
  String get pastOrders => 'Past';

  @override
  String get signInToSeeOrders => 'Sign in to see your orders';

  @override
  String get signInToSeeOrdersHint =>
      'Your orders, bills and warranty are saved to your mobile number.';

  @override
  String get noOrdersYet => 'No orders yet';

  @override
  String get noOrdersYetHint =>
      'When you buy, your order and its tracking will appear here.';

  @override
  String get paymentNotDone => 'Payment not completed';

  @override
  String get paymentNotDoneHint =>
      'Your order is saved. Pay now to confirm it, or it is released in 30 minutes.';

  @override
  String get orderPlacedTitle => 'Order placed';

  @override
  String orderNumberIs(String number) {
    return 'Your order number is $number';
  }

  @override
  String get showThisCode => 'Show this code at the store';

  @override
  String nextCod(String amount) {
    return 'Keep $amount in cash ready. Our team will call before delivery.';
  }

  @override
  String nextCashStore(String amount) {
    return 'We are keeping it ready. Pay $amount in cash when you collect.';
  }

  @override
  String nextReserve(String balance, String until) {
    return 'Your phone is held for you. Come in before $until and pay the remaining $balance.';
  }

  @override
  String get nextBajaj =>
      'Visit the store with your Aadhaar, PAN and bank details to finish the Bajaj Finserv application. We will call you to confirm.';

  @override
  String get nextPickup =>
      'We will message you when it is ready to collect. Show the code below at the counter.';

  @override
  String get nextDelivery =>
      'We are getting it ready. You can track every step here.';

  @override
  String get viewOrder => 'View order';

  @override
  String get continueShopping => 'Continue shopping';

  @override
  String get tryAnotherWay => 'Pay now';

  @override
  String get orderNotFound => 'Order not found';

  @override
  String get shareInvoice => 'Share bill';

  @override
  String get pickupCode => 'Pickup code';

  @override
  String reservedUntil(String when) {
    return 'Held for you until $when';
  }

  @override
  String get trackOrder => 'Track order';

  @override
  String get itemsHeader => 'Items';

  @override
  String get paymentHeader => 'Payment';

  @override
  String get paymentMode => 'Payment method';

  @override
  String get balanceDue => 'Balance due';

  @override
  String balanceToPay(String amount) {
    return 'Balance to pay: $amount';
  }

  @override
  String get reserveTokenLabel => 'Reserve token';

  @override
  String get viewEmiPlan => 'View EMI plan';

  @override
  String get pickupHeader => 'Collect from the store';

  @override
  String get deliveryHeader => 'Delivery address';

  @override
  String get cancelOrder => 'Cancel order';

  @override
  String get cancelOrderQ => 'Cancel this order?';

  @override
  String get reasonOptional => 'Reason (optional)';

  @override
  String get orderCancelled =>
      'The order is cancelled. Any payment you made will be refunded.';

  @override
  String get returnItems => 'Return';

  @override
  String get returnOrderQ => 'Request a return?';

  @override
  String get returnRequestedMsg => 'Return requested. We will call you.';

  @override
  String get orderAgain => 'Order again';

  @override
  String get needHelp => 'Need help?';

  @override
  String warrantyUntil(String date) {
    return 'Warranty until $date';
  }

  @override
  String get invoiceOrder => 'Order';

  @override
  String get invoiceDate => 'Date';

  @override
  String get invoiceCustomer => 'Customer';

  @override
  String get invoiceItems => 'Items';

  @override
  String invoiceThanks(String shop) {
    return 'Thank you for shopping at $shop.';
  }

  @override
  String get emiAndAutopay => 'EMI and Autopay';

  @override
  String get emiSignInTitle => 'Sign in to see your EMI';

  @override
  String get emiSignInBody =>
      'Your plans, due dates and Autopay settings are kept against your mobile number.';

  @override
  String get noEmiPlans => 'No EMI plans yet';

  @override
  String get noEmiPlansBody =>
      'Buy a phone on 0% or easy EMI and the plan, dates and Autopay will show up here.';

  @override
  String get browseEmiPhones => 'Browse phones on EMI';

  @override
  String get yourEmiPlans => 'Your EMI plans';

  @override
  String get emiHowItWorks => 'How EMI works at Brandhoop';

  @override
  String get emiPointBajaj =>
      'Bajaj Finserv EMI: a small down payment, then easy monthly instalments. Approval is by Bajaj Finserv.';

  @override
  String get emiPointCard =>
      'Card EMI: turn the bill into instalments on your credit or debit card, if your bank offers it.';

  @override
  String get emiPointAutopay =>
      'Autopay: each instalment is debited on its date. Pause or cancel any time.';

  @override
  String get emiPointDocs =>
      'Keep your Aadhaar, PAN and bank details handy for the Bajaj Finserv check.';

  @override
  String get nextEmiDue => 'Next EMI due';

  @override
  String get emiOverdue => 'EMI overdue';

  @override
  String inDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'in $days days',
      one: 'tomorrow',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String paidOf(int paid, int total) {
    return '$paid of $total paid';
  }

  @override
  String nextOn(String date) {
    return 'Next: $date';
  }

  @override
  String get emiPlan => 'EMI plan';

  @override
  String get planNotFound => 'Plan not found';

  @override
  String get itemPrice => 'Item price';

  @override
  String get tenure => 'Tenure';

  @override
  String get monthlyEmi => 'Monthly EMI';

  @override
  String get lenderRef => 'Loan reference';

  @override
  String get planAppliedHint =>
      'Your application is with the shop and the lender. We will call you to finish it in the store.';

  @override
  String get planRejectedHint =>
      'This application was not approved. You can still buy the phone with another way of paying. Please speak to the shop.';

  @override
  String get instalmentSchedule => 'Instalment schedule';

  @override
  String paidOn(String date) {
    return 'Paid on $date';
  }

  @override
  String get openBajajApp => 'Pay or view on Bajaj Finserv';

  @override
  String get bankAutoDebit =>
      'Your bank debits this EMI to your card each month. Keep enough limit available.';

  @override
  String get autopaySettings => 'Autopay settings';

  @override
  String get autopayOnBody =>
      'Each instalment is debited on its due date, up to your limit. We remind you before every debit.';

  @override
  String get autopayOffBody =>
      'Turn on Autopay so you never miss an instalment. You stay in control and can stop it any time.';

  @override
  String get autopayMethodLabel => 'Method';

  @override
  String get autopayAccount => 'Account';

  @override
  String get autopayLimit => 'Debit limit';

  @override
  String get nextDebit => 'Next debit';

  @override
  String get remindMe => 'Remind me';

  @override
  String daysBefore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days before',
      one: '1 day before',
      zero: 'On the day',
    );
    return '$_temp0';
  }

  @override
  String get pauseAutopay => 'Pause Autopay';

  @override
  String get cancelAutopay => 'Cancel Autopay';

  @override
  String get cancelAutopayQ => 'Cancel Autopay?';

  @override
  String get cancelAutopayBody =>
      'Future instalments will not be debited automatically. You will need to pay them yourself before the due date.';

  @override
  String get resumeAutopay => 'Resume Autopay';

  @override
  String get turnOnAutopay => 'Turn on Autopay';

  @override
  String get setupAutopayAgain => 'Set up Autopay again';

  @override
  String get autopayLenderNote =>
      'For Bajaj Finserv plans, the lender runs the final debit. This screen shows its status and your reminder.';

  @override
  String autopaySheetBody(String emi) {
    return 'Choose how your $emi instalment should be paid each month.';
  }

  @override
  String autopayConsent(String limit) {
    return 'I allow automatic debit of each instalment, up to $limit, on its due date. I can pause or cancel this any time.';
  }

  @override
  String get authoriseAutopay => 'Authorise Autopay';

  @override
  String get phonePrice => 'Phone price';

  @override
  String get emiScheme => 'EMI scheme';

  @override
  String priceOutsideScheme(String min) {
    return 'This scheme starts from $min. Choose another scheme or a higher price.';
  }

  @override
  String get exchangeIntro =>
      'Tell us about your old phone and see an indicative value. The shop confirms the final price after a quick check.';

  @override
  String get model => 'Model';

  @override
  String get priceWhenNew => 'Price when new (approx.)';

  @override
  String get howOld => 'How old is it?';

  @override
  String get ageUnder6 => 'Under 6 months';

  @override
  String get age6to12 => '6 to 12 months';

  @override
  String get age1to2 => '1 to 2 years';

  @override
  String get age2to3 => '2 to 3 years';

  @override
  String get ageOver3 => 'Over 3 years';

  @override
  String get screenCondition => 'Screen condition';

  @override
  String get screenPerfect => 'Perfect';

  @override
  String get screenScratches => 'Light scratches';

  @override
  String get screenCracked => 'Cracked';

  @override
  String get bodyDents => 'Dents or damage on the body';

  @override
  String get batteryWeak => 'Battery drains fast';

  @override
  String get allWorking => 'Everything works (camera, speaker, touch, buttons)';

  @override
  String get haveBill => 'I have the bill and box';

  @override
  String get estimatedValue => 'Indicative value';

  @override
  String get exchangeIndicative =>
      'This is only a guide. The final value is set after the shop checks your phone, and may be higher or lower.';

  @override
  String get sendToShop => 'Send to the shop';

  @override
  String get exchangeEnterPrice =>
      'Enter roughly what the phone cost when new to see its value.';

  @override
  String get exchangeSent => 'Sent. We will call you with the next step.';

  @override
  String get repairIntro =>
      'Book a repair from home. Bring the phone in or ask us to collect it, and follow every step here.';

  @override
  String get whatIsWrong => 'What is wrong?';

  @override
  String fromPrice(String price) {
    return 'from $price';
  }

  @override
  String get describeProblem => 'Describe the problem (optional)';

  @override
  String get repairHowItWorks =>
      'The price shown is a starting estimate. We check the phone, tell you the exact price, and repair only after you agree.';

  @override
  String get bookRepair => 'Book repair';

  @override
  String get myRepairs => 'My repairs';

  @override
  String get enterBrandModel => 'Please enter the phone brand and model.';

  @override
  String repairBookedMsg(String number) {
    return 'Repair booked: $number';
  }

  @override
  String get estimatedPrice => 'Estimated price';

  @override
  String get quotedPrice => 'Final price';

  @override
  String repairApprovePrompt(String price) {
    return 'The shop has checked your phone. The repair will cost $price. Approve to start.';
  }

  @override
  String get approveAndRepair => 'Approve and repair';

  @override
  String get progress => 'Progress';

  @override
  String get cancelRepairQ => 'Cancel this repair?';

  @override
  String get welcomeGuest => 'Welcome to Brandhoop';

  @override
  String coinsBalance(int coins) {
    String _temp0 = intl.Intl.pluralLogic(
      coins,
      locale: localeName,
      other: '$coins coins',
      one: '1 coin',
    );
    return '$_temp0';
  }

  @override
  String get myAccount => 'My account';

  @override
  String get myProfile => 'My profile';

  @override
  String get myAddresses => 'My addresses';

  @override
  String get referAndEarn => 'Refer and earn';

  @override
  String referShareText(String shop, String code, String bonus) {
    return 'Buy phones and accessories from $shop on the Brandhoop app. Use my code $code and we both get $bonus in coins after your first purchase.';
  }

  @override
  String get settingsHeader => 'Settings';

  @override
  String get languageLabel => 'Language';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeSystem => 'Phone setting';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get helpHeader => 'Help';

  @override
  String get helpAndFaq => 'Help and FAQ';

  @override
  String get signOutQ => 'Sign out?';

  @override
  String get phoneCannotChange =>
      'Your mobile number is your account and cannot be changed here.';

  @override
  String get myReferralCode => 'My referral code';

  @override
  String get noAddresses => 'No saved addresses';

  @override
  String get noAddressesHint => 'Add an address to get home delivery.';

  @override
  String get deleteAddressQ => 'Delete this address?';

  @override
  String get editAddress => 'Edit address';

  @override
  String get addrHome => 'Home';

  @override
  String get addrShop => 'Shop';

  @override
  String get addrWork => 'Work';

  @override
  String get addrOther => 'Other';

  @override
  String get fullName => 'Full name';

  @override
  String get houseNoStreet => 'House no. and street';

  @override
  String get colonyOrVillage => 'Colony, mohalla or village';

  @override
  String get landmark => 'Landmark';

  @override
  String get cityTown => 'City or town';

  @override
  String get pincode => 'Pincode';

  @override
  String get stateLabel => 'State';

  @override
  String get wishlistEmpty => 'Your wishlist is empty';

  @override
  String get wishlistEmptyHint =>
      'Tap the heart on any product to save it for later.';

  @override
  String get helpBody =>
      'The quickest help is at the store. You can also call or message us.';

  @override
  String get faq1q => 'How can I pay?';

  @override
  String get faq1a =>
      'By UPI, credit or debit card, net banking, or cash (at the store, or on delivery in town). You can also use Bajaj Finserv EMI or card EMI.';

  @override
  String get faq2q => 'How does Bajaj Finserv EMI work?';

  @override
  String get faq2a =>
      'Apply in the app and pay a small down payment. Visit the store with your Aadhaar, PAN and bank details to complete the check. Once Bajaj Finserv approves, you take the phone and pay monthly. Approval is the lender decision, not the shop.';

  @override
  String get faq3q => 'What is Autopay?';

  @override
  String get faq3a =>
      'A standing instruction so each EMI is debited on its due date. You choose UPI, card or bank, set a limit, get a reminder before every debit, and can pause or cancel any time.';

  @override
  String get faq4q => 'Can I return what I bought?';

  @override
  String get faq4a =>
      'Within 7 days of delivery you can ask for a return of a wrong or defective item, with its box and bill. The shop checks it and refunds you. Opened phones are checked by the brand service centre.';

  @override
  String get faq5q => 'How does the warranty work?';

  @override
  String get faq5a =>
      'Every phone comes with the brand warranty. We record the IMEI on your bill, so your warranty and bill are always in your Orders, even if you lose the paper.';

  @override
  String get faq6q => 'How does delivery work?';

  @override
  String get faq6a =>
      'Same-day home delivery in town and nearby areas. Elsewhere we send by courier, and phones are prepaid. Cash on delivery is only for local delivery under the shop limit.';

  @override
  String get faq7q => 'What does Reserve mean?';

  @override
  String get faq7a =>
      'Pay a small token and we hold the phone for you for a few days. Visit the store, pay the rest and take it. If you cancel before the time ends, the token is refunded.';

  @override
  String roadToTarget(String target) {
    return 'Road to $target a month';
  }

  @override
  String get onTrack => 'On track';

  @override
  String get behindTarget => 'Behind target';

  @override
  String get ofTarget => 'of target';

  @override
  String get profitThisMonth => 'Profit this month';

  @override
  String projectedMonthEnd(String amount) {
    return 'On this pace: $amount by month end';
  }

  @override
  String needPerDay(String amount, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'next $days days',
      one: 'last day',
    );
    return 'Need $amount a day for the $_temp0';
  }

  @override
  String baselineLine(String baseline, String multiple) {
    return 'From about $baseline a month to the target: $multiple times today.';
  }

  @override
  String get profitBasisNote =>
      'Profit after GST and fees, before rent, salaries and power.';

  @override
  String get todaySales => 'Sales today';

  @override
  String get ordersToday => 'Orders today';

  @override
  String get needsAttention => 'Needs your attention';

  @override
  String attnOrders(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n orders to handle',
      one: '1 order to handle',
      zero: 'No orders to handle',
    );
    return '$_temp0';
  }

  @override
  String attnEmiApprovals(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n EMI applications waiting',
      one: '1 EMI application waiting',
      zero: 'No EMI applications waiting',
    );
    return '$_temp0';
  }

  @override
  String attnOverdue(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overdue instalments ($amount)',
      one: '1 overdue instalment ($amount)',
      zero: 'No overdue instalments',
    );
    return '$_temp0';
  }

  @override
  String attnLeads(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n new leads to call',
      one: '1 new lead to call',
      zero: 'No new leads',
    );
    return '$_temp0';
  }

  @override
  String attnFollowUps(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n follow-ups due',
      one: '1 follow-up due',
      zero: 'No follow-ups due',
    );
    return '$_temp0';
  }

  @override
  String attnRepairs(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n repairs waiting',
      one: '1 repair waiting',
      zero: 'No repairs waiting',
    );
    return '$_temp0';
  }

  @override
  String attnLowStock(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items low or out of stock',
      one: '1 item low or out of stock',
      zero: 'Stock looks healthy',
    );
    return '$_temp0';
  }

  @override
  String get last14Days => 'Profit, last 14 days';

  @override
  String get profit => 'Profit';

  @override
  String get whereProfitComes => 'Where the profit comes from';

  @override
  String get leverRepairs => 'Repairs';

  @override
  String get leversHint =>
      'Phones carry thin margins. Accessories, protection plans and repairs are where profit grows fastest: sell them with every phone.';

  @override
  String get growthScorecard => 'Growth scorecard (last 30 days)';

  @override
  String get scorecardHint =>
      'What you did against what the target month needs.';

  @override
  String get scPhones => 'Phones sold';

  @override
  String get scAttach => 'Phones sold with an accessory';

  @override
  String get scProtection => 'Phones sold with a protection plan';

  @override
  String get scRepairs => 'Repairs done';

  @override
  String get scLeadConv => 'Leads that became a sale';

  @override
  String get scRepeat => 'Sales to returning customers';

  @override
  String get finishSetup => 'Finish setting up your shop';

  @override
  String get finishSetupBody =>
      'The app hides buttons that need these until you add them, so customers never reach a wrong number.';

  @override
  String get setupPhone => 'Shop phone';

  @override
  String get setupWhatsapp => 'WhatsApp number';

  @override
  String get setupUpi => 'UPI ID';

  @override
  String get setupGstin => 'GSTIN';

  @override
  String get setupLocation => 'Map location';

  @override
  String get setupEmiRates => 'Confirm EMI rates';

  @override
  String get openSettings => 'Open settings';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get newSale => 'New sale';

  @override
  String get newSaleHint => 'Bill a customer at the counter';

  @override
  String get addProduct => 'Add product';

  @override
  String get runAutopayNow => 'Run Autopay now';

  @override
  String autopayRan(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Collected $n instalments.',
      one: 'Collected 1 instalment.',
      zero: 'No instalments were due.',
    );
    return '$_temp0';
  }

  @override
  String get fltToHandle => 'To handle';

  @override
  String get fltReady => 'Out or ready';

  @override
  String get fltDone => 'Done';

  @override
  String get fltCancelled => 'Cancelled';

  @override
  String get searchOrdersHint => 'Order number, name or phone';

  @override
  String get sourceCounter => 'Counter';

  @override
  String get sourceApp => 'App';

  @override
  String get customer => 'Customer';

  @override
  String orderUpdateText(String number, String status) {
    return 'Update on your order $number: $status.';
  }

  @override
  String get actMarkPaid => 'Mark as paid';

  @override
  String get actConfirm => 'Confirm order';

  @override
  String get actPack => 'Mark packed';

  @override
  String get actOut => 'Out for delivery';

  @override
  String get actReady => 'Ready for pickup';

  @override
  String get actDeliver => 'Mark delivered';

  @override
  String get actCancel => 'Cancel order';

  @override
  String get actRejectReturn => 'Reject return';

  @override
  String get actAcceptReturn => 'Accept return';

  @override
  String get confirmReturnQ => 'Accept this return?';

  @override
  String get imeiMissing => 'IMEI not entered yet';

  @override
  String get enterImei => 'Enter IMEI';

  @override
  String get imeiHelp =>
      'Dial *#06# on the phone to see its IMEI. Enter one for every phone.';

  @override
  String get discount => 'Discount';

  @override
  String get collectPayment => 'Collect payment';

  @override
  String get amount => 'Amount';

  @override
  String get referenceOptional => 'Reference (optional)';

  @override
  String get markLenderPaid => 'Lender has paid us';

  @override
  String get lenderReference => 'Lender reference';

  @override
  String sendRefund(String amount) {
    return 'Send refund $amount';
  }

  @override
  String get notes => 'Notes';

  @override
  String get stockLow => 'Low stock';

  @override
  String get hidden => 'Hidden';

  @override
  String missingCosts(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n products have no cost price, so their profit counts as zero.',
      one: '1 product has no cost price, so its profit counts as zero.',
    );
    return '$_temp0';
  }

  @override
  String get editProduct => 'Edit product';

  @override
  String get hide => 'Hide from customers';

  @override
  String get show => 'Show to customers';

  @override
  String get productName => 'Product name';

  @override
  String get categoryLabel => 'Category';

  @override
  String get variantsHeader => 'Variants and prices';

  @override
  String get addVariant => 'Add variant';

  @override
  String get variantLabel => 'Variant';

  @override
  String get colorLabel => 'Colour';

  @override
  String get sellingPrice => 'Selling price';

  @override
  String get stockLabel => 'Stock';

  @override
  String get costPrice => 'Cost price';

  @override
  String get costPriceHelp =>
      'What you paid, GST included. Customers never see it.';

  @override
  String get profitPerUnit => 'Profit per unit (after GST)';

  @override
  String get description => 'Description';

  @override
  String get imageUrls => 'Photo links';

  @override
  String get imageUrlsHelp =>
      'One web link per line. Photo upload comes with the online shop server.';

  @override
  String get tags => 'Tags';

  @override
  String get tagsHelp => 'Comma separated, e.g. refurbished, festival';

  @override
  String get sellingOptions => 'Selling options';

  @override
  String get warrantyMonthsLabel => 'Warranty (months)';

  @override
  String get gstRate => 'GST rate';

  @override
  String get emiEligible => 'Can be bought on EMI';

  @override
  String get noCostEligible => 'Eligible for 0% EMI';

  @override
  String get noCostEligibleHint =>
      'Only if your lender and the brand offer it on this model.';

  @override
  String get featuredOnHome => 'Show on the home screen';

  @override
  String get visibleToCustomers => 'Visible to customers';

  @override
  String get fltOpen => 'Open';

  @override
  String get fltFollowUpDue => 'Follow-up due';

  @override
  String get noLeads => 'No leads here';

  @override
  String get noLeadsHint =>
      'Anyone who asks about a phone, applies for EMI, books a repair or sends an exchange will appear here.';

  @override
  String followUpOn(String when) {
    return 'Follow up: $when';
  }

  @override
  String leadWhatsappText(String name, String what, String shop) {
    return 'Hello $name, this is $shop about your $what. How can we help you?';
  }

  @override
  String get yourEnquiry => 'enquiry';

  @override
  String get changeStatus => 'Change status';

  @override
  String get addNote => 'Add note';

  @override
  String get followUp => 'Follow up';

  @override
  String get emiDesk => 'EMI desk';

  @override
  String get emiDeskHint => 'Applications, approvals, due dates and Autopay';

  @override
  String get repairsDesk => 'Repairs';

  @override
  String get offersAndCoupons => 'Offers and coupons';

  @override
  String get customersTitle => 'Customers';

  @override
  String get customersHint =>
      'Everyone who has bought or asked, and who is due an upgrade';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get staffTitle => 'Staff and roles';

  @override
  String get staffHint => 'Who can do what in the app';

  @override
  String get shopSettings => 'Shop settings';

  @override
  String get resetDemoHint =>
      'You are looking at sample data. Reset it when you are ready to add your real stock.';

  @override
  String get resetDemo => 'Reset demo data';

  @override
  String get resetDemoQ => 'Reset all demo data?';

  @override
  String get resetDemoBody =>
      'This erases every order, customer and change on this device and loads the sample shop again.';

  @override
  String get addItem => 'Add item';

  @override
  String discountHelp(int pct) {
    return 'Counter staff can give up to $pct%. A manager can give more.';
  }

  @override
  String get fullCash => 'All cash';

  @override
  String get fullUpi => 'All UPI';

  @override
  String get fullCard => 'All card';

  @override
  String get addPayment => 'Add a payment';

  @override
  String get paidSoFar => 'Paid so far';

  @override
  String get financeBalanceBajaj => 'Finance the rest with Bajaj Finserv';

  @override
  String get financeBalanceHint =>
      'What the customer pays now is the down payment.';

  @override
  String get financeNeedsDown =>
      'Enter the down payment above. The rest, up to the phone price, is financed.';

  @override
  String get bajajCounterNote =>
      'The sale is held until the lender approves. IMEI is entered at hand-over.';

  @override
  String get completeSale => 'Complete sale';

  @override
  String saleDone(String number) {
    return 'Sale complete: $number';
  }

  @override
  String get saleDoneBody =>
      'The bill and warranty are now in the customer app, under their mobile number.';

  @override
  String get saleDoneEmiBody =>
      'The EMI application is open. Approve it on the EMI desk, then hand the phone over.';

  @override
  String get sendBill => 'Send bill on WhatsApp';

  @override
  String get tabApplications => 'Applications';

  @override
  String get tabActive => 'Active';

  @override
  String get tabOther => 'Closed';

  @override
  String get dueThisMonth => 'Due this month';

  @override
  String get overdueLabel => 'Overdue';

  @override
  String overdueCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n overdue',
      one: '1 overdue',
    );
    return '$_temp0';
  }

  @override
  String get approveHint =>
      'Approve only after the lender (Bajaj Finserv or the bank) has approved the loan. Then the phone can be handed over.';

  @override
  String get approvePlan => 'Approve';

  @override
  String get rejectPlan => 'Reject';

  @override
  String get lenderRefHint => 'Loan or application number';

  @override
  String get markPaid => 'Mark paid';

  @override
  String get issueLabel => 'Problem';

  @override
  String get quotePrice => 'Price quoted to the customer';

  @override
  String get partsCostPrompt => 'What did the parts cost you?';

  @override
  String moveTo(String status) {
    return 'Move to: $status';
  }

  @override
  String get waitingForCustomer =>
      'Waiting for the customer to approve the price.';

  @override
  String get customerApproved => 'Customer agreed on the phone';

  @override
  String get addOffer => 'Add offer';

  @override
  String get editOffer => 'Edit offer';

  @override
  String get noOffers => 'No offers yet';

  @override
  String get noOffersHint =>
      'Add a festival banner or a coupon code. Customers see it on the home screen and at checkout.';

  @override
  String get shareOffer => 'Share offer';

  @override
  String offerShareBanner(String title, String shop) {
    return '$title. Visit $shop or order on the Brandhoop app.';
  }

  @override
  String offerShareCoupon(String title, String code, String shop) {
    return '$title. Use code $code at $shop or on the Brandhoop app.';
  }

  @override
  String get offerTitle => 'Title';

  @override
  String get offerSubtitle => 'Subtitle';

  @override
  String get kindCoupon => 'Coupon';

  @override
  String get kindBanner => 'Banner';

  @override
  String get percentOff => 'Percent off';

  @override
  String get flatOff => 'Flat off';

  @override
  String get minOrder => 'Minimum order';

  @override
  String get maxDiscount => 'Maximum discount';

  @override
  String get appliesTo => 'Applies to';

  @override
  String get appliesToHint =>
      'Leave all unselected to apply to everything. Keep phones out of big discounts: their margin is thin.';

  @override
  String get starts => 'Starts';

  @override
  String get ends => 'Ends';

  @override
  String get activeLabel => 'Active';

  @override
  String get deleteOfferQ => 'Delete this offer?';

  @override
  String get searchCustomersHint => 'Name or phone';

  @override
  String get segUpgrade => 'Due an upgrade';

  @override
  String get segTop => 'Top spenders';

  @override
  String get segRepeat => 'Repeat buyers';

  @override
  String get segNew => 'New this month';

  @override
  String get upgradeHint =>
      'These customers bought their last phone more than 18 months ago. They are the likeliest to buy again.';

  @override
  String get tapCustomerToMessage =>
      'Open a customer to send them an offer on WhatsApp.';

  @override
  String ordersCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n orders',
      one: '1 order',
      zero: 'No orders',
    );
    return '$_temp0';
  }

  @override
  String customerSince(String date) {
    return 'Customer since $date';
  }

  @override
  String get addedAtCounter => 'added at the counter';

  @override
  String get lifetimeSpend => 'Total bought';

  @override
  String get coinsLabel => 'Brandhoop Coins';

  @override
  String get lastPhoneBought => 'Last phone bought';

  @override
  String get sendOffer => 'Send offer';

  @override
  String get sendUpgrade => 'Upgrade message';

  @override
  String customerOfferText(String name, String shop) {
    return 'Hello $name! $shop has new offers on phones and accessories this week. Visit us or reply here to know more.';
  }

  @override
  String upgradeText(String name, String shop) {
    return 'Hello $name! It has been a while since your last phone from $shop. Come and see what you get for your old phone on the latest models.';
  }

  @override
  String get addStaff => 'Add staff';

  @override
  String get staffExplain =>
      'Give a mobile number a role. When that person signs in with the code, they see the back office that role allows.';

  @override
  String get roleLabel => 'Role';

  @override
  String makeRole(String role) {
    return 'Make $role';
  }

  @override
  String get disableAccount => 'Switch off this account';

  @override
  String get enableAccount => 'Switch this account on';

  @override
  String get disabled => 'Switched off';

  @override
  String get staffAdded => 'Added. They can sign in with their mobile number.';

  @override
  String get whatEachRoleCanDo => 'What each role can do';

  @override
  String get roleStaffCan =>
      'Bills at the counter, handles orders and leads, runs repairs, adjusts stock. Cannot see costs or profit, change prices, or approve EMI.';

  @override
  String get roleManagerCan =>
      'Everything staff can do, plus products, prices, cost prices, offers, EMI approvals and reports. Cannot see profit totals, staff or settings.';

  @override
  String get roleOwnerCan =>
      'Everything, including profit and the road to the target, refunds, staff and shop settings.';

  @override
  String get exportCsv => 'Copy as CSV';

  @override
  String get csvCopied => 'Copied. Paste it into a spreadsheet.';

  @override
  String get last7Days => 'Last 7 days';

  @override
  String get last30Days => 'Last 30 days';

  @override
  String get thisMonth => 'This month';

  @override
  String get revenue => 'Sales';

  @override
  String get ordersLabel => 'Orders';

  @override
  String get avgOrder => 'Average order';

  @override
  String get phonesSold => 'Phones sold';

  @override
  String get margin => 'Profit margin';

  @override
  String get dailyProfitRevenue => 'Day by day';

  @override
  String get salesByGroup => 'Sales by type';

  @override
  String get paymentMix => 'How customers paid';

  @override
  String get topProducts => 'Best sellers';

  @override
  String unitsSold(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sold',
      one: '1 sold',
    );
    return '$_temp0';
  }

  @override
  String get setShopInfo => 'Shop details';

  @override
  String get shopName => 'Shop name';

  @override
  String get tagline => 'Tagline';

  @override
  String get shopPhone => 'Shop phone';

  @override
  String get shopPhoneHelp =>
      'Customers tap this to call. Leave empty to hide the Call button.';

  @override
  String get shopWhatsapp => 'WhatsApp number';

  @override
  String get addressLabel => 'Address';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get mapsLink => 'Google Maps link';

  @override
  String get mapsLinkHelp =>
      'Optional. Open the shop on Google Maps, tap Share, paste the link here.';

  @override
  String get shopUpi => 'Shop UPI ID';

  @override
  String get shopUpiHelp => 'Where counter UPI payments go.';

  @override
  String get shopGstin => 'GSTIN';

  @override
  String get opens => 'Opens';

  @override
  String get closes => 'Closes';

  @override
  String get deliveryAndOrders => 'Delivery and orders';

  @override
  String get localPincodes => 'Pincodes you deliver to yourself';

  @override
  String get localPincodesHelp =>
      'Comma separated. Same-day delivery and cash on delivery work only here.';

  @override
  String get localDeliveryFee => 'Local delivery fee';

  @override
  String get courierFee => 'Courier fee';

  @override
  String get freeDeliveryAbove => 'Free delivery above';

  @override
  String get reserveHoursLabel => 'Reserve hours';

  @override
  String get codLimit => 'Cash on delivery limit';

  @override
  String get allowCod => 'Allow cash on delivery in town';

  @override
  String get allowReserve => 'Allow reserve with a token';

  @override
  String get financeSettings => 'EMI and Autopay';

  @override
  String get financeSettingsHint =>
      'These rates start as placeholders. Replace them with what Bajaj Finserv and your card banks have agreed with you, then tick Rates confirmed.';

  @override
  String get allowBajaj => 'Offer Bajaj Finserv EMI';

  @override
  String get allowCardEmi => 'Offer card EMI';

  @override
  String get allowAutopay => 'Offer Autopay';

  @override
  String get allowShopInstalments => 'Instalments collected by the shop itself';

  @override
  String get allowShopInstalmentsHint =>
      'Keep off until you have taken advice: collecting instalments yourself can fall under lending and deposit rules.';

  @override
  String get ratesConfirmed => 'Rates confirmed';

  @override
  String get ratesConfirmedHint =>
      'Switch on only when the rates below are the real ones.';

  @override
  String get lenderRateLabel => 'Lender rate % a year';

  @override
  String get minPrice => 'Minimum price';

  @override
  String get minDownPct => 'Minimum down payment %';

  @override
  String get tenuresLabel => 'Months offered';

  @override
  String get tenuresHelp => 'Comma separated, e.g. 3, 6, 9, 12';

  @override
  String get noCostCostNote =>
      'On a 0% scheme the customer pays only the price. The interest the lender would charge is counted as a cost of the sale in your profit.';

  @override
  String get targetsAndFees => 'Target, fees and rewards';

  @override
  String get monthlyTarget => 'Monthly profit target';

  @override
  String get baselineProfit => 'Profit before the app';

  @override
  String get cardFee => 'Card fee %';

  @override
  String get upiFee => 'UPI fee %';

  @override
  String get profitAfterGst => 'Count profit after GST';

  @override
  String get profitAfterGstHint =>
      'The GST on your margin goes to the government, so it is not yours to keep.';

  @override
  String get coinsEarnPct => 'Coins earned % (accessories)';

  @override
  String get referralBonus => 'Referral bonus (coins)';

  @override
  String get maxCoinsPct => 'Max coins use %';

  @override
  String get repairPricesHeader => 'Repair starting prices';

  @override
  String get liveOrderCta => 'Send order on WhatsApp';

  @override
  String liveOrderIntro(String shop) {
    return 'Hello $shop, I would like to reserve these items from your app:';
  }

  @override
  String liveOrderTotal(String amount) {
    return 'Total: $amount';
  }

  @override
  String get liveOrderOutro =>
      'Please confirm availability and today’s offers. I will visit the shop.';

  @override
  String get liveCartHint =>
      'Your order goes to the shop on WhatsApp. The shop confirms stock, price and offers. Pay online by UPI or card as the shop tells you, or pay at the shop. Bajaj Finserv EMI is only at the shop (face scan needed).';

  @override
  String get liveShareTitle => 'Send this to the shop';

  @override
  String get liveShareBody =>
      'The shop’s WhatsApp number is not set in the app yet. Share this message with the shop, or visit the store.';

  @override
  String get liveCatalogTitle => 'Our catalogue is being updated';

  @override
  String get liveCatalogBody =>
      'Visit the shop or message us on WhatsApp for today’s phones, prices and Diwali offers.';

  @override
  String liveRepairMsg(String shop, String device, String issue) {
    return 'Hello $shop, I want a repair quote for $device. Issue: $issue.';
  }

  @override
  String liveVisitMsg(String shop, String when) {
    return 'Hello $shop, I will visit the shop on $when.';
  }

  @override
  String liveExchangeMsg(String shop, String device, String range) {
    return 'Hello $shop, I want to exchange my $device. The app estimate is $range. Please confirm after seeing the phone.';
  }

  @override
  String get liveWhyPayBody =>
      'UPI and cards online, cash at the shop. Bajaj Finserv EMI only at the shop (face scan needed).';

  @override
  String get liveEmiTitle => 'EMI at Brandhoop';

  @override
  String get liveEmiBody =>
      'We offer EMI with Bajaj Finserv. It is available only at the shop, because it needs a face scan. Approval, the rate and the final instalments are decided by the lender. Ask at the shop for today’s schemes and rates.';

  @override
  String get liveEmiShopOnly =>
      'Bajaj Finserv EMI is available only at the shop, because it needs a face scan. Approval and the rate are decided by the lender.';

  @override
  String get liveRefPrice => 'Reference price';

  @override
  String get liveCallForBest => 'Call for best price';

  @override
  String get liveBargainBtn => 'Call to bargain';

  @override
  String get liveWhatsappAsk => 'Ask offer on WhatsApp';

  @override
  String liveBargainMsg(String shop, String product, String price) {
    return 'Hello $shop, I am interested in $product (reference price $price). Please tell me today’s best price and the gifts and offers.';
  }

  @override
  String liveBargainMsgNoPrice(String shop, String product) {
    return 'Hello $shop, I am interested in $product. Please tell me today’s best price and the gifts and offers.';
  }

  @override
  String liveGenericAsk(String shop) {
    return 'Hello $shop, please tell me today’s best prices, gifts and offers on mobile phones.';
  }

  @override
  String get liveAskAvailability => 'Ask the shop for availability';

  @override
  String get liveGiftTitle => 'Gift and offers';

  @override
  String liveGiftWorth(String amount) {
    return 'Gift worth $amount';
  }

  @override
  String liveYouSave(String amount) {
    return 'You save $amount';
  }

  @override
  String liveTotalBenefit(String amount) {
    return 'Total benefit $amount';
  }

  @override
  String get liveRefNote =>
      'The reference price is from online listings and can differ. Prices change often: call or WhatsApp now for today’s best price, gifts and EMI help at the shop.';

  @override
  String get livePriceOnCall => 'Price on call';

  @override
  String get liveWorryTitle => 'Worried prices will go up?';

  @override
  String get liveWorryBody =>
      'Phone prices change often. Call or message us today for the best price, gifts and easy EMI at the shop, and buy without waiting.';

  @override
  String get liveWorryCta => 'Get today’s best price';

  @override
  String get liveGalleryTitle => 'Festival gifts and offers';
}
