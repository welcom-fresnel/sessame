import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = AuthService();

  final _phoneController = TextEditingController();
  final _smsController = TextEditingController();

  bool _isLoading = false;
  bool _codeSent = false;
  String _verificationId = '';
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _smsController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || !phone.startsWith('+')) {
      setState(() => _error = 'Entre un numéro au format international, ex: +33612345678');
      return;
    }

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
            _error = e.message ?? 'Erreur lors de l’envoi du code';
          });
        },
      );
    } catch (e) {
      setState(() => _error = 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      await _auth.verifySmsCode(verificationId: _verificationId, smsCode: code);
      // AuthGate prendra le relais via authStateChanges.
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Code invalide');
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
                        _codeSent ? 'Vérification' : 'Connexion',
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
                            : 'Ton numéro de téléphone est requis pour créer ton compte.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ),
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
                      child: _codeSent ? _buildSmsInput() : _buildPhoneInput(),
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

  Widget _buildPhoneInput() {
    return _buildTextField(
      controller: _phoneController,
      label: 'Téléphone (ex: +33612345678)',
      icon: Icons.phone_rounded,
      keyboardType: TextInputType.phone,
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

