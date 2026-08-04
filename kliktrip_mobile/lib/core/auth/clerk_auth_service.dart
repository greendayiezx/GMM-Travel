// Facade ClerkAuthService — memilih implementasi sesuai platform:
//  - Web            → clerk_auth_service_web.dart (clerk-js via JS interop)
//  - Mobile/desktop → clerk_auth_service_io.dart (SDK Dart `clerk_auth`)
//
// Keduanya mengekspos API publik yang sama sehingga kode UI tak perlu tahu
// platformnya: initialize, isSignedIn, getToken, signIn, signUp,
// verifyEmailCode, signInWithGoogle, signInWithApple, signOut, displayName,
// email, avatarUrl, dan getter global `clerkAuth`.
export 'clerk_auth_service_web.dart'
    if (dart.library.io) 'clerk_auth_service_io.dart';
