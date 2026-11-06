import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Brandhoop'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your own mobile shop, now in your pocket'**
  String get appTagline;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @chooseLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'You can change it any time from the top of the screen.'**
  String get chooseLanguageHint;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get languageHindi;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageShortHi.
  ///
  /// In en, this message translates to:
  /// **'हिं'**
  String get languageShortHi;

  /// No description provided for @languageShortEn.
  ///
  /// In en, this message translates to:
  /// **'EN'**
  String get languageShortEn;

  /// No description provided for @switchLanguage.
  ///
  /// In en, this message translates to:
  /// **'Switch language'**
  String get switchLanguage;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @applied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get applied;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get noResults;

  /// No description provided for @tryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again in a moment.'**
  String get tryAgainLater;

  /// No description provided for @somethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWrong;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get perMonth;

  /// No description provided for @perMonthShort.
  ///
  /// In en, this message translates to:
  /// **'/mo'**
  String get perMonthShort;

  /// No description provided for @freeLabel.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freeLabel;

  /// No description provided for @inclGst.
  ///
  /// In en, this message translates to:
  /// **'Incl. GST'**
  String get inclGst;

  /// No description provided for @sample.
  ///
  /// In en, this message translates to:
  /// **'Sample'**
  String get sample;

  /// No description provided for @demoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo mode'**
  String get demoMode;

  /// No description provided for @demoBanner.
  ///
  /// In en, this message translates to:
  /// **'Demo mode: sample products, simulated payments, no real money moves.'**
  String get demoBanner;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String itemsCount(int count);

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day left} other{{count} days left}}'**
  String daysLeft(int count);

  /// No description provided for @monthsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String monthsCount(int count);

  /// No description provided for @hoursCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String hoursCount(int count);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get navShop;

  /// No description provided for @navEmi.
  ///
  /// In en, this message translates to:
  /// **'EMI'**
  String get navEmi;

  /// No description provided for @navOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navOrders;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get navStock;

  /// No description provided for @navLeads.
  ///
  /// In en, this message translates to:
  /// **'Leads'**
  String get navLeads;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @catSmartphone.
  ///
  /// In en, this message translates to:
  /// **'Smartphones'**
  String get catSmartphone;

  /// No description provided for @catFeaturePhone.
  ///
  /// In en, this message translates to:
  /// **'Feature phones'**
  String get catFeaturePhone;

  /// No description provided for @catTablet.
  ///
  /// In en, this message translates to:
  /// **'Tablets'**
  String get catTablet;

  /// No description provided for @catEarphones.
  ///
  /// In en, this message translates to:
  /// **'Earphones and buds'**
  String get catEarphones;

  /// No description provided for @catCharger.
  ///
  /// In en, this message translates to:
  /// **'Chargers'**
  String get catCharger;

  /// No description provided for @catCable.
  ///
  /// In en, this message translates to:
  /// **'Cables'**
  String get catCable;

  /// No description provided for @catCase.
  ///
  /// In en, this message translates to:
  /// **'Cases and covers'**
  String get catCase;

  /// No description provided for @catScreenGuard.
  ///
  /// In en, this message translates to:
  /// **'Screen guards'**
  String get catScreenGuard;

  /// No description provided for @catPowerBank.
  ///
  /// In en, this message translates to:
  /// **'Power banks'**
  String get catPowerBank;

  /// No description provided for @catSmartwatch.
  ///
  /// In en, this message translates to:
  /// **'Smartwatches'**
  String get catSmartwatch;

  /// No description provided for @catSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Speakers'**
  String get catSpeaker;

  /// No description provided for @catMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory cards'**
  String get catMemory;

  /// No description provided for @catProtection.
  ///
  /// In en, this message translates to:
  /// **'Protection plans'**
  String get catProtection;

  /// No description provided for @groupPhones.
  ///
  /// In en, this message translates to:
  /// **'Phones'**
  String get groupPhones;

  /// No description provided for @groupAccessories.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get groupAccessories;

  /// No description provided for @groupProtection.
  ///
  /// In en, this message translates to:
  /// **'Protection'**
  String get groupProtection;

  /// No description provided for @groupAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get groupAll;

  /// No description provided for @specRam.
  ///
  /// In en, this message translates to:
  /// **'RAM'**
  String get specRam;

  /// No description provided for @specStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get specStorage;

  /// No description provided for @specDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get specDisplay;

  /// No description provided for @specBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get specBattery;

  /// No description provided for @specCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get specCamera;

  /// No description provided for @specChip.
  ///
  /// In en, this message translates to:
  /// **'Processor'**
  String get specChip;

  /// No description provided for @specOs.
  ///
  /// In en, this message translates to:
  /// **'Operating system'**
  String get specOs;

  /// No description provided for @statusPendingPayment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment'**
  String get statusPendingPayment;

  /// No description provided for @statusPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order placed'**
  String get statusPlaced;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusPacked.
  ///
  /// In en, this message translates to:
  /// **'Packed'**
  String get statusPacked;

  /// No description provided for @statusOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for delivery'**
  String get statusOutForDelivery;

  /// No description provided for @statusReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready to collect'**
  String get statusReadyForPickup;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusReturnRequested.
  ///
  /// In en, this message translates to:
  /// **'Return requested'**
  String get statusReturnRequested;

  /// No description provided for @statusReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get statusReturned;

  /// No description provided for @fulfilDelivery.
  ///
  /// In en, this message translates to:
  /// **'Home delivery'**
  String get fulfilDelivery;

  /// No description provided for @fulfilPickup.
  ///
  /// In en, this message translates to:
  /// **'Pick up at the store'**
  String get fulfilPickup;

  /// No description provided for @fulfilWalkIn.
  ///
  /// In en, this message translates to:
  /// **'Bought in the store'**
  String get fulfilWalkIn;

  /// No description provided for @payMethodUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get payMethodUpi;

  /// No description provided for @payMethodCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get payMethodCard;

  /// No description provided for @payMethodNetbanking.
  ///
  /// In en, this message translates to:
  /// **'Net banking'**
  String get payMethodNetbanking;

  /// No description provided for @payMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get payMethodCash;

  /// No description provided for @payMethodBajaj.
  ///
  /// In en, this message translates to:
  /// **'Bajaj Finserv EMI'**
  String get payMethodBajaj;

  /// No description provided for @payMethodCardEmi.
  ///
  /// In en, this message translates to:
  /// **'Card EMI'**
  String get payMethodCardEmi;

  /// No description provided for @payModeFull.
  ///
  /// In en, this message translates to:
  /// **'Paid in full'**
  String get payModeFull;

  /// No description provided for @payModeToken.
  ///
  /// In en, this message translates to:
  /// **'Reserved with a token'**
  String get payModeToken;

  /// No description provided for @payModeCod.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery'**
  String get payModeCod;

  /// No description provided for @payModeCashStore.
  ///
  /// In en, this message translates to:
  /// **'Cash at the store'**
  String get payModeCashStore;

  /// No description provided for @payModeBajaj.
  ///
  /// In en, this message translates to:
  /// **'Bajaj Finserv EMI'**
  String get payModeBajaj;

  /// No description provided for @payModeCardEmi.
  ///
  /// In en, this message translates to:
  /// **'Card EMI'**
  String get payModeCardEmi;

  /// No description provided for @payModeMixed.
  ///
  /// In en, this message translates to:
  /// **'Part payments'**
  String get payModeMixed;

  /// No description provided for @payStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get payStatusPending;

  /// No description provided for @payStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get payStatusPaid;

  /// No description provided for @payStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get payStatusFailed;

  /// No description provided for @payKindRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get payKindRefund;

  /// No description provided for @payKindLender.
  ///
  /// In en, this message translates to:
  /// **'Paid by lender'**
  String get payKindLender;

  /// No description provided for @planApplied.
  ///
  /// In en, this message translates to:
  /// **'Application sent'**
  String get planApplied;

  /// No description provided for @planApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get planApproved;

  /// No description provided for @planActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get planActive;

  /// No description provided for @planClosed.
  ///
  /// In en, this message translates to:
  /// **'Fully paid'**
  String get planClosed;

  /// No description provided for @planRejected.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get planRejected;

  /// No description provided for @planCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get planCancelled;

  /// No description provided for @instUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get instUpcoming;

  /// No description provided for @instPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get instPaid;

  /// No description provided for @instOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get instOverdue;

  /// No description provided for @autopayNotSet.
  ///
  /// In en, this message translates to:
  /// **'Autopay is off'**
  String get autopayNotSet;

  /// No description provided for @autopayPending.
  ///
  /// In en, this message translates to:
  /// **'Setting up'**
  String get autopayPending;

  /// No description provided for @autopayActive.
  ///
  /// In en, this message translates to:
  /// **'Autopay is on'**
  String get autopayActive;

  /// No description provided for @autopayPaused.
  ///
  /// In en, this message translates to:
  /// **'Autopay paused'**
  String get autopayPaused;

  /// No description provided for @autopayCancelled.
  ///
  /// In en, this message translates to:
  /// **'Autopay cancelled'**
  String get autopayCancelled;

  /// No description provided for @autopayFailed.
  ///
  /// In en, this message translates to:
  /// **'Autopay failed'**
  String get autopayFailed;

  /// No description provided for @autopayUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI Autopay'**
  String get autopayUpi;

  /// No description provided for @autopayCard.
  ///
  /// In en, this message translates to:
  /// **'Card standing instruction'**
  String get autopayCard;

  /// No description provided for @autopayBank.
  ///
  /// In en, this message translates to:
  /// **'Bank mandate (e-NACH)'**
  String get autopayBank;

  /// No description provided for @providerBajaj.
  ///
  /// In en, this message translates to:
  /// **'Bajaj Finserv'**
  String get providerBajaj;

  /// No description provided for @providerBank.
  ///
  /// In en, this message translates to:
  /// **'Your bank'**
  String get providerBank;

  /// No description provided for @providerShop.
  ///
  /// In en, this message translates to:
  /// **'Brandhoop'**
  String get providerShop;

  /// No description provided for @leadEnquiry.
  ///
  /// In en, this message translates to:
  /// **'Enquiry'**
  String get leadEnquiry;

  /// No description provided for @leadCallback.
  ///
  /// In en, this message translates to:
  /// **'Call back'**
  String get leadCallback;

  /// No description provided for @leadEmi.
  ///
  /// In en, this message translates to:
  /// **'EMI application'**
  String get leadEmi;

  /// No description provided for @leadExchange.
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get leadExchange;

  /// No description provided for @leadRepair.
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get leadRepair;

  /// No description provided for @leadReserve.
  ///
  /// In en, this message translates to:
  /// **'Reserved phone'**
  String get leadReserve;

  /// No description provided for @leadVisit.
  ///
  /// In en, this message translates to:
  /// **'Store visit'**
  String get leadVisit;

  /// No description provided for @leadFresh.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get leadFresh;

  /// No description provided for @leadContacted.
  ///
  /// In en, this message translates to:
  /// **'Contacted'**
  String get leadContacted;

  /// No description provided for @leadVisited.
  ///
  /// In en, this message translates to:
  /// **'Visited'**
  String get leadVisited;

  /// No description provided for @leadConverted.
  ///
  /// In en, this message translates to:
  /// **'Bought'**
  String get leadConverted;

  /// No description provided for @leadLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get leadLost;

  /// No description provided for @issueScreen.
  ///
  /// In en, this message translates to:
  /// **'Cracked or dead screen'**
  String get issueScreen;

  /// No description provided for @issueBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get issueBattery;

  /// No description provided for @issueCharging.
  ///
  /// In en, this message translates to:
  /// **'Charging problem'**
  String get issueCharging;

  /// No description provided for @issueWater.
  ///
  /// In en, this message translates to:
  /// **'Water damage'**
  String get issueWater;

  /// No description provided for @issueSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker or mic'**
  String get issueSpeaker;

  /// No description provided for @issueCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get issueCamera;

  /// No description provided for @issueSoftware.
  ///
  /// In en, this message translates to:
  /// **'Software, hang or virus'**
  String get issueSoftware;

  /// No description provided for @issueOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get issueOther;

  /// No description provided for @repairBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get repairBooked;

  /// No description provided for @repairReceived.
  ///
  /// In en, this message translates to:
  /// **'Received in the shop'**
  String get repairReceived;

  /// No description provided for @repairDiagnosing.
  ///
  /// In en, this message translates to:
  /// **'Being checked'**
  String get repairDiagnosing;

  /// No description provided for @repairAwaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your approval'**
  String get repairAwaiting;

  /// No description provided for @repairInRepair.
  ///
  /// In en, this message translates to:
  /// **'Being repaired'**
  String get repairInRepair;

  /// No description provided for @repairReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to collect'**
  String get repairReady;

  /// No description provided for @repairDelivered.
  ///
  /// In en, this message translates to:
  /// **'Handed over'**
  String get repairDelivered;

  /// No description provided for @repairCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get repairCancelled;

  /// No description provided for @roleCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get roleCustomer;

  /// No description provided for @roleStaff.
  ///
  /// In en, this message translates to:
  /// **'Counter staff'**
  String get roleStaff;

  /// No description provided for @roleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get roleManager;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get daySun;

  /// No description provided for @errBadPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a 10-digit mobile number.'**
  String get errBadPhone;

  /// No description provided for @errBadOtp.
  ///
  /// In en, this message translates to:
  /// **'That code is not right. Please check and try again.'**
  String get errBadOtp;

  /// No description provided for @errAccountDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been switched off. Please contact the shop.'**
  String get errAccountDisabled;

  /// No description provided for @errBadAddress.
  ///
  /// In en, this message translates to:
  /// **'Please complete the delivery address with name, phone and a 6-digit pincode.'**
  String get errBadAddress;

  /// No description provided for @errEmptyCart.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty.'**
  String get errEmptyCart;

  /// No description provided for @errStockChanged.
  ///
  /// In en, this message translates to:
  /// **'Stock has changed. Please review your cart.'**
  String get errStockChanged;

  /// No description provided for @errBadCoupon.
  ///
  /// In en, this message translates to:
  /// **'That coupon cannot be used on this order.'**
  String get errBadCoupon;

  /// No description provided for @errPayNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'That way of paying is not available for this order.'**
  String get errPayNotAllowed;

  /// No description provided for @errNeedInstrument.
  ///
  /// In en, this message translates to:
  /// **'Please enter your payment details.'**
  String get errNeedInstrument;

  /// No description provided for @errBadEmiScheme.
  ///
  /// In en, this message translates to:
  /// **'That EMI option is not available for this amount.'**
  String get errBadEmiScheme;

  /// No description provided for @errNothingToPay.
  ///
  /// In en, this message translates to:
  /// **'There is nothing to pay on this order.'**
  String get errNothingToPay;

  /// No description provided for @errCannotCancel.
  ///
  /// In en, this message translates to:
  /// **'This can no longer be cancelled. Please call the shop.'**
  String get errCannotCancel;

  /// No description provided for @errReturnWindowClosed.
  ///
  /// In en, this message translates to:
  /// **'The 7-day return window has closed.'**
  String get errReturnWindowClosed;

  /// No description provided for @errBadTransition.
  ///
  /// In en, this message translates to:
  /// **'That step is not allowed for this order right now.'**
  String get errBadTransition;

  /// No description provided for @errBadImei.
  ///
  /// In en, this message translates to:
  /// **'That IMEI is not valid. It must be 15 digits.'**
  String get errBadImei;

  /// No description provided for @errDupImei.
  ///
  /// In en, this message translates to:
  /// **'The same IMEI is entered twice.'**
  String get errDupImei;

  /// No description provided for @errImeiRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the IMEI of every phone before handing it over.'**
  String get errImeiRequired;

  /// No description provided for @errEmiNotApproved.
  ///
  /// In en, this message translates to:
  /// **'The EMI is not approved yet. Do not hand the phone over.'**
  String get errEmiNotApproved;

  /// No description provided for @errBalanceDue.
  ///
  /// In en, this message translates to:
  /// **'There is still money to collect on this order.'**
  String get errBalanceDue;

  /// No description provided for @errBadAmount.
  ///
  /// In en, this message translates to:
  /// **'That amount is not right.'**
  String get errBadAmount;

  /// No description provided for @errDiscountTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Counter staff can give at most 5% off. Ask a manager.'**
  String get errDiscountTooHigh;

  /// No description provided for @errPlanNotLive.
  ///
  /// In en, this message translates to:
  /// **'Autopay can be set once the EMI is approved.'**
  String get errPlanNotLive;

  /// No description provided for @errMandateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not set up Autopay. Check the details and try again.'**
  String get errMandateFailed;

  /// No description provided for @errRefundFailed.
  ///
  /// In en, this message translates to:
  /// **'The refund could not be sent. Try again.'**
  String get errRefundFailed;

  /// No description provided for @errQuoteRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the repair price first.'**
  String get errQuoteRequired;

  /// No description provided for @errNeedVariant.
  ///
  /// In en, this message translates to:
  /// **'Add at least one variant with a price.'**
  String get errNeedVariant;

  /// No description provided for @errBadPrice.
  ///
  /// In en, this message translates to:
  /// **'Check the prices: MRP cannot be below the selling price.'**
  String get errBadPrice;

  /// No description provided for @errLastOwner.
  ///
  /// In en, this message translates to:
  /// **'There must always be at least one active owner.'**
  String get errLastOwner;

  /// No description provided for @errBadRole.
  ///
  /// In en, this message translates to:
  /// **'That role cannot be given.'**
  String get errBadRole;

  /// No description provided for @errNoPermission.
  ///
  /// In en, this message translates to:
  /// **'Your role does not allow this.'**
  String get errNoPermission;

  /// No description provided for @errGatewayDeclined.
  ///
  /// In en, this message translates to:
  /// **'The payment was declined. Try another card, UPI ID or bank.'**
  String get errGatewayDeclined;

  /// No description provided for @errGatewayInvalid.
  ///
  /// In en, this message translates to:
  /// **'Those payment details do not look right. Please check them.'**
  String get errGatewayInvalid;

  /// No description provided for @errGatewayCancelled.
  ///
  /// In en, this message translates to:
  /// **'The payment was cancelled.'**
  String get errGatewayCancelled;

  /// No description provided for @errGatewayTimeout.
  ///
  /// In en, this message translates to:
  /// **'The payment timed out. You have not been charged twice; check your orders.'**
  String get errGatewayTimeout;

  /// No description provided for @payChoiceUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI (GPay, PhonePe, Paytm)'**
  String get payChoiceUpi;

  /// No description provided for @payChoiceUpiHint.
  ///
  /// In en, this message translates to:
  /// **'Instant. Pay from any UPI app.'**
  String get payChoiceUpiHint;

  /// No description provided for @payChoiceCard.
  ///
  /// In en, this message translates to:
  /// **'Credit or debit card'**
  String get payChoiceCard;

  /// No description provided for @payChoiceCardHint.
  ///
  /// In en, this message translates to:
  /// **'Visa, Mastercard, RuPay.'**
  String get payChoiceCardHint;

  /// No description provided for @payChoiceNetbankingHint.
  ///
  /// In en, this message translates to:
  /// **'Pay from your bank account.'**
  String get payChoiceNetbankingHint;

  /// No description provided for @payChoiceCod.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery'**
  String get payChoiceCod;

  /// No description provided for @payChoiceCodHint.
  ///
  /// In en, this message translates to:
  /// **'Pay in cash when it reaches your door. Available in town.'**
  String get payChoiceCodHint;

  /// No description provided for @payChoiceCashStore.
  ///
  /// In en, this message translates to:
  /// **'Pay cash at the store'**
  String get payChoiceCashStore;

  /// No description provided for @payChoiceCashStoreHint.
  ///
  /// In en, this message translates to:
  /// **'We keep it ready. Pay when you collect.'**
  String get payChoiceCashStoreHint;

  /// No description provided for @payChoiceReserve.
  ///
  /// In en, this message translates to:
  /// **'Reserve now, pay at the store'**
  String get payChoiceReserve;

  /// No description provided for @payChoiceReserveHint.
  ///
  /// In en, this message translates to:
  /// **'Pay {token} now to hold the phone for you. Pay the rest when you visit.'**
  String payChoiceReserveHint(String token);

  /// No description provided for @payChoiceBajajHint.
  ///
  /// In en, this message translates to:
  /// **'Down payment now, easy monthly instalments. Quick approval in the store.'**
  String get payChoiceBajajHint;

  /// No description provided for @payChoiceCardEmiHint.
  ///
  /// In en, this message translates to:
  /// **'Convert the bill into EMIs on your credit or debit card.'**
  String get payChoiceCardEmiHint;

  /// No description provided for @openAdmin.
  ///
  /// In en, this message translates to:
  /// **'Open admin panel'**
  String get openAdmin;

  /// No description provided for @openAdminHint.
  ///
  /// In en, this message translates to:
  /// **'Orders, stock, billing, EMI and reports'**
  String get openAdminHint;

  /// No description provided for @viewAsCustomer.
  ///
  /// In en, this message translates to:
  /// **'View as customer'**
  String get viewAsCustomer;

  /// No description provided for @visitStore.
  ///
  /// In en, this message translates to:
  /// **'Visit our store'**
  String get visitStore;

  /// No description provided for @visitUsAnytime.
  ///
  /// In en, this message translates to:
  /// **'Visit us any time we are open'**
  String get visitUsAnytime;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search phones, chargers, cases…'**
  String get searchHint;

  /// No description provided for @shopByCategory.
  ///
  /// In en, this message translates to:
  /// **'Shop by category'**
  String get shopByCategory;

  /// No description provided for @shopByBudget.
  ///
  /// In en, this message translates to:
  /// **'Shop by budget'**
  String get shopByBudget;

  /// No description provided for @budgetUnder10.
  ///
  /// In en, this message translates to:
  /// **'Under ₹10,000'**
  String get budgetUnder10;

  /// No description provided for @budget10to15.
  ///
  /// In en, this message translates to:
  /// **'₹10,000 - ₹15,000'**
  String get budget10to15;

  /// No description provided for @budget15to20.
  ///
  /// In en, this message translates to:
  /// **'₹15,000 - ₹20,000'**
  String get budget15to20;

  /// No description provided for @budgetAbove20.
  ///
  /// In en, this message translates to:
  /// **'Above ₹20,000'**
  String get budgetAbove20;

  /// No description provided for @zeroEmiPhones.
  ///
  /// In en, this message translates to:
  /// **'0% EMI phones'**
  String get zeroEmiPhones;

  /// No description provided for @ourServices.
  ///
  /// In en, this message translates to:
  /// **'Our services'**
  String get ourServices;

  /// No description provided for @serviceRepair.
  ///
  /// In en, this message translates to:
  /// **'Phone repair'**
  String get serviceRepair;

  /// No description provided for @serviceExchange.
  ///
  /// In en, this message translates to:
  /// **'Exchange old phone'**
  String get serviceExchange;

  /// No description provided for @serviceEmiCalc.
  ///
  /// In en, this message translates to:
  /// **'EMI calculator'**
  String get serviceEmiCalc;

  /// No description provided for @accessoryPicks.
  ///
  /// In en, this message translates to:
  /// **'Popular accessories'**
  String get accessoryPicks;

  /// No description provided for @whyBrandhoop.
  ///
  /// In en, this message translates to:
  /// **'Why buy from Brandhoop'**
  String get whyBrandhoop;

  /// No description provided for @whyGenuineTitle.
  ///
  /// In en, this message translates to:
  /// **'Genuine, with a GST bill'**
  String get whyGenuineTitle;

  /// No description provided for @whyGenuineBody.
  ///
  /// In en, this message translates to:
  /// **'Every phone is sealed with brand warranty. No second-hand surprises.'**
  String get whyGenuineBody;

  /// No description provided for @whyLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'A shop you can walk into'**
  String get whyLocalTitle;

  /// No description provided for @whyLocalBody.
  ///
  /// In en, this message translates to:
  /// **'Order from home, then visit, collect or ask anything at the counter, any time we are open.'**
  String get whyLocalBody;

  /// No description provided for @whyPayTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay your way'**
  String get whyPayTitle;

  /// No description provided for @whyPayBody.
  ///
  /// In en, this message translates to:
  /// **'Cash, UPI, cards, Bajaj Finserv EMI and Autopay, all in one place.'**
  String get whyPayBody;

  /// No description provided for @whySupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Local support after you buy'**
  String get whySupportTitle;

  /// No description provided for @whySupportBody.
  ///
  /// In en, this message translates to:
  /// **'Setup, data transfer, repair and warranty help from the same people you bought from.'**
  String get whySupportBody;

  /// No description provided for @trustGenuine.
  ///
  /// In en, this message translates to:
  /// **'Genuine'**
  String get trustGenuine;

  /// No description provided for @trustGstBill.
  ///
  /// In en, this message translates to:
  /// **'GST bill'**
  String get trustGstBill;

  /// No description provided for @trustLocal.
  ///
  /// In en, this message translates to:
  /// **'Local shop'**
  String get trustLocal;

  /// No description provided for @trustService.
  ///
  /// In en, this message translates to:
  /// **'Repair and service'**
  String get trustService;

  /// No description provided for @whyBuyFromUs.
  ///
  /// In en, this message translates to:
  /// **'Why buy from us'**
  String get whyBuyFromUs;

  /// No description provided for @storeOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get storeOpenNow;

  /// No description provided for @storeClosedNow.
  ///
  /// In en, this message translates to:
  /// **'Closed now'**
  String get storeClosedNow;

  /// No description provided for @storeClosesAt.
  ///
  /// In en, this message translates to:
  /// **'closes {time}'**
  String storeClosesAt(String time);

  /// No description provided for @storeOpensAt.
  ///
  /// In en, this message translates to:
  /// **'opens {time}'**
  String storeOpensAt(String time);

  /// No description provided for @storeOpensDay.
  ///
  /// In en, this message translates to:
  /// **'opens {day}, {time}'**
  String storeOpensDay(String day, String time);

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 product} other{{n} products}}'**
  String resultsCount(int n);

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get sortPopular;

  /// No description provided for @sortPriceLow.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get sortPriceLow;

  /// No description provided for @sortPriceHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get sortPriceHigh;

  /// No description provided for @sortDiscount.
  ///
  /// In en, this message translates to:
  /// **'Biggest discount'**
  String get sortDiscount;

  /// No description provided for @noResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different word or clear the filters.'**
  String get noResultsHint;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceRange;

  /// No description provided for @priceBelow.
  ///
  /// In en, this message translates to:
  /// **'Below {price}'**
  String priceBelow(String price);

  /// No description provided for @priceAbove.
  ///
  /// In en, this message translates to:
  /// **'Above {price}'**
  String priceAbove(String price);

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @zeroEmiOnly.
  ///
  /// In en, this message translates to:
  /// **'0% EMI only'**
  String get zeroEmiOnly;

  /// No description provided for @inStockOnly.
  ///
  /// In en, this message translates to:
  /// **'In stock only'**
  String get inStockOnly;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get off;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @emiFrom.
  ///
  /// In en, this message translates to:
  /// **'EMI from {amount}/month'**
  String emiFrom(String amount);

  /// No description provided for @emiFromZero.
  ///
  /// In en, this message translates to:
  /// **'0% EMI from {amount}/month'**
  String emiFromZero(String amount);

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'This product is not available'**
  String get productNotFound;

  /// No description provided for @wishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get wishlist;

  /// No description provided for @shareProductText.
  ///
  /// In en, this message translates to:
  /// **'Look at this on {shop}: {product} for {price}.'**
  String shareProductText(String shop, String product, String price);

  /// No description provided for @sampleListing.
  ///
  /// In en, this message translates to:
  /// **'Sample listing'**
  String get sampleListing;

  /// No description provided for @chooseVariant.
  ///
  /// In en, this message translates to:
  /// **'Choose a variant'**
  String get chooseVariant;

  /// No description provided for @onlyFewLeft.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Only 1 left} other{Only {n} left}}'**
  String onlyFewLeft(int n);

  /// No description provided for @inStockAtStore.
  ///
  /// In en, this message translates to:
  /// **'In stock at the store'**
  String get inStockAtStore;

  /// No description provided for @inStockCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Out of stock} =1{1 in stock} other{{n} in stock}}'**
  String inStockCount(int n);

  /// No description provided for @emiPartners.
  ///
  /// In en, this message translates to:
  /// **'With Bajaj Finserv and card EMI. Tap to see plans.'**
  String get emiPartners;

  /// No description provided for @reserveTitle.
  ///
  /// In en, this message translates to:
  /// **'Reserve this phone for {token}'**
  String reserveTitle(String token);

  /// No description provided for @reserveBody.
  ///
  /// In en, this message translates to:
  /// **'We hold it for you for {hours}. Pay the rest when you visit the store.'**
  String reserveBody(String hours);

  /// No description provided for @reserveCta.
  ///
  /// In en, this message translates to:
  /// **'Reserve now'**
  String get reserveCta;

  /// No description provided for @deliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery and pickup'**
  String get deliveryTitle;

  /// No description provided for @deliveryLocal.
  ///
  /// In en, this message translates to:
  /// **'Same-day home delivery in {city} and nearby areas we serve.'**
  String deliveryLocal(String city);

  /// No description provided for @pickupAnytime.
  ///
  /// In en, this message translates to:
  /// **'Or collect from our store any time it is open.'**
  String get pickupAnytime;

  /// No description provided for @enterPincode.
  ///
  /// In en, this message translates to:
  /// **'Enter your pincode'**
  String get enterPincode;

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// No description provided for @deliverySameDay.
  ///
  /// In en, this message translates to:
  /// **'Same-day delivery to this pincode.'**
  String get deliverySameDay;

  /// No description provided for @deliveryCourier.
  ///
  /// In en, this message translates to:
  /// **'Courier delivery: {fee}, free above {free}.'**
  String deliveryCourier(String fee, String free);

  /// No description provided for @completeYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Complete your phone'**
  String get completeYourPhone;

  /// No description provided for @aboutProduct.
  ///
  /// In en, this message translates to:
  /// **'About this product'**
  String get aboutProduct;

  /// No description provided for @specifications.
  ///
  /// In en, this message translates to:
  /// **'Specifications'**
  String get specifications;

  /// No description provided for @warranty.
  ///
  /// In en, this message translates to:
  /// **'Warranty'**
  String get warranty;

  /// No description provided for @warrantyMonths.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 month} other{{n} months}}'**
  String warrantyMonths(int n);

  /// No description provided for @similarProducts.
  ///
  /// In en, this message translates to:
  /// **'Similar products'**
  String get similarProducts;

  /// No description provided for @errBadPincode.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 6-digit pincode.'**
  String get errBadPincode;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get addToCart;

  /// No description provided for @addedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added to your cart'**
  String get addedToCart;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy now'**
  String get buyNow;

  /// No description provided for @notifyMe.
  ///
  /// In en, this message translates to:
  /// **'Ask us about it'**
  String get notifyMe;

  /// No description provided for @askAboutThis.
  ///
  /// In en, this message translates to:
  /// **'Ask about this'**
  String get askAboutThis;

  /// No description provided for @enquiryText.
  ///
  /// In en, this message translates to:
  /// **'Hello! I am interested in {product} ({variant}) at {price}. Is it available?'**
  String enquiryText(String product, String variant, String price);

  /// No description provided for @weWillCallYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you. We will call you shortly.'**
  String get weWillCallYou;

  /// No description provided for @yourDetails.
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get yourDetails;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileNumber;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'Your cart'**
  String get cartTitle;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmpty;

  /// No description provided for @cartEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add a phone or an accessory and it will show up here.'**
  String get cartEmptyHint;

  /// No description provided for @startShopping.
  ///
  /// In en, this message translates to:
  /// **'Start shopping'**
  String get startShopping;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @proceedToCheckout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get proceedToCheckout;

  /// No description provided for @youSave.
  ///
  /// In en, this message translates to:
  /// **'You save'**
  String get youSave;

  /// No description provided for @deliveryCalculatedAtCheckout.
  ///
  /// In en, this message translates to:
  /// **'Delivery and offers are worked out at checkout.'**
  String get deliveryCalculatedAtCheckout;

  /// No description provided for @itemNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer available'**
  String get itemNoLongerAvailable;

  /// No description provided for @viewCart.
  ///
  /// In en, this message translates to:
  /// **'View cart'**
  String get viewCart;

  /// No description provided for @openingHours.
  ///
  /// In en, this message translates to:
  /// **'Opening hours'**
  String get openingHours;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @planYourVisit.
  ///
  /// In en, this message translates to:
  /// **'Plan your visit'**
  String get planYourVisit;

  /// No description provided for @planYourVisitBody.
  ///
  /// In en, this message translates to:
  /// **'Tell us when you are coming and we will have your phone, bill and EMI papers ready.'**
  String get planYourVisitBody;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @closedThatDay.
  ///
  /// In en, this message translates to:
  /// **'The store is closed that day. Pick another day.'**
  String get closedThatDay;

  /// No description provided for @tellShopIAmComing.
  ///
  /// In en, this message translates to:
  /// **'Tell the shop I am coming'**
  String get tellShopIAmComing;

  /// No description provided for @visitNoted.
  ///
  /// In en, this message translates to:
  /// **'Noted. We will see you then.'**
  String get visitNoted;

  /// No description provided for @inTheShop.
  ///
  /// In en, this message translates to:
  /// **'In the shop'**
  String get inTheShop;

  /// No description provided for @shopLine1.
  ///
  /// In en, this message translates to:
  /// **'New phones from every major brand'**
  String get shopLine1;

  /// No description provided for @shopLine2.
  ///
  /// In en, this message translates to:
  /// **'Cash, UPI, cards and Bajaj Finserv EMI at the counter'**
  String get shopLine2;

  /// No description provided for @shopLine3.
  ///
  /// In en, this message translates to:
  /// **'Exchange your old phone on the spot'**
  String get shopLine3;

  /// No description provided for @shopLine4.
  ///
  /// In en, this message translates to:
  /// **'Screen, battery and charging repair'**
  String get shopLine4;

  /// No description provided for @shopLine5.
  ///
  /// In en, this message translates to:
  /// **'SIM, recharge and free setup help'**
  String get shopLine5;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Brandhoop'**
  String get signInTitle;

  /// No description provided for @signInBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number. We will send a 6-digit code.'**
  String get signInBody;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get enterCode;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to +91 {phone}'**
  String codeSentTo(String phone);

  /// No description provided for @sixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get sixDigitCode;

  /// No description provided for @demoCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Demo mode: the code is {code}'**
  String demoCodeHint(String code);

  /// No description provided for @referralCode.
  ///
  /// In en, this message translates to:
  /// **'Referral code'**
  String get referralCode;

  /// No description provided for @verifyAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify and continue'**
  String get verifyAndContinue;

  /// No description provided for @changeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get changeNumber;

  /// No description provided for @tryAs.
  ///
  /// In en, this message translates to:
  /// **'Demo: try the app as'**
  String get tryAs;

  /// No description provided for @demoAccountsHint.
  ///
  /// In en, this message translates to:
  /// **'Or sign in with owner {owner} or customer {customer}, code 123456.'**
  String demoAccountsHint(String owner, String customer);

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// No description provided for @orderTotal.
  ///
  /// In en, this message translates to:
  /// **'Order total'**
  String get orderTotal;

  /// No description provided for @howToReceive.
  ///
  /// In en, this message translates to:
  /// **'How would you like to receive it?'**
  String get howToReceive;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addAddress;

  /// No description provided for @offersAndCoins.
  ///
  /// In en, this message translates to:
  /// **'Offers and coins'**
  String get offersAndCoins;

  /// No description provided for @payWith.
  ///
  /// In en, this message translates to:
  /// **'Pay with'**
  String get payWith;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order summary'**
  String get orderSummary;

  /// No description provided for @couponCode.
  ///
  /// In en, this message translates to:
  /// **'Coupon code'**
  String get couponCode;

  /// No description provided for @coupon.
  ///
  /// In en, this message translates to:
  /// **'Coupon'**
  String get coupon;

  /// No description provided for @couponNotFound.
  ///
  /// In en, this message translates to:
  /// **'This coupon code does not exist.'**
  String get couponNotFound;

  /// No description provided for @couponNotActive.
  ///
  /// In en, this message translates to:
  /// **'This coupon has expired or is switched off.'**
  String get couponNotActive;

  /// No description provided for @couponMinOrder.
  ///
  /// In en, this message translates to:
  /// **'Add more to your cart to use this coupon.'**
  String get couponMinOrder;

  /// No description provided for @couponNotApplicable.
  ///
  /// In en, this message translates to:
  /// **'This coupon does not apply to the items in your cart.'**
  String get couponNotApplicable;

  /// No description provided for @couponApplied.
  ///
  /// In en, this message translates to:
  /// **'{code} applied: you save {amount}'**
  String couponApplied(String code, String amount);

  /// No description provided for @coinsUsed.
  ///
  /// In en, this message translates to:
  /// **'Brandhoop Coins'**
  String get coinsUsed;

  /// No description provided for @useCoins.
  ///
  /// In en, this message translates to:
  /// **'{coins, plural, =1{Use my 1 Brandhoop Coin} other{Use my {coins} Brandhoop Coins}}'**
  String useCoins(int coins);

  /// No description provided for @coinsRule.
  ///
  /// In en, this message translates to:
  /// **'One coin is one rupee off accessories, up to a share of the accessory bill.'**
  String get coinsRule;

  /// No description provided for @reserveExplain.
  ///
  /// In en, this message translates to:
  /// **'Pay {token} now. We hold the phone for {hours}. Pay the remaining {rest} when you visit.'**
  String reserveExplain(String token, String hours, String rest);

  /// No description provided for @chooseTenure.
  ///
  /// In en, this message translates to:
  /// **'Choose how many months'**
  String get chooseTenure;

  /// No description provided for @zeroInterest.
  ///
  /// In en, this message translates to:
  /// **'0% interest'**
  String get zeroInterest;

  /// No description provided for @downPayment.
  ///
  /// In en, this message translates to:
  /// **'Down payment'**
  String get downPayment;

  /// No description provided for @downPaymentMin.
  ///
  /// In en, this message translates to:
  /// **'Minimum down payment: {amount}'**
  String downPaymentMin(String amount);

  /// No description provided for @downPaymentFrom.
  ///
  /// In en, this message translates to:
  /// **'Down payment from {amount}'**
  String downPaymentFrom(String amount);

  /// No description provided for @amountFinanced.
  ///
  /// In en, this message translates to:
  /// **'Amount financed'**
  String get amountFinanced;

  /// No description provided for @interestRate.
  ///
  /// In en, this message translates to:
  /// **'Interest rate'**
  String get interestRate;

  /// No description provided for @perYear.
  ///
  /// In en, this message translates to:
  /// **'a year'**
  String get perYear;

  /// No description provided for @totalInterest.
  ///
  /// In en, this message translates to:
  /// **'Total interest'**
  String get totalInterest;

  /// No description provided for @processingFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Processing fee'**
  String get processingFeeLabel;

  /// No description provided for @processingFee.
  ///
  /// In en, this message translates to:
  /// **'Processing fee {fee}'**
  String processingFee(String fee);

  /// No description provided for @totalYouPay.
  ///
  /// In en, this message translates to:
  /// **'Total you pay'**
  String get totalYouPay;

  /// No description provided for @totalPayable.
  ///
  /// In en, this message translates to:
  /// **'Total {amount}'**
  String totalPayable(String amount);

  /// No description provided for @noExtraCost.
  ///
  /// In en, this message translates to:
  /// **'No extra cost'**
  String get noExtraCost;

  /// No description provided for @emiIndicative.
  ///
  /// In en, this message translates to:
  /// **'These figures are indicative. The final amount, rate and approval are decided by the lender.'**
  String get emiIndicative;

  /// No description provided for @emiRatesUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'The shop is still confirming its EMI rates, so treat these as estimates.'**
  String get emiRatesUnconfirmed;

  /// No description provided for @noEmiForThis.
  ///
  /// In en, this message translates to:
  /// **'EMI is not available for this amount or product.'**
  String get noEmiForThis;

  /// No description provided for @emiOptions.
  ///
  /// In en, this message translates to:
  /// **'EMI options'**
  String get emiOptions;

  /// No description provided for @openCalculator.
  ///
  /// In en, this message translates to:
  /// **'Open EMI calculator'**
  String get openCalculator;

  /// No description provided for @payDownHow.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} now'**
  String payDownHow(String amount);

  /// No description provided for @payOnlineNow.
  ///
  /// In en, this message translates to:
  /// **'Pay online now'**
  String get payOnlineNow;

  /// No description provided for @payAtStoreLater.
  ///
  /// In en, this message translates to:
  /// **'Pay at the store'**
  String get payAtStoreLater;

  /// No description provided for @whatHappensNext.
  ///
  /// In en, this message translates to:
  /// **'What happens next'**
  String get whatHappensNext;

  /// No description provided for @bajajStep1.
  ///
  /// In en, this message translates to:
  /// **'You send this application and pay the down payment.'**
  String get bajajStep1;

  /// No description provided for @bajajStep2.
  ///
  /// In en, this message translates to:
  /// **'Visit the store with your Aadhaar, PAN and bank details. We complete the Bajaj Finserv check with you.'**
  String get bajajStep2;

  /// No description provided for @bajajStep3.
  ///
  /// In en, this message translates to:
  /// **'Once Bajaj Finserv approves, your phone is handed over with the bill and IMEI.'**
  String get bajajStep3;

  /// No description provided for @bajajStep4.
  ///
  /// In en, this message translates to:
  /// **'You pay the monthly EMI. Turn on Autopay in this app so you never miss a date.'**
  String get bajajStep4;

  /// No description provided for @applyAndPay.
  ///
  /// In en, this message translates to:
  /// **'Apply and pay {amount}'**
  String applyAndPay(String amount);

  /// No description provided for @applyForEmi.
  ///
  /// In en, this message translates to:
  /// **'Apply for EMI'**
  String get applyForEmi;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place order'**
  String get placeOrder;

  /// No description provided for @payAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String payAmount(String amount);

  /// No description provided for @reserveFor.
  ///
  /// In en, this message translates to:
  /// **'Reserve for {amount}'**
  String reserveFor(String amount);

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get deliveryFee;

  /// No description provided for @totalSavings.
  ///
  /// In en, this message translates to:
  /// **'You save {amount} on this order'**
  String totalSavings(String amount);

  /// No description provided for @orEnterUpiId.
  ///
  /// In en, this message translates to:
  /// **'Or enter a UPI ID'**
  String get orEnterUpiId;

  /// No description provided for @errBadUpi.
  ///
  /// In en, this message translates to:
  /// **'That UPI ID does not look right.'**
  String get errBadUpi;

  /// No description provided for @cardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card number'**
  String get cardNumber;

  /// No description provided for @errBadCard.
  ///
  /// In en, this message translates to:
  /// **'That card number is not valid.'**
  String get errBadCard;

  /// No description provided for @cardExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get cardExpiry;

  /// No description provided for @errBadExpiry.
  ///
  /// In en, this message translates to:
  /// **'That expiry date is not valid.'**
  String get errBadExpiry;

  /// No description provided for @nameOnCard.
  ///
  /// In en, this message translates to:
  /// **'Name on card'**
  String get nameOnCard;

  /// No description provided for @testPaymentHint.
  ///
  /// In en, this message translates to:
  /// **'Test mode: no real money moves. Use card 4111 1111 1111 1111 with any future date and CVV. UPI ID fail@upi shows a failed payment.'**
  String get testPaymentHint;

  /// No description provided for @activeOrders.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeOrders;

  /// No description provided for @pastOrders.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get pastOrders;

  /// No description provided for @signInToSeeOrders.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your orders'**
  String get signInToSeeOrders;

  /// No description provided for @signInToSeeOrdersHint.
  ///
  /// In en, this message translates to:
  /// **'Your orders, bills and warranty are saved to your mobile number.'**
  String get signInToSeeOrdersHint;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYet;

  /// No description provided for @noOrdersYetHint.
  ///
  /// In en, this message translates to:
  /// **'When you buy, your order and its tracking will appear here.'**
  String get noOrdersYetHint;

  /// No description provided for @paymentNotDone.
  ///
  /// In en, this message translates to:
  /// **'Payment not completed'**
  String get paymentNotDone;

  /// No description provided for @paymentNotDoneHint.
  ///
  /// In en, this message translates to:
  /// **'Your order is saved. Pay now to confirm it, or it is released in 30 minutes.'**
  String get paymentNotDoneHint;

  /// No description provided for @orderPlacedTitle.
  ///
  /// In en, this message translates to:
  /// **'Order placed'**
  String get orderPlacedTitle;

  /// No description provided for @orderNumberIs.
  ///
  /// In en, this message translates to:
  /// **'Your order number is {number}'**
  String orderNumberIs(String number);

  /// No description provided for @showThisCode.
  ///
  /// In en, this message translates to:
  /// **'Show this code at the store'**
  String get showThisCode;

  /// No description provided for @nextCod.
  ///
  /// In en, this message translates to:
  /// **'Keep {amount} in cash ready. Our team will call before delivery.'**
  String nextCod(String amount);

  /// No description provided for @nextCashStore.
  ///
  /// In en, this message translates to:
  /// **'We are keeping it ready. Pay {amount} in cash when you collect.'**
  String nextCashStore(String amount);

  /// No description provided for @nextReserve.
  ///
  /// In en, this message translates to:
  /// **'Your phone is held for you. Come in before {until} and pay the remaining {balance}.'**
  String nextReserve(String balance, String until);

  /// No description provided for @nextBajaj.
  ///
  /// In en, this message translates to:
  /// **'Visit the store with your Aadhaar, PAN and bank details to finish the Bajaj Finserv application. We will call you to confirm.'**
  String get nextBajaj;

  /// No description provided for @nextPickup.
  ///
  /// In en, this message translates to:
  /// **'We will message you when it is ready to collect. Show the code below at the counter.'**
  String get nextPickup;

  /// No description provided for @nextDelivery.
  ///
  /// In en, this message translates to:
  /// **'We are getting it ready. You can track every step here.'**
  String get nextDelivery;

  /// No description provided for @viewOrder.
  ///
  /// In en, this message translates to:
  /// **'View order'**
  String get viewOrder;

  /// No description provided for @continueShopping.
  ///
  /// In en, this message translates to:
  /// **'Continue shopping'**
  String get continueShopping;

  /// No description provided for @tryAnotherWay.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get tryAnotherWay;

  /// No description provided for @orderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get orderNotFound;

  /// No description provided for @shareInvoice.
  ///
  /// In en, this message translates to:
  /// **'Share bill'**
  String get shareInvoice;

  /// No description provided for @pickupCode.
  ///
  /// In en, this message translates to:
  /// **'Pickup code'**
  String get pickupCode;

  /// No description provided for @reservedUntil.
  ///
  /// In en, this message translates to:
  /// **'Held for you until {when}'**
  String reservedUntil(String when);

  /// No description provided for @trackOrder.
  ///
  /// In en, this message translates to:
  /// **'Track order'**
  String get trackOrder;

  /// No description provided for @itemsHeader.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsHeader;

  /// No description provided for @paymentHeader.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentHeader;

  /// No description provided for @paymentMode.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMode;

  /// No description provided for @balanceDue.
  ///
  /// In en, this message translates to:
  /// **'Balance due'**
  String get balanceDue;

  /// No description provided for @balanceToPay.
  ///
  /// In en, this message translates to:
  /// **'Balance to pay: {amount}'**
  String balanceToPay(String amount);

  /// No description provided for @reserveTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Reserve token'**
  String get reserveTokenLabel;

  /// No description provided for @viewEmiPlan.
  ///
  /// In en, this message translates to:
  /// **'View EMI plan'**
  String get viewEmiPlan;

  /// No description provided for @pickupHeader.
  ///
  /// In en, this message translates to:
  /// **'Collect from the store'**
  String get pickupHeader;

  /// No description provided for @deliveryHeader.
  ///
  /// In en, this message translates to:
  /// **'Delivery address'**
  String get deliveryHeader;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get cancelOrder;

  /// No description provided for @cancelOrderQ.
  ///
  /// In en, this message translates to:
  /// **'Cancel this order?'**
  String get cancelOrderQ;

  /// No description provided for @reasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get reasonOptional;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'The order is cancelled. Any payment you made will be refunded.'**
  String get orderCancelled;

  /// No description provided for @returnItems.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get returnItems;

  /// No description provided for @returnOrderQ.
  ///
  /// In en, this message translates to:
  /// **'Request a return?'**
  String get returnOrderQ;

  /// No description provided for @returnRequestedMsg.
  ///
  /// In en, this message translates to:
  /// **'Return requested. We will call you.'**
  String get returnRequestedMsg;

  /// No description provided for @orderAgain.
  ///
  /// In en, this message translates to:
  /// **'Order again'**
  String get orderAgain;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get needHelp;

  /// No description provided for @warrantyUntil.
  ///
  /// In en, this message translates to:
  /// **'Warranty until {date}'**
  String warrantyUntil(String date);

  /// No description provided for @invoiceOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get invoiceOrder;

  /// No description provided for @invoiceDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get invoiceDate;

  /// No description provided for @invoiceCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get invoiceCustomer;

  /// No description provided for @invoiceItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get invoiceItems;

  /// No description provided for @invoiceThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for shopping at {shop}.'**
  String invoiceThanks(String shop);

  /// No description provided for @emiAndAutopay.
  ///
  /// In en, this message translates to:
  /// **'EMI and Autopay'**
  String get emiAndAutopay;

  /// No description provided for @emiSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your EMI'**
  String get emiSignInTitle;

  /// No description provided for @emiSignInBody.
  ///
  /// In en, this message translates to:
  /// **'Your plans, due dates and Autopay settings are kept against your mobile number.'**
  String get emiSignInBody;

  /// No description provided for @noEmiPlans.
  ///
  /// In en, this message translates to:
  /// **'No EMI plans yet'**
  String get noEmiPlans;

  /// No description provided for @noEmiPlansBody.
  ///
  /// In en, this message translates to:
  /// **'Buy a phone on 0% or easy EMI and the plan, dates and Autopay will show up here.'**
  String get noEmiPlansBody;

  /// No description provided for @browseEmiPhones.
  ///
  /// In en, this message translates to:
  /// **'Browse phones on EMI'**
  String get browseEmiPhones;

  /// No description provided for @yourEmiPlans.
  ///
  /// In en, this message translates to:
  /// **'Your EMI plans'**
  String get yourEmiPlans;

  /// No description provided for @emiHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How EMI works at Brandhoop'**
  String get emiHowItWorks;

  /// No description provided for @emiPointBajaj.
  ///
  /// In en, this message translates to:
  /// **'Bajaj Finserv EMI: a small down payment, then easy monthly instalments. Approval is by Bajaj Finserv.'**
  String get emiPointBajaj;

  /// No description provided for @emiPointCard.
  ///
  /// In en, this message translates to:
  /// **'Card EMI: turn the bill into instalments on your credit or debit card, if your bank offers it.'**
  String get emiPointCard;

  /// No description provided for @emiPointAutopay.
  ///
  /// In en, this message translates to:
  /// **'Autopay: each instalment is debited on its date. Pause or cancel any time.'**
  String get emiPointAutopay;

  /// No description provided for @emiPointDocs.
  ///
  /// In en, this message translates to:
  /// **'Keep your Aadhaar, PAN and bank details handy for the Bajaj Finserv check.'**
  String get emiPointDocs;

  /// No description provided for @nextEmiDue.
  ///
  /// In en, this message translates to:
  /// **'Next EMI due'**
  String get nextEmiDue;

  /// No description provided for @emiOverdue.
  ///
  /// In en, this message translates to:
  /// **'EMI overdue'**
  String get emiOverdue;

  /// No description provided for @inDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{today} =1{tomorrow} other{in {days} days}}'**
  String inDays(int days);

  /// No description provided for @paidOf.
  ///
  /// In en, this message translates to:
  /// **'{paid} of {total} paid'**
  String paidOf(int paid, int total);

  /// No description provided for @nextOn.
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String nextOn(String date);

  /// No description provided for @emiPlan.
  ///
  /// In en, this message translates to:
  /// **'EMI plan'**
  String get emiPlan;

  /// No description provided for @planNotFound.
  ///
  /// In en, this message translates to:
  /// **'Plan not found'**
  String get planNotFound;

  /// No description provided for @itemPrice.
  ///
  /// In en, this message translates to:
  /// **'Item price'**
  String get itemPrice;

  /// No description provided for @tenure.
  ///
  /// In en, this message translates to:
  /// **'Tenure'**
  String get tenure;

  /// No description provided for @monthlyEmi.
  ///
  /// In en, this message translates to:
  /// **'Monthly EMI'**
  String get monthlyEmi;

  /// No description provided for @lenderRef.
  ///
  /// In en, this message translates to:
  /// **'Loan reference'**
  String get lenderRef;

  /// No description provided for @planAppliedHint.
  ///
  /// In en, this message translates to:
  /// **'Your application is with the shop and the lender. We will call you to finish it in the store.'**
  String get planAppliedHint;

  /// No description provided for @planRejectedHint.
  ///
  /// In en, this message translates to:
  /// **'This application was not approved. You can still buy the phone with another way of paying. Please speak to the shop.'**
  String get planRejectedHint;

  /// No description provided for @instalmentSchedule.
  ///
  /// In en, this message translates to:
  /// **'Instalment schedule'**
  String get instalmentSchedule;

  /// No description provided for @paidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid on {date}'**
  String paidOn(String date);

  /// No description provided for @openBajajApp.
  ///
  /// In en, this message translates to:
  /// **'Pay or view on Bajaj Finserv'**
  String get openBajajApp;

  /// No description provided for @bankAutoDebit.
  ///
  /// In en, this message translates to:
  /// **'Your bank debits this EMI to your card each month. Keep enough limit available.'**
  String get bankAutoDebit;

  /// No description provided for @autopaySettings.
  ///
  /// In en, this message translates to:
  /// **'Autopay settings'**
  String get autopaySettings;

  /// No description provided for @autopayOnBody.
  ///
  /// In en, this message translates to:
  /// **'Each instalment is debited on its due date, up to your limit. We remind you before every debit.'**
  String get autopayOnBody;

  /// No description provided for @autopayOffBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on Autopay so you never miss an instalment. You stay in control and can stop it any time.'**
  String get autopayOffBody;

  /// No description provided for @autopayMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get autopayMethodLabel;

  /// No description provided for @autopayAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get autopayAccount;

  /// No description provided for @autopayLimit.
  ///
  /// In en, this message translates to:
  /// **'Debit limit'**
  String get autopayLimit;

  /// No description provided for @nextDebit.
  ///
  /// In en, this message translates to:
  /// **'Next debit'**
  String get nextDebit;

  /// No description provided for @remindMe.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get remindMe;

  /// No description provided for @daysBefore.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{On the day} =1{1 day before} other{{n} days before}}'**
  String daysBefore(int n);

  /// No description provided for @pauseAutopay.
  ///
  /// In en, this message translates to:
  /// **'Pause Autopay'**
  String get pauseAutopay;

  /// No description provided for @cancelAutopay.
  ///
  /// In en, this message translates to:
  /// **'Cancel Autopay'**
  String get cancelAutopay;

  /// No description provided for @cancelAutopayQ.
  ///
  /// In en, this message translates to:
  /// **'Cancel Autopay?'**
  String get cancelAutopayQ;

  /// No description provided for @cancelAutopayBody.
  ///
  /// In en, this message translates to:
  /// **'Future instalments will not be debited automatically. You will need to pay them yourself before the due date.'**
  String get cancelAutopayBody;

  /// No description provided for @resumeAutopay.
  ///
  /// In en, this message translates to:
  /// **'Resume Autopay'**
  String get resumeAutopay;

  /// No description provided for @turnOnAutopay.
  ///
  /// In en, this message translates to:
  /// **'Turn on Autopay'**
  String get turnOnAutopay;

  /// No description provided for @setupAutopayAgain.
  ///
  /// In en, this message translates to:
  /// **'Set up Autopay again'**
  String get setupAutopayAgain;

  /// No description provided for @autopayLenderNote.
  ///
  /// In en, this message translates to:
  /// **'For Bajaj Finserv plans, the lender runs the final debit. This screen shows its status and your reminder.'**
  String get autopayLenderNote;

  /// No description provided for @autopaySheetBody.
  ///
  /// In en, this message translates to:
  /// **'Choose how your {emi} instalment should be paid each month.'**
  String autopaySheetBody(String emi);

  /// No description provided for @autopayConsent.
  ///
  /// In en, this message translates to:
  /// **'I allow automatic debit of each instalment, up to {limit}, on its due date. I can pause or cancel this any time.'**
  String autopayConsent(String limit);

  /// No description provided for @authoriseAutopay.
  ///
  /// In en, this message translates to:
  /// **'Authorise Autopay'**
  String get authoriseAutopay;

  /// No description provided for @phonePrice.
  ///
  /// In en, this message translates to:
  /// **'Phone price'**
  String get phonePrice;

  /// No description provided for @emiScheme.
  ///
  /// In en, this message translates to:
  /// **'EMI scheme'**
  String get emiScheme;

  /// No description provided for @priceOutsideScheme.
  ///
  /// In en, this message translates to:
  /// **'This scheme starts from {min}. Choose another scheme or a higher price.'**
  String priceOutsideScheme(String min);

  /// No description provided for @exchangeIntro.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your old phone and see an indicative value. The shop confirms the final price after a quick check.'**
  String get exchangeIntro;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @priceWhenNew.
  ///
  /// In en, this message translates to:
  /// **'Price when new (approx.)'**
  String get priceWhenNew;

  /// No description provided for @howOld.
  ///
  /// In en, this message translates to:
  /// **'How old is it?'**
  String get howOld;

  /// No description provided for @ageUnder6.
  ///
  /// In en, this message translates to:
  /// **'Under 6 months'**
  String get ageUnder6;

  /// No description provided for @age6to12.
  ///
  /// In en, this message translates to:
  /// **'6 to 12 months'**
  String get age6to12;

  /// No description provided for @age1to2.
  ///
  /// In en, this message translates to:
  /// **'1 to 2 years'**
  String get age1to2;

  /// No description provided for @age2to3.
  ///
  /// In en, this message translates to:
  /// **'2 to 3 years'**
  String get age2to3;

  /// No description provided for @ageOver3.
  ///
  /// In en, this message translates to:
  /// **'Over 3 years'**
  String get ageOver3;

  /// No description provided for @screenCondition.
  ///
  /// In en, this message translates to:
  /// **'Screen condition'**
  String get screenCondition;

  /// No description provided for @screenPerfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect'**
  String get screenPerfect;

  /// No description provided for @screenScratches.
  ///
  /// In en, this message translates to:
  /// **'Light scratches'**
  String get screenScratches;

  /// No description provided for @screenCracked.
  ///
  /// In en, this message translates to:
  /// **'Cracked'**
  String get screenCracked;

  /// No description provided for @bodyDents.
  ///
  /// In en, this message translates to:
  /// **'Dents or damage on the body'**
  String get bodyDents;

  /// No description provided for @batteryWeak.
  ///
  /// In en, this message translates to:
  /// **'Battery drains fast'**
  String get batteryWeak;

  /// No description provided for @allWorking.
  ///
  /// In en, this message translates to:
  /// **'Everything works (camera, speaker, touch, buttons)'**
  String get allWorking;

  /// No description provided for @haveBill.
  ///
  /// In en, this message translates to:
  /// **'I have the bill and box'**
  String get haveBill;

  /// No description provided for @estimatedValue.
  ///
  /// In en, this message translates to:
  /// **'Indicative value'**
  String get estimatedValue;

  /// No description provided for @exchangeIndicative.
  ///
  /// In en, this message translates to:
  /// **'This is only a guide. The final value is set after the shop checks your phone, and may be higher or lower.'**
  String get exchangeIndicative;

  /// No description provided for @sendToShop.
  ///
  /// In en, this message translates to:
  /// **'Send to the shop'**
  String get sendToShop;

  /// No description provided for @exchangeEnterPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter roughly what the phone cost when new to see its value.'**
  String get exchangeEnterPrice;

  /// No description provided for @exchangeSent.
  ///
  /// In en, this message translates to:
  /// **'Sent. We will call you with the next step.'**
  String get exchangeSent;

  /// No description provided for @repairIntro.
  ///
  /// In en, this message translates to:
  /// **'Book a repair from home. Bring the phone in or ask us to collect it, and follow every step here.'**
  String get repairIntro;

  /// No description provided for @whatIsWrong.
  ///
  /// In en, this message translates to:
  /// **'What is wrong?'**
  String get whatIsWrong;

  /// No description provided for @fromPrice.
  ///
  /// In en, this message translates to:
  /// **'from {price}'**
  String fromPrice(String price);

  /// No description provided for @describeProblem.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem (optional)'**
  String get describeProblem;

  /// No description provided for @repairHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'The price shown is a starting estimate. We check the phone, tell you the exact price, and repair only after you agree.'**
  String get repairHowItWorks;

  /// No description provided for @bookRepair.
  ///
  /// In en, this message translates to:
  /// **'Book repair'**
  String get bookRepair;

  /// No description provided for @myRepairs.
  ///
  /// In en, this message translates to:
  /// **'My repairs'**
  String get myRepairs;

  /// No description provided for @enterBrandModel.
  ///
  /// In en, this message translates to:
  /// **'Please enter the phone brand and model.'**
  String get enterBrandModel;

  /// No description provided for @repairBookedMsg.
  ///
  /// In en, this message translates to:
  /// **'Repair booked: {number}'**
  String repairBookedMsg(String number);

  /// No description provided for @estimatedPrice.
  ///
  /// In en, this message translates to:
  /// **'Estimated price'**
  String get estimatedPrice;

  /// No description provided for @quotedPrice.
  ///
  /// In en, this message translates to:
  /// **'Final price'**
  String get quotedPrice;

  /// No description provided for @repairApprovePrompt.
  ///
  /// In en, this message translates to:
  /// **'The shop has checked your phone. The repair will cost {price}. Approve to start.'**
  String repairApprovePrompt(String price);

  /// No description provided for @approveAndRepair.
  ///
  /// In en, this message translates to:
  /// **'Approve and repair'**
  String get approveAndRepair;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @cancelRepairQ.
  ///
  /// In en, this message translates to:
  /// **'Cancel this repair?'**
  String get cancelRepairQ;

  /// No description provided for @welcomeGuest.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Brandhoop'**
  String get welcomeGuest;

  /// No description provided for @coinsBalance.
  ///
  /// In en, this message translates to:
  /// **'{coins, plural, =1{1 coin} other{{coins} coins}}'**
  String coinsBalance(int coins);

  /// No description provided for @myAccount.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get myAccount;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfile;

  /// No description provided for @myAddresses.
  ///
  /// In en, this message translates to:
  /// **'My addresses'**
  String get myAddresses;

  /// No description provided for @referAndEarn.
  ///
  /// In en, this message translates to:
  /// **'Refer and earn'**
  String get referAndEarn;

  /// No description provided for @referShareText.
  ///
  /// In en, this message translates to:
  /// **'Buy phones and accessories from {shop} on the Brandhoop app. Use my code {code} and we both get {bonus} in coins after your first purchase.'**
  String referShareText(String shop, String code, String bonus);

  /// No description provided for @settingsHeader.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsHeader;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Phone setting'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @helpHeader.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpHeader;

  /// No description provided for @helpAndFaq.
  ///
  /// In en, this message translates to:
  /// **'Help and FAQ'**
  String get helpAndFaq;

  /// No description provided for @signOutQ.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutQ;

  /// No description provided for @phoneCannotChange.
  ///
  /// In en, this message translates to:
  /// **'Your mobile number is your account and cannot be changed here.'**
  String get phoneCannotChange;

  /// No description provided for @myReferralCode.
  ///
  /// In en, this message translates to:
  /// **'My referral code'**
  String get myReferralCode;

  /// No description provided for @noAddresses.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses'**
  String get noAddresses;

  /// No description provided for @noAddressesHint.
  ///
  /// In en, this message translates to:
  /// **'Add an address to get home delivery.'**
  String get noAddressesHint;

  /// No description provided for @deleteAddressQ.
  ///
  /// In en, this message translates to:
  /// **'Delete this address?'**
  String get deleteAddressQ;

  /// No description provided for @editAddress.
  ///
  /// In en, this message translates to:
  /// **'Edit address'**
  String get editAddress;

  /// No description provided for @addrHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get addrHome;

  /// No description provided for @addrShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get addrShop;

  /// No description provided for @addrWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get addrWork;

  /// No description provided for @addrOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get addrOther;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @houseNoStreet.
  ///
  /// In en, this message translates to:
  /// **'House no. and street'**
  String get houseNoStreet;

  /// No description provided for @colonyOrVillage.
  ///
  /// In en, this message translates to:
  /// **'Colony, mohalla or village'**
  String get colonyOrVillage;

  /// No description provided for @landmark.
  ///
  /// In en, this message translates to:
  /// **'Landmark'**
  String get landmark;

  /// No description provided for @cityTown.
  ///
  /// In en, this message translates to:
  /// **'City or town'**
  String get cityTown;

  /// No description provided for @pincode.
  ///
  /// In en, this message translates to:
  /// **'Pincode'**
  String get pincode;

  /// No description provided for @stateLabel.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get stateLabel;

  /// No description provided for @wishlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your wishlist is empty'**
  String get wishlistEmpty;

  /// No description provided for @wishlistEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on any product to save it for later.'**
  String get wishlistEmptyHint;

  /// No description provided for @helpBody.
  ///
  /// In en, this message translates to:
  /// **'The quickest help is at the store. You can also call or message us.'**
  String get helpBody;

  /// No description provided for @faq1q.
  ///
  /// In en, this message translates to:
  /// **'How can I pay?'**
  String get faq1q;

  /// No description provided for @faq1a.
  ///
  /// In en, this message translates to:
  /// **'By UPI, credit or debit card, net banking, or cash (at the store, or on delivery in town). You can also use Bajaj Finserv EMI or card EMI.'**
  String get faq1a;

  /// No description provided for @faq2q.
  ///
  /// In en, this message translates to:
  /// **'How does Bajaj Finserv EMI work?'**
  String get faq2q;

  /// No description provided for @faq2a.
  ///
  /// In en, this message translates to:
  /// **'Apply in the app and pay a small down payment. Visit the store with your Aadhaar, PAN and bank details to complete the check. Once Bajaj Finserv approves, you take the phone and pay monthly. Approval is the lender decision, not the shop.'**
  String get faq2a;

  /// No description provided for @faq3q.
  ///
  /// In en, this message translates to:
  /// **'What is Autopay?'**
  String get faq3q;

  /// No description provided for @faq3a.
  ///
  /// In en, this message translates to:
  /// **'A standing instruction so each EMI is debited on its due date. You choose UPI, card or bank, set a limit, get a reminder before every debit, and can pause or cancel any time.'**
  String get faq3a;

  /// No description provided for @faq4q.
  ///
  /// In en, this message translates to:
  /// **'Can I return what I bought?'**
  String get faq4q;

  /// No description provided for @faq4a.
  ///
  /// In en, this message translates to:
  /// **'Within 7 days of delivery you can ask for a return of a wrong or defective item, with its box and bill. The shop checks it and refunds you. Opened phones are checked by the brand service centre.'**
  String get faq4a;

  /// No description provided for @faq5q.
  ///
  /// In en, this message translates to:
  /// **'How does the warranty work?'**
  String get faq5q;

  /// No description provided for @faq5a.
  ///
  /// In en, this message translates to:
  /// **'Every phone comes with the brand warranty. We record the IMEI on your bill, so your warranty and bill are always in your Orders, even if you lose the paper.'**
  String get faq5a;

  /// No description provided for @faq6q.
  ///
  /// In en, this message translates to:
  /// **'How does delivery work?'**
  String get faq6q;

  /// No description provided for @faq6a.
  ///
  /// In en, this message translates to:
  /// **'Same-day home delivery in town and nearby areas. Elsewhere we send by courier, and phones are prepaid. Cash on delivery is only for local delivery under the shop limit.'**
  String get faq6a;

  /// No description provided for @faq7q.
  ///
  /// In en, this message translates to:
  /// **'What does Reserve mean?'**
  String get faq7q;

  /// No description provided for @faq7a.
  ///
  /// In en, this message translates to:
  /// **'Pay a small token and we hold the phone for you for a few days. Visit the store, pay the rest and take it. If you cancel before the time ends, the token is refunded.'**
  String get faq7a;

  /// No description provided for @roadToTarget.
  ///
  /// In en, this message translates to:
  /// **'Road to {target} a month'**
  String roadToTarget(String target);

  /// No description provided for @onTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get onTrack;

  /// No description provided for @behindTarget.
  ///
  /// In en, this message translates to:
  /// **'Behind target'**
  String get behindTarget;

  /// No description provided for @ofTarget.
  ///
  /// In en, this message translates to:
  /// **'of target'**
  String get ofTarget;

  /// No description provided for @profitThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Profit this month'**
  String get profitThisMonth;

  /// No description provided for @projectedMonthEnd.
  ///
  /// In en, this message translates to:
  /// **'On this pace: {amount} by month end'**
  String projectedMonthEnd(String amount);

  /// No description provided for @needPerDay.
  ///
  /// In en, this message translates to:
  /// **'Need {amount} a day for the {days, plural, =1{last day} other{next {days} days}}'**
  String needPerDay(String amount, int days);

  /// No description provided for @baselineLine.
  ///
  /// In en, this message translates to:
  /// **'From about {baseline} a month to the target: {multiple} times today.'**
  String baselineLine(String baseline, String multiple);

  /// No description provided for @profitBasisNote.
  ///
  /// In en, this message translates to:
  /// **'Profit after GST and fees, before rent, salaries and power.'**
  String get profitBasisNote;

  /// No description provided for @todaySales.
  ///
  /// In en, this message translates to:
  /// **'Sales today'**
  String get todaySales;

  /// No description provided for @ordersToday.
  ///
  /// In en, this message translates to:
  /// **'Orders today'**
  String get ordersToday;

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs your attention'**
  String get needsAttention;

  /// No description provided for @attnOrders.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No orders to handle} =1{1 order to handle} other{{n} orders to handle}}'**
  String attnOrders(int n);

  /// No description provided for @attnEmiApprovals.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No EMI applications waiting} =1{1 EMI application waiting} other{{n} EMI applications waiting}}'**
  String attnEmiApprovals(int n);

  /// No description provided for @attnOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No overdue instalments} =1{1 overdue instalment ({amount})} other{{count} overdue instalments ({amount})}}'**
  String attnOverdue(int count, String amount);

  /// No description provided for @attnLeads.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No new leads} =1{1 new lead to call} other{{n} new leads to call}}'**
  String attnLeads(int n);

  /// No description provided for @attnFollowUps.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No follow-ups due} =1{1 follow-up due} other{{n} follow-ups due}}'**
  String attnFollowUps(int n);

  /// No description provided for @attnRepairs.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No repairs waiting} =1{1 repair waiting} other{{n} repairs waiting}}'**
  String attnRepairs(int n);

  /// No description provided for @attnLowStock.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Stock looks healthy} =1{1 item low or out of stock} other{{n} items low or out of stock}}'**
  String attnLowStock(int n);

  /// No description provided for @last14Days.
  ///
  /// In en, this message translates to:
  /// **'Profit, last 14 days'**
  String get last14Days;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @whereProfitComes.
  ///
  /// In en, this message translates to:
  /// **'Where the profit comes from'**
  String get whereProfitComes;

  /// No description provided for @leverRepairs.
  ///
  /// In en, this message translates to:
  /// **'Repairs'**
  String get leverRepairs;

  /// No description provided for @leversHint.
  ///
  /// In en, this message translates to:
  /// **'Phones carry thin margins. Accessories, protection plans and repairs are where profit grows fastest: sell them with every phone.'**
  String get leversHint;

  /// No description provided for @growthScorecard.
  ///
  /// In en, this message translates to:
  /// **'Growth scorecard (last 30 days)'**
  String get growthScorecard;

  /// No description provided for @scorecardHint.
  ///
  /// In en, this message translates to:
  /// **'What you did against what the target month needs.'**
  String get scorecardHint;

  /// No description provided for @scPhones.
  ///
  /// In en, this message translates to:
  /// **'Phones sold'**
  String get scPhones;

  /// No description provided for @scAttach.
  ///
  /// In en, this message translates to:
  /// **'Phones sold with an accessory'**
  String get scAttach;

  /// No description provided for @scProtection.
  ///
  /// In en, this message translates to:
  /// **'Phones sold with a protection plan'**
  String get scProtection;

  /// No description provided for @scRepairs.
  ///
  /// In en, this message translates to:
  /// **'Repairs done'**
  String get scRepairs;

  /// No description provided for @scLeadConv.
  ///
  /// In en, this message translates to:
  /// **'Leads that became a sale'**
  String get scLeadConv;

  /// No description provided for @scRepeat.
  ///
  /// In en, this message translates to:
  /// **'Sales to returning customers'**
  String get scRepeat;

  /// No description provided for @finishSetup.
  ///
  /// In en, this message translates to:
  /// **'Finish setting up your shop'**
  String get finishSetup;

  /// No description provided for @finishSetupBody.
  ///
  /// In en, this message translates to:
  /// **'The app hides buttons that need these until you add them, so customers never reach a wrong number.'**
  String get finishSetupBody;

  /// No description provided for @setupPhone.
  ///
  /// In en, this message translates to:
  /// **'Shop phone'**
  String get setupPhone;

  /// No description provided for @setupWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp number'**
  String get setupWhatsapp;

  /// No description provided for @setupUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI ID'**
  String get setupUpi;

  /// No description provided for @setupGstin.
  ///
  /// In en, this message translates to:
  /// **'GSTIN'**
  String get setupGstin;

  /// No description provided for @setupLocation.
  ///
  /// In en, this message translates to:
  /// **'Map location'**
  String get setupLocation;

  /// No description provided for @setupEmiRates.
  ///
  /// In en, this message translates to:
  /// **'Confirm EMI rates'**
  String get setupEmiRates;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @newSale.
  ///
  /// In en, this message translates to:
  /// **'New sale'**
  String get newSale;

  /// No description provided for @newSaleHint.
  ///
  /// In en, this message translates to:
  /// **'Bill a customer at the counter'**
  String get newSaleHint;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get addProduct;

  /// No description provided for @runAutopayNow.
  ///
  /// In en, this message translates to:
  /// **'Run Autopay now'**
  String get runAutopayNow;

  /// No description provided for @autopayRan.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No instalments were due.} =1{Collected 1 instalment.} other{Collected {n} instalments.}}'**
  String autopayRan(int n);

  /// No description provided for @fltToHandle.
  ///
  /// In en, this message translates to:
  /// **'To handle'**
  String get fltToHandle;

  /// No description provided for @fltReady.
  ///
  /// In en, this message translates to:
  /// **'Out or ready'**
  String get fltReady;

  /// No description provided for @fltDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get fltDone;

  /// No description provided for @fltCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get fltCancelled;

  /// No description provided for @searchOrdersHint.
  ///
  /// In en, this message translates to:
  /// **'Order number, name or phone'**
  String get searchOrdersHint;

  /// No description provided for @sourceCounter.
  ///
  /// In en, this message translates to:
  /// **'Counter'**
  String get sourceCounter;

  /// No description provided for @sourceApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get sourceApp;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @orderUpdateText.
  ///
  /// In en, this message translates to:
  /// **'Update on your order {number}: {status}.'**
  String orderUpdateText(String number, String status);

  /// No description provided for @actMarkPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get actMarkPaid;

  /// No description provided for @actConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm order'**
  String get actConfirm;

  /// No description provided for @actPack.
  ///
  /// In en, this message translates to:
  /// **'Mark packed'**
  String get actPack;

  /// No description provided for @actOut.
  ///
  /// In en, this message translates to:
  /// **'Out for delivery'**
  String get actOut;

  /// No description provided for @actReady.
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup'**
  String get actReady;

  /// No description provided for @actDeliver.
  ///
  /// In en, this message translates to:
  /// **'Mark delivered'**
  String get actDeliver;

  /// No description provided for @actCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get actCancel;

  /// No description provided for @actRejectReturn.
  ///
  /// In en, this message translates to:
  /// **'Reject return'**
  String get actRejectReturn;

  /// No description provided for @actAcceptReturn.
  ///
  /// In en, this message translates to:
  /// **'Accept return'**
  String get actAcceptReturn;

  /// No description provided for @confirmReturnQ.
  ///
  /// In en, this message translates to:
  /// **'Accept this return?'**
  String get confirmReturnQ;

  /// No description provided for @imeiMissing.
  ///
  /// In en, this message translates to:
  /// **'IMEI not entered yet'**
  String get imeiMissing;

  /// No description provided for @enterImei.
  ///
  /// In en, this message translates to:
  /// **'Enter IMEI'**
  String get enterImei;

  /// No description provided for @imeiHelp.
  ///
  /// In en, this message translates to:
  /// **'Dial *#06# on the phone to see its IMEI. Enter one for every phone.'**
  String get imeiHelp;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @collectPayment.
  ///
  /// In en, this message translates to:
  /// **'Collect payment'**
  String get collectPayment;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @referenceOptional.
  ///
  /// In en, this message translates to:
  /// **'Reference (optional)'**
  String get referenceOptional;

  /// No description provided for @markLenderPaid.
  ///
  /// In en, this message translates to:
  /// **'Lender has paid us'**
  String get markLenderPaid;

  /// No description provided for @lenderReference.
  ///
  /// In en, this message translates to:
  /// **'Lender reference'**
  String get lenderReference;

  /// No description provided for @sendRefund.
  ///
  /// In en, this message translates to:
  /// **'Send refund {amount}'**
  String sendRefund(String amount);

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @stockLow.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get stockLow;

  /// No description provided for @hidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hidden;

  /// No description provided for @missingCosts.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 product has no cost price, so its profit counts as zero.} other{{n} products have no cost price, so their profit counts as zero.}}'**
  String missingCosts(int n);

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get editProduct;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide from customers'**
  String get hide;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show to customers'**
  String get show;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productName;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @variantsHeader.
  ///
  /// In en, this message translates to:
  /// **'Variants and prices'**
  String get variantsHeader;

  /// No description provided for @addVariant.
  ///
  /// In en, this message translates to:
  /// **'Add variant'**
  String get addVariant;

  /// No description provided for @variantLabel.
  ///
  /// In en, this message translates to:
  /// **'Variant'**
  String get variantLabel;

  /// No description provided for @colorLabel.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get colorLabel;

  /// No description provided for @sellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling price'**
  String get sellingPrice;

  /// No description provided for @stockLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stockLabel;

  /// No description provided for @costPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost price'**
  String get costPrice;

  /// No description provided for @costPriceHelp.
  ///
  /// In en, this message translates to:
  /// **'What you paid, GST included. Customers never see it.'**
  String get costPriceHelp;

  /// No description provided for @profitPerUnit.
  ///
  /// In en, this message translates to:
  /// **'Profit per unit (after GST)'**
  String get profitPerUnit;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @imageUrls.
  ///
  /// In en, this message translates to:
  /// **'Photo links'**
  String get imageUrls;

  /// No description provided for @imageUrlsHelp.
  ///
  /// In en, this message translates to:
  /// **'One web link per line. Photo upload comes with the online shop server.'**
  String get imageUrlsHelp;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @tagsHelp.
  ///
  /// In en, this message translates to:
  /// **'Comma separated, e.g. refurbished, festival'**
  String get tagsHelp;

  /// No description provided for @sellingOptions.
  ///
  /// In en, this message translates to:
  /// **'Selling options'**
  String get sellingOptions;

  /// No description provided for @warrantyMonthsLabel.
  ///
  /// In en, this message translates to:
  /// **'Warranty (months)'**
  String get warrantyMonthsLabel;

  /// No description provided for @gstRate.
  ///
  /// In en, this message translates to:
  /// **'GST rate'**
  String get gstRate;

  /// No description provided for @emiEligible.
  ///
  /// In en, this message translates to:
  /// **'Can be bought on EMI'**
  String get emiEligible;

  /// No description provided for @noCostEligible.
  ///
  /// In en, this message translates to:
  /// **'Eligible for 0% EMI'**
  String get noCostEligible;

  /// No description provided for @noCostEligibleHint.
  ///
  /// In en, this message translates to:
  /// **'Only if your lender and the brand offer it on this model.'**
  String get noCostEligibleHint;

  /// No description provided for @featuredOnHome.
  ///
  /// In en, this message translates to:
  /// **'Show on the home screen'**
  String get featuredOnHome;

  /// No description provided for @visibleToCustomers.
  ///
  /// In en, this message translates to:
  /// **'Visible to customers'**
  String get visibleToCustomers;

  /// No description provided for @fltOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get fltOpen;

  /// No description provided for @fltFollowUpDue.
  ///
  /// In en, this message translates to:
  /// **'Follow-up due'**
  String get fltFollowUpDue;

  /// No description provided for @noLeads.
  ///
  /// In en, this message translates to:
  /// **'No leads here'**
  String get noLeads;

  /// No description provided for @noLeadsHint.
  ///
  /// In en, this message translates to:
  /// **'Anyone who asks about a phone, applies for EMI, books a repair or sends an exchange will appear here.'**
  String get noLeadsHint;

  /// No description provided for @followUpOn.
  ///
  /// In en, this message translates to:
  /// **'Follow up: {when}'**
  String followUpOn(String when);

  /// No description provided for @leadWhatsappText.
  ///
  /// In en, this message translates to:
  /// **'Hello {name}, this is {shop} about your {what}. How can we help you?'**
  String leadWhatsappText(String name, String what, String shop);

  /// No description provided for @yourEnquiry.
  ///
  /// In en, this message translates to:
  /// **'enquiry'**
  String get yourEnquiry;

  /// No description provided for @changeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get changeStatus;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNote;

  /// No description provided for @followUp.
  ///
  /// In en, this message translates to:
  /// **'Follow up'**
  String get followUp;

  /// No description provided for @emiDesk.
  ///
  /// In en, this message translates to:
  /// **'EMI desk'**
  String get emiDesk;

  /// No description provided for @emiDeskHint.
  ///
  /// In en, this message translates to:
  /// **'Applications, approvals, due dates and Autopay'**
  String get emiDeskHint;

  /// No description provided for @repairsDesk.
  ///
  /// In en, this message translates to:
  /// **'Repairs'**
  String get repairsDesk;

  /// No description provided for @offersAndCoupons.
  ///
  /// In en, this message translates to:
  /// **'Offers and coupons'**
  String get offersAndCoupons;

  /// No description provided for @customersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// No description provided for @customersHint.
  ///
  /// In en, this message translates to:
  /// **'Everyone who has bought or asked, and who is due an upgrade'**
  String get customersHint;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @staffTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff and roles'**
  String get staffTitle;

  /// No description provided for @staffHint.
  ///
  /// In en, this message translates to:
  /// **'Who can do what in the app'**
  String get staffHint;

  /// No description provided for @shopSettings.
  ///
  /// In en, this message translates to:
  /// **'Shop settings'**
  String get shopSettings;

  /// No description provided for @resetDemoHint.
  ///
  /// In en, this message translates to:
  /// **'You are looking at sample data. Reset it when you are ready to add your real stock.'**
  String get resetDemoHint;

  /// No description provided for @resetDemo.
  ///
  /// In en, this message translates to:
  /// **'Reset demo data'**
  String get resetDemo;

  /// No description provided for @resetDemoQ.
  ///
  /// In en, this message translates to:
  /// **'Reset all demo data?'**
  String get resetDemoQ;

  /// No description provided for @resetDemoBody.
  ///
  /// In en, this message translates to:
  /// **'This erases every order, customer and change on this device and loads the sample shop again.'**
  String get resetDemoBody;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @discountHelp.
  ///
  /// In en, this message translates to:
  /// **'Counter staff can give up to {pct}%. A manager can give more.'**
  String discountHelp(int pct);

  /// No description provided for @fullCash.
  ///
  /// In en, this message translates to:
  /// **'All cash'**
  String get fullCash;

  /// No description provided for @fullUpi.
  ///
  /// In en, this message translates to:
  /// **'All UPI'**
  String get fullUpi;

  /// No description provided for @fullCard.
  ///
  /// In en, this message translates to:
  /// **'All card'**
  String get fullCard;

  /// No description provided for @addPayment.
  ///
  /// In en, this message translates to:
  /// **'Add a payment'**
  String get addPayment;

  /// No description provided for @paidSoFar.
  ///
  /// In en, this message translates to:
  /// **'Paid so far'**
  String get paidSoFar;

  /// No description provided for @financeBalanceBajaj.
  ///
  /// In en, this message translates to:
  /// **'Finance the rest with Bajaj Finserv'**
  String get financeBalanceBajaj;

  /// No description provided for @financeBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'What the customer pays now is the down payment.'**
  String get financeBalanceHint;

  /// No description provided for @financeNeedsDown.
  ///
  /// In en, this message translates to:
  /// **'Enter the down payment above. The rest, up to the phone price, is financed.'**
  String get financeNeedsDown;

  /// No description provided for @bajajCounterNote.
  ///
  /// In en, this message translates to:
  /// **'The sale is held until the lender approves. IMEI is entered at hand-over.'**
  String get bajajCounterNote;

  /// No description provided for @completeSale.
  ///
  /// In en, this message translates to:
  /// **'Complete sale'**
  String get completeSale;

  /// No description provided for @saleDone.
  ///
  /// In en, this message translates to:
  /// **'Sale complete: {number}'**
  String saleDone(String number);

  /// No description provided for @saleDoneBody.
  ///
  /// In en, this message translates to:
  /// **'The bill and warranty are now in the customer app, under their mobile number.'**
  String get saleDoneBody;

  /// No description provided for @saleDoneEmiBody.
  ///
  /// In en, this message translates to:
  /// **'The EMI application is open. Approve it on the EMI desk, then hand the phone over.'**
  String get saleDoneEmiBody;

  /// No description provided for @sendBill.
  ///
  /// In en, this message translates to:
  /// **'Send bill on WhatsApp'**
  String get sendBill;

  /// No description provided for @tabApplications.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get tabApplications;

  /// No description provided for @tabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get tabActive;

  /// No description provided for @tabOther.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get tabOther;

  /// No description provided for @dueThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Due this month'**
  String get dueThisMonth;

  /// No description provided for @overdueLabel.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueLabel;

  /// No description provided for @overdueCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 overdue} other{{n} overdue}}'**
  String overdueCount(int n);

  /// No description provided for @approveHint.
  ///
  /// In en, this message translates to:
  /// **'Approve only after the lender (Bajaj Finserv or the bank) has approved the loan. Then the phone can be handed over.'**
  String get approveHint;

  /// No description provided for @approvePlan.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approvePlan;

  /// No description provided for @rejectPlan.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectPlan;

  /// No description provided for @lenderRefHint.
  ///
  /// In en, this message translates to:
  /// **'Loan or application number'**
  String get lenderRefHint;

  /// No description provided for @markPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark paid'**
  String get markPaid;

  /// No description provided for @issueLabel.
  ///
  /// In en, this message translates to:
  /// **'Problem'**
  String get issueLabel;

  /// No description provided for @quotePrice.
  ///
  /// In en, this message translates to:
  /// **'Price quoted to the customer'**
  String get quotePrice;

  /// No description provided for @partsCostPrompt.
  ///
  /// In en, this message translates to:
  /// **'What did the parts cost you?'**
  String get partsCostPrompt;

  /// No description provided for @moveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to: {status}'**
  String moveTo(String status);

  /// No description provided for @waitingForCustomer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the customer to approve the price.'**
  String get waitingForCustomer;

  /// No description provided for @customerApproved.
  ///
  /// In en, this message translates to:
  /// **'Customer agreed on the phone'**
  String get customerApproved;

  /// No description provided for @addOffer.
  ///
  /// In en, this message translates to:
  /// **'Add offer'**
  String get addOffer;

  /// No description provided for @editOffer.
  ///
  /// In en, this message translates to:
  /// **'Edit offer'**
  String get editOffer;

  /// No description provided for @noOffers.
  ///
  /// In en, this message translates to:
  /// **'No offers yet'**
  String get noOffers;

  /// No description provided for @noOffersHint.
  ///
  /// In en, this message translates to:
  /// **'Add a festival banner or a coupon code. Customers see it on the home screen and at checkout.'**
  String get noOffersHint;

  /// No description provided for @shareOffer.
  ///
  /// In en, this message translates to:
  /// **'Share offer'**
  String get shareOffer;

  /// No description provided for @offerShareBanner.
  ///
  /// In en, this message translates to:
  /// **'{title}. Visit {shop} or order on the Brandhoop app.'**
  String offerShareBanner(String title, String shop);

  /// No description provided for @offerShareCoupon.
  ///
  /// In en, this message translates to:
  /// **'{title}. Use code {code} at {shop} or on the Brandhoop app.'**
  String offerShareCoupon(String title, String code, String shop);

  /// No description provided for @offerTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get offerTitle;

  /// No description provided for @offerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Subtitle'**
  String get offerSubtitle;

  /// No description provided for @kindCoupon.
  ///
  /// In en, this message translates to:
  /// **'Coupon'**
  String get kindCoupon;

  /// No description provided for @kindBanner.
  ///
  /// In en, this message translates to:
  /// **'Banner'**
  String get kindBanner;

  /// No description provided for @percentOff.
  ///
  /// In en, this message translates to:
  /// **'Percent off'**
  String get percentOff;

  /// No description provided for @flatOff.
  ///
  /// In en, this message translates to:
  /// **'Flat off'**
  String get flatOff;

  /// No description provided for @minOrder.
  ///
  /// In en, this message translates to:
  /// **'Minimum order'**
  String get minOrder;

  /// No description provided for @maxDiscount.
  ///
  /// In en, this message translates to:
  /// **'Maximum discount'**
  String get maxDiscount;

  /// No description provided for @appliesTo.
  ///
  /// In en, this message translates to:
  /// **'Applies to'**
  String get appliesTo;

  /// No description provided for @appliesToHint.
  ///
  /// In en, this message translates to:
  /// **'Leave all unselected to apply to everything. Keep phones out of big discounts: their margin is thin.'**
  String get appliesToHint;

  /// No description provided for @starts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get starts;

  /// No description provided for @ends.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get ends;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeLabel;

  /// No description provided for @deleteOfferQ.
  ///
  /// In en, this message translates to:
  /// **'Delete this offer?'**
  String get deleteOfferQ;

  /// No description provided for @searchCustomersHint.
  ///
  /// In en, this message translates to:
  /// **'Name or phone'**
  String get searchCustomersHint;

  /// No description provided for @segUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Due an upgrade'**
  String get segUpgrade;

  /// No description provided for @segTop.
  ///
  /// In en, this message translates to:
  /// **'Top spenders'**
  String get segTop;

  /// No description provided for @segRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat buyers'**
  String get segRepeat;

  /// No description provided for @segNew.
  ///
  /// In en, this message translates to:
  /// **'New this month'**
  String get segNew;

  /// No description provided for @upgradeHint.
  ///
  /// In en, this message translates to:
  /// **'These customers bought their last phone more than 18 months ago. They are the likeliest to buy again.'**
  String get upgradeHint;

  /// No description provided for @tapCustomerToMessage.
  ///
  /// In en, this message translates to:
  /// **'Open a customer to send them an offer on WhatsApp.'**
  String get tapCustomerToMessage;

  /// No description provided for @ordersCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No orders} =1{1 order} other{{n} orders}}'**
  String ordersCount(int n);

  /// No description provided for @customerSince.
  ///
  /// In en, this message translates to:
  /// **'Customer since {date}'**
  String customerSince(String date);

  /// No description provided for @addedAtCounter.
  ///
  /// In en, this message translates to:
  /// **'added at the counter'**
  String get addedAtCounter;

  /// No description provided for @lifetimeSpend.
  ///
  /// In en, this message translates to:
  /// **'Total bought'**
  String get lifetimeSpend;

  /// No description provided for @coinsLabel.
  ///
  /// In en, this message translates to:
  /// **'Brandhoop Coins'**
  String get coinsLabel;

  /// No description provided for @lastPhoneBought.
  ///
  /// In en, this message translates to:
  /// **'Last phone bought'**
  String get lastPhoneBought;

  /// No description provided for @sendOffer.
  ///
  /// In en, this message translates to:
  /// **'Send offer'**
  String get sendOffer;

  /// No description provided for @sendUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade message'**
  String get sendUpgrade;

  /// No description provided for @customerOfferText.
  ///
  /// In en, this message translates to:
  /// **'Hello {name}! {shop} has new offers on phones and accessories this week. Visit us or reply here to know more.'**
  String customerOfferText(String name, String shop);

  /// No description provided for @upgradeText.
  ///
  /// In en, this message translates to:
  /// **'Hello {name}! It has been a while since your last phone from {shop}. Come and see what you get for your old phone on the latest models.'**
  String upgradeText(String name, String shop);

  /// No description provided for @addStaff.
  ///
  /// In en, this message translates to:
  /// **'Add staff'**
  String get addStaff;

  /// No description provided for @staffExplain.
  ///
  /// In en, this message translates to:
  /// **'Give a mobile number a role. When that person signs in with the code, they see the back office that role allows.'**
  String get staffExplain;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @makeRole.
  ///
  /// In en, this message translates to:
  /// **'Make {role}'**
  String makeRole(String role);

  /// No description provided for @disableAccount.
  ///
  /// In en, this message translates to:
  /// **'Switch off this account'**
  String get disableAccount;

  /// No description provided for @enableAccount.
  ///
  /// In en, this message translates to:
  /// **'Switch this account on'**
  String get enableAccount;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Switched off'**
  String get disabled;

  /// No description provided for @staffAdded.
  ///
  /// In en, this message translates to:
  /// **'Added. They can sign in with their mobile number.'**
  String get staffAdded;

  /// No description provided for @whatEachRoleCanDo.
  ///
  /// In en, this message translates to:
  /// **'What each role can do'**
  String get whatEachRoleCanDo;

  /// No description provided for @roleStaffCan.
  ///
  /// In en, this message translates to:
  /// **'Bills at the counter, handles orders and leads, runs repairs, adjusts stock. Cannot see costs or profit, change prices, or approve EMI.'**
  String get roleStaffCan;

  /// No description provided for @roleManagerCan.
  ///
  /// In en, this message translates to:
  /// **'Everything staff can do, plus products, prices, cost prices, offers, EMI approvals and reports. Cannot see profit totals, staff or settings.'**
  String get roleManagerCan;

  /// No description provided for @roleOwnerCan.
  ///
  /// In en, this message translates to:
  /// **'Everything, including profit and the road to the target, refunds, staff and shop settings.'**
  String get roleOwnerCan;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Copy as CSV'**
  String get exportCsv;

  /// No description provided for @csvCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied. Paste it into a spreadsheet.'**
  String get csvCopied;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30Days;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get revenue;

  /// No description provided for @ordersLabel.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get ordersLabel;

  /// No description provided for @avgOrder.
  ///
  /// In en, this message translates to:
  /// **'Average order'**
  String get avgOrder;

  /// No description provided for @phonesSold.
  ///
  /// In en, this message translates to:
  /// **'Phones sold'**
  String get phonesSold;

  /// No description provided for @margin.
  ///
  /// In en, this message translates to:
  /// **'Profit margin'**
  String get margin;

  /// No description provided for @dailyProfitRevenue.
  ///
  /// In en, this message translates to:
  /// **'Day by day'**
  String get dailyProfitRevenue;

  /// No description provided for @salesByGroup.
  ///
  /// In en, this message translates to:
  /// **'Sales by type'**
  String get salesByGroup;

  /// No description provided for @paymentMix.
  ///
  /// In en, this message translates to:
  /// **'How customers paid'**
  String get paymentMix;

  /// No description provided for @topProducts.
  ///
  /// In en, this message translates to:
  /// **'Best sellers'**
  String get topProducts;

  /// No description provided for @unitsSold.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 sold} other{{n} sold}}'**
  String unitsSold(int n);

  /// No description provided for @setShopInfo.
  ///
  /// In en, this message translates to:
  /// **'Shop details'**
  String get setShopInfo;

  /// No description provided for @shopName.
  ///
  /// In en, this message translates to:
  /// **'Shop name'**
  String get shopName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Tagline'**
  String get tagline;

  /// No description provided for @shopPhone.
  ///
  /// In en, this message translates to:
  /// **'Shop phone'**
  String get shopPhone;

  /// No description provided for @shopPhoneHelp.
  ///
  /// In en, this message translates to:
  /// **'Customers tap this to call. Leave empty to hide the Call button.'**
  String get shopPhoneHelp;

  /// No description provided for @shopWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp number'**
  String get shopWhatsapp;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @mapsLink.
  ///
  /// In en, this message translates to:
  /// **'Google Maps link'**
  String get mapsLink;

  /// No description provided for @mapsLinkHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional. Open the shop on Google Maps, tap Share, paste the link here.'**
  String get mapsLinkHelp;

  /// No description provided for @shopUpi.
  ///
  /// In en, this message translates to:
  /// **'Shop UPI ID'**
  String get shopUpi;

  /// No description provided for @shopUpiHelp.
  ///
  /// In en, this message translates to:
  /// **'Where counter UPI payments go.'**
  String get shopUpiHelp;

  /// No description provided for @shopGstin.
  ///
  /// In en, this message translates to:
  /// **'GSTIN'**
  String get shopGstin;

  /// No description provided for @opens.
  ///
  /// In en, this message translates to:
  /// **'Opens'**
  String get opens;

  /// No description provided for @closes.
  ///
  /// In en, this message translates to:
  /// **'Closes'**
  String get closes;

  /// No description provided for @deliveryAndOrders.
  ///
  /// In en, this message translates to:
  /// **'Delivery and orders'**
  String get deliveryAndOrders;

  /// No description provided for @localPincodes.
  ///
  /// In en, this message translates to:
  /// **'Pincodes you deliver to yourself'**
  String get localPincodes;

  /// No description provided for @localPincodesHelp.
  ///
  /// In en, this message translates to:
  /// **'Comma separated. Same-day delivery and cash on delivery work only here.'**
  String get localPincodesHelp;

  /// No description provided for @localDeliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Local delivery fee'**
  String get localDeliveryFee;

  /// No description provided for @courierFee.
  ///
  /// In en, this message translates to:
  /// **'Courier fee'**
  String get courierFee;

  /// No description provided for @freeDeliveryAbove.
  ///
  /// In en, this message translates to:
  /// **'Free delivery above'**
  String get freeDeliveryAbove;

  /// No description provided for @reserveHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Reserve hours'**
  String get reserveHoursLabel;

  /// No description provided for @codLimit.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery limit'**
  String get codLimit;

  /// No description provided for @allowCod.
  ///
  /// In en, this message translates to:
  /// **'Allow cash on delivery in town'**
  String get allowCod;

  /// No description provided for @allowReserve.
  ///
  /// In en, this message translates to:
  /// **'Allow reserve with a token'**
  String get allowReserve;

  /// No description provided for @financeSettings.
  ///
  /// In en, this message translates to:
  /// **'EMI and Autopay'**
  String get financeSettings;

  /// No description provided for @financeSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'These rates start as placeholders. Replace them with what Bajaj Finserv and your card banks have agreed with you, then tick Rates confirmed.'**
  String get financeSettingsHint;

  /// No description provided for @allowBajaj.
  ///
  /// In en, this message translates to:
  /// **'Offer Bajaj Finserv EMI'**
  String get allowBajaj;

  /// No description provided for @allowCardEmi.
  ///
  /// In en, this message translates to:
  /// **'Offer card EMI'**
  String get allowCardEmi;

  /// No description provided for @allowAutopay.
  ///
  /// In en, this message translates to:
  /// **'Offer Autopay'**
  String get allowAutopay;

  /// No description provided for @allowShopInstalments.
  ///
  /// In en, this message translates to:
  /// **'Instalments collected by the shop itself'**
  String get allowShopInstalments;

  /// No description provided for @allowShopInstalmentsHint.
  ///
  /// In en, this message translates to:
  /// **'Keep off until you have taken advice: collecting instalments yourself can fall under lending and deposit rules.'**
  String get allowShopInstalmentsHint;

  /// No description provided for @ratesConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Rates confirmed'**
  String get ratesConfirmed;

  /// No description provided for @ratesConfirmedHint.
  ///
  /// In en, this message translates to:
  /// **'Switch on only when the rates below are the real ones.'**
  String get ratesConfirmedHint;

  /// No description provided for @lenderRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Lender rate % a year'**
  String get lenderRateLabel;

  /// No description provided for @minPrice.
  ///
  /// In en, this message translates to:
  /// **'Minimum price'**
  String get minPrice;

  /// No description provided for @minDownPct.
  ///
  /// In en, this message translates to:
  /// **'Minimum down payment %'**
  String get minDownPct;

  /// No description provided for @tenuresLabel.
  ///
  /// In en, this message translates to:
  /// **'Months offered'**
  String get tenuresLabel;

  /// No description provided for @tenuresHelp.
  ///
  /// In en, this message translates to:
  /// **'Comma separated, e.g. 3, 6, 9, 12'**
  String get tenuresHelp;

  /// No description provided for @noCostCostNote.
  ///
  /// In en, this message translates to:
  /// **'On a 0% scheme the customer pays only the price. The interest the lender would charge is counted as a cost of the sale in your profit.'**
  String get noCostCostNote;

  /// No description provided for @targetsAndFees.
  ///
  /// In en, this message translates to:
  /// **'Target, fees and rewards'**
  String get targetsAndFees;

  /// No description provided for @monthlyTarget.
  ///
  /// In en, this message translates to:
  /// **'Monthly profit target'**
  String get monthlyTarget;

  /// No description provided for @baselineProfit.
  ///
  /// In en, this message translates to:
  /// **'Profit before the app'**
  String get baselineProfit;

  /// No description provided for @cardFee.
  ///
  /// In en, this message translates to:
  /// **'Card fee %'**
  String get cardFee;

  /// No description provided for @upiFee.
  ///
  /// In en, this message translates to:
  /// **'UPI fee %'**
  String get upiFee;

  /// No description provided for @profitAfterGst.
  ///
  /// In en, this message translates to:
  /// **'Count profit after GST'**
  String get profitAfterGst;

  /// No description provided for @profitAfterGstHint.
  ///
  /// In en, this message translates to:
  /// **'The GST on your margin goes to the government, so it is not yours to keep.'**
  String get profitAfterGstHint;

  /// No description provided for @coinsEarnPct.
  ///
  /// In en, this message translates to:
  /// **'Coins earned % (accessories)'**
  String get coinsEarnPct;

  /// No description provided for @referralBonus.
  ///
  /// In en, this message translates to:
  /// **'Referral bonus (coins)'**
  String get referralBonus;

  /// No description provided for @maxCoinsPct.
  ///
  /// In en, this message translates to:
  /// **'Max coins use %'**
  String get maxCoinsPct;

  /// No description provided for @repairPricesHeader.
  ///
  /// In en, this message translates to:
  /// **'Repair starting prices'**
  String get repairPricesHeader;

  /// No description provided for @liveOrderCta.
  ///
  /// In en, this message translates to:
  /// **'Send order on WhatsApp'**
  String get liveOrderCta;

  /// No description provided for @liveOrderIntro.
  ///
  /// In en, this message translates to:
  /// **'Hello {shop}, I would like to reserve these items from your app:'**
  String liveOrderIntro(String shop);

  /// No description provided for @liveOrderTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {amount}'**
  String liveOrderTotal(String amount);

  /// No description provided for @liveOrderOutro.
  ///
  /// In en, this message translates to:
  /// **'Please confirm availability and today’s offers. I will visit the shop.'**
  String get liveOrderOutro;

  /// No description provided for @liveCartHint.
  ///
  /// In en, this message translates to:
  /// **'Your order goes to the shop on WhatsApp. The shop confirms stock, price and offers. Pay online by UPI or card as the shop tells you, or pay at the shop. Bajaj Finserv EMI is only at the shop (face scan needed).'**
  String get liveCartHint;

  /// No description provided for @liveShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Send this to the shop'**
  String get liveShareTitle;

  /// No description provided for @liveShareBody.
  ///
  /// In en, this message translates to:
  /// **'The shop’s WhatsApp number is not set in the app yet. Share this message with the shop, or visit the store.'**
  String get liveShareBody;

  /// No description provided for @liveCatalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Our catalogue is being updated'**
  String get liveCatalogTitle;

  /// No description provided for @liveCatalogBody.
  ///
  /// In en, this message translates to:
  /// **'Visit the shop or message us on WhatsApp for today’s phones, prices and Diwali offers.'**
  String get liveCatalogBody;

  /// No description provided for @liveRepairMsg.
  ///
  /// In en, this message translates to:
  /// **'Hello {shop}, I want a repair quote for {device}. Issue: {issue}.'**
  String liveRepairMsg(String shop, String device, String issue);

  /// No description provided for @liveVisitMsg.
  ///
  /// In en, this message translates to:
  /// **'Hello {shop}, I will visit the shop on {when}.'**
  String liveVisitMsg(String shop, String when);

  /// No description provided for @liveExchangeMsg.
  ///
  /// In en, this message translates to:
  /// **'Hello {shop}, I want to exchange my {device}. The app estimate is {range}. Please confirm after seeing the phone.'**
  String liveExchangeMsg(String shop, String device, String range);

  /// No description provided for @liveWhyPayBody.
  ///
  /// In en, this message translates to:
  /// **'UPI and cards online, cash at the shop. Bajaj Finserv EMI only at the shop (face scan needed).'**
  String get liveWhyPayBody;

  /// No description provided for @liveEmiTitle.
  ///
  /// In en, this message translates to:
  /// **'EMI at Brandhoop'**
  String get liveEmiTitle;

  /// No description provided for @liveEmiBody.
  ///
  /// In en, this message translates to:
  /// **'We offer EMI with Bajaj Finserv. It is available only at the shop, because it needs a face scan. Approval, the rate and the final instalments are decided by the lender. Ask at the shop for today’s schemes and rates.'**
  String get liveEmiBody;

  /// No description provided for @liveEmiShopOnly.
  ///
  /// In en, this message translates to:
  /// **'Bajaj Finserv EMI is available only at the shop, because it needs a face scan. Approval and the rate are decided by the lender.'**
  String get liveEmiShopOnly;

  /// No description provided for @liveRefPrice.
  ///
  /// In en, this message translates to:
  /// **'Reference price'**
  String get liveRefPrice;

  /// No description provided for @liveCallForBest.
  ///
  /// In en, this message translates to:
  /// **'Call for best price'**
  String get liveCallForBest;

  /// No description provided for @liveBargainBtn.
  ///
  /// In en, this message translates to:
  /// **'Call to bargain'**
  String get liveBargainBtn;

  /// No description provided for @liveWhatsappAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask offer on WhatsApp'**
  String get liveWhatsappAsk;

  /// No description provided for @liveBargainMsg.
  ///
  /// In en, this message translates to:
  /// **'Hello {shop}, I am interested in {product} (reference price {price}). Please tell me today’s best price and the gifts and offers.'**
  String liveBargainMsg(String shop, String product, String price);

  /// No description provided for @liveBargainMsgNoPrice.
  ///
  /// In en, this message translates to:
  /// **'Hello {shop}, I am interested in {product}. Please tell me today’s best price and the gifts and offers.'**
  String liveBargainMsgNoPrice(String shop, String product);

  /// No description provided for @liveGenericAsk.
  ///
  /// In en, this message translates to:
  /// **'Hello {shop}, please tell me today’s best prices, gifts and offers on mobile phones.'**
  String liveGenericAsk(String shop);

  /// No description provided for @liveAskAvailability.
  ///
  /// In en, this message translates to:
  /// **'Ask the shop for availability'**
  String get liveAskAvailability;

  /// No description provided for @liveGiftTitle.
  ///
  /// In en, this message translates to:
  /// **'Gift and offers'**
  String get liveGiftTitle;

  /// No description provided for @liveGiftWorth.
  ///
  /// In en, this message translates to:
  /// **'Gift worth {amount}'**
  String liveGiftWorth(String amount);

  /// No description provided for @liveYouSave.
  ///
  /// In en, this message translates to:
  /// **'You save {amount}'**
  String liveYouSave(String amount);

  /// No description provided for @liveTotalBenefit.
  ///
  /// In en, this message translates to:
  /// **'Total benefit {amount}'**
  String liveTotalBenefit(String amount);

  /// No description provided for @liveRefNote.
  ///
  /// In en, this message translates to:
  /// **'The reference price is from online listings and can differ. Prices change often: call or WhatsApp now for today’s best price, gifts and EMI help at the shop.'**
  String get liveRefNote;

  /// No description provided for @livePriceOnCall.
  ///
  /// In en, this message translates to:
  /// **'Price on call'**
  String get livePriceOnCall;

  /// No description provided for @liveWorryTitle.
  ///
  /// In en, this message translates to:
  /// **'Worried prices will go up?'**
  String get liveWorryTitle;

  /// No description provided for @liveWorryBody.
  ///
  /// In en, this message translates to:
  /// **'Phone prices change often. Call or message us today for the best price, gifts and easy EMI at the shop, and buy without waiting.'**
  String get liveWorryBody;

  /// No description provided for @liveWorryCta.
  ///
  /// In en, this message translates to:
  /// **'Get today’s best price'**
  String get liveWorryCta;

  /// No description provided for @liveGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Festival gifts and offers'**
  String get liveGalleryTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
