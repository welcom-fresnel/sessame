import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/project_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, int>? _stats;

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
                        _stats!['total']!,
                        Icons.folder_rounded,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'EN COURS',
                        _stats!['en_cours']!,
                        Icons.rocket_launch_rounded,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'TERMINÉS',
                        _stats!['terminés']!,
                        Icons.check_circle_rounded,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'EN RETARD',
                        _stats!['en_retard']!,
                        Icons.warning_rounded,
                        Colors.red,
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  if (_stats!['total']! > 0) ...[
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
    final total = _stats!['total']!.toDouble();
    if (total == 0) return [];

    final enCours = _stats!['en_cours']!.toDouble();
    final termines = _stats!['terminés']!.toDouble();
    final abandonnes = _stats!['abandonnés']?.toDouble() ?? 0.0;

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
        if (_stats!['en_cours']! > 0)
          _buildLegendItem('En cours', Colors.orange, _stats!['en_cours']!),
        if (_stats!['terminés']! > 0)
          _buildLegendItem('Terminés', Colors.green, _stats!['terminés']!),
        if ((_stats!['abandonnés'] ?? 0) > 0)
          _buildLegendItem('Abandonnés', Colors.grey, _stats!['abandonnés']!),
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
    final completed = _stats!['terminés']!;
    final total = _stats!['total']!;
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
}
