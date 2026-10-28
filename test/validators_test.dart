import 'package:brandhoop/core/money.dart';
import 'package:brandhoop/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.mobile', () {
    test('accepts and normalises Indian mobiles', () {
      expect(Validators.mobile('9876543210'), '9876543210');
      expect(Validators.mobile('+91 98765-43210'), '9876543210');
      expect(Validators.mobile('919876543210'), '9876543210');
      expect(Validators.mobile('09876543210'), '9876543210');
    });
    test('rejects the rest', () {
      expect(Validators.mobile('5876543210'), isNull);
      expect(Validators.mobile('98765'), isNull);
      expect(Validators.mobile(''), isNull);
      expect(Validators.mobile(null), isNull);
      expect(Validators.mobile('98765432101'), isNull);
    });
  });

  test('pincode', () {
    expect(Validators.pincode('332713'), isTrue);
    expect(Validators.pincode('032713'), isFalse);
    expect(Validators.pincode('3327'), isFalse);
  });

  test('upi id', () {
    expect(Validators.upiId('ravi@okaxis'), isTrue);
    expect(Validators.upiId('ravi.kumar-1@ybl'), isTrue);
    expect(Validators.upiId('ravi@'), isFalse);
    expect(Validators.upiId('ravi okaxis'), isFalse);
  });

  test('luhn, imei and cards', () {
    expect(Validators.luhn('4111111111111111'), isTrue);
    expect(Validators.luhn('4111111111111112'), isFalse);
    expect(Validators.imei('490154203237518'), isTrue);
    expect(Validators.imei('490154203237519'), isFalse);
    expect(Validators.imei('49015420323751'), isFalse);
    expect(Validators.cardNumber('4111 1111 1111 1111'), isTrue);
    expect(Validators.cardNumber('1234'), isFalse);
  });

  test('card expiry', () {
    final DateTime now = DateTime(2026, 10, 15);
    expect(Validators.cardExpiry('10/26', now), isTrue);
    expect(Validators.cardExpiry('09/26', now), isFalse);
    expect(Validators.cardExpiry('12/30', now), isTrue);
    expect(Validators.cardExpiry('13/30', now), isFalse);
    expect(Validators.cardExpiry('1230', now), isFalse);
  });

  test('masked phone', () {
    expect(Validators.maskPhone('9876543210'), '98XXXXXX10');
  });

  group('money', () {
    test('indian grouping', () {
      expect(formatRupees(500000), '₹5,00,000');
      expect(formatRupees(1234567), '₹12,34,567');
      expect(formatRupees(999), '₹999');
    });
    test('compact', () {
      expect(formatCompactRupees(500000), '₹5 L');
      expect(formatCompactRupees(35000), '₹35K');
      expect(formatCompactRupees(250000), '₹2.5 L');
      expect(formatCompactRupees(500000, hindi: true), '₹5 लाख');
      expect(formatCompactRupees(35000, hindi: true), '₹35 हज़ार');
      expect(formatCompactRupees(950), '₹950');
      expect(formatCompactRupees(20000000), '₹2 Cr');
    });
    test('discount percent and gst', () {
      expect(discountPercent(1000, 800), 20);
      expect(discountPercent(1000, 1200), 0);
      expect(discountPercent(0, 0), 0);
      expect(gstInside(11800, 18), 1800);
      expect(gstInside(100, 0), 0);
    });
  });
}
