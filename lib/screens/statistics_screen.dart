import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/premium_provider.dart';
import '../providers/project_provider.dart';
import '../widgets/gamification_card.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, int>? _stats;

  int _statValue(String key) => _stats?[key] ?? 0;

  Future<void> _exportCsv() async {
    final premiumProvider = context.read<PremiumProvider>();
    if (!premiumProvider.isPremium) {
      _showPremiumRequiredMessage('L’export CSV est réservé aux utilisateurs Premium.');
      return;
    }

    final projects = context.read<ProjectProvider>().projects;
    final buffer = StringBuffer();
    buffer.writeln('Titre;Statut;Catégorie;Progression;Date création;Deadline;En retard');
    for (final project in projects) {
      buffer.writeln([
        _csvCell(project.title),
        _csvCell(project.status),
        _csvCell(project.category ?? 'Non classé'),
        '${(project.progress * 100).toStringAsFixed(0)}%',
        _formatDate(project.createdAt),
        _formatDate(project.deadline),
        project.isOverdue ? 'Oui' : 'Non',
      ].join(';'));
    }

    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('L’export CSV est désactivé dans le navigateur. Utilise la version mobile/desktop pour télécharger un fichier.')),
        );
      }
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/sesame_stats_export.csv');
    await file.writeAsString(buffer.toString());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export CSV enregistré : ${file.path}')),
    );
  }

  String _csvCell(String value) {
    return '"${value.replaceAll('"', '""')}"';
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  void _showPremiumRequiredMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await context.read<ProjectProvider>().getStatistics();
    setState(() {
      _stats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text(
          'Statistiques',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _stats == null
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(
                    child: const Text(
                      'Tes Performances',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildStatCard(
                        'TOTAL',
                        _statValue('total'),
                        Icons.folder_rounded,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'EN COURS',
                        _statValue('en_cours'),
                        Icons.rocket_launch_rounded,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'TERMINÉS',
                        _statValue('terminés'),
                        Icons.check_circle_rounded,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'EN RETARD',
                        _statValue('en_retard'),
                        Icons.warning_rounded,
                        Colors.red,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const GamificationCard(),
                  const SizedBox(height: 40),

                  if (_statValue('total') > 0) ...[
                    FadeInUp(
                      child: _buildGlassContainer(
                        title: 'RÉPARTITION',
                        child: Column(
                          children: [
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 50,
                                  sections: _buildPieChartSections(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildLegend(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: _buildSuccessRateCard(),
                    ),
                    const SizedBox(height: 24),
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: _buildPremiumAdvancedStats(),
                    ),
                    const SizedBox(height: 24),
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: _buildExportCard(),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return FadeIn(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassContainer({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final total = _statValue('total').toDouble();
    if (total == 0) return [];

    final enCours = _statValue('en_cours').toDouble();
    final termines = _statValue('terminés').toDouble();
    final abandonnes = _statValue('abandonnés').toDouble();

    return [
      if (enCours > 0)
        PieChartSectionData(
          value: enCours,
          title: '${((enCours / total) * 100).toInt()}%',
          color: Colors.orange,
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      if (termines > 0)
        PieChartSectionData(
          value: termines,
          title: '${((termines / total) * 100).toInt()}%',
          color: Colors.green,
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      if (abandonnes > 0)
        PieChartSectionData(
          value: abandonnes,
          title: '${((abandonnes / total) * 100).toInt()}%',
          color: Colors.grey,
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
    ];
  }

  Widget _buildLegend() {
    return Column(
      children: [
        if (_statValue('en_cours') > 0)
          _buildLegendItem('En cours', Colors.orange, _statValue('en_cours')),
        if (_statValue('terminés') > 0)
          _buildLegendItem('Terminés', Colors.green, _statValue('terminés')),
        if (_statValue('abandonnés') > 0)
          _buildLegendItem('Abandonnés', Colors.grey, _statValue('abandonnés')),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(
            '$label: $count',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessRateCard() {
    final completed = _statValue('terminés');
    final total = _statValue('total');
    final rate = total > 0 ? (completed / total * 100).toInt() : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurpleAccent.withValues(alpha: 0.2),
            Colors.purple.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.deepPurpleAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TAUX DE RÉUSSITE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$rate%',
                style: const TextStyle(
                  color: Colors.deepPurpleAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: rate / 100,
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.deepPurpleAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumAdvancedStats() {
    final isPremium = context.watch<PremiumProvider>().isPremium;
    final projects = context.watch<ProjectProvider>().projects;
    final averageProgress = projects.isEmpty
        ? 0
        : (projects.fold<double>(0, (sum, project) => sum + project.progress) /
                projects.length *
                100)
            .round();
    final riskProjects = projects
        .where((project) => project.status == 'en_cours' && project.isOverdue)
        .length;
    final activeCategories = projects
        .map((project) => project.category ?? 'Non classé')
        .toSet()
        .length;

    return _buildGlassContainer(
      title: 'STATISTIQUES PREMIUM',
      child: isPremium
          ? Column(
              children: [
                _buildAdvancedStatRow(
                  icon: Icons.trending_up_rounded,
                  label: 'Progression moyenne',
                  value: '$averageProgress%',
                  color: Colors.cyanAccent,
                ),
                _buildAdvancedStatRow(
                  icon: Icons.warning_amber_rounded,
                  label: 'Projets à risque',
                  value: riskProjects.toString(),
                  color: Colors.redAccent,
                ),
                _buildAdvancedStatRow(
                  icon: Icons.category_rounded,
                  label: 'Catégories actives',
                  value: activeCategories.toString(),
                  color: Colors.amberAccent,
                ),
              ],
            )
          : _buildPremiumLockedContent(
              'Passez à Premium pour voir la progression moyenne, les projets à risque et les catégories les plus actives.',
            ),
    );
  }

  Widget _buildAdvancedStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard() {
    final isPremium = context.watch<PremiumProvider>().isPremium;

    return _buildGlassContainer(
      title: 'EXPORTS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPremium
                ? 'Téléchargez un rapport CSV complet de vos projets.'
                : 'Les exports sont réservés aux utilisateurs Premium.',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _exportCsv,
              icon: Icon(isPremium ? Icons.file_download_rounded : Icons.lock_rounded),
              label: const Text('Exporter en CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPremium ? Colors.amberAccent : Colors.white12,
                foregroundColor: isPremium ? Colors.black : Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumLockedContent(String message) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_rounded, color: Colors.amberAccent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
        ),
      ],
    );
  }
}
