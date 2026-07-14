import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/project.dart';
import '../providers/premium_provider.dart';
import '../providers/project_provider.dart';

class AddProjectScreen extends StatefulWidget {
  final Project? project;

  const AddProjectScreen({super.key, this.project});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _descriptionTodos = [];

  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 30));
  int _notificationFrequency = 3;
  String? _selectedCategory;
  String? _imagePath;
  final ImagePicker _imagePicker = ImagePicker();

  // Catégories prédéfinies
  static const List<String> _categories = [
    'Travail',
    'Personnel',
    'Études',
    'Santé',
    'Finance',
    'Loisirs',
    'Famille',
    'Autre',
  ];

  static const List<Map<String, Object>> _premiumTemplates = [
    {
      'name': 'Business',
      'title': 'Lancer une nouvelle offre',
      'category': 'Travail',
      'days': 45,
      'todos': [
        'Définir le problème client',
        'Valider le prix',
        'Préparer une page de présentation',
        'Trouver 10 premiers prospects',
      ],
    },
    {
      'name': 'Études',
      'title': 'Réussir mon objectif académique',
      'category': 'Études',
      'days': 30,
      'todos': [
        'Lister les chapitres à réviser',
        'Planifier les séances de travail',
        'Faire des exercices pratiques',
        'Préparer une simulation finale',
      ],
    },
    {
      'name': 'Application mobile',
      'title': 'Créer mon application mobile',
      'category': 'Travail',
      'days': 60,
      'todos': [
        'Définir les écrans principaux',
        'Créer le prototype',
        'Développer les fonctionnalités clés',
        'Tester sur téléphone',
      ],
    },
    {
      'name': 'Marketing',
      'title': 'Campagne de visibilité',
      'category': 'Travail',
      'days': 21,
      'todos': [
        'Définir la cible',
        'Préparer le calendrier de contenu',
        'Créer les visuels',
        'Mesurer les résultats',
      ],
    },
  ];

  bool get isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _titleController.text = widget.project!.title;
      _hydrateDescription(widget.project!.description);
      _selectedDeadline = widget.project!.deadline;
      _notificationFrequency = widget.project!.notificationFrequency;
      _selectedCategory = widget.project!.category;
      _imagePath = widget.project!.imagePath;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.deepPurpleAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  Future<String?> _saveImageToLocal(XFile image) async {
    if (kIsWeb) {
      // Un chemin "blob:" du navigateur n'est pas durable et ne peut pas être
      // affiché avec Image.file. Les octets restent disponibles après le
      // rechargement de l'application via la base locale.
      final bytes = await image.readAsBytes();
      final mimeType = image.mimeType ?? 'image/jpeg';
      return 'data:$mimeType;base64,${base64Encode(bytes)}';
    }

    try {
      final imageFile = File(image.path);
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(appDir.path, 'project_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName = '${const Uuid().v4()}.jpg';
      final savedImage = await imageFile.copy(
        path.join(imagesDir.path, fileName),
      );
      return savedImage.path;
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'image: $e');
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );

      if (image != null) {
        final savedPath = await _saveImageToLocal(image);
        if (savedPath != null && mounted) {
          setState(() {
            _imagePath = savedPath;
          });
        }
      }
    } catch (e) {
      print('Erreur détaillée image_picker: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Erreur lors de la sélection de l\'image.\n'
              'Assurez-vous d\'avoir les permissions nécessaires.\n'
              'Erreur: ${e.toString()}',
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeImage() async {
    if (!kIsWeb && _imagePath != null) {
      try {
        final file = File(_imagePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Erreur lors de la suppression de l\'image: $e');
      }
    }
    setState(() {
      _imagePath = null;
    });
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final projectProvider = context.read<ProjectProvider>();
      final premiumProvider = context.read<PremiumProvider>();
      final description = _composeDescription();

      if (isEditing) {
        final updatedProject = widget.project!.copyWith(
          title: _titleController.text.trim(),
          description: description,
          deadline: _selectedDeadline,
          notificationFrequency: _notificationFrequency,
          category: _selectedCategory,
          imagePath: _imagePath,
        );
        await projectProvider.updateProject(updatedProject);
      } else {
        if (!premiumProvider.isPremium && projectProvider.projects.length >= 3) {
          _showPremiumLimitDialog();
          return;
        }

        final newProject = Project(
          id: const Uuid().v4(),
          title: _titleController.text.trim(),
          description: description,
          createdAt: DateTime.now(),
          deadline: _selectedDeadline,
          notificationFrequency: _notificationFrequency,
          category: _selectedCategory,
          imagePath: _imagePath,
        );
        await projectProvider.addProject(newProject);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showPremiumLimitDialog() {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        'Limite gratuite atteinte',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: const Text(
        'La version gratuite permet de créer 3 projets. Passez à Premium pour créer des projets illimités.',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Compris'),
        ),
      ],
    ),
  );
}

void _applyTemplate(Map<String, Object> template) {
  final todos = (template['todos'] as List).cast<String>();
  setState(() {
    _titleController.text = template['title'] as String;
    _selectedCategory = template['category'] as String;
    _selectedDeadline = DateTime.now().add(Duration(days: template['days'] as int));
    _descriptionController.text = 'Projet créé à partir du modèle ${template['name']}.';
    _descriptionTodos
      ..clear()
      ..addAll(todos);
  });
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Modifier le projet' : 'Nouveau projet',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F0F), Color(0xFF141318)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              _buildHeroHeader(),
              const SizedBox(height: 24),
              if (!isEditing) ...[
                _buildTemplateSection(),
                const SizedBox(height: 24),
              ],
              _buildSectionTitle('TITRE DU PROJET'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _titleController,
                hint: 'Ex: Lancer mon blog de cuisine',
                icon: Icons.edit_note_rounded,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('DESCRIPTION'),
              const SizedBox(height: 12),
              _buildDescriptionCard(),
              const SizedBox(height: 28),
              _buildSectionTitle('DATE LIMITE'),
              const SizedBox(height: 12),
              _buildGlassCard(
                onTap: _selectDeadline,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.deepPurpleAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Échéance',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          '${_selectedDeadline.day}/${_selectedDeadline.month}/${_selectedDeadline.year}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('CATÉGORIE'),
              const SizedBox(height: 12),
              _buildCategorySelector(),
              const SizedBox(height: 28),
              _buildSectionTitle('PHOTO (OPTIONNEL)'),
              const SizedBox(height: 12),
              _buildImagePicker(),
              const SizedBox(height: 28),
              _buildSectionTitle('FRÉQUENCE DES RAPPELS'),
              const SizedBox(height: 12),
              _buildGlassCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tous les $_notificationFrequency jour${_notificationFrequency > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.orangeAccent,
                          size: 20,
                        ),
                      ],
                    ),
                    Slider(
                      value: _notificationFrequency.toDouble(),
                      min: 1,
                      max: 14,
                      activeColor: Colors.deepPurpleAccent,
                      inactiveColor: Colors.white.withValues(alpha: 0.1),
                      onChanged: (value) =>
                          setState(() => _notificationFrequency = value.toInt()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Colors.deepPurpleAccent, Colors.purple],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurpleAccent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _saveProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isEditing
                            ? Icons.check_circle_rounded
                            : Icons.add_task_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          isEditing ? 'ENREGISTRER' : 'CRÉER LE PROJET',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF5B2EFF), Color(0xFF9B4DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B2EFF).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isEditing ? Icons.edit_rounded : Icons.rocket_launch_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Ajuste ton projet' : 'Crée un projet puissant',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isEditing
                      ? 'Peaufine les détails pour aller plus vite.'
                      : 'Donne un cap clair et des objectifs concrets.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    final hasText = _descriptionController.text.trim().isNotEmpty;
    final hasTodos = _descriptionTodos.isNotEmpty;

    return InkWell(
      onTap: _openDescriptionEditor,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Colors.deepPurpleAccent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasText
                        ? _descriptionController.text.trim()
                        : 'DÃ©cris ton objectif ici...',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasText
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildTag(
                        hasTodos ? '${_descriptionTodos.length} items' : '0 item',
                        icon: Icons.checklist_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildTag(
                        'Ã‰dition plein Ã©cran',
                        icon: Icons.open_in_full_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateSection() {
  final isPremium = context.watch<PremiumProvider>().isPremium;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          _buildSectionTitle('MODÈLES PREMIUM'),
          const SizedBox(width: 8),
          const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.amberAccent,
            size: 16,
          ),
        ],
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 104,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _premiumTemplates.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final template = _premiumTemplates[index];

            return GestureDetector(
              onTap: isPremium
                  ? () => _applyTemplate(template)
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Les modèles de projets sont réservés aux utilisateurs Premium.',
                          ),
                        ),
                      ),
              child: Container(
                width: 180,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isPremium
                        ? Colors.amberAccent.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isPremium
                          ? Icons.auto_awesome_rounded
                          : Icons.lock_rounded,
                      color: isPremium ? Colors.amberAccent : Colors.white38,
                      size: 20,
                    ),
                    const Spacer(),
                    Text(
                      template['name'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${template['days']} jours',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

  Widget _buildTag(String label, {required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Future<void> _openDescriptionEditor() async {
    final result = await Navigator.push<_DescriptionResult>(
      context,
      MaterialPageRoute(
        builder: (_) => _DescriptionEditorScreen(
          initialText: _descriptionController.text.trim(),
          initialTodos: List<String>.from(_descriptionTodos),
        ),
      ),
    );

    if (result == null) return;
    setState(() {
      _descriptionController.text = result.text;
      _descriptionTodos
        ..clear()
        ..addAll(result.todos);
    });
  }

  String _composeDescription() {
    final base = _descriptionController.text.trim();
    if (_descriptionTodos.isEmpty) return base;

    final buffer = StringBuffer();
    if (base.isNotEmpty) {
      buffer.writeln(base);
      buffer.writeln();
    }
    buffer.writeln('TÃ¢ches:');
    for (final item in _descriptionTodos) {
      buffer.writeln('- $item');
    }
    return buffer.toString().trim();
  }

  void _hydrateDescription(String raw) {
    final marker = '\n\nTÃ¢ches:\n';
    if (!raw.contains(marker)) {
      _descriptionController.text = raw;
      return;
    }

    final parts = raw.split(marker);
    _descriptionController.text = parts.first.trim();

    final todosRaw = parts.last
        .split('\n')
        .where((line) => line.trim().startsWith('- '))
        .map((line) => line.trim().substring(2).trim())
        .where((line) => line.isNotEmpty)
        .toList();
    _descriptionTodos
      ..clear()
      ..addAll(todosRaw);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          prefixIcon: Icon(icon, color: Colors.deepPurpleAccent, size: 22),
          suffixIcon: readOnly
              ? const Icon(Icons.open_in_full_rounded, color: Colors.white70)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Ce champ est requis'
            : null,
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: child,
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((category) {
        final isSelected = _selectedCategory == category;
        return GestureDetector(
          onTap: () =>
              setState(() => _selectedCategory = isSelected ? null : category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.deepPurpleAccent
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.deepPurpleAccent
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImagePicker() {
    return _imagePath != null
        ? Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _buildProjectImage(
                  _imagePath!,
                  width: double.infinity,
                  height: 200,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _removeImage,
                  ),
                ),
              ),
            ],
          )
        : _buildGlassCard(
            onTap: _pickImage,
            child: Column(
              children: [
                Icon(
                  Icons.add_photo_alternate_rounded,
                  color: Colors.deepPurpleAccent,
                  size: 48,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ajouter une photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Optionnel',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        );
  }

  Widget _buildProjectImage(
    String imagePath, {
    required double width,
    required double height,
  }) {
    final errorImage = Container(
      width: width,
      height: height,
      color: Colors.grey[800],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
    Widget errorBuilder(BuildContext context, Object error, StackTrace? stackTrace) =>
        errorImage;

    if (imagePath.startsWith('data:image/')) {
      final commaIndex = imagePath.indexOf(',');
      if (commaIndex == -1) return errorImage;
      try {
        return Image.memory(
          base64Decode(imagePath.substring(commaIndex + 1)),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: errorBuilder,
        );
      } on FormatException {
        return errorImage;
      }
    }

    if (kIsWeb) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: errorBuilder,
      );
    }

    return Image.file(
      File(imagePath),
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: errorBuilder,
    );
  }
}

class _DescriptionResult {
  final String text;
  final List<String> todos;

  const _DescriptionResult({
    required this.text,
    required this.todos,
  });
}

class _DescriptionEditorScreen extends StatefulWidget {
  final String initialText;
  final List<String> initialTodos;

  const _DescriptionEditorScreen({
    required this.initialText,
    required this.initialTodos,
  });

  @override
  State<_DescriptionEditorScreen> createState() => _DescriptionEditorScreenState();
}

class _DescriptionEditorScreenState extends State<_DescriptionEditorScreen> {
  final _textController = TextEditingController();
  final _todoController = TextEditingController();
  final List<String> _todos = [];

  @override
  void initState() {
    super.initState();
    _textController.text = widget.initialText;
    _todos.addAll(widget.initialTodos);
  }

  @override
  void dispose() {
    _textController.dispose();
    _todoController.dispose();
    super.dispose();
  }

  void _addTodo() {
    final value = _todoController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _todos.add(value);
      _todoController.clear();
    });
  }

  void _removeTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });
  }

  void _save() {
    Navigator.pop(
      context,
      _DescriptionResult(
        text: _textController.text.trim(),
        todos: List<String>.from(_todos),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text(
          'Description du projet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Enregistrer',
              style: TextStyle(color: Colors.deepPurpleAccent),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: TextField(
              controller: _textController,
              maxLines: 10,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Décris ton objectif en détail...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Liste de détails',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${_todos.length})',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.playlist_add_rounded, color: Colors.white70),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _todoController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ajouter un point de description',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _addTodo(),
                  ),
                ),
                IconButton(
                  onPressed: _addTodo,
                  icon: const Icon(Icons.add_circle_rounded, color: Colors.deepPurpleAccent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_todos.isEmpty)
            Text(
              'Ajoute des points clés pour stru.....',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
            ),
          ..._todos.asMap().entries.map((entry) {
            final index = entry.key;
            final value = entry.value;
            return Dismissible(
              key: ValueKey('todo_${index}_$value'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => _removeTodo(index),
              background: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: Colors.white70),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      onPressed: () => _removeTodo(index),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Valider la description',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
