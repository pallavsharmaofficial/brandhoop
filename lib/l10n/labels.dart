import '../core/permissions.dart';
import '../domain/emi_plan.dart';
import '../domain/lead.dart';
import '../domain/order.dart';
import '../domain/payment.dart';
import '../domain/product.dart';
import '../domain/repair.dart';
import '../services/guard.dart';
import '../services/payment_gateway.dart';
import '../services/payment_rules.dart';
import 'app_localizations.dart';

/// Words for every enum the shop uses, in whichever language is showing.
extension Labels on AppLocalizations {
  String category(ProductCategory c) {
    switch (c) {
      case ProductCategory.smartphone:
        return catSmartphone;
      case ProductCategory.featurePhone:
        return catFeaturePhone;
      case ProductCategory.tablet:
        return catTablet;
      case ProductCategory.earphones:
        return catEarphones;
      case ProductCategory.charger:
        return catCharger;
      case ProductCategory.cable:
        return catCable;
      case ProductCategory.caseCover:
        return catCase;
      case ProductCategory.screenGuard:
        return catScreenGuard;
      case ProductCategory.powerBank:
        return catPowerBank;
      case ProductCategory.smartwatch:
        return catSmartwatch;
      case ProductCategory.speaker:
        return catSpeaker;
      case ProductCategory.memory:
        return catMemory;
      case ProductCategory.protection:
        return catProtection;
    }
  }

  String group(ProductGroup g) {
    switch (g) {
      case ProductGroup.phones:
        return groupPhones;
      case ProductGroup.accessories:
        return groupAccessories;
      case ProductGroup.protection:
        return groupProtection;
    }
  }

  String orderStatus(OrderStatus s) {
    switch (s) {
      case OrderStatus.pendingPayment:
        return statusPendingPayment;
      case OrderStatus.placed:
        return statusPlaced;
      case OrderStatus.confirmed:
        return statusConfirmed;
      case OrderStatus.packed:
        return statusPacked;
      case OrderStatus.outForDelivery:
        return statusOutForDelivery;
      case OrderStatus.readyForPickup:
        return statusReadyForPickup;
      case OrderStatus.delivered:
        return statusDelivered;
      case OrderStatus.cancelled:
        return statusCancelled;
      case OrderStatus.returnRequested:
        return statusReturnRequested;
      case OrderStatus.returned:
        return statusReturned;
    }
  }

  String fulfilment(Fulfilment f) {
    switch (f) {
      case Fulfilment.delivery:
        return fulfilDelivery;
      case Fulfilment.pickup:
        return fulfilPickup;
      case Fulfilment.walkIn:
        return fulfilWalkIn;
    }
  }

