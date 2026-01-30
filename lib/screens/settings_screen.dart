import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
            title: 'Développé avec',
            subtitle: 'Flutter & ❤️',
            onTap: null,
          ),
        ],
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

