import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signOut() => _auth.signOut();

  Future<UserCredential> signInWithGoogle() async {
    try {
      final google = GoogleSignIn.instance;
      await google.initialize();

      final account = await google.authenticate(scopeHint: const ['email', 'profile']);
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(code: 'missing-id-token', message: 'Google ID token manquant');
      }

      final authz = await account.authorizationClient.authorizeScopes(const ['email', 'profile']);
      final accessToken = authz.accessToken;
      if (accessToken.isEmpty) {
        throw FirebaseAuthException(code: 'missing-access-token', message: 'Google access token manquant');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken, accessToken: accessToken);
      return _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      throw FirebaseAuthException(code: 'google-sign-in-failed', message: '${e.code}: ${e.description}');
    }
  }

  Future<void> sendPhoneCode({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException e) onFailure,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: timeout,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _auth.signInWithCredential(credential);
        } catch (_) {
          // Ignore: user can still complete manually with SMS code.
        }
      },
      verificationFailed: (FirebaseAuthException e) => onFailure(e),
      codeSent: (String verificationId, int? resendToken) => onCodeSent(verificationId, resendToken),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<UserCredential> verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> linkPhoneToCurrentUser({
    required String verificationId,
    required String smsCode,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'not-signed-in', message: 'Utilisateur non connectÃ©');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return user.linkWithCredential(credential);
  }
}