  String payMethod(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.upi:
        return payMethodUpi;
      case PaymentMethod.card:
        return payMethodCard;
      case PaymentMethod.netbanking:
        return payMethodNetbanking;
      case PaymentMethod.cash:
        return payMethodCash;
      case PaymentMethod.bajajEmi:
        return payMethodBajaj;
      case PaymentMethod.cardEmi:
        return payMethodCardEmi;
    }
  }

  String payMode(PaymentMode m) {
    switch (m) {
      case PaymentMode.full:
        return payModeFull;
      case PaymentMode.token:
        return payModeToken;
      case PaymentMode.cashOnDelivery:
        return payModeCod;
      case PaymentMode.cashAtStore:
        return payModeCashStore;
      case PaymentMode.bajajEmi:
        return payModeBajaj;
      case PaymentMode.cardEmi:
        return payModeCardEmi;
      case PaymentMode.mixed:
        return payModeMixed;
    }
  }

  String payStatus(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.pending:
        return payStatusPending;
      case PaymentStatus.paid:
        return payStatusPaid;
      case PaymentStatus.failed:
        return payStatusFailed;
    }
  }

  String planStatus(EmiPlanStatus s) {
    switch (s) {
      case EmiPlanStatus.applied:
        return planApplied;
      case EmiPlanStatus.approved:
        return planApproved;
      case EmiPlanStatus.active:
        return planActive;
      case EmiPlanStatus.closed:
        return planClosed;
      case EmiPlanStatus.rejected:
        return planRejected;
      case EmiPlanStatus.cancelled:
        return planCancelled;
    }
  }

  String instalmentStatus(InstalmentStatus s) {
    switch (s) {
      case InstalmentStatus.upcoming:
        return instUpcoming;
      case InstalmentStatus.paid:
        return instPaid;
      case InstalmentStatus.overdue:
        return instOverdue;
    }
  }

  String autopayStatus(AutopayStatus s) {
    switch (s) {
      case AutopayStatus.notSet:
        return autopayNotSet;
      case AutopayStatus.pending:
        return autopayPending;
      case AutopayStatus.active:
        return autopayActive;
      case AutopayStatus.paused:
        return autopayPaused;
      case AutopayStatus.cancelled:
        return autopayCancelled;
      case AutopayStatus.failed:
        return autopayFailed;
    }
  }

  String autopayMethod(AutopayMethod m) {
    switch (m) {
      case AutopayMethod.upiAutopay:
        return autopayUpi;
      case AutopayMethod.cardMandate:
        return autopayCard;
      case AutopayMethod.bankMandate:
        return autopayBank;
    }
  }

  String provider(EmiProvider p) {
    switch (p) {
      case EmiProvider.bajaj:
        return providerBajaj;
      case EmiProvider.bank:
        return providerBank;
      case EmiProvider.shop:
        return providerShop;
    }
  }

  String leadType(LeadType t) {
    switch (t) {
      case LeadType.enquiry:
        return leadEnquiry;
      case LeadType.callback:
        return leadCallback;
      case LeadType.emiApplication:
        return leadEmi;
      case LeadType.exchange:
        return leadExchange;
      case LeadType.repair:
        return leadRepair;
      case LeadType.reserve:
        return leadReserve;
      case LeadType.visit:
        return leadVisit;
    }
  }

  String leadStatus(LeadStatus s) {
    switch (s) {
      case LeadStatus.fresh:
        return leadFresh;
      case LeadStatus.contacted:
        return leadContacted;
      case LeadStatus.visited:
        return leadVisited;
      case LeadStatus.converted:
        return leadConverted;
      case LeadStatus.lost:
        return leadLost;
    }
  }

  String repairIssue(RepairIssue i) {
    switch (i) {
      case RepairIssue.screen:
        return issueScreen;
      case RepairIssue.battery:
        return issueBattery;
      case RepairIssue.charging:
        return issueCharging;
      case RepairIssue.water:
        return issueWater;
      case RepairIssue.speaker:
        return issueSpeaker;
      case RepairIssue.camera:
        return issueCamera;
      case RepairIssue.software:
        return issueSoftware;
      case RepairIssue.other:
        return issueOther;
    }
  }

  String repairStatus(RepairStatus s) {
    switch (s) {
      case RepairStatus.booked:
        return repairBooked;
      case RepairStatus.received:
        return repairReceived;
      case RepairStatus.diagnosing:
        return repairDiagnosing;
      case RepairStatus.awaitingApproval:
        return repairAwaiting;
      case RepairStatus.inRepair:
        return repairInRepair;
      case RepairStatus.ready:
        return repairReady;
      case RepairStatus.delivered:
        return repairDelivered;
      case RepairStatus.cancelled:
        return repairCancelled;
    }
  }

  String role(AppRole r) {
    switch (r) {
      case AppRole.customer:
        return roleCustomer;
      case AppRole.staff:
        return roleStaff;
      case AppRole.manager:
        return roleManager;
      case AppRole.owner:
        return roleOwner;
    }
  }

  /// 1 = Monday ... 7 = Sunday.
  String weekday(int d) {
    switch (d) {
      case 1:
        return dayMon;
      case 2:
        return dayTue;
      case 3:
        return dayWed;
      case 4:
        return dayThu;
      case 5:
        return dayFri;
      case 6:
        return daySat;
      default:
        return daySun;
    }
  }

  String specLabel(String key) {
    switch (key) {
      case 'ram':
        return specRam;
      case 'storage':
        return specStorage;
      case 'display':
        return specDisplay;
      case 'battery':
        return specBattery;
      case 'camera':
        return specCamera;
      case 'chip':
        return specChip;
      case 'os':
        return specOs;
    }
    return key;
  }

  String gatewayFailure(GatewayFailure f) {
    switch (f) {
      case GatewayFailure.declined:
        return errGatewayDeclined;
      case GatewayFailure.invalidInstrument:
        return errGatewayInvalid;
      case GatewayFailure.cancelled:
        return errGatewayCancelled;
      case GatewayFailure.timeout:
        return errGatewayTimeout;
    }
  }

  /// A sentence a person can act on, for anything a service threw.
  String error(Object e) {
    if (e is PermissionDenied) return errNoPermission;
    if (e is ShopException) {
      switch (e.code) {
        case 'badPhone':
          return errBadPhone;
        case 'badOtp':
          return errBadOtp;
        case 'accountDisabled':
          return errAccountDisabled;
        case 'badAddress':
          return errBadAddress;
        case 'emptyCart':
          return errEmptyCart;
        case 'stockChanged':
          return errStockChanged;
        case 'badCoupon':
          return errBadCoupon;
        case 'payNotAllowed':
          return errPayNotAllowed;
        case 'needInstrument':
          return errNeedInstrument;
        case 'badEmiScheme':
          return errBadEmiScheme;
        case 'nothingToPay':
          return errNothingToPay;
        case 'cannotCancel':
          return errCannotCancel;
        case 'returnWindowClosed':
          return errReturnWindowClosed;
        case 'badTransition':
          return errBadTransition;
        case 'badImei':
          return errBadImei;
        case 'dupImei':
          return errDupImei;
        case 'imeiRequired':
          return errImeiRequired;
        case 'emiNotApproved':
          return errEmiNotApproved;
        case 'balanceDue':
          return errBalanceDue;
        case 'badAmount':
          return errBadAmount;
        case 'discountTooHigh':
          return errDiscountTooHigh;
        case 'planNotLive':
          return errPlanNotLive;
        case 'mandateFailed':
          return errMandateFailed;
        case 'refundFailed':
          return errRefundFailed;
        case 'quoteRequired':
          return errQuoteRequired;
        case 'needVariant':
          return errNeedVariant;
        case 'badPrice':
          return errBadPrice;
        case 'lastOwner':
          return errLastOwner;
        case 'badRole':
          return errBadRole;
      }
    }
    return somethingWrong;
  }

  String payChoiceName(PayChoice c) {
    switch (c) {
      case PayChoice.upi:
        return payChoiceUpi;
      case PayChoice.card:
        return payChoiceCard;
      case PayChoice.netbanking:
        return payMethodNetbanking;
      case PayChoice.cashOnDelivery:
        return payChoiceCod;
      case PayChoice.cashAtStore:
        return payChoiceCashStore;
      case PayChoice.reserve:
        return payChoiceReserve;
      case PayChoice.bajajEmi:
        return payMethodBajaj;
      case PayChoice.cardEmi:
        return payMethodCardEmi;
    }
  }

  String payChoiceHint(PayChoice c, {String token = ''}) {
    switch (c) {
      case PayChoice.upi:
        return payChoiceUpiHint;
      case PayChoice.card:
        return payChoiceCardHint;
      case PayChoice.netbanking:
        return payChoiceNetbankingHint;
      case PayChoice.cashOnDelivery:
        return payChoiceCodHint;
      case PayChoice.cashAtStore:
        return payChoiceCashStoreHint;
      case PayChoice.reserve:
        return payChoiceReserveHint(token);
      case PayChoice.bajajEmi:
        return payChoiceBajajHint;
      case PayChoice.cardEmi:
        return payChoiceCardEmiHint;
    }
  }
}
