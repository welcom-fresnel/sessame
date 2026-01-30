class Project {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime deadline;
  final double progress; // 0.0 to 1.0
  final String status; // 'en_cours', 'terminé', 'abandonné'
  final int notificationFrequency; // Nombre de jours entre les notifications
  final DateTime? lastNotificationDate;
  final DateTime? lastUpdateDate;
  final String? category; // Catégorie du projet (ex: 'Travail', 'Personnel', 'Études', etc.)
  final String? imagePath; // Chemin vers l'image/photo du projet

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.deadline,
    this.progress = 0.0,
    this.status = 'en_cours',
    this.notificationFrequency = 3,
    this.lastNotificationDate,
    this.lastUpdateDate,
    this.category,
    this.imagePath,
  });

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'deadline': deadline.toIso8601String(),
      'progress': progress,
      'status': status,
      'notificationFrequency': notificationFrequency,
      'lastNotificationDate': lastNotificationDate?.toIso8601String(),
      'lastUpdateDate': lastUpdateDate?.toIso8601String(),
      'category': category,
      'imagePath': imagePath,
    };
  }

  // Create from Map
  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
      deadline: DateTime.parse(map['deadline']),
      progress: map['progress'],
      status: map['status'],
      notificationFrequency: map['notificationFrequency'],
      lastNotificationDate: map['lastNotificationDate'] != null
          ? DateTime.parse(map['lastNotificationDate'])
          : null,
      lastUpdateDate: map['lastUpdateDate'] != null
          ? DateTime.parse(map['lastUpdateDate'])
          : null,
      category: map['category'],
      imagePath: map['imagePath'],
    );
  }

  // Copy with method for updates
  Project copyWith({
    String? title,
    String? description,
    DateTime? deadline,
    double? progress,
    String? status,
    int? notificationFrequency,
    DateTime? lastNotificationDate,
    DateTime? lastUpdateDate,
    String? category,
    String? imagePath,
  }) {
    return Project(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt,
      deadline: deadline ?? this.deadline,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      notificationFrequency: notificationFrequency ?? this.notificationFrequency,
      lastNotificationDate: lastNotificationDate ?? this.lastNotificationDate,
      lastUpdateDate: lastUpdateDate ?? this.lastUpdateDate,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  // Calculate days remaining
  int get daysRemaining {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    return difference.inDays;
  }

  // Check if overdue
  bool get isOverdue {
    return DateTime.now().isAfter(deadline) && status != 'terminé';
  }
}

