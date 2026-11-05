// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'ब्रांडहूप';

  @override
  String get appTagline => 'आपकी अपनी मोबाइल दुकान, अब आपकी जेब में';

  @override
  String get chooseLanguage => 'अपनी भाषा चुनें';

  @override
  String get chooseLanguageHint =>
      'आप इसे कभी भी स्क्रीन के ऊपर से बदल सकते हैं।';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageShortHi => 'हिं';

  @override
  String get languageShortEn => 'EN';

  @override
  String get switchLanguage => 'भाषा बदलें';

  @override
  String get continueLabel => 'आगे बढ़ें';

  @override
  String get ok => 'ठीक है';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सहेजें';

  @override
  String get saved => 'सहेज लिया';

  @override
  String get delete => 'हटाएं';

  @override
  String get edit => 'बदलें';

  @override
  String get add => 'जोड़ें';

  @override
  String get remove => 'हटाएं';

  @override
  String get retry => 'फिर कोशिश करें';

  @override
  String get close => 'बंद करें';

  @override
  String get done => 'हो गया';

  @override
  String get next => 'आगे';

  @override
  String get back => 'पीछे';

  @override
  String get search => 'खोजें';

  @override
  String get apply => 'लगाएं';

  @override
  String get applied => 'लग गया';

  @override
  String get copy => 'कॉपी करें';

  @override
  String get copied => 'कॉपी हो गया';

  @override
  String get share => 'शेयर करें';

  @override
  String get call => 'कॉल करें';

  @override
  String get whatsapp => 'व्हाट्सऐप';

  @override
  String get directions => 'रास्ता';

  @override
  String get viewAll => 'सभी देखें';

  @override
  String get confirm => 'पक्का करें';

  @override
  String get yes => 'हां';

  @override
  String get no => 'नहीं';

  @override
  String get loading => 'लोड हो रहा है…';

  @override
  String get optional => 'वैकल्पिक';

  @override
  String get required => 'ज़रूरी';

  @override
  String get noResults => 'कुछ नहीं मिला';

  @override
  String get tryAgainLater => 'कृपया थोड़ी देर में फिर कोशिश करें।';

  @override
  String get somethingWrong => 'कुछ गड़बड़ हो गई';

  @override
  String get signIn => 'साइन इन करें';

  @override
  String get signOut => 'साइन आउट करें';

  @override
  String get perMonth => '/माह';

  @override
  String get perMonthShort => '/माह';

  @override
  String get freeLabel => 'मुफ़्त';

  @override
  String get inclGst => 'जीएसटी सहित';

  @override
  String get sample => 'नमूना';

  @override
  String get demoMode => 'डेमो मोड';

  @override
  String get demoBanner =>
      'डेमो मोड: नमूना प्रोडक्ट, नकली पेमेंट, कोई असली पैसा नहीं जाता।';

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count आइटम',
      one: '1 आइटम',
    );
    return '$_temp0';
  }

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन बाकी',
      one: '1 दिन बाकी',
    );
    return '$_temp0';
  }

  @override
  String monthsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count महीने',
      one: '1 महीना',
    );
    return '$_temp0';
  }

  @override
  String hoursCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count घंटे',
      one: '1 घंटा',
    );
    return '$_temp0';
  }

  @override
  String get navHome => 'होम';

  @override
  String get navShop => 'दुकान';

  @override
  String get navEmi => 'ईएमआई';

  @override
  String get navOrders => 'ऑर्डर';

  @override
  String get navAccount => 'खाता';

  @override
  String get navDashboard => 'डैशबोर्ड';

  @override
  String get navStock => 'स्टॉक';

  @override
  String get navLeads => 'लीड्स';

  @override
  String get navMore => 'और';

  @override
  String get catSmartphone => 'स्मार्टफोन';

  @override
  String get catFeaturePhone => 'फीचर फोन';

  @override
  String get catTablet => 'टैबलेट';

  @override
  String get catEarphones => 'ईयरफोन और बड्स';

  @override
  String get catCharger => 'चार्जर';

  @override
  String get catCable => 'केबल';

  @override
  String get catCase => 'कवर और केस';

  @override
  String get catScreenGuard => 'स्क्रीन गार्ड';

  @override
  String get catPowerBank => 'पावर बैंक';

  @override
  String get catSmartwatch => 'स्मार्टवॉच';

  @override
  String get catSpeaker => 'स्पीकर';

  @override
  String get catMemory => 'मेमोरी कार्ड';

  @override
  String get catProtection => 'प्रोटेक्शन प्लान';

  @override
  String get groupPhones => 'फोन';

  @override
  String get groupAccessories => 'एक्सेसरीज़';

  @override
  String get groupProtection => 'प्रोटेक्शन';

  @override
  String get groupAll => 'सभी';

  @override
  String get specRam => 'रैम';

  @override
  String get specStorage => 'स्टोरेज';

  @override
  String get specDisplay => 'डिस्प्ले';

  @override
  String get specBattery => 'बैटरी';

  @override
  String get specCamera => 'कैमरा';

  @override
  String get specChip => 'प्रोसेसर';

  @override
  String get specOs => 'ऑपरेटिंग सिस्टम';

  @override
  String get statusPendingPayment => 'पेमेंट का इंतज़ार';

  @override
  String get statusPlaced => 'ऑर्डर मिल गया';

  @override
  String get statusConfirmed => 'पक्का हो गया';

  @override
  String get statusPacked => 'पैक हो गया';

  @override
  String get statusOutForDelivery => 'डिलीवरी के लिए निकला';

  @override
  String get statusReadyForPickup => 'लेने के लिए तैयार';

  @override
  String get statusDelivered => 'मिल गया';

  @override
  String get statusCancelled => 'रद्द';

  @override
  String get statusReturnRequested => 'वापसी का अनुरोध';

  @override
  String get statusReturned => 'वापस हो गया';

  @override
  String get fulfilDelivery => 'घर पर डिलीवरी';

  @override
  String get fulfilPickup => 'दुकान से ले जाएं';

  @override
  String get fulfilWalkIn => 'दुकान पर खरीदा';

  @override
  String get payMethodUpi => 'यूपीआई';

  @override
  String get payMethodCard => 'कार्ड';

  @override
  String get payMethodNetbanking => 'नेट बैंकिंग';

  @override
  String get payMethodCash => 'नकद';

  @override
  String get payMethodBajaj => 'बजाज फिनसर्व ईएमआई';

  @override
  String get payMethodCardEmi => 'कार्ड ईएमआई';

  @override
  String get payModeFull => 'पूरा पेमेंट';

  @override
  String get payModeToken => 'टोकन देकर रिज़र्व';

  @override
  String get payModeCod => 'डिलीवरी पर नकद';

  @override
  String get payModeCashStore => 'दुकान पर नकद';

  @override
  String get payModeBajaj => 'बजाज फिनसर्व ईएमआई';

  @override
  String get payModeCardEmi => 'कार्ड ईएमआई';

  @override
  String get payModeMixed => 'अलग-अलग पेमेंट';

  @override
  String get payStatusPending => 'बाकी';

  @override
  String get payStatusPaid => 'चुकाया';

  @override
  String get payStatusFailed => 'नाकाम';

  @override
  String get payKindRefund => 'रिफंड';

  @override
  String get payKindLender => 'ऋणदाता द्वारा';

  @override
  String get planApplied => 'आवेदन भेजा गया';

  @override
  String get planApproved => 'मंज़ूर';

  @override
  String get planActive => 'चालू';

  @override
  String get planClosed => 'पूरा चुकाया';

  @override
  String get planRejected => 'मंज़ूर नहीं हुआ';

  @override
  String get planCancelled => 'रद्द';

  @override
  String get instUpcoming => 'आने वाली';

  @override
  String get instPaid => 'चुकाई';

  @override
  String get instOverdue => 'बकाया';

  @override
  String get autopayNotSet => 'ऑटोपे बंद है';

  @override
  String get autopayPending => 'चालू हो रहा है';

  @override
  String get autopayActive => 'ऑटोपे चालू है';

  @override
  String get autopayPaused => 'ऑटोपे रुका हुआ है';

  @override
  String get autopayCancelled => 'ऑटोपे रद्द';

  @override
  String get autopayFailed => 'ऑटोपे नाकाम';

  @override
  String get autopayUpi => 'यूपीआई ऑटोपे';

  @override
  String get autopayCard => 'कार्ड स्टैंडिंग इंस्ट्रक्शन';

  @override
  String get autopayBank => 'बैंक मैंडेट (ई-एनएसीएच)';

  @override
  String get providerBajaj => 'बजाज फिनसर्व';

  @override
  String get providerBank => 'आपका बैंक';

  @override
  String get providerShop => 'ब्रांडहूप';

  @override
  String get leadEnquiry => 'पूछताछ';

  @override
  String get leadCallback => 'कॉल बैक';

  @override
  String get leadEmi => 'ईएमआई आवेदन';

  @override
  String get leadExchange => 'एक्सचेंज';

  @override
  String get leadRepair => 'रिपेयर';

  @override
  String get leadReserve => 'रिज़र्व फोन';

  @override
  String get leadVisit => 'दुकान विज़िट';

  @override
  String get leadFresh => 'नया';

  @override
  String get leadContacted => 'बात हुई';

  @override
  String get leadVisited => 'दुकान आया';

  @override
  String get leadConverted => 'खरीदा';

  @override
  String get leadLost => 'छूट गया';

  @override
  String get issueScreen => 'टूटी या खराब स्क्रीन';

  @override
  String get issueBattery => 'बैटरी';

  @override
  String get issueCharging => 'चार्जिंग की समस्या';

  @override
  String get issueWater => 'पानी से खराबी';

  @override
  String get issueSpeaker => 'स्पीकर या माइक';

  @override
  String get issueCamera => 'कैमरा';

  @override
  String get issueSoftware => 'सॉफ्टवेयर, हैंग या वायरस';

  @override
  String get issueOther => 'कुछ और';

  @override
  String get repairBooked => 'बुक हो गया';

  @override
  String get repairReceived => 'दुकान पर मिला';

  @override
  String get repairDiagnosing => 'जाँच हो रही है';

  @override
  String get repairAwaiting => 'आपकी मंज़ूरी का इंतज़ार';

  @override
  String get repairInRepair => 'रिपेयर हो रहा है';

  @override
  String get repairReady => 'लेने के लिए तैयार';

  @override
  String get repairDelivered => 'सौंप दिया';

  @override
  String get repairCancelled => 'रद्द';

  @override
  String get roleCustomer => 'ग्राहक';

  @override
  String get roleStaff => 'काउंटर स्टाफ';

  @override
  String get roleManager => 'मैनेजर';

  @override
  String get roleOwner => 'मालिक';

  @override
  String get dayMon => 'सोमवार';

  @override
  String get dayTue => 'मंगलवार';

  @override
  String get dayWed => 'बुधवार';

  @override
  String get dayThu => 'गुरुवार';

  @override
  String get dayFri => 'शुक्रवार';

  @override
  String get daySat => 'शनिवार';

  @override
  String get daySun => 'रविवार';

  @override
  String get errBadPhone => '10 अंकों का मोबाइल नंबर डालें।';

  @override
  String get errBadOtp => 'यह कोड सही नहीं है। कृपया जाँचकर फिर डालें।';

  @override
  String get errAccountDisabled =>
      'यह खाता बंद कर दिया गया है। कृपया दुकान से संपर्क करें।';

  @override
  String get errBadAddress =>
      'कृपया नाम, फोन और 6 अंकों के पिनकोड के साथ पूरा पता भरें।';

  @override
  String get errEmptyCart => 'आपका कार्ट खाली है।';

  @override
  String get errStockChanged => 'स्टॉक बदल गया है। कृपया अपना कार्ट देखें।';

  @override
  String get errBadCoupon => 'यह कूपन इस ऑर्डर पर नहीं लग सकता।';

  @override
  String get errPayNotAllowed =>
      'इस ऑर्डर के लिए यह पेमेंट तरीका उपलब्ध नहीं है।';

  @override
  String get errNeedInstrument => 'कृपया अपने पेमेंट की जानकारी डालें।';

  @override
  String get errBadEmiScheme => 'इस रकम के लिए यह ईएमआई विकल्प उपलब्ध नहीं है।';

  @override
  String get errNothingToPay => 'इस ऑर्डर पर कोई पेमेंट बाकी नहीं है।';

  @override
  String get errCannotCancel =>
      'अब इसे रद्द नहीं किया जा सकता। कृपया दुकान को कॉल करें।';

  @override
  String get errReturnWindowClosed => '7 दिन की वापसी अवधि खत्म हो गई है।';

  @override
  String get errBadTransition => 'अभी इस ऑर्डर के लिए यह कदम संभव नहीं है।';

  @override
  String get errBadImei => 'यह आईएमईआई सही नहीं है। यह 15 अंकों का होना चाहिए।';

  @override
  String get errDupImei => 'एक ही आईएमईआई दो बार डाला गया है।';

  @override
  String get errImeiRequired => 'फोन देने से पहले हर फोन का आईएमईआई डालें।';

  @override
  String get errEmiNotApproved => 'ईएमआई अभी मंज़ूर नहीं हुई है। फोन न दें।';

  @override
  String get errBalanceDue => 'इस ऑर्डर पर अभी पैसे लेने बाकी हैं।';

  @override
  String get errBadAmount => 'यह रकम सही नहीं है।';

  @override
  String get errDiscountTooHigh =>
      'काउंटर स्टाफ ज़्यादा से ज़्यादा 5% छूट दे सकता है। मैनेजर से कहें।';

  @override
  String get errPlanNotLive => 'ईएमआई मंज़ूर होने के बाद ही ऑटोपे लग सकता है।';

  @override
  String get errMandateFailed =>
      'ऑटोपे चालू नहीं हो सका। जानकारी जाँचकर फिर कोशिश करें।';

  @override
  String get errRefundFailed => 'रिफंड नहीं भेजा जा सका। फिर कोशिश करें।';

  @override
  String get errQuoteRequired => 'पहले रिपेयर की कीमत डालें।';

  @override
  String get errNeedVariant => 'कीमत के साथ कम से कम एक वेरिएंट जोड़ें।';

  @override
  String get errBadPrice =>
      'कीमतें जाँचें: एमआरपी बिक्री मूल्य से कम नहीं हो सकती।';

  @override
  String get errLastOwner => 'कम से कम एक सक्रिय मालिक होना ज़रूरी है।';

  @override
  String get errBadRole => 'यह भूमिका नहीं दी जा सकती।';

  @override
  String get errNoPermission => 'आपकी भूमिका को इसकी अनुमति नहीं है।';

  @override
  String get errGatewayDeclined =>
      'पेमेंट अस्वीकृत हुआ। दूसरा कार्ड, यूपीआई आईडी या बैंक आज़माएं।';

  @override
  String get errGatewayInvalid =>
      'पेमेंट की जानकारी सही नहीं लगती। कृपया जाँचें।';

  @override
  String get errGatewayCancelled => 'पेमेंट रद्द हो गया।';

  @override
  String get errGatewayTimeout =>
      'पेमेंट का समय खत्म हो गया। दो बार पैसे नहीं कटे; अपने ऑर्डर देखें।';

  @override
  String get payChoiceUpi => 'यूपीआई (GPay, PhonePe, Paytm)';

  @override
  String get payChoiceUpiHint => 'तुरंत। किसी भी यूपीआई ऐप से भुगतान करें।';

  @override
  String get payChoiceCard => 'क्रेडिट या डेबिट कार्ड';

  @override
  String get payChoiceCardHint => 'वीज़ा, मास्टरकार्ड, रुपे।';

  @override
  String get payChoiceNetbankingHint => 'अपने बैंक खाते से भुगतान करें।';

  @override
  String get payChoiceCod => 'डिलीवरी पर नकद';

  @override
  String get payChoiceCodHint =>
      'दरवाज़े पर पहुंचने पर नकद दें। शहर में उपलब्ध।';

  @override
  String get payChoiceCashStore => 'दुकान पर नकद दें';

  @override
  String get payChoiceCashStoreHint => 'हम तैयार रखेंगे। लेते समय भुगतान करें।';

  @override
  String get payChoiceReserve => 'अभी रिज़र्व करें, दुकान पर पूरा दें';

  @override
  String payChoiceReserveHint(String token) {
    return 'फोन आपके लिए रोकने को अभी $token दें। बाकी दुकान पर आकर दें।';
  }

  @override
  String get payChoiceBajajHint =>
      'अभी डाउन पेमेंट, आसान मासिक किस्तें। दुकान पर जल्दी मंज़ूरी।';

  @override
  String get payChoiceCardEmiHint =>
      'बिल को अपने क्रेडिट या डेबिट कार्ड पर ईएमआई में बदलें।';

  @override
  String get openAdmin => 'एडमिन पैनल खोलें';

  @override
  String get openAdminHint => 'ऑर्डर, स्टॉक, बिलिंग, ईएमआई और रिपोर्ट';

  @override
  String get viewAsCustomer => 'ग्राहक की तरह देखें';

  @override
  String get visitStore => 'हमारी दुकान पर आएं';

  @override
  String get visitUsAnytime => 'दुकान खुली हो तब कभी भी आएं';

  @override
  String get searchHint => 'फोन, चार्जर, कवर खोजें…';

  @override
  String get shopByCategory => 'श्रेणी से खरीदें';

  @override
  String get shopByBudget => 'बजट से खरीदें';

  @override
  String get budgetUnder10 => '₹10,000 से कम';

  @override
  String get budget10to15 => '₹10,000 - ₹15,000';

  @override
  String get budget15to20 => '₹15,000 - ₹20,000';

  @override
  String get budgetAbove20 => '₹20,000 से ऊपर';

  @override
  String get zeroEmiPhones => '0% ईएमआई वाले फोन';

  @override
  String get ourServices => 'हमारी सेवाएं';

  @override
  String get serviceRepair => 'फोन रिपेयर';

  @override
  String get serviceExchange => 'पुराना फोन एक्सचेंज';

  @override
  String get serviceEmiCalc => 'ईएमआई कैलकुलेटर';

  @override
  String get accessoryPicks => 'लोकप्रिय एक्सेसरीज़';

  @override
  String get whyBrandhoop => 'ब्रांडहूप से क्यों खरीदें';

  @override
  String get whyGenuineTitle => 'असली प्रोडक्ट, जीएसटी बिल के साथ';

  @override
  String get whyGenuineBody =>
      'हर फोन सील्ड और ब्रांड वारंटी के साथ। कोई पुराना माल नहीं।';

  @override
  String get whyLocalTitle => 'ऐसी दुकान जहां आप जा सकते हैं';

  @override
  String get whyLocalBody =>
      'घर से ऑर्डर करें, फिर दुकान पर आकर लें या कुछ भी पूछें, जब दुकान खुली हो।';

  @override
  String get whyPayTitle => 'अपने तरीके से भुगतान करें';

  @override
  String get whyPayBody =>
      'नकद, यूपीआई, कार्ड, बजाज फिनसर्व ईएमआई और ऑटोपे, सब एक जगह।';

  @override
  String get whySupportTitle => 'खरीदने के बाद भी लोकल सपोर्ट';

  @override
  String get whySupportBody =>
      'सेटअप, डेटा ट्रांसफर, रिपेयर और वारंटी में मदद, उन्हीं से जिनसे आपने खरीदा।';

  @override
  String get trustGenuine => 'असली';

  @override
  String get trustGstBill => 'जीएसटी बिल';

  @override
  String get trustLocal => 'लोकल दुकान';

  @override
  String get trustService => 'रिपेयर और सर्विस';

  @override
  String get whyBuyFromUs => 'हमसे क्यों खरीदें';

  @override
  String get storeOpenNow => 'अभी खुला है';

  @override
  String get storeClosedNow => 'अभी बंद है';

  @override
  String storeClosesAt(String time) {
    return '$time बंद होगा';
  }

  @override
  String storeOpensAt(String time) {
    return '$time खुलेगा';
  }

  @override
  String storeOpensDay(String day, String time) {
    return '$day को $time खुलेगा';
  }

  @override
  String resultsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n प्रोडक्ट',
      one: '1 प्रोडक्ट',
    );
    return '$_temp0';
  }

  @override
  String get filters => 'फ़िल्टर';

  @override
  String get sortBy => 'क्रम';

  @override
  String get sortPopular => 'लोकप्रिय';

  @override
  String get sortPriceLow => 'कीमत: कम से ज़्यादा';

  @override
  String get sortPriceHigh => 'कीमत: ज़्यादा से कम';

  @override
  String get sortDiscount => 'सबसे ज़्यादा छूट';

  @override
  String get noResultsHint => 'कोई दूसरा शब्द आज़माएं या फ़िल्टर हटाएं।';

  @override
  String get clearFilters => 'फ़िल्टर हटाएं';

  @override
  String get priceRange => 'कीमत';

  @override
  String priceBelow(String price) {
    return '$price से कम';
  }

  @override
  String priceAbove(String price) {
    return '$price से ऊपर';
  }

  @override
  String get brand => 'ब्रांड';

  @override
  String get zeroEmiOnly => 'सिर्फ़ 0% ईएमआई';

  @override
  String get inStockOnly => 'सिर्फ़ स्टॉक में';

  @override
  String get off => 'छूट';

  @override
  String get outOfStock => 'स्टॉक में नहीं';

  @override
  String emiFrom(String amount) {
    return 'ईएमआई $amount/माह से';
  }

  @override
  String emiFromZero(String amount) {
    return '0% ईएमआई $amount/माह से';
  }

  @override
  String get productNotFound => 'यह प्रोडक्ट उपलब्ध नहीं है';

  @override
  String get wishlist => 'विशलिस्ट';

  @override
  String shareProductText(String shop, String product, String price) {
    return '$shop पर देखें: $product, सिर्फ़ $price में।';
  }

  @override
  String get sampleListing => 'नमूना लिस्टिंग';

  @override
  String get chooseVariant => 'वेरिएंट चुनें';

  @override
  String onlyFewLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'सिर्फ़ $n बचे हैं',
      one: 'सिर्फ़ 1 बचा है',
    );
    return '$_temp0';
  }

  @override
  String get inStockAtStore => 'दुकान पर स्टॉक में है';

  @override
  String inStockCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n स्टॉक में',
      one: '1 स्टॉक में',
      zero: 'स्टॉक खत्म',
    );
    return '$_temp0';
  }

  @override
  String get emiPartners =>
      'बजाज फिनसर्व और कार्ड ईएमआई के साथ। प्लान देखने के लिए टैप करें।';

  @override
  String reserveTitle(String token) {
    return 'यह फोन $token में रिज़र्व करें';
  }

  @override
  String reserveBody(String hours) {
    return 'हम इसे आपके लिए $hours तक रोककर रखेंगे। बाकी रकम दुकान पर आकर दें।';
  }

  @override
  String get reserveCta => 'अभी रिज़र्व करें';

  @override
  String get deliveryTitle => 'डिलीवरी और पिकअप';

  @override
  String deliveryLocal(String city) {
    return '$city और आसपास के इलाकों में उसी दिन घर पर डिलीवरी।';
  }

  @override
  String get pickupAnytime => 'या दुकान खुली हो तब कभी भी आकर ले जाएं।';

  @override
  String get enterPincode => 'अपना पिनकोड डालें';

  @override
  String get check => 'जाँचें';

  @override
  String get deliverySameDay => 'इस पिनकोड पर उसी दिन डिलीवरी।';

  @override
  String deliveryCourier(String fee, String free) {
    return 'कूरियर डिलीवरी: $fee, $free से ऊपर मुफ़्त।';
  }

  @override
  String get completeYourPhone => 'अपना फोन पूरा करें';

  @override
  String get aboutProduct => 'इस प्रोडक्ट के बारे में';

  @override
  String get specifications => 'खूबियां';

  @override
  String get warranty => 'वारंटी';

  @override
  String warrantyMonths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n महीने',
      one: '1 महीना',
    );
    return '$_temp0';
  }

  @override
  String get similarProducts => 'मिलते-जुलते प्रोडक्ट';

  @override
  String get errBadPincode => 'सही 6 अंकों का पिनकोड डालें।';

  @override
  String get addToCart => 'कार्ट में डालें';

  @override
  String get addedToCart => 'कार्ट में डाल दिया';

  @override
  String get buyNow => 'अभी खरीदें';

  @override
  String get notifyMe => 'हमसे पूछें';

  @override
  String get askAboutThis => 'इसके बारे में पूछें';

  @override
  String enquiryText(String product, String variant, String price) {
    return 'नमस्ते! मुझे $product ($variant) चाहिए, $price में। क्या उपलब्ध है?';
  }

  @override
  String get weWillCallYou => 'धन्यवाद। हम जल्दी ही आपको कॉल करेंगे।';

  @override
  String get yourDetails => 'आपकी जानकारी';

  @override
  String get yourName => 'आपका नाम';

  @override
  String get mobileNumber => 'मोबाइल नंबर';

  @override
  String get send => 'भेजें';

  @override
  String get cartTitle => 'आपका कार्ट';

  @override
  String get cartEmpty => 'आपका कार्ट खाली है';

  @override
  String get cartEmptyHint => 'कोई फोन या एक्सेसरी जोड़ें, वह यहां दिखेगी।';

  @override
  String get startShopping => 'खरीदारी शुरू करें';

  @override
  String get subtotal => 'उप-योग';

  @override
  String get proceedToCheckout => 'चेकआउट करें';

  @override
  String get youSave => 'आपकी बचत';

  @override
  String get deliveryCalculatedAtCheckout =>
      'डिलीवरी और ऑफ़र चेकआउट पर जुड़ेंगे।';

  @override
  String get itemNoLongerAvailable => 'यह आइटम अब उपलब्ध नहीं है';

  @override
  String get viewCart => 'कार्ट देखें';

  @override
  String get openingHours => 'खुलने का समय';

  @override
  String get closed => 'बंद';

  @override
  String get planYourVisit => 'अपनी विज़िट तय करें';

  @override
  String get planYourVisitBody =>
      'बताइए कब आ रहे हैं, हम आपका फोन, बिल और ईएमआई के कागज़ तैयार रखेंगे।';

  @override
  String get today => 'आज';

  @override
  String get tomorrow => 'कल';

  @override
  String get closedThatDay => 'उस दिन दुकान बंद है। कोई और दिन चुनें।';

  @override
  String get tellShopIAmComing => 'दुकान को बताएं कि मैं आ रहा हूं';

  @override
  String get visitNoted => 'नोट कर लिया। तब मिलते हैं।';

  @override
  String get inTheShop => 'दुकान पर';

  @override
  String get shopLine1 => 'हर बड़े ब्रांड के नए फोन';

  @override
  String get shopLine2 => 'काउंटर पर नकद, यूपीआई, कार्ड और बजाज फिनसर्व ईएमआई';

  @override
  String get shopLine3 => 'पुराना फोन मौके पर एक्सचेंज करें';

  @override
  String get shopLine4 => 'स्क्रीन, बैटरी और चार्जिंग रिपेयर';

  @override
  String get shopLine5 => 'सिम, रिचार्ज और मुफ़्त सेटअप मदद';

  @override
  String get signInTitle => 'ब्रांडहूप में साइन इन करें';

  @override
  String get signInBody => 'अपना मोबाइल नंबर डालें। हम 6 अंकों का कोड भेजेंगे।';

  @override
  String get sendCode => 'कोड भेजें';

  @override
  String get enterCode => 'कोड डालें';

  @override
  String codeSentTo(String phone) {
    return 'कोड +91 $phone पर भेजा गया';
  }

  @override
  String get sixDigitCode => '6 अंकों का कोड';

  @override
  String demoCodeHint(String code) {
    return 'डेमो मोड: कोड $code है';
  }

  @override
  String get referralCode => 'रेफ़रल कोड';

  @override
  String get verifyAndContinue => 'जाँचें और आगे बढ़ें';

  @override
  String get changeNumber => 'नंबर बदलें';

  @override
  String get tryAs => 'डेमो: ऐप को इस रूप में आज़माएं';

  @override
  String demoAccountsHint(String owner, String customer) {
    return 'या मालिक $owner अथवा ग्राहक $customer से साइन इन करें, कोड 123456।';
  }

  @override
  String get checkoutTitle => 'चेकआउट';

  @override
  String get orderTotal => 'ऑर्डर का कुल';

  @override
  String get howToReceive => 'आप इसे कैसे लेना चाहेंगे?';

  @override
  String get addAddress => 'पता जोड़ें';

  @override
  String get offersAndCoins => 'ऑफ़र और कॉइन';

  @override
  String get payWith => 'भुगतान का तरीका';

  @override
  String get orderSummary => 'ऑर्डर का सार';

  @override
  String get couponCode => 'कूपन कोड';

  @override
  String get coupon => 'कूपन';

  @override
  String get couponNotFound => 'यह कूपन कोड मौजूद नहीं है।';

  @override
  String get couponNotActive => 'यह कूपन खत्म हो चुका है या बंद है।';

  @override
  String get couponMinOrder =>
      'यह कूपन लगाने के लिए कार्ट में और सामान जोड़ें।';

  @override
  String get couponNotApplicable => 'यह कूपन आपके कार्ट के सामान पर नहीं लगता।';

  @override
  String couponApplied(String code, String amount) {
    return '$code लग गया: आपकी बचत $amount';
  }

  @override
  String get coinsUsed => 'ब्रांडहूप कॉइन';

  @override
  String useCoins(int coins) {
    String _temp0 = intl.Intl.pluralLogic(
      coins,
      locale: localeName,
      other: 'मेरे $coins ब्रांडहूप कॉइन इस्तेमाल करें',
      one: 'मेरा 1 ब्रांडहूप कॉइन इस्तेमाल करें',
    );
    return '$_temp0';
  }

  @override
  String get coinsRule =>
      'एक कॉइन यानी एक रुपया छूट, सिर्फ़ एक्सेसरीज़ पर और बिल के एक हिस्से तक।';

  @override
  String reserveExplain(String token, String hours, String rest) {
    return 'अभी $token दें। हम फोन $hours तक रोकेंगे। बाकी $rest दुकान पर आकर दें।';
  }

  @override
  String get chooseTenure => 'कितने महीने चुनें';

  @override
  String get zeroInterest => '0% ब्याज';

  @override
  String get downPayment => 'डाउन पेमेंट';

  @override
  String downPaymentMin(String amount) {
    return 'न्यूनतम डाउन पेमेंट: $amount';
  }

  @override
  String downPaymentFrom(String amount) {
    return 'डाउन पेमेंट $amount से';
  }

  @override
  String get amountFinanced => 'फाइनेंस की रकम';

  @override
  String get interestRate => 'ब्याज दर';

  @override
  String get perYear => 'सालाना';

  @override
  String get totalInterest => 'कुल ब्याज';

  @override
  String get processingFeeLabel => 'प्रोसेसिंग फीस';

  @override
  String processingFee(String fee) {
    return 'प्रोसेसिंग फीस $fee';
  }

  @override
  String get totalYouPay => 'आप कुल देंगे';

  @override
  String totalPayable(String amount) {
    return 'कुल $amount';
  }

  @override
  String get noExtraCost => 'कोई अतिरिक्त खर्च नहीं';

  @override
  String get emiIndicative =>
      'ये आंकड़े अनुमानित हैं। अंतिम रकम, दर और मंज़ूरी ऋणदाता तय करता है।';

  @override
  String get emiRatesUnconfirmed =>
      'दुकान अभी अपनी ईएमआई दरें पक्की कर रही है, इसलिए इन्हें अनुमान मानें।';

  @override
  String get noEmiForThis => 'इस रकम या प्रोडक्ट पर ईएमआई उपलब्ध नहीं है।';

  @override
  String get emiOptions => 'ईएमआई विकल्प';

  @override
  String get openCalculator => 'ईएमआई कैलकुलेटर खोलें';

  @override
  String payDownHow(String amount) {
    return 'अभी $amount दें';
  }

  @override
  String get payOnlineNow => 'अभी ऑनलाइन दें';

  @override
  String get payAtStoreLater => 'दुकान पर दें';

  @override
  String get whatHappensNext => 'आगे क्या होगा';

  @override
  String get bajajStep1 => 'आप यह आवेदन भेजते हैं और डाउन पेमेंट देते हैं।';

  @override
  String get bajajStep2 =>
      'अपने आधार, पैन और बैंक की जानकारी के साथ दुकान आएं। हम आपके साथ बजाज फिनसर्व की जाँच पूरी करेंगे।';

  @override
  String get bajajStep3 =>
      'बजाज फिनसर्व की मंज़ूरी मिलते ही फोन बिल और आईएमईआई के साथ आपको सौंप दिया जाता है।';

  @override
  String get bajajStep4 =>
      'आप हर महीने ईएमआई चुकाते हैं। तारीख न चूकें, इसलिए इस ऐप में ऑटोपे चालू करें।';

  @override
  String applyAndPay(String amount) {
    return 'आवेदन करें और $amount दें';
  }

  @override
  String get applyForEmi => 'ईएमआई के लिए आवेदन करें';

  @override
  String get placeOrder => 'ऑर्डर करें';

  @override
  String payAmount(String amount) {
    return '$amount दें';
  }

  @override
  String reserveFor(String amount) {
    return '$amount देकर रिज़र्व करें';
  }

  @override
  String get deliveryFee => 'डिलीवरी';

  @override
  String totalSavings(String amount) {
    return 'इस ऑर्डर पर आपकी बचत $amount';
  }

  @override
  String get orEnterUpiId => 'या यूपीआई आईडी डालें';

  @override
  String get errBadUpi => 'यह यूपीआई आईडी सही नहीं लगती।';

  @override
  String get cardNumber => 'कार्ड नंबर';

  @override
  String get errBadCard => 'यह कार्ड नंबर सही नहीं है।';

  @override
  String get cardExpiry => 'समाप्ति';

  @override
  String get errBadExpiry => 'यह समाप्ति तिथि सही नहीं है।';

  @override
  String get nameOnCard => 'कार्ड पर नाम';

  @override
  String get testPaymentHint =>
      'टेस्ट मोड: कोई असली पैसा नहीं जाता। कार्ड 4111 1111 1111 1111, कोई आगे की तारीख और CVV डालें। यूपीआई आईडी fail@upi से फेल पेमेंट दिखेगा।';

  @override
  String get activeOrders => 'चालू';

  @override
  String get pastOrders => 'पुराने';

  @override
  String get signInToSeeOrders => 'अपने ऑर्डर देखने के लिए साइन इन करें';

  @override
  String get signInToSeeOrdersHint =>
      'आपके ऑर्डर, बिल और वारंटी आपके मोबाइल नंबर से जुड़े रहते हैं।';

  @override
  String get noOrdersYet => 'अभी कोई ऑर्डर नहीं';

  @override
  String get noOrdersYetHint =>
      'खरीदने पर आपका ऑर्डर और उसकी ट्रैकिंग यहां दिखेगी।';

  @override
  String get paymentNotDone => 'पेमेंट पूरा नहीं हुआ';

  @override
  String get paymentNotDoneHint =>
      'आपका ऑर्डर सेव है। पक्का करने के लिए अभी पेमेंट करें, वरना 30 मिनट में यह छूट जाएगा।';

  @override
  String get orderPlacedTitle => 'ऑर्डर हो गया';

  @override
  String orderNumberIs(String number) {
    return 'आपका ऑर्डर नंबर $number है';
  }

  @override
  String get showThisCode => 'दुकान पर यह कोड दिखाएं';

  @override
  String nextCod(String amount) {
    return '$amount नकद तैयार रखें। डिलीवरी से पहले हमारी टीम कॉल करेगी।';
  }

  @override
  String nextCashStore(String amount) {
    return 'हम इसे तैयार रख रहे हैं। लेते समय $amount नकद दें।';
  }

  @override
  String nextReserve(String balance, String until) {
    return 'आपका फोन आपके लिए रुका है। $until से पहले आकर बाकी $balance दें।';
  }

  @override
  String get nextBajaj =>
      'बजाज फिनसर्व का आवेदन पूरा करने के लिए आधार, पैन और बैंक की जानकारी लेकर दुकान आएं। पक्का करने के लिए हम कॉल करेंगे।';

  @override
  String get nextPickup =>
      'तैयार होते ही हम आपको बताएंगे। काउंटर पर नीचे का कोड दिखाएं।';

  @override
  String get nextDelivery =>
      'हम इसे तैयार कर रहे हैं। हर कदम आप यहां देख सकते हैं।';

  @override
  String get viewOrder => 'ऑर्डर देखें';

  @override
  String get continueShopping => 'खरीदारी जारी रखें';

  @override
  String get tryAnotherWay => 'अभी पेमेंट करें';

  @override
  String get orderNotFound => 'ऑर्डर नहीं मिला';

  @override
  String get shareInvoice => 'बिल शेयर करें';

  @override
  String get pickupCode => 'पिकअप कोड';

  @override
  String reservedUntil(String when) {
    return '$when तक आपके लिए रुका है';
  }

  @override
  String get trackOrder => 'ऑर्डर ट्रैक करें';

  @override
  String get itemsHeader => 'सामान';

  @override
  String get paymentHeader => 'भुगतान';

  @override
  String get paymentMode => 'भुगतान का तरीका';

  @override
  String get balanceDue => 'बाकी रकम';

  @override
  String balanceToPay(String amount) {
    return 'देना बाकी: $amount';
  }

  @override
  String get reserveTokenLabel => 'रिज़र्व टोकन';

  @override
  String get viewEmiPlan => 'ईएमआई प्लान देखें';

  @override
  String get pickupHeader => 'दुकान से लें';

  @override
  String get deliveryHeader => 'डिलीवरी का पता';

  @override
  String get cancelOrder => 'ऑर्डर रद्द करें';

  @override
  String get cancelOrderQ => 'यह ऑर्डर रद्द करें?';

  @override
  String get reasonOptional => 'कारण (वैकल्पिक)';

  @override
  String get orderCancelled =>
      'ऑर्डर रद्द हो गया। आपने जो पेमेंट किया है, वह वापस होगा।';

  @override
  String get returnItems => 'वापस करें';

  @override
  String get returnOrderQ => 'वापसी का अनुरोध करें?';

  @override
  String get returnRequestedMsg =>
      'वापसी का अनुरोध भेज दिया। हम आपको कॉल करेंगे।';

  @override
  String get orderAgain => 'फिर से मंगाएं';

  @override
  String get needHelp => 'मदद चाहिए?';

  @override
  String warrantyUntil(String date) {
    return 'वारंटी $date तक';
  }

  @override
  String get invoiceOrder => 'ऑर्डर';

  @override
  String get invoiceDate => 'तारीख';

  @override
  String get invoiceCustomer => 'ग्राहक';

  @override
  String get invoiceItems => 'सामान';

  @override
  String invoiceThanks(String shop) {
    return '$shop से खरीदारी के लिए धन्यवाद।';
  }

  @override
  String get emiAndAutopay => 'ईएमआई और ऑटोपे';

  @override
  String get emiSignInTitle => 'अपनी ईएमआई देखने के लिए साइन इन करें';

  @override
  String get emiSignInBody =>
      'आपके प्लान, तारीखें और ऑटोपे सेटिंग आपके मोबाइल नंबर से जुड़ी रहती हैं।';

  @override
  String get noEmiPlans => 'अभी कोई ईएमआई प्लान नहीं';

  @override
  String get noEmiPlansBody =>
      '0% या आसान ईएमआई पर फोन खरीदें, प्लान, तारीखें और ऑटोपे यहां दिखेंगे।';

  @override
  String get browseEmiPhones => 'ईएमआई वाले फोन देखें';

  @override
  String get yourEmiPlans => 'आपके ईएमआई प्लान';

  @override
  String get emiHowItWorks => 'ब्रांडहूप पर ईएमआई कैसे काम करती है';

  @override
  String get emiPointBajaj =>
      'बजाज फिनसर्व ईएमआई: थोड़ा डाउन पेमेंट, फिर आसान मासिक किस्तें। मंज़ूरी बजाज फिनसर्व देता है।';

  @override
  String get emiPointCard =>
      'कार्ड ईएमआई: अगर आपका बैंक देता है तो बिल को क्रेडिट या डेबिट कार्ड पर किस्तों में बदलें।';

  @override
  String get emiPointAutopay =>
      'ऑटोपे: हर किस्त उसकी तारीख पर कटती है। कभी भी रोकें या रद्द करें।';

  @override
  String get emiPointDocs =>
      'बजाज फिनसर्व की जाँच के लिए आधार, पैन और बैंक की जानकारी साथ रखें।';

  @override
  String get nextEmiDue => 'अगली ईएमआई';

  @override
  String get emiOverdue => 'ईएमआई बकाया है';

  @override
  String inDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन में',
      one: 'कल',
      zero: 'आज',
    );
    return '$_temp0';
  }

  @override
  String paidOf(int paid, int total) {
    return '$total में से $paid चुकाई';
  }

  @override
  String nextOn(String date) {
    return 'अगली: $date';
  }

  @override
  String get emiPlan => 'ईएमआई प्लान';

  @override
  String get planNotFound => 'प्लान नहीं मिला';

  @override
  String get itemPrice => 'सामान की कीमत';

  @override
  String get tenure => 'अवधि';

  @override
  String get monthlyEmi => 'मासिक ईएमआई';

  @override
  String get lenderRef => 'लोन रेफ़रेंस';

  @override
  String get planAppliedHint =>
      'आपका आवेदन दुकान और ऋणदाता के पास है। दुकान पर पूरा करने के लिए हम आपको कॉल करेंगे।';

  @override
  String get planRejectedHint =>
      'यह आवेदन मंज़ूर नहीं हुआ। आप दूसरे तरीके से भुगतान करके फोन खरीद सकते हैं। कृपया दुकान से बात करें।';

  @override
  String get instalmentSchedule => 'किस्तों का कार्यक्रम';

  @override
  String paidOn(String date) {
    return '$date को चुकाई';
  }

  @override
  String get openBajajApp => 'बजाज फिनसर्व पर चुकाएं या देखें';

  @override
  String get bankAutoDebit =>
      'आपका बैंक यह ईएमआई हर महीने आपके कार्ड से काटता है। पर्याप्त लिमिट रखें।';

  @override
  String get autopaySettings => 'ऑटोपे सेटिंग';

  @override
  String get autopayOnBody =>
      'हर किस्त उसकी तारीख पर आपकी सीमा तक कटती है। हर कटौती से पहले हम याद दिलाते हैं।';

  @override
  String get autopayOffBody =>
      'ऑटोपे चालू करें ताकि कोई किस्त न छूटे। नियंत्रण आपके पास रहता है, कभी भी रोक सकते हैं।';

  @override
  String get autopayMethodLabel => 'तरीका';

  @override
  String get autopayAccount => 'खाता';

  @override
  String get autopayLimit => 'कटौती की सीमा';

  @override
  String get nextDebit => 'अगली कटौती';

  @override
  String get remindMe => 'मुझे याद दिलाएं';

  @override
  String daysBefore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n दिन पहले',
      one: '1 दिन पहले',
      zero: 'उसी दिन',
    );
    return '$_temp0';
  }

  @override
  String get pauseAutopay => 'ऑटोपे रोकें';

  @override
  String get cancelAutopay => 'ऑटोपे रद्द करें';

  @override
  String get cancelAutopayQ => 'ऑटोपे रद्द करें?';

  @override
  String get cancelAutopayBody =>
      'आगे की किस्तें अपने आप नहीं कटेंगी। आपको उन्हें खुद तारीख से पहले चुकाना होगा।';

  @override
  String get resumeAutopay => 'ऑटोपे फिर चालू करें';

  @override
  String get turnOnAutopay => 'ऑटोपे चालू करें';

  @override
  String get setupAutopayAgain => 'ऑटोपे फिर से लगाएं';

  @override
  String get autopayLenderNote =>
      'बजाज फिनसर्व प्लान में अंतिम कटौती ऋणदाता करता है। यह स्क्रीन उसकी स्थिति और आपका रिमाइंडर दिखाती है।';

  @override
  String autopaySheetBody(String emi) {
    return 'चुनें कि आपकी $emi की किस्त हर महीने कैसे चुकाई जाए।';
  }

  @override
  String autopayConsent(String limit) {
    return 'मैं हर किस्त की तारीख पर $limit तक की स्वचालित कटौती की अनुमति देता/देती हूं। मैं इसे कभी भी रोक या रद्द कर सकता/सकती हूं।';
  }

  @override
  String get authoriseAutopay => 'ऑटोपे की अनुमति दें';

  @override
  String get phonePrice => 'फोन की कीमत';

  @override
  String get emiScheme => 'ईएमआई स्कीम';

  @override
  String priceOutsideScheme(String min) {
    return 'यह स्कीम $min से शुरू होती है। दूसरी स्कीम या ज़्यादा कीमत चुनें।';
  }

  @override
  String get exchangeIntro =>
      'अपने पुराने फोन के बारे में बताएं और अनुमानित कीमत देखें। थोड़ी जाँच के बाद दुकान अंतिम कीमत बताएगी।';

  @override
  String get model => 'मॉडल';

  @override
  String get priceWhenNew => 'नए की कीमत (लगभग)';

  @override
  String get howOld => 'कितना पुराना है?';

  @override
  String get ageUnder6 => '6 महीने से कम';

  @override
  String get age6to12 => '6 से 12 महीने';

  @override
  String get age1to2 => '1 से 2 साल';

  @override
  String get age2to3 => '2 से 3 साल';

  @override
  String get ageOver3 => '3 साल से ज़्यादा';

  @override
  String get screenCondition => 'स्क्रीन की हालत';

  @override
  String get screenPerfect => 'एकदम सही';

  @override
  String get screenScratches => 'हल्के स्क्रैच';

  @override
  String get screenCracked => 'टूटी हुई';

  @override
  String get bodyDents => 'बॉडी पर डेंट या नुकसान';

  @override
  String get batteryWeak => 'बैटरी जल्दी उतरती है';

  @override
  String get allWorking => 'सब कुछ चलता है (कैमरा, स्पीकर, टच, बटन)';

  @override
  String get haveBill => 'मेरे पास बिल और डिब्बा है';

  @override
  String get estimatedValue => 'अनुमानित कीमत';

  @override
  String get exchangeIndicative =>
      'यह सिर्फ़ अंदाज़ा है। दुकान आपका फोन जाँचने के बाद अंतिम कीमत तय करेगी, जो ज़्यादा या कम हो सकती है।';

  @override
  String get sendToShop => 'दुकान को भेजें';

  @override
  String get exchangeEnterPrice =>
      'फोन की नए की लगभग कीमत डालें, तब उसकी कीमत दिखेगी।';

  @override
  String get exchangeSent => 'भेज दिया। अगले कदम के लिए हम आपको कॉल करेंगे।';

  @override
  String get repairIntro =>
      'घर बैठे रिपेयर बुक करें। फोन दुकान पर लाएं या हमसे मंगवाएं, और हर कदम यहां देखें।';

  @override
  String get whatIsWrong => 'क्या खराबी है?';

  @override
  String fromPrice(String price) {
    return '$price से';
  }

  @override
  String get describeProblem => 'समस्या बताएं (वैकल्पिक)';

  @override
  String get repairHowItWorks =>
      'दिखाई गई कीमत शुरुआती अनुमान है। हम फोन जाँचकर सही कीमत बताते हैं और आपकी सहमति के बाद ही रिपेयर करते हैं।';

  @override
  String get bookRepair => 'रिपेयर बुक करें';

  @override
  String get myRepairs => 'मेरे रिपेयर';

  @override
  String get enterBrandModel => 'कृपया फोन का ब्रांड और मॉडल डालें।';

  @override
  String repairBookedMsg(String number) {
    return 'रिपेयर बुक हुआ: $number';
  }

  @override
  String get estimatedPrice => 'अनुमानित कीमत';

  @override
  String get quotedPrice => 'अंतिम कीमत';

  @override
  String repairApprovePrompt(String price) {
    return 'दुकान ने आपका फोन जाँच लिया है। रिपेयर की कीमत $price होगी। शुरू करने के लिए मंज़ूरी दें।';
  }

  @override
  String get approveAndRepair => 'मंज़ूर करें और रिपेयर करें';

  @override
  String get progress => 'प्रगति';

  @override
  String get cancelRepairQ => 'यह रिपेयर रद्द करें?';

  @override
  String get welcomeGuest => 'ब्रांडहूप में आपका स्वागत है';

  @override
  String coinsBalance(int coins) {
    String _temp0 = intl.Intl.pluralLogic(
      coins,
      locale: localeName,
      other: '$coins कॉइन',
      one: '1 कॉइन',
    );
    return '$_temp0';
  }

  @override
  String get myAccount => 'मेरा खाता';

  @override
  String get myProfile => 'मेरी प्रोफ़ाइल';

  @override
  String get myAddresses => 'मेरे पते';

  @override
  String get referAndEarn => 'रेफ़र करें और कमाएं';

  @override
  String referShareText(String shop, String code, String bonus) {
    return '$shop से फोन और एक्सेसरीज़ ब्रांडहूप ऐप पर खरीदें। मेरा कोड $code इस्तेमाल करें, आपकी पहली खरीद के बाद हम दोनों को $bonus के कॉइन मिलेंगे।';
  }

  @override
  String get settingsHeader => 'सेटिंग';

  @override
  String get languageLabel => 'भाषा';

  @override
  String get themeLabel => 'थीम';

  @override
  String get themeSystem => 'फोन की सेटिंग';

  @override
  String get themeLight => 'हल्का';

  @override
  String get themeDark => 'गहरा';

  @override
  String get helpHeader => 'मदद';

  @override
  String get helpAndFaq => 'मदद और सवाल-जवाब';

  @override
  String get signOutQ => 'साइन आउट करें?';

  @override
  String get phoneCannotChange =>
      'आपका मोबाइल नंबर ही आपका खाता है और यहां बदला नहीं जा सकता।';

  @override
  String get myReferralCode => 'मेरा रेफ़रल कोड';

  @override
  String get noAddresses => 'कोई पता सेव नहीं है';

  @override
  String get noAddressesHint => 'घर पर डिलीवरी के लिए पता जोड़ें।';

  @override
  String get deleteAddressQ => 'यह पता हटाएं?';

  @override
  String get editAddress => 'पता बदलें';

  @override
  String get addrHome => 'घर';

  @override
  String get addrShop => 'दुकान';

  @override
  String get addrWork => 'ऑफ़िस';

  @override
  String get addrOther => 'अन्य';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get houseNoStreet => 'मकान नंबर और गली';

  @override
  String get colonyOrVillage => 'कॉलोनी, मोहल्ला या गांव';

  @override
  String get landmark => 'लैंडमार्क';

  @override
  String get cityTown => 'शहर या कस्बा';

  @override
  String get pincode => 'पिनकोड';

  @override
  String get stateLabel => 'राज्य';

  @override
  String get wishlistEmpty => 'आपकी विशलिस्ट खाली है';

  @override
  String get wishlistEmptyHint =>
      'किसी भी प्रोडक्ट पर दिल दबाकर उसे बाद के लिए सेव करें।';

  @override
  String get helpBody =>
      'सबसे तेज़ मदद दुकान पर मिलती है। आप कॉल या मैसेज भी कर सकते हैं।';

  @override
  String get faq1q => 'मैं भुगतान कैसे कर सकता/सकती हूं?';

  @override
  String get faq1a =>
      'यूपीआई, क्रेडिट या डेबिट कार्ड, नेट बैंकिंग या नकद (दुकान पर, या शहर में डिलीवरी पर) से। आप बजाज फिनसर्व ईएमआई या कार्ड ईएमआई भी ले सकते हैं।';

  @override
  String get faq2q => 'बजाज फिनसर्व ईएमआई कैसे काम करती है?';

  @override
  String get faq2a =>
      'ऐप में आवेदन करें और थोड़ा डाउन पेमेंट दें। जाँच पूरी करने के लिए आधार, पैन और बैंक की जानकारी लेकर दुकान आएं। बजाज फिनसर्व की मंज़ूरी मिलते ही फोन लें और हर महीने किस्त दें। मंज़ूरी ऋणदाता का फ़ैसला है, दुकान का नहीं।';

  @override
  String get faq3q => 'ऑटोपे क्या है?';

  @override
  String get faq3a =>
      'एक स्थायी निर्देश, ताकि हर ईएमआई उसकी तारीख पर कट जाए। आप यूपीआई, कार्ड या बैंक चुनते हैं, सीमा तय करते हैं, हर कटौती से पहले रिमाइंडर पाते हैं और कभी भी रोक या रद्द कर सकते हैं।';

  @override
  String get faq4q => 'क्या मैं खरीदा हुआ सामान वापस कर सकता/सकती हूं?';

  @override
  String get faq4a =>
      'डिलीवरी के 7 दिन के भीतर, गलत या खराब सामान को डिब्बे और बिल के साथ वापस करने का अनुरोध कर सकते हैं। दुकान जाँचकर आपको रिफंड देती है। खोले गए फोन की जाँच ब्रांड का सर्विस सेंटर करता है।';

  @override
  String get faq5q => 'वारंटी कैसे काम करती है?';

  @override
  String get faq5a =>
      'हर फोन ब्रांड की वारंटी के साथ आता है। हम आपके बिल पर आईएमईआई दर्ज करते हैं, इसलिए कागज़ खो जाए तो भी वारंटी और बिल आपके ऑर्डर में रहते हैं।';

  @override
  String get faq6q => 'डिलीवरी कैसे होती है?';

  @override
  String get faq6a =>
      'शहर और आसपास के इलाकों में उसी दिन घर पर डिलीवरी। बाकी जगह कूरियर से भेजते हैं और फोन के लिए पहले भुगतान होता है। डिलीवरी पर नकद सिर्फ़ लोकल डिलीवरी में, दुकान की सीमा तक।';

  @override
  String get faq7q => 'रिज़र्व का क्या मतलब है?';

  @override
  String get faq7a =>
      'थोड़ा टोकन दें और हम फोन आपके लिए कुछ दिन रोक देते हैं। दुकान आएं, बाकी रकम दें और ले जाएं। समय खत्म होने से पहले रद्द करने पर टोकन वापस होता है।';

  @override
  String roadToTarget(String target) {
    return 'हर महीने $target की राह';
  }

  @override
  String get onTrack => 'सही राह पर';

  @override
  String get behindTarget => 'लक्ष्य से पीछे';

  @override
  String get ofTarget => 'लक्ष्य का';

  @override
  String get profitThisMonth => 'इस महीने का मुनाफ़ा';

  @override
  String projectedMonthEnd(String amount) {
    return 'इसी रफ़्तार से महीने के अंत तक: $amount';
  }

  @override
  String needPerDay(String amount, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन',
      one: '1 दिन',
    );
    return 'अगले $_temp0 में रोज़ $amount चाहिए';
  }

  @override
  String baselineLine(String baseline, String multiple) {
    return 'करीब $baseline प्रति माह से लक्ष्य तक: आज का $multiple गुना।';
  }

  @override
  String get profitBasisNote =>
      'जीएसटी और शुल्क के बाद का मुनाफ़ा, किराया, वेतन और बिजली से पहले।';

  @override
  String get todaySales => 'आज की बिक्री';

  @override
  String get ordersToday => 'आज के ऑर्डर';

  @override
  String get needsAttention => 'आपके ध्यान की ज़रूरत';

  @override
  String attnOrders(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'संभालने को $n ऑर्डर',
      one: 'संभालने को 1 ऑर्डर',
      zero: 'संभालने को कोई ऑर्डर नहीं',
    );
    return '$_temp0';
  }

  @override
  String attnEmiApprovals(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ईएमआई आवेदन बाकी',
      one: '1 ईएमआई आवेदन बाकी',
      zero: 'कोई ईएमआई आवेदन बाकी नहीं',
    );
    return '$_temp0';
  }

  @override
  String attnOverdue(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बकाया किस्तें ($amount)',
      one: '1 बकाया किस्त ($amount)',
      zero: 'कोई बकाया किस्त नहीं',
    );
    return '$_temp0';
  }

  @override
  String attnLeads(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'कॉल करने को $n नई लीड',
      one: 'कॉल करने को 1 नई लीड',
      zero: 'कोई नई लीड नहीं',
    );
    return '$_temp0';
  }

  @override
  String attnFollowUps(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n फॉलो-अप बाकी',
      one: '1 फॉलो-अप बाकी',
      zero: 'कोई फॉलो-अप बाकी नहीं',
    );
    return '$_temp0';
  }

  @override
  String attnRepairs(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n रिपेयर इंतज़ार में',
      one: '1 रिपेयर इंतज़ार में',
      zero: 'कोई रिपेयर इंतज़ार में नहीं',
    );
    return '$_temp0';
  }

  @override
  String attnLowStock(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n आइटम कम या खत्म',
      one: '1 आइटम कम या खत्म',
      zero: 'स्टॉक ठीक है',
    );
    return '$_temp0';
  }

  @override
  String get last14Days => 'मुनाफ़ा, पिछले 14 दिन';

  @override
  String get profit => 'मुनाफ़ा';

  @override
  String get whereProfitComes => 'मुनाफ़ा कहां से आ रहा है';

  @override
  String get leverRepairs => 'रिपेयर';

  @override
  String get leversHint =>
      'फोन पर मार्जिन कम होता है। एक्सेसरीज़, प्रोटेक्शन प्लान और रिपेयर में मुनाफ़ा सबसे तेज़ बढ़ता है: हर फोन के साथ इन्हें बेचें।';

  @override
  String get growthScorecard => 'ग्रोथ स्कोरकार्ड (पिछले 30 दिन)';

  @override
  String get scorecardHint =>
      'आपने क्या किया, बनाम लक्ष्य वाले महीने को क्या चाहिए।';

  @override
  String get scPhones => 'बिके फोन';

  @override
  String get scAttach => 'एक्सेसरी के साथ बिके फोन';

  @override
  String get scProtection => 'प्रोटेक्शन प्लान के साथ बिके फोन';

  @override
  String get scRepairs => 'हुए रिपेयर';

  @override
  String get scLeadConv => 'वे लीड जो बिक्री बनीं';

  @override
  String get scRepeat => 'पुराने ग्राहकों को बिक्री';

  @override
  String get finishSetup => 'अपनी दुकान की सेटिंग पूरी करें';

  @override
  String get finishSetupBody =>
      'जब तक आप ये नहीं जोड़ते, इनसे जुड़े बटन छिपे रहते हैं, ताकि ग्राहक गलत नंबर पर न पहुंचें।';

  @override
  String get setupPhone => 'दुकान का फोन';

  @override
  String get setupWhatsapp => 'व्हाट्सऐप नंबर';

  @override
  String get setupUpi => 'यूपीआई आईडी';

  @override
  String get setupGstin => 'जीएसटीआईएन';

  @override
  String get setupLocation => 'मैप लोकेशन';

  @override
  String get setupEmiRates => 'ईएमआई दरें पक्की करें';

  @override
  String get openSettings => 'सेटिंग खोलें';

  @override
  String get quickActions => 'फटाफट काम';

  @override
  String get newSale => 'नई बिक्री';

  @override
  String get newSaleHint => 'काउंटर पर ग्राहक का बिल बनाएं';

  @override
  String get addProduct => 'प्रोडक्ट जोड़ें';

  @override
  String get runAutopayNow => 'अभी ऑटोपे चलाएं';

  @override
  String autopayRan(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n किस्तें वसूली गईं।',
      one: '1 किस्त वसूली गई।',
      zero: 'कोई किस्त बाकी नहीं थी।',
    );
    return '$_temp0';
  }

  @override
  String get fltToHandle => 'संभालने हैं';

  @override
  String get fltReady => 'रवाना या तैयार';

  @override
  String get fltDone => 'पूरे';

  @override
  String get fltCancelled => 'रद्द';

  @override
  String get searchOrdersHint => 'ऑर्डर नंबर, नाम या फोन';

  @override
  String get sourceCounter => 'काउंटर';

  @override
  String get sourceApp => 'ऐप';

  @override
  String get customer => 'ग्राहक';

  @override
  String orderUpdateText(String number, String status) {
    return 'आपके ऑर्डर $number की जानकारी: $status।';
  }

  @override
  String get actMarkPaid => 'पेमेंट हो गया';

  @override
  String get actConfirm => 'ऑर्डर पक्का करें';

  @override
  String get actPack => 'पैक हो गया';

  @override
  String get actOut => 'डिलीवरी के लिए भेजा';

  @override
  String get actReady => 'लेने के लिए तैयार';

  @override
  String get actDeliver => 'सौंप दिया';

  @override
  String get actCancel => 'ऑर्डर रद्द करें';

  @override
  String get actRejectReturn => 'वापसी नामंज़ूर';

  @override
  String get actAcceptReturn => 'वापसी मंज़ूर';

  @override
  String get confirmReturnQ => 'यह वापसी मंज़ूर करें?';

  @override
  String get imeiMissing => 'आईएमईआई अभी डाला नहीं';

  @override
  String get enterImei => 'आईएमईआई डालें';

  @override
  String get imeiHelp =>
      'फोन पर *#06# डायल करके आईएमईआई देखें। हर फोन का एक डालें।';

  @override
  String get discount => 'छूट';

  @override
  String get collectPayment => 'पेमेंट लें';

  @override
  String get amount => 'रकम';

  @override
  String get referenceOptional => 'रेफ़रेंस (वैकल्पिक)';

  @override
  String get markLenderPaid => 'ऋणदाता ने पैसे दे दिए';

  @override
  String get lenderReference => 'ऋणदाता का रेफ़रेंस';

  @override
  String sendRefund(String amount) {
    return 'रिफंड $amount भेजें';
  }

  @override
  String get notes => 'नोट';

  @override
  String get stockLow => 'कम स्टॉक';

  @override
  String get hidden => 'छिपा हुआ';

  @override
  String missingCosts(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n प्रोडक्ट की खरीद कीमत नहीं डाली, इसलिए उनका मुनाफ़ा शून्य गिना जाता है।',
      one: '1 प्रोडक्ट की खरीद कीमत नहीं डाली, इसलिए उसका मुनाफ़ा शून्य गिना जाता है।',
    );
    return '$_temp0';
  }

  @override
  String get editProduct => 'प्रोडक्ट बदलें';

  @override
  String get hide => 'ग्राहकों से छिपाएं';

  @override
  String get show => 'ग्राहकों को दिखाएं';

  @override
  String get productName => 'प्रोडक्ट का नाम';

  @override
  String get categoryLabel => 'श्रेणी';

  @override
  String get variantsHeader => 'वेरिएंट और कीमतें';

  @override
  String get addVariant => 'वेरिएंट जोड़ें';

  @override
  String get variantLabel => 'वेरिएंट';

  @override
  String get colorLabel => 'रंग';

  @override
  String get sellingPrice => 'बिक्री कीमत';

  @override
  String get stockLabel => 'स्टॉक';

  @override
  String get costPrice => 'खरीद कीमत';

  @override
  String get costPriceHelp =>
      'आपने जो दिया, जीएसटी सहित। ग्राहक इसे कभी नहीं देखते।';

  @override
  String get profitPerUnit => 'प्रति नग मुनाफ़ा (जीएसटी के बाद)';

  @override
  String get description => 'विवरण';

  @override
  String get imageUrls => 'फोटो के लिंक';

  @override
  String get imageUrlsHelp =>
      'हर लाइन में एक वेब लिंक। फोटो अपलोड ऑनलाइन सर्वर के साथ आएगा।';

  @override
  String get tags => 'टैग';

  @override
  String get tagsHelp => 'कॉमा से अलग करें, जैसे refurbished, festival';

  @override
  String get sellingOptions => 'बिक्री के विकल्प';

  @override
  String get warrantyMonthsLabel => 'वारंटी (महीने)';

  @override
  String get gstRate => 'जीएसटी दर';

  @override
  String get emiEligible => 'ईएमआई पर मिल सकता है';

  @override
  String get noCostEligible => '0% ईएमआई के योग्य';

  @override
  String get noCostEligibleHint =>
      'सिर्फ़ तब जब आपका ऋणदाता और ब्रांड इस मॉडल पर देते हों।';

  @override
  String get featuredOnHome => 'होम स्क्रीन पर दिखाएं';

  @override
  String get visibleToCustomers => 'ग्राहकों को दिखे';

  @override
  String get fltOpen => 'खुले';

  @override
  String get fltFollowUpDue => 'फॉलो-अप बाकी';

  @override
  String get noLeads => 'यहां कोई लीड नहीं';

  @override
  String get noLeadsHint =>
      'जो भी फोन के बारे में पूछे, ईएमआई के लिए आवेदन करे, रिपेयर बुक करे या एक्सचेंज भेजे, यहां दिखेगा।';

  @override
  String followUpOn(String when) {
    return 'फॉलो-अप: $when';
  }

  @override
  String leadWhatsappText(String name, String what, String shop) {
    return 'नमस्ते $name जी, $shop से बोल रहे हैं, आपके $what के बारे में। हम आपकी क्या मदद करें?';
  }

  @override
  String get yourEnquiry => 'पूछताछ';

  @override
  String get changeStatus => 'स्थिति बदलें';

  @override
  String get addNote => 'नोट जोड़ें';

  @override
  String get followUp => 'फॉलो-अप';

  @override
  String get emiDesk => 'ईएमआई डेस्क';

  @override
  String get emiDeskHint => 'आवेदन, मंज़ूरी, तारीखें और ऑटोपे';

  @override
  String get repairsDesk => 'रिपेयर';

  @override
  String get offersAndCoupons => 'ऑफ़र और कूपन';

  @override
  String get customersTitle => 'ग्राहक';

  @override
  String get customersHint =>
      'हर वह व्यक्ति जिसने खरीदा या पूछा, और किसे अपग्रेड चाहिए';

  @override
  String get reportsTitle => 'रिपोर्ट';

  @override
  String get staffTitle => 'स्टाफ और भूमिकाएं';

  @override
  String get staffHint => 'ऐप में कौन क्या कर सकता है';

  @override
  String get shopSettings => 'दुकान की सेटिंग';

  @override
  String get resetDemoHint =>
      'आप नमूना डेटा देख रहे हैं। असली स्टॉक जोड़ने के लिए तैयार हों तो इसे रीसेट करें।';

  @override
  String get resetDemo => 'डेमो डेटा रीसेट करें';

  @override
  String get resetDemoQ => 'सारा डेमो डेटा रीसेट करें?';

  @override
  String get resetDemoBody =>
      'यह इस डिवाइस के हर ऑर्डर, ग्राहक और बदलाव को मिटाकर नमूना दुकान फिर से लोड करता है।';

  @override
  String get addItem => 'आइटम जोड़ें';

  @override
  String discountHelp(int pct) {
    return 'काउंटर स्टाफ $pct% तक दे सकता है। मैनेजर ज़्यादा दे सकता है।';
  }

  @override
  String get fullCash => 'पूरा नकद';

  @override
  String get fullUpi => 'पूरा यूपीआई';

  @override
  String get fullCard => 'पूरा कार्ड';

  @override
  String get addPayment => 'पेमेंट जोड़ें';

  @override
  String get paidSoFar => 'अब तक मिला';

  @override
  String get financeBalanceBajaj => 'बाकी रकम बजाज फिनसर्व से फाइनेंस करें';

  @override
  String get financeBalanceHint => 'ग्राहक अभी जो देता है, वही डाउन पेमेंट है।';

  @override
  String get financeNeedsDown =>
      'ऊपर डाउन पेमेंट डालें। बाकी रकम, फोन की कीमत तक, फाइनेंस होती है।';

  @override
  String get bajajCounterNote =>
      'ऋणदाता की मंज़ूरी तक बिक्री रुकी रहती है। आईएमईआई फोन देते समय डाला जाता है।';

  @override
  String get completeSale => 'बिक्री पूरी करें';

  @override
  String saleDone(String number) {
    return 'बिक्री पूरी: $number';
  }

  @override
  String get saleDoneBody =>
      'बिल और वारंटी अब ग्राहक के ऐप में उनके मोबाइल नंबर के नीचे हैं।';

  @override
  String get saleDoneEmiBody =>
      'ईएमआई आवेदन खुला है। ईएमआई डेस्क पर उसे मंज़ूर करें, फिर फोन दें।';

  @override
  String get sendBill => 'व्हाट्सऐप पर बिल भेजें';

  @override
  String get tabApplications => 'आवेदन';

  @override
  String get tabActive => 'चालू';

  @override
  String get tabOther => 'बंद';

  @override
  String get dueThisMonth => 'इस महीने की किस्तें';

  @override
  String get overdueLabel => 'बकाया';

  @override
  String overdueCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n बकाया',
      one: '1 बकाया',
    );
    return '$_temp0';
  }

  @override
  String get approveHint =>
      'ऋणदाता (बजाज फिनसर्व या बैंक) के लोन मंज़ूर करने के बाद ही मंज़ूर करें। तभी फोन दिया जा सकता है।';

  @override
  String get approvePlan => 'मंज़ूर करें';

  @override
  String get rejectPlan => 'नामंज़ूर करें';

  @override
  String get lenderRefHint => 'लोन या आवेदन नंबर';

  @override
  String get markPaid => 'चुकाई मार्क करें';

  @override
  String get issueLabel => 'समस्या';

  @override
  String get quotePrice => 'ग्राहक को बताई गई कीमत';

  @override
  String get partsCostPrompt => 'पुर्ज़ों में आपका कितना खर्च हुआ?';

  @override
  String moveTo(String status) {
    return 'आगे: $status';
  }

  @override
  String get waitingForCustomer => 'ग्राहक के कीमत मंज़ूर करने का इंतज़ार।';

  @override
  String get customerApproved => 'ग्राहक ने फोन पर हामी भरी';

  @override
  String get addOffer => 'ऑफ़र जोड़ें';

  @override
  String get editOffer => 'ऑफ़र बदलें';

  @override
  String get noOffers => 'अभी कोई ऑफ़र नहीं';

  @override
  String get noOffersHint =>
      'त्योहार का बैनर या कूपन कोड जोड़ें। ग्राहक इसे होम स्क्रीन और चेकआउट पर देखेंगे।';

  @override
  String get shareOffer => 'ऑफ़र शेयर करें';

  @override
  String offerShareBanner(String title, String shop) {
    return '$title। $shop पर आएं या ब्रांडहूप ऐप पर ऑर्डर करें।';
  }

  @override
  String offerShareCoupon(String title, String code, String shop) {
    return '$title। $shop पर या ब्रांडहूप ऐप पर कोड $code इस्तेमाल करें।';
  }

  @override
  String get offerTitle => 'शीर्षक';

  @override
  String get offerSubtitle => 'उप-शीर्षक';

  @override
  String get kindCoupon => 'कूपन';

  @override
  String get kindBanner => 'बैनर';

  @override
  String get percentOff => 'प्रतिशत छूट';

  @override
  String get flatOff => 'सीधी छूट';

  @override
  String get minOrder => 'न्यूनतम ऑर्डर';

  @override
  String get maxDiscount => 'अधिकतम छूट';

  @override
  String get appliesTo => 'किस पर लगेगा';

  @override
  String get appliesToHint =>
      'सब पर लगाने के लिए कुछ न चुनें। फोन को बड़ी छूट से दूर रखें: उन पर मार्जिन कम है।';

  @override
  String get starts => 'शुरू';

  @override
  String get ends => 'खत्म';

  @override
  String get activeLabel => 'चालू';

  @override
  String get deleteOfferQ => 'यह ऑफ़र हटाएं?';

  @override
  String get searchCustomersHint => 'नाम या फोन';

  @override
  String get segUpgrade => 'अपग्रेड का समय';

  @override
  String get segTop => 'सबसे ज़्यादा खरीदने वाले';

  @override
  String get segRepeat => 'बार-बार खरीदने वाले';

  @override
  String get segNew => 'इस महीने नए';

  @override
  String get upgradeHint =>
      'इन ग्राहकों ने आख़िरी फोन 18 महीने से पहले खरीदा था। ये सबसे ज़्यादा दोबारा खरीदने वाले हैं।';

  @override
  String get tapCustomerToMessage => 'ग्राहक को खोलकर व्हाट्सऐप पर ऑफ़र भेजें।';

  @override
  String ordersCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ऑर्डर',
      one: '1 ऑर्डर',
      zero: 'कोई ऑर्डर नहीं',
    );
    return '$_temp0';
  }

  @override
  String customerSince(String date) {
    return '$date से ग्राहक';
  }

  @override
  String get addedAtCounter => 'काउंटर पर जोड़ा गया';

  @override
  String get lifetimeSpend => 'कुल खरीदा';

  @override
  String get coinsLabel => 'ब्रांडहूप कॉइन';

  @override
  String get lastPhoneBought => 'आख़िरी फोन खरीदा';

  @override
  String get sendOffer => 'ऑफ़र भेजें';

  @override
  String get sendUpgrade => 'अपग्रेड मैसेज';

  @override
  String customerOfferText(String name, String shop) {
    return 'नमस्ते $name जी! $shop पर इस हफ़्ते फोन और एक्सेसरीज़ पर नए ऑफ़र हैं। दुकान पर आएं या यहीं जवाब देकर जानें।';
  }

  @override
  String upgradeText(String name, String shop) {
    return 'नमस्ते $name जी! $shop से आपका आख़िरी फोन लिए काफ़ी समय हो गया। आइए, पुराने फोन के बदले नए मॉडल पर क्या मिलेगा, देखिए।';
  }

  @override
  String get addStaff => 'स्टाफ जोड़ें';

  @override
  String get staffExplain =>
      'किसी मोबाइल नंबर को भूमिका दें। वह व्यक्ति कोड से साइन इन करे तो उसे वही बैक ऑफ़िस दिखेगा जो उस भूमिका को मिला है।';

  @override
  String get roleLabel => 'भूमिका';

  @override
  String makeRole(String role) {
    return '$role बनाएं';
  }

  @override
  String get disableAccount => 'यह खाता बंद करें';

  @override
  String get enableAccount => 'यह खाता चालू करें';

  @override
  String get disabled => 'बंद';

  @override
  String get staffAdded =>
      'जोड़ दिया। वे अपने मोबाइल नंबर से साइन इन कर सकते हैं।';

  @override
  String get whatEachRoleCanDo => 'हर भूमिका क्या कर सकती है';

  @override
  String get roleStaffCan =>
      'काउंटर पर बिल, ऑर्डर और लीड, रिपेयर, स्टॉक में बदलाव। खरीद कीमत या मुनाफ़ा नहीं देख सकता, कीमतें नहीं बदल सकता, ईएमआई मंज़ूर नहीं कर सकता।';

  @override
  String get roleManagerCan =>
      'स्टाफ के सब काम, साथ में प्रोडक्ट, कीमतें, खरीद कीमतें, ऑफ़र, ईएमआई मंज़ूरी और रिपोर्ट। कुल मुनाफ़ा, स्टाफ या सेटिंग नहीं देख सकता।';

  @override
  String get roleOwnerCan =>
      'सब कुछ, जिसमें मुनाफ़ा और लक्ष्य की राह, रिफंड, स्टाफ और दुकान की सेटिंग शामिल हैं।';

  @override
  String get exportCsv => 'CSV के रूप में कॉपी करें';

  @override
  String get csvCopied => 'कॉपी हो गया। इसे स्प्रेडशीट में पेस्ट करें।';

  @override
  String get last7Days => 'पिछले 7 दिन';

  @override
  String get last30Days => 'पिछले 30 दिन';

  @override
  String get thisMonth => 'इस महीने';

  @override
  String get revenue => 'बिक्री';

  @override
  String get ordersLabel => 'ऑर्डर';

  @override
  String get avgOrder => 'औसत ऑर्डर';

  @override
  String get phonesSold => 'बिके फोन';

  @override
  String get margin => 'मुनाफ़े का प्रतिशत';

  @override
  String get dailyProfitRevenue => 'दिन-ब-दिन';

  @override
  String get salesByGroup => 'प्रकार के अनुसार बिक्री';

  @override
  String get paymentMix => 'ग्राहकों ने कैसे भुगतान किया';

  @override
  String get topProducts => 'सबसे ज़्यादा बिकने वाले';

  @override
  String unitsSold(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n बिके',
      one: '1 बिका',
    );
    return '$_temp0';
  }

  @override
  String get setShopInfo => 'दुकान की जानकारी';

  @override
  String get shopName => 'दुकान का नाम';

  @override
  String get tagline => 'टैगलाइन';

  @override
  String get shopPhone => 'दुकान का फोन';

  @override
  String get shopPhoneHelp =>
      'ग्राहक इस पर टैप करके कॉल करते हैं। खाली रखने पर कॉल बटन छिप जाता है।';

  @override
  String get shopWhatsapp => 'व्हाट्सऐप नंबर';

  @override
  String get addressLabel => 'पता';

  @override
  String get latitude => 'अक्षांश';

  @override
  String get longitude => 'देशांतर';

  @override
  String get mapsLink => 'गूगल मैप्स लिंक';

  @override
  String get mapsLinkHelp =>
      'वैकल्पिक। गूगल मैप्स पर दुकान खोलें, शेयर दबाएं और लिंक यहां पेस्ट करें।';

  @override
  String get shopUpi => 'दुकान की यूपीआई आईडी';

  @override
  String get shopUpiHelp => 'काउंटर के यूपीआई पेमेंट यहां आते हैं।';

  @override
  String get shopGstin => 'जीएसटीआईएन';

  @override
  String get opens => 'खुलता है';

  @override
  String get closes => 'बंद होता है';

  @override
  String get deliveryAndOrders => 'डिलीवरी और ऑर्डर';

  @override
  String get localPincodes => 'जिन पिनकोड पर आप खुद डिलीवरी करते हैं';

  @override
  String get localPincodesHelp =>
      'कॉमा से अलग करें। उसी दिन डिलीवरी और डिलीवरी पर नकद सिर्फ़ यहीं चलता है।';

  @override
  String get localDeliveryFee => 'लोकल डिलीवरी शुल्क';

  @override
  String get courierFee => 'कूरियर शुल्क';

  @override
  String get freeDeliveryAbove => 'इससे ऊपर डिलीवरी मुफ़्त';

  @override
  String get reserveHoursLabel => 'रिज़र्व के घंटे';

  @override
  String get codLimit => 'डिलीवरी पर नकद की सीमा';

  @override
  String get allowCod => 'शहर में डिलीवरी पर नकद की अनुमति';

  @override
  String get allowReserve => 'टोकन देकर रिज़र्व की अनुमति';

  @override
  String get financeSettings => 'ईएमआई और ऑटोपे';

  @override
  String get financeSettingsHint =>
      'ये दरें शुरू में नमूना हैं। इन्हें उन दरों से बदलें जो बजाज फिनसर्व और आपके कार्ड बैंक ने आपसे तय की हैं, फिर दरें पक्की पर टिक करें।';

  @override
  String get allowBajaj => 'बजाज फिनसर्व ईएमआई दें';

  @override
  String get allowCardEmi => 'कार्ड ईएमआई दें';

  @override
  String get allowAutopay => 'ऑटोपे दें';

  @override
  String get allowShopInstalments => 'दुकान खुद किस्त वसूले';

  @override
  String get allowShopInstalmentsHint =>
      'सलाह लेने तक बंद रखें: खुद किस्त वसूलना उधार और जमा के नियमों के अंतर्गत आ सकता है।';

  @override
  String get ratesConfirmed => 'दरें पक्की हैं';

  @override
  String get ratesConfirmedHint => 'तभी चालू करें जब नीचे की दरें असली हों।';

  @override
  String get lenderRateLabel => 'ऋणदाता की दर % सालाना';

  @override
  String get minPrice => 'न्यूनतम कीमत';

  @override
  String get minDownPct => 'न्यूनतम डाउन पेमेंट %';

  @override
  String get tenuresLabel => 'कितने महीने';

  @override
  String get tenuresHelp => 'कॉमा से अलग करें, जैसे 3, 6, 9, 12';

  @override
  String get noCostCostNote =>
      '0% स्कीम में ग्राहक सिर्फ़ कीमत देता है। ऋणदाता जो ब्याज लेता, उसे आपके मुनाफ़े में बिक्री का खर्च गिना जाता है।';

  @override
  String get targetsAndFees => 'लक्ष्य, शुल्क और इनाम';

  @override
  String get monthlyTarget => 'मासिक मुनाफ़े का लक्ष्य';

  @override
  String get baselineProfit => 'ऐप से पहले का मुनाफ़ा';

  @override
  String get cardFee => 'कार्ड शुल्क %';

  @override
  String get upiFee => 'यूपीआई शुल्क %';

  @override
  String get profitAfterGst => 'जीएसटी के बाद मुनाफ़ा गिनें';

  @override
  String get profitAfterGstHint =>
      'आपके मार्जिन पर लगा जीएसटी सरकार को जाता है, इसलिए वह आपका नहीं है।';

  @override
  String get coinsEarnPct => 'कॉइन कमाई % (एक्सेसरीज़)';

  @override
  String get referralBonus => 'रेफ़रल बोनस (कॉइन)';

  @override
  String get maxCoinsPct => 'कॉइन इस्तेमाल की सीमा %';

  @override
  String get repairPricesHeader => 'रिपेयर की शुरुआती कीमतें';

  @override
  String get liveOrderCta => 'व्हाट्सऐप पर ऑर्डर भेजें';

  @override
  String liveOrderIntro(String shop) {
    return 'नमस्ते $shop, मैं आपके ऐप से ये सामान रिज़र्व करना चाहता/चाहती हूँ:';
  }

  @override
  String liveOrderTotal(String amount) {
    return 'कुल: $amount';
  }

  @override
  String get liveOrderOutro =>
      'कृपया उपलब्धता और आज के ऑफ़र बताएँ। मैं दुकान पर आऊँगा/आऊँगी।';

  @override
  String get liveCartHint =>
      'आपका ऑर्डर व्हाट्सऐप पर दुकान को जाता है। स्टॉक, कीमत और ऑफ़र दुकान पक्का करती है। भुगतान दुकान के बताए अनुसार UPI या कार्ड से ऑनलाइन, या दुकान पर करें। बजाज फिनसर्व EMI सिर्फ़ दुकान पर (फ़ेस स्कैन ज़रूरी)।';

  @override
  String get liveShareTitle => 'यह दुकान को भेजें';

  @override
  String get liveShareBody =>
      'दुकान का व्हाट्सऐप नंबर अभी ऐप में नहीं डाला गया है। यह संदेश दुकान को भेजें, या दुकान पर आएँ।';

  @override
  String get liveCatalogTitle => 'हमारा कैटलॉग अपडेट हो रहा है';

  @override
  String get liveCatalogBody =>
      'आज के फ़ोन, कीमतें और दिवाली ऑफ़र के लिए दुकान पर आएँ या हमें व्हाट्सऐप करें।';

  @override
  String liveRepairMsg(String shop, String device, String issue) {
    return 'नमस्ते $shop, मुझे $device की रिपेयर का खर्च जानना है। समस्या: $issue।';
  }

  @override
  String liveVisitMsg(String shop, String when) {
    return 'नमस्ते $shop, मैं $when को दुकान पर आऊँगा/आऊँगी।';
  }

  @override
  String liveExchangeMsg(String shop, String device, String range) {
    return 'नमस्ते $shop, मैं अपना $device एक्सचेंज करना चाहता/चाहती हूँ। ऐप का अनुमान $range है। फ़ोन देखकर कृपया पक्का करें।';
  }

  @override
  String get liveWhyPayBody =>
      'UPI और कार्ड ऑनलाइन, नकद दुकान पर। बजाज फिनसर्व EMI सिर्फ़ दुकान पर (फ़ेस स्कैन ज़रूरी)।';

  @override
  String get liveEmiTitle => 'ब्रांडहूप में EMI';

  @override
  String get liveEmiBody =>
      'हम बजाज फिनसर्व के साथ EMI देते हैं। यह सिर्फ़ दुकान पर मिलती है, क्योंकि इसमें फ़ेस स्कैन ज़रूरी है। मंज़ूरी, ब्याज दर और अंतिम किश्तें फाइनेंस कंपनी तय करती है। आज की स्कीम और दरें दुकान पर पूछें।';

  @override
  String get liveEmiShopOnly =>
      'बजाज फिनसर्व EMI सिर्फ़ दुकान पर मिलती है, क्योंकि इसमें फ़ेस स्कैन ज़रूरी है। मंज़ूरी और दर फाइनेंस कंपनी तय करती है।';
}
