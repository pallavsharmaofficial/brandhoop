import 'package:brandhoop/core/emi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Emi', () {
    test('reducing balance EMI matches the textbook figure', () {
      final double exact = Emi.exactMonthly(
        principal: 100000,
        months: 12,
        annualRatePct: 15,
      );
      expect(exact, closeTo(9025.83, 0.01));
      final EmiQuote q = Emi.quote(principal: 100000, months: 12, annualRatePct: 15);
      expect(q.emi, 9026);
      expect(q.totalPayable, 108310);
      expect(q.totalInterest, 8310);
      expect(q.instalments.length, 12);
      expect(q.instalments.reduce((int a, int b) => a + b), q.totalPayable);
    });

    test('zero interest splits the price exactly', () {
      final EmiQuote q = Emi.quote(principal: 10000, months: 3, annualRatePct: 0);
      expect(q.emi, 3334);
      expect(q.instalments, <int>[3334, 3334, 3332]);
      expect(q.totalPayable, 10000);
      expect(q.totalInterest, 0);
      expect(q.isZeroInterest, isTrue);
    });

    test('instalments always add up to the total', () {
      for (final int p in <int>[7999, 12499, 23450, 99999]) {
        for (final int m in <int>[3, 6, 9, 12, 18, 24]) {
          for (final double r in <double>[0, 12, 15.5, 18]) {
            final EmiQuote q = Emi.quote(principal: p, months: m, annualRatePct: r);
            expect(q.instalments.length, m);
            expect(
              q.instalments.reduce((int a, int b) => a + b),
              q.totalPayable,
              reason: 'p=$p m=$m r=$r',
            );
            expect(q.totalPayable, greaterThanOrEqualTo(p));
          }
        }
      }
    });

    test('rejects a zero tenure', () {
      expect(
        () => Emi.quote(principal: 1000, months: 0, annualRatePct: 10),
        throwsArgumentError,
      );
    });

    test('no principal means no EMI', () {
      final EmiQuote q = Emi.quote(principal: 0, months: 6, annualRatePct: 12);
      expect(q.emi, 0);
      expect(q.totalPayable, 0);
    });

    test('subvention is the interest a lender would have charged', () {
      final int cost = Emi.subventionCost(
        principal: 100000,
        months: 12,
        lenderRatePct: 15,
      );
      expect(cost, 8310);
      expect(
        Emi.subventionCost(principal: 0, months: 6, lenderRatePct: 15),
        0,
      );
    });

    test('addMonths clamps to the end of a shorter month', () {
      expect(Emi.addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(Emi.addMonths(DateTime(2028, 1, 31), 1), DateTime(2028, 2, 29));
      expect(Emi.addMonths(DateTime(2026, 11, 15), 3), DateTime(2027, 2, 15));
      expect(Emi.addMonths(DateTime(2026, 12, 5), 12), DateTime(2027, 12, 5));
    });
  });
}
