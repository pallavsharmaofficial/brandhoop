import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hindi / English labels. Missing Hindi falls back to English.
class Lang extends ValueNotifier<String> {
  Lang._() : super('en');
  static final Lang I = Lang._();

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    value = p.getString('lang') ?? 'en';
  }

  Future<void> set(String code) async {
    value = code;
    final p = await SharedPreferences.getInstance();
    await p.setString('lang', code);
  }
}

String t(String key) => (Lang.I.value == 'hi' ? _hi[key] : null) ?? _en[key] ?? key;

const _en = <String, String>{
  'login': 'Sign in',
  'mobile': 'Mobile number',
  'password': 'Password',
  'android': 'Android',
  'iphone': 'iPhone',
  'collect': 'Collect EMI',
  'total': 'Total\nDevice',
  'active': 'Active\nDevice',
  'inactive': 'Inactive\nDevice',
  'removed': 'Uninstall\nDevice',
  'locked': 'Lock\nDevice',
  'keys': 'Key\nBalance',
  'customers': 'Customers',
  'reports': 'Reports',
  'profile': 'Profile',
  'settings': 'Shop settings',
  'staff': 'Staff',
  'key_history': 'Key history',
  'audit': 'Activity log',
  'shops': 'Shops (admin)',
  'list_title': 'List of Customers',
  'users': 'USERS',
  'next_emi': 'NEXT EMI',
  'high_risk': 'HIGH RISK',
  'details': 'Customer Details',
  'device': 'DEVICE',
  'reminder': 'REMINDER',
  'agreement': 'AGREEMENT',
  'location': 'LOCATION',
  'history': 'HISTORY',
  'online': 'ONLINE',
  'offline': 'OFFLINE',
  'lock_device': 'Lock Device',
  'unlock_device': 'Unlock Device',
  'warning': 'Warning',
  'restrict': 'Restrict Apps',
  'message': 'Message',
  'locate': 'Locate',
  'release': 'Release',
  'remind': 'Send Reminder',
  'show_qr': 'Enrollment QR',
  'new_sale': 'New EMI sale',
  'save': 'Save',
  'cancel': 'Cancel',
  'search': 'Search name, mobile, IMEI',
  'no_customers': 'No customers here yet',
  'logout': 'Sign out',
  'language': 'हिन्दी',
};

const _hi = <String, String>{
  'login': 'लॉग इन',
  'mobile': 'मोबाइल नंबर',
  'password': 'पासवर्ड',
  'android': 'एंड्रॉयड',
  'iphone': 'आईफ़ोन',
  'collect': 'EMI जमा करें',
  'total': 'कुल\nडिवाइस',
  'active': 'सक्रिय\nडिवाइस',
  'inactive': 'निष्क्रिय\nडिवाइस',
  'removed': 'अनइंस्टॉल\nडिवाइस',
  'locked': 'लॉक\nडिवाइस',
  'keys': 'की\nबैलेंस',
  'customers': 'ग्राहक',
  'reports': 'रिपोर्ट',
  'profile': 'प्रोफ़ाइल',
  'settings': 'दुकान सेटिंग',
  'staff': 'स्टाफ़',
  'key_history': 'की इतिहास',
  'audit': 'गतिविधि लॉग',
  'shops': 'दुकानें (एडमिन)',
  'list_title': 'ग्राहकों की सूची',
  'users': 'ग्राहक',
  'next_emi': 'अगली EMI',
  'high_risk': 'जोखिम',
  'details': 'ग्राहक विवरण',
  'device': 'डिवाइस',
  'reminder': 'रिमाइंडर',
  'agreement': 'अनुबंध',
  'location': 'लोकेशन',
  'history': 'इतिहास',
  'online': 'ऑनलाइन',
  'offline': 'ऑफ़लाइन',
  'lock_device': 'फ़ोन लॉक करें',
  'unlock_device': 'फ़ोन अनलॉक करें',
  'warning': 'चेतावनी',
  'restrict': 'ऐप रोकें',
  'message': 'संदेश',
  'locate': 'लोकेशन देखें',
  'release': 'फ़ोन मुक्त करें',
  'remind': 'रिमाइंडर भेजें',
  'show_qr': 'एनरोलमेंट QR',
  'new_sale': 'नई EMI बिक्री',
  'save': 'सेव करें',
  'cancel': 'रद्द करें',
  'search': 'नाम, मोबाइल, IMEI खोजें',
  'no_customers': 'अभी कोई ग्राहक नहीं',
  'logout': 'लॉग आउट',
  'language': 'English',
};
