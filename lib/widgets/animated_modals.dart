import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../providers/project_provider.dart';

/// Modal animé pour créer un projet rapidement
class AnimatedProjectModal {
  static void show(BuildContext context) {
    WoltModalSheet.show<void>(
      context: context,
      pageListBuilder: (modalSheetContext) {
        return [
          _buildProjectPage(modalSheetContext),
          _buildDeadlinePage(modalSheetContext),
          _buildConfirmationPage(modalSheetContext),
        ];
      },
      modalTypeBuilder: (context) {
        return WoltModalType.bottomSheet();
      },
      onModalDismissedWithBarrierTap: () {
        Navigator.of(context).pop();
      },
    );
  }

  // Page 1 : Informations de base
  static SliverWoltModalSheetPage _buildProjectPage(
    BuildContext modalSheetContext,
  ) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    return WoltModalSheetPage(
      hasSabGradient: false,
      topBarTitle: Text(
        '📝 Nouveau Projet',
        style: Theme.of(modalSheetContext).textTheme.titleLarge,
      ),
      isTopBarLayerAlwaysVisible: true,
      trailingNavBarWidget: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(modalSheetContext).pop(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Titre du projet',
                hintText: 'Ex: Apprendre Flutter',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Décrivez votre projet...',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Naviguer vers la page suivante
                WoltModalSheet.of(modalSheetContext).showNext();
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Suivant'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Page 2 : Deadline
  static SliverWoltModalSheetPage _buildDeadlinePage(
    BuildContext modalSheetContext,
  ) {
    return WoltModalSheetPage(
      hasSabGradient: false,
      topBarTitle: Text(
        '📅 Date Limite',
        style: Theme.of(modalSheetContext).textTheme.titleLarge,
      ),
      isTopBarLayerAlwaysVisible: true,
      trailingNavBarWidget: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(modalSheetContext).pop(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Choisissez une échéance pour votre projet',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildDeadlineOption(
              modalSheetContext,
              '7 jours',
              Icons.calendar_today,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildDeadlineOption(
              modalSheetContext,
              '1 mois',
              Icons.calendar_month,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildDeadlineOption(
              modalSheetContext,
              '3 mois',
              Icons.event_available,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildDeadlineOption(
              modalSheetContext,
              '6 mois',
              Icons.event,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildDeadlineOption(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () => WoltModalSheet.of(context).showNext(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  // Page 3 : Confirmation
  static SliverWoltModalSheetPage _buildConfirmationPage(
    BuildContext modalSheetContext,
  ) {
    return WoltModalSheetPage(
      hasSabGradient: false,
      topBarTitle: Text(
        '✅ Confirmation',
        style: Theme.of(modalSheetContext).textTheme.titleLarge,
      ),
      isTopBarLayerAlwaysVisible: true,
      trailingNavBarWidget: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(modalSheetContext).pop(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            const Text(
              'Projet prêt à être créé !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Vous allez recevoir des rappels réguliers pour suivre votre progression.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Créer le projet
                Navigator.of(modalSheetContext).pop();
                ScaffoldMessenger.of(modalSheetContext).showSnackBar(
                  const SnackBar(
                    content: Text('🎉 Projet créé avec succès !'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Créer le projet'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal animé pour ajouter une tâche rapidement
class QuickAddTaskModal {
  static void show(BuildContext context, String projectId) {
    final controller = TextEditingController();

    WoltModalSheet.show<void>(
      context: context,
      pageListBuilder: (modalSheetContext) {
        return [
          WoltModalSheetPage(
            hasSabGradient: false,
            topBarTitle: Text(
              '✅ Ajouter une tâche',
              style: Theme.of(modalSheetContext).textTheme.titleLarge,
            ),
            isTopBarLayerAlwaysVisible: true,
            trailingNavBarWidget: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(modalSheetContext).pop(),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Titre de la tâche',
                      hintText: 'Que devez-vous faire ?',
                      prefixIcon: Icon(Icons.check_box_outline_blank),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    autofocus: true,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(modalSheetContext).pop(),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (controller.text.trim().isEmpty) return;

                            final task = Task(
                              id: const Uuid().v4(),
                              projectId: projectId,
                              title: controller.text.trim(),
                              createdAt: DateTime.now(),
                            );

                            await context.read<ProjectProvider>().addTask(task);

                            if (modalSheetContext.mounted) {
                              Navigator.of(modalSheetContext).pop();
                              ScaffoldMessenger.of(
                                modalSheetContext,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Tâche ajoutée'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ];
      },
      modalTypeBuilder: (context) => WoltModalType.bottomSheet(),
    );
  }
}

/// Modal pour changer le statut d'un projet avec animation
class StatusChangeModal {
  static void show(BuildContext context, Project project) {
    WoltModalSheet.show<void>(
      context: context,
      pageListBuilder: (modalSheetContext) {
        return [
          WoltModalSheetPage(
            hasSabGradient: false,
            topBarTitle: Text(
              '🔄 Changer le statut',
              style: Theme.of(modalSheetContext).textTheme.titleLarge,
            ),
            isTopBarLayerAlwaysVisible: true,
            trailingNavBarWidget: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(modalSheetContext).pop(),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildStatusOption(
                    modalSheetContext,
                    'En cours',
                    'Le projet est actif',
                    Icons.pending_actions,
                    Colors.blue,
                    'en_cours',
                    project,
                  ),
                  const SizedBox(height: 12),
                  _buildStatusOption(
                    modalSheetContext,
                    'Terminé',
                    'Félicitations ! 🎉',
                    Icons.check_circle,
                    Colors.green,
                    'terminé',
                    project,
                  ),
                  const SizedBox(height: 12),
                  _buildStatusOption(
                    modalSheetContext,
                    'Abandonné',
                    'Archiver ce projet',
                    Icons.cancel,
                    Colors.grey,
                    'abandonné',
                    project,
                  ),
                ],
              ),
            ),
          ),
        ];
      },
      modalTypeBuilder: (context) => WoltModalType.bottomSheet(),
    );
  }

  static Widget _buildStatusOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String status,
    Project project,
  ) {
    final isSelected = project.status == status;

    return InkWell(
      onTap: () async {
        if (!isSelected) {
          final updatedProject = project.copyWith(
            status: status,
            progress: status == 'terminé' ? 1.0 : project.progress,
          );

          await context.read<ProjectProvider>().updateProject(updatedProject);
        }
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color)
            else
              Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
