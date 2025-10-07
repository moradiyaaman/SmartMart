# SmartMart AI Contributor Guide

## Architecture snapshot
- Mobile-first Flutter app backed by Firebase; `lib/main.dart` wires `Firebase.initializeApp`, wraps the tree in `MultiProvider`, and delegates navigation to `AuthScreen` via the `AuthWrapper`.
- Authentication flows live in `lib/screens/auth_screen.dart`; after login the app branches to `AdminDashboard` or `CustomerHomeScreen` based on `AdminService().isUserAdmin`.
- Domain models are centralized in `lib/models/app_models.dart` (products, orders, users, addresses). Keep these maps in sync with Firestore field names when adding features.

## Data & services
- Firestore collections expected today: `users`, `products`, `orders`, and per-user carts under `carts/{uid}/items`. Cross-check the richer rule notes in `UPDATED_FIRESTORE_RULES.md` when expanding permissions.
- `lib/services` contains the canonical service layer. `CartService` is a `ChangeNotifier` that must be initialized with the authenticated `User` (handled automatically in `main.dart`); any new cart mutations should call `_firestore.collection('carts').doc(userId).collection('items')` to keep isolation.
- `AdminService` governs admin-only operations (product CRUD, order/user management) and relies on role flags stored in `users.role`. Reuse its helpers instead of hitting Firestore directly.
- Asset uploads default to Firebase Storage; `LocalImageService` offers a fallback that persists files to app documents — prefer it in offline-first flows or when Storage is unavailable.

## UI conventions
- Screens live in `lib/screens/`; they mostly compose smaller helpers from `lib/widgets/custom_widgets.dart`. Reuse `CustomTextField` and `CustomButton` for consistent theming instead of raw `TextFormField` / `ElevatedButton`.
- Admin tooling (product, order, user management) is under the same directory; product cards and editors reference `models.Product` and expect price/stock as numbers.
- Navigation uses plain `Navigator.push` / `pushReplacement`; guard admin routes by re-checking `AdminService.isUserAdmin` when new entry points are added.

## Firebase setup notes
- Keep `lib/firebase_options.dart` in sync with the project credentials. Update both Android (`android/app/google-services.json`) and iOS (`ios/Runner/GoogleService-Info.plist`) artifacts when rotating environments.
- Firestore/Storage rules templates live in `FIREBASE_SETUP.md`, `UPDATED_FIRESTORE_RULES.md`, and `firestore_rules.txt`; mirror those when adjusting security to avoid breaking write paths relied on by services.

## Dev workflows
- Install dependencies with `flutter pub get`; run `flutter analyze` before committing. The repo still ships the default `flutter test` smoke test — extend it when adding logic-heavy components.
- Use the in-project diagnostic screens (`lib/screens/debug_screen.dart`, `test_cart_isolation.dart`) to validate Firebase connectivity or cart isolation without touching production flows.
- For Cloudinary experiments, see `test_cloudinary_auth.dart` and `test_cloudinary_signed.dart`; production code currently prefers Firebase Storage.

## When extending features
- Update both the model (`app_models.dart`) and any Firestore serialization helpers when adding fields; remember to migrate existing documents or add null-safe defaults.
- Surface new user data through the appropriate service (`UserProfileService`, `OrderService`, etc.) rather than embedding Firestore calls inside widgets.
- Keep mobile responsiveness in mind: most screens expect portrait-first layouts, so prefer scrollable columns with breakpoint-aware padding.

## QA checklist
- Validate auth-critical flows (login, admin role detection, cart sync) against a real Firebase project; many services short-circuit or log warnings if configuration is missing.
- Confirm Firestore rules after changes using the snippets in `UPDATED_FIRESTORE_RULES.md`; broken rules manifest as "permission-denied" errors in the existing snackbars.
- Run on at least one physical/virtual device (`flutter run -d <device-id>`) because layout issues often surface only with the on-screen keyboard or tablet widths.
