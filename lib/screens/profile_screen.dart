import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/user_profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = UserProfileService();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthYearController = TextEditingController();
  final _phoneController = TextEditingController();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _success;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthYearController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = _user;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'Utilisateur non connecté';
      });
      return;
    }

    try {
      final profile = await _profileService.getProfile(user.uid);
      _firstNameController.text = (profile?['firstName'] ?? '').toString();
      _lastNameController.text = (profile?['lastName'] ?? '').toString();
      final birthYear = profile?['birthYear'];
      _birthYearController.text = (birthYear is num) ? birthYear.toInt().toString() : '';
      _phoneController.text = (profile?['phoneNumber'] ?? '').toString();
      _emailController.text = (user.email ?? '');
    } catch (e) {
      _error = 'Erreur chargement profil: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    final user = _user;
    if (user == null) return;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final birthYear = int.tryParse(_birthYearController.text.trim());
    final phoneNumber = _phoneController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || birthYear == null) {
      setState(() => _error = 'Complète prénom/nom/année de naissance.');
      return;
    }
    if (phoneNumber.isNotEmpty && !phoneNumber.startsWith('+')) {
      setState(() => _error = 'Le numéro doit être au format international, ex: +33612345678.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });

    try {
      await _profileService.upsertProfile(
        uid: user.uid,
        firstName: firstName,
        lastName: lastName,
        birthYear: birthYear,
        phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
        email: user.email,
        displayName: user.displayName,
      );
      setState(() => _success = 'Profil mis à jour');
    } catch (e) {
      setState(() => _error = 'Erreur sauvegarde: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _linkEmailPassword() async {
    final user = _user;
    if (user == null) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || !email.contains('@') || password.length < 6) {
      setState(() => _error = 'Email invalide ou mot de passe trop court (min 6).');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });

    try {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      await user.linkWithCredential(credential);
      setState(() => _success = 'Mot de passe ajouté au compte');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Erreur Firebase');
    } catch (e) {
      setState(() => _error = 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  _Banner(text: _error!, color: Colors.red.withValues(alpha: 0.15)),
                if (_success != null)
                  _Banner(text: _success!, color: Colors.green.withValues(alpha: 0.15)),
                const SizedBox(height: 8),
                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'Prénom'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _birthYearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Année de naissance'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone (optionnel)',
                    hintText: '+33612345678',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveProfile,
                    child: const Text('Enregistrer le profil'),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Ajouter un mot de passe (optionnel)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mot de passe (min 6)'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _saving ? null : _linkEmailPassword,
                    child: const Text('Ajouter un mot de passe'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text),
    );
  }
}
