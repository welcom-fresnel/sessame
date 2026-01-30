import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'sessame.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create Projects table
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        deadline TEXT NOT NULL,
        progress REAL NOT NULL DEFAULT 0.0,
        status TEXT NOT NULL DEFAULT 'en_cours',
        notificationFrequency INTEGER NOT NULL DEFAULT 3,
        lastNotificationDate TEXT,
        lastUpdateDate TEXT
      )
    ''');

    // Create Tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        projectId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        completedAt TEXT,
        "order" INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    // Create Conversations table
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Create Messages table
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversationId TEXT NOT NULL,
        content TEXT NOT NULL,
        isUser INTEGER NOT NULL DEFAULT 1,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (conversationId) REFERENCES conversations (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add conversations and messages tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS conversations (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS messages (
          id TEXT PRIMARY KEY,
          conversationId TEXT NOT NULL,
          content TEXT NOT NULL,
          isUser INTEGER NOT NULL DEFAULT 1,
          timestamp TEXT NOT NULL,
          FOREIGN KEY (conversationId) REFERENCES conversations (id) ON DELETE CASCADE
        )
      ''');
    }
    
    if (oldVersion < 3) {
      // Add category and imagePath columns to projects table
      try {
        await db.execute('ALTER TABLE projects ADD COLUMN category TEXT');
        await db.execute('ALTER TABLE projects ADD COLUMN imagePath TEXT');
        print('✅ Colonnes category et imagePath ajoutées à la table projects');
      } catch (e) {
        // Les colonnes existent peut-être déjà
        print('⚠️ Erreur lors de l\'ajout des colonnes: $e');
      }
    }
  }

  // ========== PROJECT OPERATIONS ==========

  Future<void> insertProject(Project project) async {
    final db = await database;
    await db.insert(
      'projects',
      project.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Project>> getAllProjects() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'projects',
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Project.fromMap(maps[i]));
  }

  Future<Project?> getProjectById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Project.fromMap(maps.first);
  }

  Future<void> updateProject(Project project) async {
    final db = await database;
    await db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<void> deleteProject(String id) async {
    final db = await database;
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);
    // Tasks will be deleted automatically due to CASCADE
  }

  Future<List<Project>> getProjectsByStatus(String status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'projects',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'deadline ASC',
    );
    return List.generate(maps.length, (i) => Project.fromMap(maps[i]));
  }

  // ========== TASK OPERATIONS ==========

  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Task>> getTasksByProject(String projectId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'projectId = ?',
      whereArgs: [projectId],
      orderBy: '"order" ASC, createdAt ASC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getCompletedTasksCount(String projectId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE projectId = ? AND isCompleted = 1',
      [projectId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalTasksCount(String projectId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE projectId = ?',
      [projectId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ========== STATISTICS ==========

  Future<Map<String, int>> getProjectStatistics() async {
    final projects = await getAllProjects();
    int total = projects.length;
    int enCours = projects.where((p) => p.status == 'en_cours').length;
    int termines = projects.where((p) => p.status == 'terminé').length;
    int abandonnes = projects.where((p) => p.status == 'abandonné').length;
    int enRetard = projects.where((p) => p.isOverdue).length;

    return {
      'total': total,
      'en_cours': enCours,
      'terminés': termines,
      'abandonnés': abandonnes,
      'en_retard': enRetard,
    };
  }

  // ========== CONVERSATION OPERATIONS ==========

  Future<void> insertConversation(Conversation conversation) async {
    final db = await database;
    await db.insert('conversations', {
      'id': conversation.id,
      'title': conversation.title,
      'createdAt': conversation.createdAt.toIso8601String(),
      'updatedAt': conversation.updatedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Insert all messages
    for (var message in conversation.messages) {
      await insertMessage(conversation.id, message);
    }
  }

  Future<List<Conversation>> getAllConversations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'conversations',
      orderBy: 'updatedAt DESC',
    );

    final List<Conversation> conversations = [];
    for (var map in maps) {
      final messages = await getMessagesByConversation(map['id']);
      conversations.add(
        Conversation(
          id: map['id'],
          title: map['title'],
          messages: messages,
          createdAt: DateTime.parse(map['createdAt']),
          updatedAt: DateTime.parse(map['updatedAt']),
        ),
      );
    }
    return conversations;
  }

  Future<Conversation?> getConversationById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;

    final map = maps.first;
    final messages = await getMessagesByConversation(id);
    return Conversation(
      id: map['id'],
      title: map['title'],
      messages: messages,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Future<void> updateConversation(Conversation conversation) async {
    final db = await database;
    await db.update(
      'conversations',
      {
        'title': conversation.title,
        'updatedAt': conversation.updatedAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [conversation.id],
    );
  }

  Future<void> deleteConversation(String id) async {
    final db = await database;
    await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
    // Messages will be deleted automatically due to CASCADE
  }

  // ========== MESSAGE OPERATIONS ==========

  Future<void> insertMessage(String conversationId, Message message) async {
    final db = await database;
    // Generate a unique ID for the message
    final messageId =
        '${conversationId}_${message.timestamp.millisecondsSinceEpoch}_${message.isUser ? 'u' : 'a'}';
    await db.insert('messages', {
      'id': messageId,
      'conversationId': conversationId,
      'content': message.content,
      'isUser': message.isUser ? 1 : 0,
      'timestamp': message.timestamp.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Message>> getMessagesByConversation(String conversationId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );
    return List.generate(
      maps.length,
      (i) => Message(
        content: maps[i]['content'],
        isUser: maps[i]['isUser'] == 1,
        timestamp: DateTime.parse(maps[i]['timestamp']),
      ),
    );
  }
}
