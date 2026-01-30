import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:animate_do/animate_do.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../providers/project_provider.dart';
import '../services/ai_service.dart';
import 'add_project_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final _taskController = TextEditingController();
  final _aiService = AIService();
  final _scrollController = ScrollController();
  final _taskInputFocusNode = FocusNode();

  String? _aiAdvice;
  bool _isLoadingAdvice = false;
  bool _isGeneratingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _aiService.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().loadProjectTasks(widget.project.id);
    });

    // Scroller automatiquement quand le champ obtient le focus
    _taskInputFocusNode.addListener(() {
      if (_taskInputFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _taskController.dispose();
    _scrollController.dispose();
    _taskInputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    if (_taskController.text.trim().isEmpty) return;

    final newTask = Task(
      id: const Uuid().v4(),
      projectId: widget.project.id,
      title: _taskController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await context.read<ProjectProvider>().addTask(newTask);
      _taskController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Tâche ajoutée'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Erreur: $e')));
    }
  }

  Future<void> _getAIAdvice() async {
    setState(() {
      _isLoadingAdvice = true;
      _aiAdvice = null;
    });

    try {
      final tasks = context.read<ProjectProvider>().currentProjectTasks;
      final advice = await _aiService.getProjectAdvice(
        project: widget.project,
        tasks: tasks,
      );

      if (mounted) {
        setState(() {
          _aiAdvice = advice;
          _isLoadingAdvice = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiAdvice =
              "Je ne peux pas te conseiller pour le moment. Réessaye ! 🤖";
          _isLoadingAdvice = false;
        });
      }
    }
  }

  Future<void> _generateTaskSuggestions() async {
    setState(() => _isGeneratingSuggestions = true);

    try {
      final suggestions = await _aiService.suggestTasks(
        projectTitle: widget.project.title,
        projectDescription: widget.project.description,
      );

      if (!mounted) return;

      if (suggestions.isNotEmpty) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.deepPurpleAccent),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Suggestions IA',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'L\'IA suggère ces étapes :',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ...suggestions.map(
                  (suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: Colors.deepPurpleAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ANNULER'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'AJOUTER',
                  style: TextStyle(color: Colors.deepPurpleAccent),
                ),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          final provider = context.read<ProjectProvider>();
          for (var suggestion in suggestions) {
            final task = Task(
              id: const Uuid().v4(),
              projectId: widget.project.id,
              title: suggestion,
              createdAt: DateTime.now(),
            );
            await provider.addTask(task);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✨ ${suggestions.length} tâches suggérées ajoutées !',
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erreur lors de la génération de suggestions'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingSuggestions = false);
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Supprimer', style: TextStyle(color: Colors.white)),
        content: Text(
          'Supprimer "${task.title}" ?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SUPPRIMER', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<ProjectProvider>().deleteTask(
        task.id,
        widget.project.id,
      );
    }
  }

  Future<void> _updateProjectStatus(String newStatus) async {
    final updatedProject = widget.project.copyWith(
      status: newStatus,
      progress: newStatus == 'terminé' ? 1.0 : widget.project.progress,
    );
    await context.read<ProjectProvider>().updateProject(updatedProject);
  }

  void _showStatusMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusOption(
                Icons.pending_actions,
                'En cours',
                Colors.blue,
                'en_cours',
              ),
              _buildStatusOption(
                Icons.check_circle,
                'Terminé',
                Colors.green,
                'terminé',
              ),
              _buildStatusOption(
                Icons.cancel,
                'Abandonné',
                Colors.grey,
                'abandonné',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOption(
    IconData icon,
    String label,
    Color color,
    String status,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        _updateProjectStatus(status);
      },
    );
  }

  Future<void> _deleteProject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Supprimer le projet',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'C\'est irréversible, t\'es sûr ? 🧐',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'OUI, SUPPRIMER',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<ProjectProvider>().deleteProject(widget.project.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text(
          'Détails',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddProjectScreen(project: widget.project),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            color: const Color(0xFF1A1A1A),
            onSelected: (value) {
              if (value == 'status') _showStatusMenu();
              if (value == 'delete') _deleteProject();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'status',
                child: Text('Statut', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Supprimer', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, projectProvider, child) {
          final isOverdue = widget.project.isOverdue;

          return SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Header Project
                FadeInDown(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isOverdue
                            ? [
                                Colors.red.withValues(alpha: 0.1),
                                Colors.black.withValues(alpha: 0.2),
                              ]
                            : [
                                Colors.deepPurpleAccent.withValues(alpha: 0.1),
                                Colors.black.withValues(alpha: 0.2),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildChip(
                              icon: Icons.event_rounded,
                              label: '${widget.project.daysRemaining} j',
                              color: isOverdue ? Colors.red : Colors.blue,
                            ),
                            _buildStatusBadge(widget.project.status),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.project.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 100),
                          child: SingleChildScrollView(
                            child: Text(
                              widget.project.description,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildNeonProgressBar(
                          widget.project.progress,
                          isOverdue,
                        ),
                      ],
                    ),
                  ),
                ),

                // Coach IA Section
                if (_aiAdvice != null || _isLoadingAdvice)
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurpleAccent.withValues(alpha: 0.15),
                            Colors.blueAccent.withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.deepPurpleAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: _isLoadingAdvice
                          ? const Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.deepPurpleAccent,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text(
                                  'Le coach réfléchit...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurpleAccent
                                            .withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.psychology_rounded,
                                        color: Colors.deepPurpleAccent,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Coach IA',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 120,
                                  ),
                                  child: SingleChildScrollView(
                                    child: Text(
                                      _aiAdvice ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                if (_aiAdvice != null || _isLoadingAdvice)
                  const SizedBox(height: 12),

                // Section Tâches
                FadeInUp(
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF161616),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(40),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Handle fixe
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Boutons IA
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoadingAdvice
                                    ? null
                                    : _getAIAdvice,
                                icon: const Icon(
                                  Icons.psychology_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Coach IA',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurpleAccent
                                      .withValues(alpha: 0.2),
                                  foregroundColor: Colors.deepPurpleAccent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.deepPurpleAccent.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isGeneratingSuggestions
                                    ? null
                                    : _generateTaskSuggestions,
                                icon: _isGeneratingSuggestions
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.auto_awesome, size: 18),
                                label: const Text(
                                  'Suggérer',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent.withValues(
                                    alpha: 0.2,
                                  ),
                                  foregroundColor: Colors.blueAccent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.blueAccent.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildTaskInput(),
                        const SizedBox(height: 20),

                        // Liste des tâches
                        _buildTaskListInline(projectProvider),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNeonProgressBar(double progress, bool isOverdue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progression',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  height: 6,
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOverdue
                          ? [Colors.red, Colors.orange]
                          : [Colors.deepPurpleAccent, Colors.purple],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isOverdue ? Colors.red : Colors.deepPurpleAccent)
                                .withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTaskInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: _taskController,
        focusNode: _taskInputFocusNode,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Ajouter une étape...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          prefixIcon: const Icon(
            Icons.add_task_rounded,
            color: Colors.deepPurpleAccent,
          ),
          suffixIcon: IconButton(
            icon: const Icon(
              Icons.send_rounded,
              color: Colors.deepPurpleAccent,
            ),
            onPressed: _addTask,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        onSubmitted: (_) => _addTask(),
      ),
    );
  }

  Widget _buildTaskListInline(ProjectProvider provider) {
    if (provider.currentProjectTasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(
              Icons.checklist_rounded,
              size: 60,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            const Text(
              'Zéro étape pour l\'instant...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ...provider.currentProjectTasks.map((task) {
          return Dismissible(
            key: Key(task.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
              ),
            ),
            onDismissed: (_) => _deleteTask(task),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
              ),
              child: CheckboxListTile(
                value: task.isCompleted,
                activeColor: Colors.deepPurpleAccent,
                checkColor: Colors.white,
                checkboxShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    color: task.isCompleted ? Colors.grey : Colors.white,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                onChanged: (val) => provider.toggleTaskCompletion(task),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'terminé'
        ? Colors.green
        : (status == 'en_cours' ? Colors.blue : Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
