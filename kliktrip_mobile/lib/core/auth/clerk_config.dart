/// Publishable key Clerk — sama dengan web app (kliktrip-premium).
/// Bisa dioverride saat build tanpa mengubah kode:
///   flutter run --dart-define=CLERK_PUBLISHABLE_KEY=pk_live_xxx
const String clerkPublishableKey = String.fromEnvironment(
  'CLERK_PUBLISHABLE_KEY',
  defaultValue: 'pk_test_ZmlybS1zZWFzbmFpbC03Ny5jbGVyay5hY2NvdW50cy5kZXYk',
);

/// URL CDN clerk-js (dipakai hanya di build web).
const String clerkJsCdn =
    'https://unpkg.com/@clerk/clerk-js@5/dist/clerk.browser.js';
