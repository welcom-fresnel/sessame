import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<UserCredential> platformSignInWithGoogle(FirebaseAuth auth) async {
  final google = GoogleSignIn(scopes: const ['email', 'profile']);
  final account = await google.signIn();
  if (account == null) {
    throw FirebaseAuthException(code: 'google-sign-in-cancelled', message: 'Connexion Google annulée par l\'utilisateur');
  }
  final authDetails = await account.authentication;
  final idToken = authDetails.idToken;
  final accessToken = authDetails.accessToken;
  if (idToken == null || idToken.isEmpty) {
    throw FirebaseAuthException(code: 'missing-id-token', message: 'Google ID token manquant');
  }
  if (accessToken == null || accessToken.isEmpty) {
    throw FirebaseAuthException(code: 'missing-access-token', message: 'Google access token manquant');
  }
  final credential = GoogleAuthProvider.credential(idToken: idToken, accessToken: accessToken);
  return await auth.signInWithCredential(credential);
}
