# QuickMart

QuickMart is a Flutter quick-commerce application for browsing products, managing a private shopping cart, placing demo orders, viewing invoices, and receiving optional order-confirmation emails. The backend is powered by Supabase Auth and Postgres.

> This project is a demo/portfolio application. It is not affiliated with Zepto or any other grocery-delivery brand.

## Contents

- [Product Scope](#product-scope)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Local Setup](#local-setup)
- [Supabase Setup](#supabase-setup)
- [Email Notifications](#email-notifications)
- [Security](#security)
- [Testing and Quality](#testing-and-quality)
- [Android Release](#android-release)
- [Play Store Readiness](#play-store-readiness)
- [Known Limitations](#known-limitations)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Product Scope

### Customer capabilities

- Create an account and sign in with email and password.
- Browse product categories and search products.
- Add products to a user-specific cart.
- Change quantities or remove cart items.
- Choose a demo payment method and address at checkout.
- Place an order and view an itemized invoice.
- Receive an optional order-confirmation email.

### Admin capabilities

- Admin users can open the product-management screen.
- Admin users can add and delete products.
- Product write access is enforced by Supabase Row Level Security, not only by hiding UI controls.

## Tech Stack

| Area | Technology |
| --- | --- |
| Client | Flutter, Dart |
| UI | Material 3, responsive Flutter widgets |
| State | Provider / `ChangeNotifier` |
| Authentication | Supabase Auth, email/password |
| Database | Supabase Postgres |
| Authorization | Postgres Row Level Security policies |
| Serverless | Supabase Edge Functions, Deno/TypeScript |
| Email | EmailJS through the Edge Function |
| Android build | Gradle, Kotlin DSL, compile SDK 36 |
| Supported targets | Android, iOS, Web, Windows, macOS, Linux |

Dependency versions are declared in [`pubspec.yaml`](pubspec.yaml). Platform folders are generated and maintained by Flutter.

## Architecture

```text
Flutter UI
  ├── Screens and reusable widgets
  ├── Provider state management
  ├── Services (Supabase data access)
  └── Models (typed product/cart data)

Supabase
  ├── Auth
  ├── Postgres tables and RLS policies
  └── Edge Function: send-order-confirmation
       └── EmailJS API
```

### Runtime flow

1. `main.dart` initializes Supabase and the root Provider.
2. `AuthGate` listens to Supabase auth state changes.
3. Screens call service classes rather than querying Supabase directly.
4. Services read and write Postgres through the Supabase client.
5. RLS policies enforce ownership and admin permissions at the database boundary.
6. Checkout creates an order and line items, then best-effort invokes the email Edge Function.

### Main modules

- [`lib/main.dart`](lib/main.dart): application bootstrap, theme, and auth gate.
- [`lib/config/supabase_config.dart`](lib/config/supabase_config.dart): Supabase URL and public client key.
- [`lib/models/`](lib/models/): product and cart domain models.
- [`lib/providers/cart_provider.dart`](lib/providers/cart_provider.dart): in-memory cart state and UI notifications.
- [`lib/services/`](lib/services/): authentication, product, cart, and order data access.
- [`lib/screens/`](lib/screens/): auth, home, cart, checkout, invoice, and admin flows.
- [`lib/widgets/product_card.dart`](lib/widgets/product_card.dart): reusable product presentation.
- [`supabase/schema.sql`](supabase/schema.sql): tables, triggers, RLS policies, and seed data.
- [`supabase/functions/send-order-confirmation/index.ts`](supabase/functions/send-order-confirmation/index.ts): authenticated order email function.

## Repository Structure

```text
QuickMart/
├── android/                 # Android application and Gradle configuration
├── ios/                     # iOS application target
├── lib/
│   ├── config/              # Runtime configuration
│   ├── models/              # Domain models
│   ├── providers/           # Shared client state
│   ├── screens/             # Feature screens
│   ├── services/            # Backend access layer
│   └── widgets/             # Reusable UI components
├── supabase/
│   ├── functions/           # Edge Functions
│   └── schema.sql           # Database schema and seed data
├── test/                    # Flutter tests
├── pubspec.yaml             # Dependencies and project metadata
└── README.md
```

## Prerequisites

Install the following before development:

- Flutter SDK compatible with Dart SDK `>=3.0.0 <4.0.0`.
- Android Studio with Android SDK and an emulator, or a physical Android device.
- Android SDK Platform 36 for the current Android plugin requirements.
- Node.js LTS and `npx` for Supabase CLI commands.
- A Supabase project.
- An EmailJS account only if email notifications are required.

Verify the local environment:

```powershell
flutter doctor
node --version
npx supabase --version
```

## Local Setup

### 1. Open the correct directory

The Flutter project root is the directory containing `pubspec.yaml`:

```powershell
cd "D:\Playstore APP\QuickMart"
```

### 2. Configure Supabase client values

Edit [`lib/config/supabase_config.dart`](lib/config/supabase_config.dart):

```dart
class SupabaseConfig {
  static const String url = 'https://your-project-ref.supabase.co';
  static const String anonKey = 'your-publishable-or-anon-public-key';
}
```

Use only the Supabase **Publishable** or legacy **anon public** key. Never put a `service_role` or secret key in the Flutter application.

### 3. Install dependencies and generate platform files

```powershell
flutter pub get
```

If platform folders are missing in a fresh checkout:

```powershell
flutter create .
```

### 4. Run locally

Start an emulator or connect a device, then run:

```powershell
flutter devices
flutter run
```

For web:

```powershell
flutter run -d chrome
```

## Supabase Setup

1. Create a Supabase project.
2. Open **SQL Editor** and run [`supabase/schema.sql`](supabase/schema.sql).
3. Confirm the following tables exist: `profiles`, `products`, `cart_items`, `orders`, and `order_items`.
4. Configure email authentication under **Authentication → Providers → Email**.
5. Copy the project URL and public client key into `supabase_config.dart`.

The schema creates a trigger that automatically creates a `profiles` row when a user signs up. It also enables RLS policies for user-owned carts/orders and admin-only product writes.

### Create an admin user

After signing up, run this in Supabase SQL Editor:

```sql
update profiles
set is_admin = true
where email = 'your-email@example.com';
```

Log out and back in after changing the flag.

### Add seed products to an existing database

The complete schema includes starter products and additional Chocolates, Electronics, and Juices products. If the base schema was already run, execute only the additional product insert block, not the entire schema again.

## Email Notifications

Order confirmation email is optional. The Flutter client creates the order first, then invokes the Supabase Edge Function [`send-order-confirmation`](supabase/functions/send-order-confirmation/index.ts). The function validates the authenticated user and order ownership before calling EmailJS.

### EmailJS template

Create an EmailJS service and template with these fields:

```text
To Email:  {{to_email}}
From Name: QuickMart
Subject:  QuickMart order #{{order_id}} confirmed
```

Use these template variables in the message:

```text
{{to_email}}
{{order_id}}
{{order_items}}
{{order_total}}
```

Enable EmailJS API access for non-browser applications under the EmailJS security settings.

### Deploy the Edge Function

From the project root:

```powershell
npx supabase login
npx supabase link --project-ref YOUR_PROJECT_REF
npx supabase secrets set EMAILJS_SERVICE_ID=service_xxxxx EMAILJS_TEMPLATE_ID=template_xxxxx EMAILJS_PUBLIC_KEY=your_public_key
npx supabase functions deploy send-order-confirmation
```

If your EmailJS account requires a private key, set it as a Supabase secret:

```powershell
npx supabase secrets set EMAILJS_PRIVATE_KEY=your_private_key
```

The project reference is the subdomain only. For `https://abcxyz.supabase.co`, use `abcxyz`.

Do not store EmailJS private credentials or Supabase service-role keys in Flutter, Git, or the repository.

## Security

- The mobile app contains only the Supabase public client key.
- RLS limits cart and order access to the authenticated owner.
- Product insertion and deletion require `profiles.is_admin = true`.
- The Edge Function verifies the bearer token and checks that the order belongs to the requesting user.
- EmailJS and service-role credentials are stored as Supabase secrets.
- Product names are HTML-escaped before being inserted into the email body.
- HTTPS is used for Supabase and EmailJS requests.

Before production, review the schema with a security-focused database migration process and avoid granting broad policies without a specific ownership rule.

## Testing and Quality

Run these checks before opening a release candidate:

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

Manually verify:

- New account creation and email confirmation behavior.
- Login, logout, and session restoration.
- Product loading, search, category filtering, and image fallbacks.
- Cart isolation between two users.
- Quantity changes, deletion, and checkout navigation.
- Invoice creation and order ownership.
- Admin-only product creation/deletion.
- Email confirmation delivery and failure behavior.
- Offline, denied-network, empty-data, and expired-session states.

For email troubleshooting, inspect Android Studio Logcat for `Order confirmation response` or `Order confirmation email failed`, then inspect the Edge Function logs in the Supabase Dashboard.

## Android Release

### Application identity

Before publishing, replace the generated application ID `com.example.QuickMart` with a unique reverse-domain ID, such as:

```text
com.yourcompany.quickmart
```

Update the namespace, application ID, Kotlin package, app label, and launcher icon consistently. Do not use another company's brand, logo, or package identity.

### Signing

Create a protected upload keystore:

```powershell
keytool -genkeypair -v -keystore "$env:USERPROFILE\upload-keystore.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Configure release signing using `android/key.properties` and the Android Gradle configuration. Add `android/key.properties` and all keystore files to `.gitignore`. Back up the keystore and passwords securely.

The generated Flutter project currently uses debug signing for release builds. Replace that configuration before any production build.

### Build an App Bundle

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

The Play Store bundle is generated at:

```text
build\app\outputs\bundle\release\app-release.aab
```

## Play Store Readiness

Before uploading to Google Play Console:

- Create a Google Play Developer account and complete verification.
- Use a unique package ID and production app name.
- Add a privacy policy URL.
- Complete the Data Safety, content rating, target audience, ads, and app-access declarations.
- Provide a reviewer test account because the app requires login.
- Add account deletion functionality or a compliant deletion workflow.
- Test release builds on supported Android versions and screen sizes.
- Upload screenshots, app icon, feature graphic, descriptions, and support contact details.
- Start with internal or closed testing before production rollout.
- Confirm Supabase billing, quotas, backups, and project activity expectations.
- Confirm email sender verification and notification deliverability.

## Known Limitations

- Checkout records an order but does not process real payments.
- Delivery timing is a demo countdown, not live fulfillment tracking.
- Product categories are currently inferred from product names rather than a dedicated `category` column.
- Product images are remote URLs and require network access.
- The default app does not yet include account deletion or a complete privacy-policy workflow.
- The generated Android release configuration must be replaced with production signing before publishing.
- Email delivery is best-effort after order creation; an email-provider failure does not roll back the order.

## Troubleshooting

### Gradle requires a newer compile SDK

Install Android SDK Platform 36 and confirm [`android/app/build.gradle.kts`](android/app/build.gradle.kts) contains:

```kotlin
compileSdk = 36
```

Then run:

```powershell
flutter clean
flutter pub get
flutter run
```

### Supabase CLI is not recognized

Install Node.js LTS, then use:

```powershell
npx supabase login
```

### Supabase project reference error

Pass only the project reference, not the full URL:

```powershell
npx supabase link --project-ref qdqlmtvpffflenvkstwe
```

### Email is not sent

Check EmailJS API access, template variables, service/template IDs, Supabase secrets, and Edge Function logs. The Flutter client logs the function response but intentionally does not fail the completed order when notification delivery fails.

## Contributing

1. Create a focused branch for each change.
2. Keep UI, service, model, and database responsibilities separated.
3. Do not commit secrets, keystores, generated credentials, or personal Supabase URLs where avoidable.
4. Run `flutter analyze` and `flutter test` before submitting changes.
5. Document database migrations and release-impacting changes.

## License

No license has been declared for this repository. Add an explicit license before distributing the project publicly or accepting external contributions.
