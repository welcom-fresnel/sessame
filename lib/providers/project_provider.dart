import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/project.dart';
import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class ProjectProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  StreamSubscription<User?>? _authSub;
  String? _uid;

  List<Project> _projects = [];
  List<Task> _currentProjectTasks = [];
  bool _isLoading = false;

  List<Project> get projects => _projects;
  List<Task> get currentProjectTasks => _currentProjectTasks;
  bool get isLoading => _isLoading;
  bool get isSignedIn => _uid != null;

  ProjectProvider() {
    _uid = _authService.currentUser?.uid;
    _authSub = _authService.authStateChanges().listen((user) {
      _handleAuthChange(user?.uid);
    });
  }

  // Filter projects
  List<Project> get activeProjects => _projects.where((p) => p.status == 'en_cours').toList();

  List<Project> get completedProjects => _projects.where((p) => p.status == 'terminé').toList();

  List<Project> get overdueProjects =>
      _projects.where((p) => p.isOverdue && p.status == 'en_cours').toList();

  // Initialize and load projects
  Future<void> initialize() async {
    try {
      await _notificationService.initialize();
    } catch (e) {
      // Notifications are not critical
      // ignore: avoid_print
      print('Notification initialization failed: $e');
    }

    try {
      if (_uid != null) {
        await _migrateLocalToCloudIfNeeded(_uid!);
      }
      await loadProjects();
    } catch (e) {
      // ignore: avoid_print
      print('Error loading projects during initialization: $e');
      _projects = [];
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _handleAuthChange(String? newUid) async {
    if (_uid == newUid) return;
    _uid = newUid;

    try {
      if (_uid != null) {
        await _migrateLocalToCloudIfNeeded(_uid!);
      }
      await loadProjects();
    } catch (e) {
      // ignore: avoid_print
      print('Auth change reload failed: $e');
    }
  }

  Future<void> _migrateLocalToCloudIfNeeded(String uid) async {
    try {
      final remote = await _firestoreService.getAllProjects(uid);
      if (remote.isNotEmpty) return;

      final localProjects = await _dbService.getAllProjects();
      if (localProjects.isEmpty) return;

      for (final project in localProjects) {
        await _firestoreService.upsertProject(uid, project);
        final tasks = await _dbService.getTasksByProject(project.id);
        for (final task in tasks) {
          await _firestoreService.upsertTask(uid, task);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Migration local->cloud skipped: $e');
    }
  }

  // Load all projects
  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_uid != null) {
        _projects = await _firestoreService.getAllProjects(_uid!);
      } else {
        _projects = await _dbService.getAllProjects();
      }
      await _syncProjectNotifications();
    } catch (e) {
      // ignore: avoid_print
      print('Error loading projects: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new project
  Future<void> addProject(Project project) async {
    try {
      if (_uid != null) {
        await _firestoreService.upsertProject(_uid!, project);
      } else {
        await _dbService.insertProject(project);
      }
      try {
        await _notificationService.scheduleProjectNotification(project);
      } catch (e) {
        // ignore: avoid_print
        print('Project notification scheduling failed: $e');
      }
      await loadProjects();
    } catch (e) {
      // ignore: avoid_print
      print('Error adding project: $e');
      rethrow;
    }
  }

  // Update a project
  Future<void> updateProject(Project project) async {
    try {
      final updatedProject = project.copyWith(lastUpdateDate: DateTime.now());

      if (_uid != null) {
        await _firestoreService.upsertProject(_uid!, updatedProject);
      } else {
        await _dbService.updateProject(updatedProject);
      }

      if (project.status == 'en_cours') {
        try {
          await _notificationService.scheduleProjectNotification(updatedProject);
        } catch (e) {
          // ignore: avoid_print
          print('Project notification scheduling failed: $e');
        }
      }

      await loadProjects();
    } catch (e) {
      // ignore: avoid_print
      print('Error updating project: $e');
      rethrow;
    }
  }

  // Delete a project
  Future<void> deleteProject(String projectId) async {
    try {
      if (_uid != null) {
        await _firestoreService.deleteProject(_uid!, projectId);
      } else {
        await _dbService.deleteProject(projectId);
      }
      await _notificationService.cancelNotification(projectId.hashCode);
      await loadProjects();
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting project: $e');
      rethrow;
    }
  }

  // Update project progress based on tasks
  Future<void> updateProjectProgress(String projectId) async {
    try {
      int totalTasks = 0;
      int completedTasks = 0;

      if (_uid != null) {
        final tasks = await _firestoreService.getTasksByProject(_uid!, projectId);
        totalTasks = tasks.length;
        completedTasks = tasks.where((t) => t.isCompleted).length;
      } else {
        totalTasks = await _dbService.getTotalTasksCount(projectId);
        completedTasks = await _dbService.getCompletedTasksCount(projectId);
      }

      final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

      Project? project;
      if (_uid != null) {
        try {
          project = _projects.firstWhere((p) => p.id == projectId);
        } catch (_) {
          project = null;
        }
      } else {
        project = await _dbService.getProjectById(projectId);
      }

      if (project != null) {
        final updatedProject = project.copyWith(
          progress: progress,
          lastUpdateDate: DateTime.now(),
        );

        if (_uid != null) {
          await _firestoreService.upsertProject(_uid!, updatedProject);
        } else {
          await _dbService.updateProject(updatedProject);
        }

        await _notificationService.scheduleProjectNotification(updatedProject);
        await _notifyProgressMilestone(project: project, updatedProject: updatedProject);
        await loadProjects();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error updating project progress: $e');
    }
  }

  // ========== TASK OPERATIONS ==========

  // Load tasks for a specific project
  Future<void> loadProjectTasks(String projectId) async {
    try {
      if (_uid != null) {
        _currentProjectTasks = await _firestoreService.getTasksByProject(_uid!, projectId);
      } else {
        _currentProjectTasks = await _dbService.getTasksByProject(projectId);
      }
      notifyListeners();
    } catch (e) {
      // ignore: avoid_print
      print('Error loading tasks: $e');
    }
  }

  // Add a task to a project
  Future<void> addTask(Task task) async {
    try {
      if (_uid != null) {
        await _firestoreService.upsertTask(_uid!, task);
      } else {
        await _dbService.insertTask(task);
      }
      await loadProjectTasks(task.projectId);
      await updateProjectProgress(task.projectId);
    } catch (e) {
      // ignore: avoid_print
      print('Error adding task: $e');
      rethrow;
    }
  }

  // Update a task
  Future<void> updateTask(Task task) async {
    try {
      if (_uid != null) {
        await _firestoreService.upsertTask(_uid!, task);
      } else {
        await _dbService.updateTask(task);
      }
      await loadProjectTasks(task.projectId);
      await updateProjectProgress(task.projectId);
    } catch (e) {
      // ignore: avoid_print
      print('Error updating task: $e');
      rethrow;
    }
  }

  // Toggle task completion
  Future<void> toggleTaskCompletion(Task task) async {
    try {
      final updatedTask = task.copyWith(
        isCompleted: !task.isCompleted,
        completedAt: !task.isCompleted ? DateTime.now() : null,
      );
      await updateTask(updatedTask);
    } catch (e) {
      // ignore: avoid_print
      print('Error toggling task: $e');
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId, String projectId) async {
    try {
      if (_uid != null) {
        await _firestoreService.deleteTask(_uid!, projectId, taskId);
      } else {
        await _dbService.deleteTask(taskId);
      }
      await loadProjectTasks(projectId);
      await updateProjectProgress(projectId);
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting task: $e');
      rethrow;
    }
  }

  // ========== STATISTICS ==========

  Future<Map<String, int>> getStatistics() async {
    if (_uid != null) {
      if (_projects.isEmpty) {
        await loadProjects();
      }
      int total = _projects.length;
      int enCours = _projects.where((p) => p.status == 'en_cours').length;
      int termines = _projects.where((p) => p.status == 'terminé').length;
      int abandonnes = _projects.where((p) => p.status == 'abandonné').length;
      int enRetard = _projects.where((p) => p.isOverdue).length;

      return {
        'total': total,
        'en_cours': enCours,
        'terminés': termines,
        'abandonnés': abandonnes,
        'en_retard': enRetard,
      };
    }

    return await _dbService.getProjectStatistics();
  }

  Future<void> _syncProjectNotifications() async {
    for (final project in _projects) {
      if (project.status == 'en_cours') {
        await _notificationService.scheduleProjectNotification(project);
      }
    }
  }

  Future<void> _notifyProgressMilestone({
    required Project project,
    required Project updatedProject,
  }) async {
    if (project.status != 'en_cours') return;

    const milestones = [0.25, 0.5, 0.75, 1.0];
    final previous = project.progress;
    final current = updatedProject.progress;

    for (final milestone in milestones) {
      if (previous < milestone && current >= milestone) {
        final percent = (milestone * 100).toInt();
        await _notificationService.sendImmediateNotification(
          title: 'ðŸ“ˆ ${project.title} progresse',
          body: percent == 100
              ? 'Bravo, projet terminÃ© Ã  100% !'
              : 'Tu as atteint $percent% de progression. Continue comme Ã§a.',
          payload: project.id,
        );
        break;
      }
    }
  }
}

