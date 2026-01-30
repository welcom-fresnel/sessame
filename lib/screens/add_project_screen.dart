import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/project.dart';
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

  bool get isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _titleController.text = widget.project!.title;
      _descriptionController.text = widget.project!.description;
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

  Future<String?> _saveImageToLocal(File imageFile) async {
    try {
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
        final savedPath = await _saveImageToLocal(File(image.path));
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
    if (_imagePath != null) {
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

      if (isEditing) {
        final updatedProject = widget.project!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          deadline: _selectedDeadline,
          notificationFrequency: _notificationFrequency,
          category: _selectedCategory,
          imagePath: _imagePath,
        );
        await projectProvider.updateProject(updatedProject);
      } else {
        final newProject = Project(
          id: const Uuid().v4(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildSectionTitle('TITRE DU PROJET'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _titleController,
              hint: 'Ex: Maîtriser Flutter en 30 jours',
              icon: Icons.edit_note_rounded,
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('DESCRIPTION'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _descriptionController,
              hint: 'Décris ton objectif ici...',
              icon: Icons.description_outlined,
              maxLines: 4,
            ),
            const SizedBox(height: 32),
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
            const SizedBox(height: 32),
            _buildSectionTitle('PHOTO (OPTIONNEL)'),
            const SizedBox(height: 12),
            _buildImagePicker(),
            const SizedBox(height: 32),
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
    );
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
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          prefixIcon: Icon(icon, color: Colors.deepPurpleAccent, size: 22),
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
                child: Image.file(
                  File(_imagePath!),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
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
}
