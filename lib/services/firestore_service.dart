import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/project.dart';
import '../models/task.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _userRoot(String uid) {
    return _firestore.collection('users').doc(uid).collection('projects');
  }

  DocumentReference<Map<String, dynamic>> _projectRef(String uid, String projectId) {
    return _firestore.collection('users').doc(uid).collection('projects').doc(projectId);
  }

  CollectionReference<Map<String, dynamic>> _tasksRef(String uid, String projectId) {
    return _projectRef(uid, projectId).collection('tasks');
  }

  Map<String, dynamic> _projectToFirestore(Project p) {
    return {
      'id': p.id,
      'title': p.title,
      'description': p.description,
      'createdAt': Timestamp.fromDate(p.createdAt),
      'deadline': Timestamp.fromDate(p.deadline),
      'progress': p.progress,
      'status': p.status,
      'notificationFrequency': p.notificationFrequency,
      'lastNotificationDate':
          p.lastNotificationDate != null ? Timestamp.fromDate(p.lastNotificationDate!) : null,
      'lastUpdateDate': p.lastUpdateDate != null ? Timestamp.fromDate(p.lastUpdateDate!) : null,
      'category': p.category,
      'imagePath': p.imagePath,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Project _projectFromFirestore(Map<String, dynamic> map) {
    DateTime? tsToDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return Project(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      createdAt: tsToDate(map['createdAt']) ?? DateTime.now(),
      deadline: tsToDate(map['deadline']) ?? DateTime.now(),
      progress: (map['progress'] is num) ? (map['progress'] as num).toDouble() : 0.0,
      status: (map['status'] ?? 'en_cours').toString(),
      notificationFrequency: (map['notificationFrequency'] is num)
          ? (map['notificationFrequency'] as num).toInt()
          : 3,
      lastNotificationDate: tsToDate(map['lastNotificationDate']),
      lastUpdateDate: tsToDate(map['lastUpdateDate']),
      category: map['category']?.toString(),
      imagePath: map['imagePath']?.toString(),
    );
  }

  Map<String, dynamic> _taskToFirestore(Task t) {
    return {
      'id': t.id,
      'projectId': t.projectId,
      'title': t.title,
      'description': t.description,
      'isCompleted': t.isCompleted,
      'createdAt': Timestamp.fromDate(t.createdAt),
      'completedAt': t.completedAt != null ? Timestamp.fromDate(t.completedAt!) : null,
      'order': t.order,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Task _taskFromFirestore(Map<String, dynamic> map) {
    DateTime? tsToDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return Task(
      id: (map['id'] ?? '').toString(),
      projectId: (map['projectId'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: map['description']?.toString(),
      isCompleted: map['isCompleted'] == true,
      createdAt: tsToDate(map['createdAt']) ?? DateTime.now(),
      completedAt: tsToDate(map['completedAt']),
      order: (map['order'] is num) ? (map['order'] as num).toInt() : 0,
    );
  }

  Future<List<Project>> getAllProjects(String uid) async {
    final snap = await _userRoot(uid).orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => _projectFromFirestore(d.data())).toList();
  }

  Future<void> upsertProject(String uid, Project project) async {
    await _projectRef(uid, project.id).set(_projectToFirestore(project), SetOptions(merge: true));
  }

  Future<void> deleteProject(String uid, String projectId) async {
    final tasksSnap = await _tasksRef(uid, projectId).get();
    for (final doc in tasksSnap.docs) {
      await doc.reference.delete();
    }
    await _projectRef(uid, projectId).delete();
  }

  Future<List<Task>> getTasksByProject(String uid, String projectId) async {
    final snap = await _tasksRef(uid, projectId).orderBy('order').get();
    return snap.docs.map((d) => _taskFromFirestore(d.data())).toList();
  }

  Future<void> upsertTask(String uid, Task task) async {
    await _tasksRef(uid, task.projectId).doc(task.id).set(_taskToFirestore(task), SetOptions(merge: true));
  }

  Future<void> deleteTask(String uid, String projectId, String taskId) async {
    await _tasksRef(uid, projectId).doc(taskId).delete();
  }
}

