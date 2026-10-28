# Roles and permissions

One app. The signed-in user's role decides the screens. The rules are in
`lib/core/permissions.dart`; services re-check them, so a hidden button is not
the only guard.

| Permission | Customer | Staff | Manager | Owner |
|---|:-:|:-:|:-:|:-:|
| Shop, cart, checkout, own orders, EMI, repairs | yes | yes | yes | yes |
| Dashboard (sales, orders, stock alerts) | | yes | yes | yes |
| Manage orders, counter sale (POS), adjust stock | | yes | yes | yes |
| Leads, repairs desk, view customers | | yes | yes | yes |
| Manage catalogue, see and edit costs | | | yes | yes |
| EMI desk: approve or decline applications, mark lender paid | | | yes | yes |
| Offers and coupons, reports and CSV export | | | yes | yes |
| Profit and the road to ₹5 lakh | | | | yes |
| Staff and roles, store settings, refunds | | | | yes |

Limits worth knowing:

- Staff discounts at the counter are capped at 5% of the bill.
- A user who is deactivated cannot sign in.
- Staff can flip to **customer mode** to test the shop as a buyer would see it.
- Delivery of a phone needs its IMEI first.
- Bajaj approval is the lender's decision. The EMI desk records it; it does
  not make it.

Changing a role is an owner action (Admin, More, Staff). With a backend, role
changes must be done by a Cloud Function that sets a custom claim, never by
the client (`docs/BACKEND.md`).
