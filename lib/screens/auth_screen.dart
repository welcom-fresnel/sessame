import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/user_profile_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.initialTabIndex = 0});

  /// 0 = Inscription, 1 = Connexion
  final int initialTabIndex;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _profileService = UserProfileService();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthYearController = TextEditingController();
  final _phoneController = TextEditingController();
  final _smsController = TextEditingController();

  bool _isLoading = false;
  bool _codeSent = false;
  bool _googleSignedIn = false;
  String _verificationId = '';
  String? _error;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthYearController.dispose();
    _phoneController.dispose();
    _smsController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final birthYearStr = _birthYearController.text.trim();
    final phone = _phoneController.text.trim();

    final birthYear = int.tryParse(birthYearStr);
    final currentYear = DateTime.now().year;

    if (firstName.isEmpty || lastName.isEmpty) {
      setState(() => _error = 'Renseigne ton nom et prénom.');
      return false;
    }
    if (birthYear == null || birthYear < 1900 || birthYear > currentYear) {
      setState(() => _error = "AnnÃ©e de naissance invalide.");
      return false;
    }
    if (phone.isEmpty || !phone.startsWith('+')) {
      setState(() => _error = 'NumÃ©ro invalide (format: +33612345678).');
      return false;
    }
    return true;
  }

  bool _validateLoginPhoneOnly() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || !phone.startsWith('+')) {
      setState(() => _error = 'Numéro invalide (format: +33612345678).');
      return false;
    }
    return true;
  }

  Future<void> _sendCode() async {
    final isSignup = _tabController.index == 0;
    if (isSignup) {
      if (!_validateForm()) return;
    } else {
      if (!_validateLoginPhoneOnly()) return;
    }
    final phone = _phoneController.text.trim();

    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      await _auth.sendPhoneCode(
        phoneNumber: phone,
        onCodeSent: (verificationId, _) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
          });
        },
        onFailure: (e) {
          if (!mounted) return;
          setState(() {
            _error = _humanizeFirebaseAuthError(e);
          });
        },
      );
    } catch (e) {
      setState(() => _error = 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _humanizeFirebaseAuthError(FirebaseAuthException e) {
    final code = (e.code).toLowerCase();
    final message = (e.message ?? '').toLowerCase();

    if (code == 'google-sign-in-failed') {
      if (message.contains('canceled') || message.contains('cancelled')) {
        return "Connexion Google annulÃ©e. VÃ©rifie que le tÃ©lÃ©phone a un compte Google connectÃ© (ParamÃ¨tres â†’ Comptes) et que Google Play services / Play Store sont Ã  jour, puis rÃ©essaie.";
      }
      if (message.contains('developer_error') || message.contains('api exception: 10')) {
        return "Google Sign-In refusÃ© (DEVELOPER_ERROR). Ã‡a arrive quand le SHA-1/SHA-256 ne correspond pas Ã  l'APK installÃ© ou que le packageName n'est pas le bon dans Firebase. Re-vÃ©rifie les empreintes et le package `com.example.sessame`.";
      }
      return e.message ?? "Erreur Google Sign-In.";
    }

    if (code.contains('billing') || message.contains('billing_not_enabled')) {
      return "Firebase Phone Auth est bloquÃ©: Billing non activÃ© (reCAPTCHA/Play Integrity). Active la facturation sur le projet Google Cloud liÃ© Ã  Firebase, puis configure reCAPTCHA Enterprise pour l'auth tÃ©lÃ©phone. (Tu peux aussi utiliser des numÃ©ros de test en attendant.)";
    }

    if (code == 'invalid-phone-number') {
      return 'NumÃ©ro invalide. Utilise le format international, ex: +33612345678.';
    }

    if (code == 'too-many-requests') {
      return "Trop d'essais. Attends un peu puis rÃ©essaie.";
    }

    if (code == 'network-request-failed') {
      return 'ProblÃ¨me rÃ©seau. VÃ©rifie internet puis rÃ©essaie.';
    }

    return e.message ?? "Erreur lors de l'envoi du code.";
  }

  Future<void> _verifyCode() async {
    final code = _smsController.text.trim();
    if (code.length < 4) {
      setState(() => _error = 'Entre le code SMS');
      return;
    }
    if (_verificationId.isEmpty) {
      setState(() => _error = 'VerificationId manquant, renvoie le code.');
      return;
    }

    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      if (_googleSignedIn) {
        await _auth.linkPhoneToCurrentUser(
          verificationId: _verificationId,
          smsCode: code,
        );
      } else {
        await _auth.verifySmsCode(verificationId: _verificationId, smsCode: code);
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final isSignup = _tabController.index == 0;
        if (isSignup) {
          final firstName = _firstNameController.text.trim();
          final lastName = _lastNameController.text.trim();
          final birthYear = int.parse(_birthYearController.text.trim());
          final phoneNumber = user.phoneNumber ?? _phoneController.text.trim();
          await _profileService.upsertProfile(
            uid: user.uid,
            firstName: firstName,
            lastName: lastName,
            birthYear: birthYear,
            phoneNumber: phoneNumber,
            email: user.email,
            displayName: user.displayName,
          );
        }
      }
      // AuthGate prendra le relais via authStateChanges.
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _humanizeFirebaseAuthError(e));
    } catch (e) {
      setState(() => _error = 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _backToPhone() {
    setState(() {
      _codeSent = false;
      _verificationId = '';
      _smsController.clear();
      _error = null;
    });
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      await _auth.signInWithGoogle();
      if (!mounted) return;
      setState(() {
        _googleSignedIn = true;
      });

      // Phone is mandatory: after Google sign-in we still ask for SMS verification and link it.
      if (_validateForm()) {
        await _sendCode();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _humanizeFirebaseAuthError(e));
    } catch (e) {
      setState(() => _error = 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F0F0F), Color(0xFF1A1033)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: _GlowOrb(size: 220, color: const Color(0xFF5B2EFF)),
          ),
          Positioned(
            bottom: -100,
            left: -40,
            child: _GlowOrb(size: 260, color: const Color(0xFF9B4DFF)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Icon(
                          Icons.rocket_launch_rounded,
                          color: Color(0xFF00D4FF),
                          size: 56,
                        ),
                      ),
                    ),
                    FadeInUp(
                      delay: const Duration(milliseconds: 100),
                      child: Text(
                        _codeSent ? 'Vérification' : (_tabController.index == 0 ? 'Inscription' : 'Connexion'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        _codeSent
                            ? 'Entre le code reçu par SMS.'
                            : (_tabController.index == 0
                                ? 'Renseigne tes infos puis valide ton numéro (obligatoire).'
                                : 'Connecte-toi avec Google ou ton numéro.'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (!_codeSent) ...[
                      const SizedBox(height: 18),
                      TabBar(
                        controller: _tabController,
                        indicatorColor: const Color(0xFF00D4FF),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        onTap: (_) => setState(() => _error = null),
                        tabs: const [
                          Tab(text: 'Inscription'),
                          Tab(text: 'Connexion'),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (_error != null) ...[
                      FadeIn(
                        duration: const Duration(milliseconds: 250),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FadeInUp(
                      delay: const Duration(milliseconds: 250),
                      child: _codeSent
                          ? _buildSmsInput()
                          : (_tabController.index == 0 ? _buildSignupForm() : _buildLoginForm()),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : (_codeSent ? _verifyCode : _sendCode),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1A1033),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  _codeSent ? 'Valider le code' : 'Envoyer le code',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                        ),
                      ),
                    ),
                    if (!_codeSent) ...[
                      const SizedBox(height: 12),
                      FadeInUp(
                        delay: const Duration(milliseconds: 340),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _signInWithGoogle,
                            icon: const Icon(Icons.g_mobiledata_rounded, color: Color(0xFF00D4FF)),
                            label: const Text(
                              'Continuer avec Google',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (_codeSent) ...[
                      const SizedBox(height: 10),
                      FadeInUp(
                        delay: const Duration(milliseconds: 350),
                        child: TextButton(
                          onPressed: _isLoading ? null : _backToPhone,
                          child: const Text(
                            'Changer de numéro',
                            style: TextStyle(color: Color(0xFF00D4FF)),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FadeInUp(
                      delay: const Duration(milliseconds: 450),
                      child: Text(
                        'En continuant, tu acceptes notre Politique de confidentialité.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _firstNameController,
          label: 'Prénom',
          icon: Icons.person_rounded,
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _lastNameController,
          label: 'Nom',
          icon: Icons.badge_rounded,
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _birthYearController,
          label: 'Année de naissance (ex: 2001)',
          icon: Icons.cake_rounded,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _phoneController,
          label: 'Téléphone (ex: +242612345678)',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _phoneController,
          label: 'Téléphone (ex: +33612345678)',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildSmsInput() {
    return _buildTextField(
      controller: _smsController,
      label: 'Code SMS',
      icon: Icons.sms_rounded,
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
        prefixIcon: Icon(icon, color: const Color(0xFF00D4FF)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF00D4FF)),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.5),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
