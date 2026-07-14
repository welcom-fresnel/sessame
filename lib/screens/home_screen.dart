import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/home_ad.dart';
import '../providers/project_provider.dart';
import '../services/ad_service.dart';
import '../widgets/project_card.dart';
import 'add_project_screen.dart';
import 'statistics_screen.dart';
import 'conversation.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _guidedTourSeenKey = 'home_guided_tour_seen';
  String _selectedFilter = 'tous'; // tous, en_cours, terminé
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<HomeAd> _homeAds = [];
  int _currentAdIndex = 0;
  Timer? _adRotationTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().loadProjects();
      _loadHomeAd();
      _showGuidedTourIfNeeded();
    });
  }

  Future<void> _showGuidedTourIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTour = prefs.getBool(_guidedTourSeenKey) ?? false;
    if (hasSeenTour || !mounted) return;

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    await _showGuidedTourDialog();
    await prefs.setBool(_guidedTourSeenKey, true);
  }

  Future<void> _showGuidedTourDialog() async {
    var currentStep = 0;
    const steps = [
      (
        icon: Icons.folder_rounded,
        title: 'Bienvenue sur Asala',
        message:
            'Ici, tu peux organiser tes objectifs sous forme de projets simples à suivre.',
      ),
      (
        icon: Icons.add_circle_rounded,
        title: 'Créer ton premier projet',
        message:
            'Utilise le bouton New en bas pour ajouter un projet, définir une deadline et suivre ta progression.',
      ),
      (
        icon: Icons.search_rounded,
        title: 'Retrouver rapidement',
        message:
            'La barre de recherche et les filtres te permettent de retrouver tes projets en cours ou terminés.',
      ),
      (
        icon: Icons.auto_graph_rounded,
        title: 'Suivre tes performances',
        message:
            'Le bouton statistiques te montre ton évolution, tes projets en retard et tes résultats Premium.',
      ),
      (
        icon: Icons.smart_toy_rounded,
        title: 'Demander conseil',
        message:
            'Le coach IA peut t’aider à trouver les prochaines étapes pour avancer plus vite.',
      ),
    ];

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final step = steps[currentStep];
            final isLastStep = currentStep == steps.length - 1;

            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(step.icon, color: Colors.deepPurpleAccent, size: 34),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    step.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    step.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      steps.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: index == currentStep ? 22 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: index == currentStep
                              ? Colors.deepPurpleAccent
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Passer'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (isLastStep) {
                          Navigator.pop(context);
                        } else {
                          setDialogState(() => currentStep++);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(isLastStep ? 'Commencer' : 'Suivant'),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _loadHomeAd() async {
    final ads = await AdService().getHomeSummaryAds();
    if (!mounted) return;
    setState(() {
      _homeAds = ads;
      _currentAdIndex = 0;
    });
    _startAdRotation();
  }

  void _startAdRotation() {
    _adRotationTimer?.cancel();
    if (_homeAds.length <= 1) return;

    _adRotationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        _currentAdIndex = (_currentAdIndex + 1) % _homeAds.length;
      });
    });
  }

  @override
  void dispose() {
    _adRotationTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<ProjectProvider>(
          builder: (context, projectProvider, child) {
            final filteredProjects = _getFilteredProjects(projectProvider);

            return CustomScrollView(
              slivers: [
                // Header stylisé
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FadeInLeft(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bonjour',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey
                                          : Colors.grey[700],
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Tes Projets',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FadeInRight(child: _buildActionButtons()),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Barre de recherche
                        _buildSearchBar(),
                        const SizedBox(height: 24),
                        // Résumé rapide
                        _buildSummaryCard(projectProvider),
                        const SizedBox(height: 32),
                        // Filtres modernes
                        _buildFilters(),
                      ],
                    ),
                  ),
                ),

                // Liste des projets
                if (filteredProjects.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return ProjectCard(
                          project: filteredProjects[index],
                          index: index,
                        );
                      }, childCount: filteredProjects.length),
                    ),
                  ),

                // Espace en bas pour le FAB
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FadeInUp(
        delay: const Duration(milliseconds: 500),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProjectScreen()),
          ),
          backgroundColor: Colors.deepPurpleAccent,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'New',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  List _getFilteredProjects(ProjectProvider provider) {
    List projects;
    switch (_selectedFilter) {
      case 'en_cours':
        projects = provider.activeProjects;
        break;
      case 'terminé':
        projects = provider.completedProjects;
        break;
      default:
        projects = provider.projects;
    }

    // Appliquer la recherche si une requête existe
    if (_searchQuery.isNotEmpty) {
      projects = projects.where((project) {
        return project.title.toLowerCase().contains(_searchQuery) ||
            project.description.toLowerCase().contains(_searchQuery) ||
            (project.category != null &&
                project.category!.toLowerCase().contains(_searchQuery));
      }).toList();
    }

    return projects;
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey[300]!,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Rechercher un projet...',
          hintStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey
                : Colors.grey[600],
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey
                : Colors.grey[600],
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey
                        : Colors.grey[600],
                  ),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        _buildCircleIconButton(
          icon: Icons.chat_bubble_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ConversationScreen()),
          ),
        ),
        const SizedBox(width: 5),
        _buildCircleIconButton(
          icon: Icons.bar_chart_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StatisticsScreen()),
          ),
        ),
        const SizedBox(width: 5),
        _buildCircleIconButton(
          icon: Icons.settings_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey[300]!,
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isDark ? Colors.white : Colors.black87,
          size: 20,
        ),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildSummaryCard(ProjectProvider provider) {
    final activeCount = provider.activeProjects.length;
    final overdueCount = provider.overdueProjects.length;
    final ad = _homeAds.isEmpty ? null : _homeAds[_currentAdIndex];
    final showAd = ad != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurpleAccent, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: Row(
          key: ValueKey(ad?.id ?? 'summary'),
          children: [
            Expanded(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showAd
                      ? ad.title
                      : overdueCount > 0
                          ? 'Attention !'
                          : 'Tout va bien !',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  showAd
                      ? ad.message
                      : overdueCount > 0
                          ? 'Tu as $overdueCount projets en retard ⚠️'
                          : 'Tu as $activeCount projets en cours activement.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                if (showAd) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Sponsorisé • ${ad.ctaLabel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
              ),
            ),
            if (showAd && ad.isImageAd)
              _buildAdImage(ad.imageUrl!)
            else
              Icon(
                showAd ? Icons.campaign_rounded : Icons.rocket_launch_rounded,
                color: Colors.white,
                size: 40,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdImage(String imageUrl) {
    final imageProvider = _adImageProvider(imageUrl);

    return Container(
      width: 74,
      height: 74,
      margin: const EdgeInsets.only(left: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image(
        image: imageProvider,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.campaign_rounded,
          color: Colors.white,
          size: 34,
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }

  ImageProvider _adImageProvider(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      final base64Part = imageUrl.substring(imageUrl.indexOf(',') + 1);
      return MemoryImage(base64Decode(base64Part));
    }

    return NetworkImage(imageUrl);
  }

  Widget _buildFilters() {
    return Row(
      children: [
        _buildFilterChip('Tous', 'tous'),
        const SizedBox(width: 12),
        _buildFilterChip('En cours', 'en_cours'),
        const SizedBox(width: 12),
        _buildFilterChip('Terminés', 'terminé'),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepPurpleAccent
              : isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : isDark
                ? Colors.grey
                : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_motion_rounded,
            size: 80,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Rien à signaler ici...',
            style: TextStyle(
              color: isDark ? Colors.grey : Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
