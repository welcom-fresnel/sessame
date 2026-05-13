import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // États pour naviguer entre les écrans
  String _currentScreen = 'login'; // login, signup, otp, verify
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _otpController;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = false;
  String _otpCode = '';

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _handleLogin() {
    // Simulation de connexion
    if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
      setState(() => _currentScreen = 'otp');
    }
  }

  void _handleSignup() {
    if (_emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text) {
      setState(() => _currentScreen = 'otp');
    }
  }

  void _handleOtpSubmit() {
    if (_otpCode.length == 4) {
      setState(() => _currentScreen = 'verify');
    }
  }

  void _handleVerify() {
    _navigateToHome();
  }

  void _addOtpDigit(String digit) {
    if (_otpCode.length < 4) {
      setState(() => _otpCode += digit);
    }
  }

  void _removeOtpDigit() {
    if (_otpCode.isNotEmpty) {
      setState(() => _otpCode = _otpCode.substring(0, _otpCode.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F0F0F), Color(0xFF1A1033)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Glow orbs
          Positioned(
            top: -80,
            right: -60,
            child: _GlowOrb(
              size: 220,
              color: const Color(0xFF5B2EFF),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -40,
            child: _GlowOrb(
              size: 260,
              color: const Color(0xFF9B4DFF),
            ),
          ),
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 100,
                  child: Column(
                    children: [
                      // Logo
                      FadeInDown(
                        duration: const Duration(milliseconds: 800),
                        child: const Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: Icon(
                            Icons.rocket_launch_rounded,
                            color: Color(0xFF00D4FF),
                            size: 60,
                          ),
                        ),
                      ),
                      // Contenu dynamique selon l'écran
                      Expanded(
                        child: _buildCurrentScreen(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case 'login':
        return _buildLoginScreen();
      case 'signup':
        return _buildSignupScreen();
      case 'otp':
        return _buildOtpScreen();
      case 'verify':
        return _buildVerifyScreen();
      default:
        return _buildLoginScreen();
    }
  }

  Widget _buildLoginScreen() {
    return FadeIn(
      duration: const Duration(milliseconds: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInUp(
            delay: const Duration(milliseconds: 100),
            child: const Text(
              'Log In',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Email field
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_rounded,
            ),
          ),
          const SizedBox(height: 16),
          // Password field
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: _buildPasswordField(
              controller: _passwordController,
              label: 'Mot de passe',
              obscure: _obscurePassword,
              onToggleObscure: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          const SizedBox(height: 12),
          // Remember me & Forgot password
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() => _rememberMe = value ?? false);
                        },
                        fillColor: WidgetStatePropertyAll(
                          _rememberMe ? const Color(0xFF00D4FF) : Colors.transparent,
                        ),
                        side: const BorderSide(color: Color(0xFF00D4FF)),
                        checkColor: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Se rappeler de moi',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Mot de passe oublier',
                    style: TextStyle(
                      color: Color(0xFF00D4FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Login button
          FadeInUp(
            delay: const Duration(milliseconds: 500),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4FF),
                  foregroundColor: const Color(0xFF0F0F0F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'se connecter',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Or divider
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: const Row(
              children: [
                Expanded(child: Divider(color: Colors.white24)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Or Log in with',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white24)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Social login buttons
          FadeInUp(
            delay: const Duration(milliseconds: 700),
            child: Column(
              children: [
                _buildSocialButton(
                  label: 'Log in with Google',
                  icon: Icons.g_mobiledata,
                  color: const Color(0xFF1F2937),
                ),
                const SizedBox(height: 12),
                _buildSocialButton(
                  label: 'Log in with Facebook',
                  icon: Icons.facebook,
                  color: const Color(0xFF1F2937),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Sign up link
          FadeInUp(
            delay: const Duration(milliseconds: 800),
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() => _currentScreen = 'signup'),
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      TextSpan(
                        text: 'Create Account',
                        style: TextStyle(
                          color: Color(0xFF00D4FF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupScreen() {
    return FadeIn(
      duration: const Duration(milliseconds: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInUp(
            delay: const Duration(milliseconds: 100),
            child: const Text(
              'Create Account',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Email field
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_rounded,
            ),
          ),
          const SizedBox(height: 16),
          // Password field
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: _buildPasswordField(
              controller: _passwordController,
              label: 'Password',
              obscure: _obscurePassword,
              onToggleObscure: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          const SizedBox(height: 16),
          // Confirm Password field
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              obscure: _obscureConfirmPassword,
              onToggleObscure: () {
                setState(() =>
                    _obscureConfirmPassword = !_obscureConfirmPassword);
              },
            ),
          ),
          const SizedBox(height: 16),
          // Terms checkbox
          FadeInUp(
            delay: const Duration(milliseconds: 500),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() => _rememberMe = value ?? false);
                    },
                    fillColor: WidgetStatePropertyAll(
                      _rememberMe ? const Color(0xFF00D4FF) : Colors.transparent,
                    ),
                    side: const BorderSide(color: Color(0xFF00D4FF)),
                    checkColor: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'I agree to the ',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            color: Color(0xFF00D4FF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Sign up button
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _handleSignup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4FF),
                  foregroundColor: const Color(0xFF0F0F0F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Create Account',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Or divider
          FadeInUp(
            delay: const Duration(milliseconds: 700),
            child: const Row(
              children: [
                Expanded(child: Divider(color: Colors.white24)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Or Create with',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white24)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Social signup buttons
          FadeInUp(
            delay: const Duration(milliseconds: 800),
            child: Column(
              children: [
                _buildSocialButton(
                  label: 'Log in with Google',
                  icon: Icons.g_mobiledata,
                  color: const Color(0xFF1F2937),
                ),
                const SizedBox(height: 12),
                _buildSocialButton(
                  label: 'Log in with Facebook',
                  icon: Icons.facebook,
                  color: const Color(0xFF1F2937),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Login link
          FadeInUp(
            delay: const Duration(milliseconds: 900),
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() => _currentScreen = 'login'),
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Do you have an account? ',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      TextSpan(
                        text: 'Log In',
                        style: TextStyle(
                          color: Color(0xFF00D4FF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpScreen() {
    return FadeIn(
      duration: const Duration(milliseconds: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FadeInUp(
            delay: const Duration(milliseconds: 100),
            child: const Text(
              'Enter OTP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'OTP sent to your email address\n${_emailController.text}. Enter the code to proceed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // OTP display boxes
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: index < _otpCode.length
                            ? const Color(0xFF00D4FF)
                            : Colors.white24,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: index < _otpCode.length
                          ? const Color(0xFF00D4FF).withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        index < _otpCode.length ? _otpCode[index] : '',
                        style: const TextStyle(
                          color: Color(0xFF00D4FF),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 40),
          // Continue button
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _otpCode.length == 4 ? _handleOtpSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _otpCode.length == 4
                      ? const Color(0xFF00D4FF)
                      : Colors.grey[700],
                  foregroundColor: const Color(0xFF0F0F0F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Resend link
          FadeInUp(
            delay: const Duration(milliseconds: 500),
            child: TextButton(
              onPressed: () {},
              child: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: "Don't receive the OTP? ",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    TextSpan(
                      text: 'Resend OTP',
                      style: TextStyle(
                        color: Color(0xFF00D4FF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Numeric keypad
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: _buildNumericKeypad(),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyScreen() {
    return FadeIn(
      duration: const Duration(milliseconds: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ZoomIn(
            delay: const Duration(milliseconds: 200),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00D4FF).withValues(alpha: 0.2),
              ),
              child: const Center(
                child: Icon(
                  Icons.check_rounded,
                  color: Color(0xFF00D4FF),
                  size: 50,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: const Text(
              'Verify Your Account',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: Text(
              'Enter the code sent to your number or email to secure your profile and unlock a smarter charging experience.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Verify button
          FadeInUp(
            delay: const Duration(milliseconds: 500),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4FF),
                  foregroundColor: const Color(0xFF0F0F0F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Verify & Continue',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.03),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.5)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggleObscure,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.03),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          prefixIcon: Icon(Icons.lock_rounded,
              color: Colors.white.withValues(alpha: 0.5)),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            onPressed: onToggleObscure,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
        color: color,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumericKeypad() {
    final buttons = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '✕'],
    ];

    return Column(
      children: buttons.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((digit) {
              return GestureDetector(
                onTap: () {
                  if (digit == '✕') {
                    _removeOtpDigit();
                  } else if (digit.isNotEmpty) {
                    _addOtpDigit(digit);
                  }
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: digit.isEmpty
                        ? null
                        : Border.all(
                            color: Colors.white24,
                          ),
                    borderRadius: BorderRadius.circular(12),
                    color: digit.isEmpty
                        ? Colors.transparent
                        : Colors.white.withValues(alpha: 0.05),
                  ),
                  child: Center(
                    child: digit == '✕'
                        ? const Icon(
                            Icons.backspace_rounded,
                            color: Colors.white70,
                            size: 20,
                          )
                        : Text(
                            digit,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
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
