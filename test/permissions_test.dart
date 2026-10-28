import 'package:brandhoop/core/permissions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a customer can do nothing in the back office', () {
    for (final Permission p in Permission.values) {
      expect(RolePolicy.can(AppRole.customer, p), isFalse, reason: '$p');
    }
  });

  test('the owner can do everything', () {
    for (final Permission p in Permission.values) {
      expect(RolePolicy.can(AppRole.owner, p), isTrue, reason: '$p');
    }
  });

  test('staff work the counter but never see profit, costs or staff pay', () {
    expect(RolePolicy.can(AppRole.staff, Permission.createWalkInSale), isTrue);
    expect(RolePolicy.can(AppRole.staff, Permission.manageOrders), isTrue);
    expect(RolePolicy.can(AppRole.staff, Permission.viewFinancials), isFalse);
    expect(RolePolicy.can(AppRole.staff, Permission.viewCosts), isFalse);
    expect(RolePolicy.can(AppRole.staff, Permission.manageStaff), isFalse);
    expect(RolePolicy.can(AppRole.staff, Permission.manageSettings), isFalse);
    expect(RolePolicy.can(AppRole.staff, Permission.issueRefunds), isFalse);
  });

  test('a manager runs the shop but not the money or the people', () {
    expect(RolePolicy.can(AppRole.manager, Permission.manageCatalog), isTrue);
    expect(RolePolicy.can(AppRole.manager, Permission.manageEmi), isTrue);
    expect(RolePolicy.can(AppRole.manager, Permission.viewCosts), isTrue);
    expect(RolePolicy.can(AppRole.manager, Permission.viewFinancials), isFalse);
    expect(RolePolicy.can(AppRole.manager, Permission.manageStaff), isFalse);
    expect(RolePolicy.can(AppRole.manager, Permission.manageSettings), isFalse);
  });

  test('every role is a superset of the one below it', () {
    expect(
      RolePolicy.of(AppRole.manager).containsAll(RolePolicy.of(AppRole.staff)),
      isTrue,
    );
    expect(
      RolePolicy.of(AppRole.owner).containsAll(RolePolicy.of(AppRole.manager)),
      isTrue,
    );
  });

  test('only staff roles can be assigned', () {
    expect(RolePolicy.assignable, isNot(contains(AppRole.customer)));
  });
}
