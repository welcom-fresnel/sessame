import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/project.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Android initialization settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final bool? initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        print('✅ Notifications initialisées avec succès');
      } else {
        print('⚠️ Notifications initialisées mais peut-être sans permissions');
      }

      // Créer le canal de notification Android (important!)
      await _createNotificationChannel();

      // Request permissions
      await _requestPermissions();

      _initialized = true;
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des notifications: $e');
      rethrow;
    }
  }

  // Créer le canal de notification Android (requis pour Android 8.0+)
  Future<void> _createNotificationChannel() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'project_reminders', // id
        'Rappels de projets', // name
        description: 'Notifications pour vous rappeler de faire le point sur vos projets',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await androidImplementation.createNotificationChannel(channel);
      print('✅ Canal de notification créé');
    }
  }

  Future<void> _requestPermissions() async {
    // Android 13+ permissions
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestNotificationsPermission();
      if (granted == true) {
        print('✅ Permissions Android accordées');
      } else {
        print('⚠️ Permissions Android refusées ou non disponibles');
      }
    }

    // iOS permissions
    final IOSFlutterLocalNotificationsPlugin? iosImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosImplementation != null) {
      final bool? granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (granted == true) {
        print('✅ Permissions iOS accordées');
      } else {
        print('⚠️ Permissions iOS refusées ou non disponibles');
      }
    }
  }

  // Vérifier si les permissions sont accordées
  Future<bool> arePermissionsGranted() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.areNotificationsEnabled();
      return granted ?? false;
    }

    // Pour iOS, on suppose que les permissions sont accordées si l'initialisation a réussi
    return true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    // You can navigate to the project detail page here
    print('Notification tapped: ${response.payload}');
  }

  // Schedule notification for a project
  Future<void> scheduleProjectNotification(Project project) async {
    if (!_initialized) await initialize();

    final now = DateTime.now();
    final nextNotificationDate = project.lastNotificationDate != null
        ? project.lastNotificationDate!.add(
            Duration(days: project.notificationFrequency),
          )
        : now.add(Duration(days: project.notificationFrequency));

    // Only schedule if the notification date is in the future and project is active
    if (nextNotificationDate.isAfter(now) &&
        project.status == 'en_cours' &&
        !project.isOverdue) {
      await _scheduleNotification(
        id: project.id.hashCode,
        title: '📋 Comment avance votre projet ?',
        body:
            'Bonjour ! Des nouvelles de "${project.title}" ? Prenez un moment pour faire le point.',
        scheduledDate: nextNotificationDate,
        payload: project.id,
      );
    }
  }

  // Schedule a notification at a specific time
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      // Vérifier les permissions avant de programmer
      final hasPermissions = await arePermissionsGranted();
      if (!hasPermissions) {
        print('⚠️ Permissions non accordées, impossible de programmer la notification');
        return;
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'project_reminders', // Doit correspondre au channel créé
        'Rappels de projets',
        channelDescription:
            'Notifications pour vous rappeler de faire le point sur vos projets',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true, // Utilise le son par défaut du système (pas besoin de .mp3)
        // Si vous voulez un son personnalisé, ajoutez: sound: RawResourceAndroidNotificationSound('notification_sound'),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true, // Utilise le son par défaut (pas besoin de .mp3)
        // Si vous voulez un son personnalisé, ajoutez: sound: 'notification_sound.caf',
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final scheduledTime = tz.TZDateTime.from(scheduledDate, tz.local);
      
      // Vérifier que la date est dans le futur
      if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
        print('⚠️ Date de notification dans le passé, annulation');
        return;
      }

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );

      print('✅ Notification programmée pour le ${scheduledTime.toString()}');
    } catch (e) {
      print('❌ Erreur lors de la programmation de la notification: $e');
      rethrow;
    }
  }

  // Send immediate notification
  Future<void> sendImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'project_reminders',
          'Rappels de projets',
          channelDescription: 'Notifications pour vos projets',
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
