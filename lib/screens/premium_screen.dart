import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/premium_provider.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  String? _selectedPaymentMethod;
  bool _isProcessingPayment = false;

  Future<void> _simulatePayment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez MTN Money ou Airtel Money')),
      );
      return;
    }

    setState(() => _isProcessingPayment = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    await context.read<PremiumProvider>().activatePremiumForTesting();
    if (!mounted) return;

    setState(() => _isProcessingPayment = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Paiement simulé via $_selectedPaymentMethod. Premium activé.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final premiumProvider = context.watch<PremiumProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text(
          'Asala Premium',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _buildHeroCard(premiumProvider.isPremium),
          const SizedBox(height: 24),
          if (!premiumProvider.isPremium) ...[
            const Text(
              'Choisissez votre mode de paiement',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildPaymentMethodCard(
              method: 'MTN Money',
              icon: Icons.phone_android_rounded,
              color: Colors.amberAccent,
            ),
            _buildPaymentMethodCard(
              method: 'Airtel Money',
              icon: Icons.account_balance_wallet_rounded,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessingPayment ? null : _simulatePayment,
                icon: _isProcessingPayment
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_open_rounded),
                label: Text(
                  _isProcessingPayment
                      ? 'Paiement en cours...'
                      : 'Payer 650 XAF et accéder au Premium',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.amberAccent.withValues(alpha: 0.35),
                  disabledForegroundColor: Colors.black54,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_rounded, color: Colors.greenAccent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Votre accès Premium est actif. Toutes les fonctionnalités avancées sont disponibles.',
                      style: TextStyle(color: Colors.white, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          const Text(
            'Fonctionnalités incluses',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildPremiumFeature(
            icon: Icons.all_inclusive_rounded,
            title: 'Projets illimités',
            subtitle: 'Créez autant de projets que nécessaire sans blocage.',
          ),
          _buildPremiumFeature(
            icon: Icons.psychology_rounded,
            title: 'Coach IA détaillé',
            subtitle: 'Recevez des étapes repliables avec des instructions concrètes pour chaque action.',
          ),
          _buildPremiumFeature(
            icon: Icons.notifications_active_rounded,
            title: 'Rappels intelligents avancés',
            subtitle: 'Planifiez des rappels selon la deadline, le retard et l’inactivité du projet.',
          ),
          _buildPremiumFeature(
            icon: Icons.query_stats_rounded,
            title: 'Statistiques avancées',
            subtitle: 'Suivez le taux de réussite, les projets à risque, l’évolution mensuelle et les catégories les plus productives.',
          ),
          _buildPremiumFeature(
            icon: Icons.file_download_rounded,
            title: 'Export PDF et Excel',
            subtitle: 'Exportez vos projets, tâches, statistiques et rapports mensuels.',
          ),
          _buildPremiumFeature(
            icon: Icons.palette_rounded,
            title: 'Thèmes Premium',
            subtitle: 'Débloquez des thèmes Focus, AMOLED, Productivité et des couleurs personnalisées.',
          ),
          _buildPremiumFeature(
            icon: Icons.auto_awesome_rounded,
            title: 'Assistant IA avancé',
            subtitle: 'Générez des plans de projet, analysez les blocages et priorisez automatiquement les tâches.',
          ),
          _buildPremiumFeature(
            icon: Icons.backup_rounded,
            title: 'Sauvegarde cloud améliorée',
            subtitle: 'Préparez la synchronisation multi-appareils, l’historique et la restauration.',
          ),
          _buildPremiumFeature(
            icon: Icons.dashboard_customize_rounded,
            title: 'Modèles de projets',
            subtitle: 'Démarrez plus vite avec des modèles Business, Études, Application mobile, Marketing et Objectif personnel.',
          ),
          _buildPremiumFeature(
            icon: Icons.image_rounded,
            title: 'Personnalisation projet',
            subtitle: 'Ajoutez couvertures, images, icônes de catégorie et couleurs par projet.',
          ),
          if (premiumProvider.isPremium) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () async {
                await context.read<PremiumProvider>().deactivatePremiumForTesting();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Premium désactivé en mode test')),
                );
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Désactiver le mode test'),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroCard(bool isPremium) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurpleAccent.withValues(alpha: 0.25),
            Colors.amberAccent.withValues(alpha: 0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.amberAccent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Débloquez tout le potentiel de Asala',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            isPremium ? 'Premium activé' : '650 XAF',
            style: TextStyle(
              color: isPremium ? Colors.greenAccent : Colors.amberAccent,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPremium
                ? 'Merci pour votre soutien'
                : 'Paiement simulé pour la version beta',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required String method,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedPaymentMethod == method;

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                method,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? color : Colors.white38,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeature({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.deepPurpleAccent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.deepPurpleAccent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
