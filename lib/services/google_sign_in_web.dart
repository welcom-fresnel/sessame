import 'package:firebase_auth/firebase_auth.dart';

Future<UserCredential> platformSignInWithGoogle(FirebaseAuth auth) async {
  final provider = GoogleAuthProvider();
  provider.addScope('email');
  provider.addScope('profile');

  try {
    return await auth.signInWithPopup(provider);
  } catch (e) {
    // Popup may be blocked by COOP/COEP policies in some environments (see popup.ts console warnings).
    // Fallback to redirect flow which works better when popups are restricted.
    await auth.signInWithRedirect(provider);
    // After redirect the app will reload; try to get the result (may be null until redirect completes).
    final result = await auth.getRedirectResult();
    if (result.credential != null || result.user != null) {
      return result as UserCredential;
    }
    // If no credential is immediately available, throw to let caller handle via authStateChanges.
    throw FirebaseAuthException(code: 'popup-fallback-redirect', message: e.toString());
  }
}
