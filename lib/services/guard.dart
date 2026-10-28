import '../core/permissions.dart';
import '../domain/app_user.dart';

class PermissionDenied implements Exception {
  PermissionDenied(this.permission);
  final Permission permission;
  @override
  String toString() => 'PermissionDenied($permission)';
}

/// Defence in depth. The screens hide what a role may not do, the services
/// refuse it, and the server rules (docs/BACKEND.md) are the last word.
void requirePermission(AppUser? actor, Permission p) {
  if (actor == null || !actor.can(p)) throw PermissionDenied(p);
}

/// A problem the person can fix, carried to the screen as a message key.
class ShopException implements Exception {
  ShopException(this.code, [this.detail = '']);
  final String code;
  final String detail;
  @override
  String toString() => 'ShopException($code${detail.isEmpty ? '' : ': $detail'})';
}
