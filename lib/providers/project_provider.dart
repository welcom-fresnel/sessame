import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class ProjectProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  List<Project> _projects = [];
  List<Task> _currentProjectTasks = [];
  bool _isLoading = false;

  List<Project> get projects => _projects;
  List<Task> get currentProjectTasks => _currentProjectTasks;
  bool get isLoading => _isLoading;

  // Filter projects
  List<Project> get activeProjects =>
      _projects.where((p) => p.status == 'en_cours').toList();

  List<Project> get completedProjects =>
      _projects.where((p) => p.status == 'terminé').toList();

  List<Project> get overdueProjects =>
      _projects.where((p) => p.isOverdue && p.status == 'en_cours').toList();

  // Initialize and load projects
  Future<void> initialize() async {
    await _notificationService.initialize();
    await loadProjects();
  }

  // Load all projects
  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      _projects = await _dbService.getAllProjects();
    } catch (e) {
      print('Error loading projects: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new project
  Future<void> addProject(Project project) async {
    try {
      await _dbService.insertProject(project);
      await _notificationService.scheduleProjectNotification(project);
      await loadProjects();
    } catch (e) {
      print('Error adding project: $e');
      rethrow;
    }
  }

  // Update a project
  Future<void> updateProject(Project project) async {
    try {
      // Update last update date
      final updatedProject = project.copyWith(
        lastUpdateDate: DateTime.now(),
      );

      await _dbService.updateProject(updatedProject);

      // Reschedule notification if project is still active
      if (project.status == 'en_cours') {
        await _notificationService.scheduleProjectNotification(updatedProject);
      }

      await loadProjects();
    } catch (e) {
      print('Error updating project: $e');
      rethrow;
    }
  }

  // Delete a project
  Future<void> deleteProject(String projectId) async {
    try {
      await _dbService.deleteProject(projectId);
      await _notificationService.cancelNotification(projectId.hashCode);
      await loadProjects();
    } catch (e) {
      print('Error deleting project: $e');
      rethrow;
    }
  }

  // Update project progress based on tasks
  Future<void> updateProjectProgress(String projectId) async {
    try {
      final totalTasks = await _dbService.getTotalTasksCount(projectId);
      final completedTasks = await _dbService.getCompletedTasksCount(projectId);

      final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

      final project = await _dbService.getProjectById(projectId);
      if (project != null) {
        final updatedProject = project.copyWith(
          progress: progress,
          lastUpdateDate: DateTime.now(),
        );
        await _dbService.updateProject(updatedProject);
        await loadProjects();
      }
    } catch (e) {
      print('Error updating project progress: $e');
    }
  }

  // ========== TASK OPERATIONS ==========

  // Load tasks for a specific project
  Future<void> loadProjectTasks(String projectId) async {
    try {
      _currentProjectTasks = await _dbService.getTasksByProject(projectId);
      notifyListeners();
    } catch (e) {
      print('Error loading tasks: $e');
    }
  }

  // Add a task to a project
  Future<void> addTask(Task task) async {
    try {
      await _dbService.insertTask(task);
      await loadProjectTasks(task.projectId);
      await updateProjectProgress(task.projectId);
    } catch (e) {
      print('Error adding task: $e');
      rethrow;
    }
  }

  // Update a task
  Future<void> updateTask(Task task) async {
    try {
      await _dbService.updateTask(task);
      await loadProjectTasks(task.projectId);
      await updateProjectProgress(task.projectId);
    } catch (e) {
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
      print('Error toggling task: $e');
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId, String projectId) async {
    try {
      await _dbService.deleteTask(taskId);
      await loadProjectTasks(projectId);
      await updateProjectProgress(projectId);
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }

  // ========== STATISTICS ==========

  Future<Map<String, int>> getStatistics() async {
    return await _dbService.getProjectStatistics();
  }
}

