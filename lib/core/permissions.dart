/// Who may do what. This is the single source of truth for the client; the
/// same table is written into the server rules (docs/BACKEND.md), because a
/// button that is hidden is a courtesy and a rule that is enforced is security.
enum AppRole { customer, staff, manager, owner }

enum Permission {
  viewDashboard,
  viewFinancials,
  manageOrders,
  createWalkInSale,
  adjustStock,
  manageCatalog,
  viewCosts,
  editCosts,
  manageLeads,
  manageRepairs,
  manageEmi,
  manageOffers,
  viewCustomers,
  viewReports,
  manageStaff,
  manageSettings,
  issueRefunds,
}

class RolePolicy {
  const RolePolicy._();

  static const Set<Permission> _staff = <Permission>{
    Permission.viewDashboard,
    Permission.manageOrders,
    Permission.createWalkInSale,
    Permission.adjustStock,
    Permission.manageLeads,
    Permission.manageRepairs,
    Permission.viewCustomers,
  };

  static const Set<Permission> _manager = <Permission>{
    ..._staff,
    Permission.manageCatalog,
    Permission.viewCosts,
    Permission.editCosts,
    Permission.manageEmi,
    Permission.manageOffers,
    Permission.viewReports,
  };

  static Set<Permission> of(AppRole role) {
    switch (role) {
      case AppRole.customer:
        return const <Permission>{};
      case AppRole.staff:
        return _staff;
      case AppRole.manager:
        return _manager;
      case AppRole.owner:
        return Permission.values.toSet();
    }
  }

  static bool can(AppRole role, Permission p) => of(role).contains(p);

  static bool isStaff(AppRole role) => role != AppRole.customer;

  /// Roles an owner may hand out. Nobody but an owner creates another owner.
  static const List<AppRole> assignable = <AppRole>[
    AppRole.staff,
    AppRole.manager,
    AppRole.owner,
  ];
}
