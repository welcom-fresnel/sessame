import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();

  String _gender = 'Non precise';
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('profile_name') ?? '';
      _ageController.text = prefs.getString('profile_age') ?? '';
      _addressController.text = prefs.getString('profile_address') ?? '';
      _gender = prefs.getString('profile_gender') ?? 'Non precise';
      _isLoadingProfile = false;
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', _nameController.text.trim());
    await prefs.setString('profile_age', _ageController.text.trim());
    await prefs.setString('profile_address', _addressController.text.trim());
    await prefs.setString('profile_gender', _gender);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil enregistre')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Paramètres',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section Profil
          _buildSectionHeader('Profil'),
          const SizedBox(height: 8),
          _buildProfileCard(context),
          const SizedBox(height: 24),

          // Section Apparence
          _buildSectionHeader('Apparence'),
          const SizedBox(height: 8),
          _buildSettingTile(
            context,
            icon: Icons.dark_mode_rounded,
            title: 'Mode sombre',
            subtitle: isDark ? 'Activé' : 'Désactivé',
            trailing: Switch(
              value: isDark,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
              activeColor: Colors.deepPurpleAccent,
            ),
          ),
          const SizedBox(height: 24),

          // Section À propos
          _buildSectionHeader('À propos'),
          const SizedBox(height: 8),
          _buildSettingTile(
            context,
            icon: Icons.info_rounded,
            title: 'Version',
            subtitle: '1.0.0',
            onTap: null,
          ),
          _buildSettingTile(
            context,
            icon: Icons.code_rounded,
            title: 'Développé par welcom Engondzi',
            subtitle: '🫰🫰🫰',
            onTap: null,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoadingProfile
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      prefixIcon: Icon(Icons.cake_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    items: const [
                      DropdownMenuItem(value: 'Non precise', child: Text('Non precise')),
                      DropdownMenuItem(value: 'Homme', child: Text('Homme')),
                      DropdownMenuItem(value: 'Femme', child: Text('Femme')),
                      DropdownMenuItem(value: 'Autre', child: Text('Autre')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _gender = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Sexe',
                      prefixIcon: Icon(Icons.wc_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Adresse',
                      prefixIcon: Icon(Icons.home_rounded),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Enregistrer'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.deepPurpleAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.grey[100],
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.deepPurpleAccent, size: 20),
        ),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

