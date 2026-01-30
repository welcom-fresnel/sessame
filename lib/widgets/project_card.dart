import 'dart:io';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../models/project.dart';
import '../screens/project_detail_screen.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final int index; // Pour l'animation en cascade

  const ProjectCard({super.key, required this.project, required this.index});

  @override
  Widget build(BuildContext context) {
    final isOverdue = project.isOverdue;

    return FadeInUp(
      delay: Duration(milliseconds: 100 * index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isOverdue
                ? [
                    Colors.red.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.3),
                  ]
                : [
                    Colors.deepPurple.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.3),
                  ],
          ),
          border: Border.all(
            color: isOverdue
                ? Colors.red.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProjectDetailScreen(project: project),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image du projet si disponible
                if (project.imagePath != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: Image.file(
                      File(project.imagePath!),
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          color: Colors.grey[800],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildStatusBadge(),
                              if (project.category != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurpleAccent.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.deepPurpleAccent.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    project.category!,
                                    style: const TextStyle(
                                      color: Colors.deepPurpleAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (isOverdue)
                            Flash(
                              infinite: true,
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        project.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        project.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                  const SizedBox(height: 20),

                  // Barre de progression stylisée
                  Row(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(seconds: 1),
                                  height: 8,
                                  width:
                                      constraints.maxWidth * project.progress,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isOverdue
                                          ? [Colors.red, Colors.orange]
                                          : [
                                              Colors.deepPurpleAccent,
                                              Colors.purple,
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (isOverdue
                                                    ? Colors.red
                                                    : Colors.deepPurple)
                                                .withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(project.progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: isOverdue ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOverdue
                            ? 'En retard'
                            : '${project.daysRemaining} jours restants',
                        style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.grey,
                          fontSize: 12,
                          fontWeight: isOverdue
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String label;
    switch (project.status) {
      case 'terminé':
        color = Colors.green;
        label = 'TERMINÉ';
        break;
      case 'abandonné':
        color = Colors.grey;
        label = 'ABANDONNÉ';
        break;
      default:
        color = Colors.blue;
        label = 'EN COURS';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, letterSpacing: 1),
      ),
    );
  }
}
