import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../models/task.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  /// URL de ton backend Node.js sur Railway
  /// À remplacer par ton URL après le déploiement
  static const String _backendUrl =
      'https://hopeful-courtesy-production.up.railway.app'; // Replace with your Railway URL
  static const String _model = 'openrouter/free';



  // Méthode d'initialisation (pour compatibilité)
  void initialize() {
    // Rien à initialiser maintenant
  }

  Future<String> _callOpenRouter(String prompt) async {
    return _callOpenRouterWithMessages(
      [
        {"role": "user", "content": prompt},
      ],
    );
  }

  Future<String> _callOpenRouterWithMessages(
    List<Map<String, String>> messages, {
    String? model,
    int maxTokens = 800,
    double temperature = 0.7,
  }) async {
    final headers = {
      "Content-Type": "application/json",
    };

    final prefs = await SharedPreferences.getInstance();
    final clientProfile = {
      "name": prefs.getString("profile_name") ?? "",
      "age": prefs.getString("profile_age") ?? "",
      "gender": prefs.getString("profile_gender") ?? "",
      "address": prefs.getString("profile_address") ?? "",
    };

    final body = jsonEncode({
      "model": model ?? _model,
      "client_profile": clientProfile,
      "messages": messages,
      "max_tokens": maxTokens,
      "temperature": temperature,
    });

    try {
      final response = await http
          .post(
            Uri.parse("$_backendUrl/api/openrouter"),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 25));

      print("AI Service - Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["choices"][0]["message"]["content"] ?? "Pas de réponse";
      } else {
        String errorMessage = response.body;
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData["error"]?.toString() ?? response.body;
        } catch (_) {}
        print("AI Service - Erreur: $errorMessage");
        throw Exception("Erreur Backend (${response.statusCode}): $errorMessage");
      }
    } catch (e) {
      print("AI Service - Exception: $e");
      rethrow;
    }
  }

  Future<String> callWithMessages(
    List<Map<String, String>> messages, {
    String? model,
    int maxTokens = 800,
    double temperature = 0.7,
  }) {
    return _callOpenRouterWithMessages(
      messages,
      model: model,
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }
  /// Analyse le projet et donne un conseil personnalisé
  Future<String> getProjectAdvice({
    required Project project,
    required List<Task> tasks,
  }) async {
    try {
      final completedTasks = tasks.where((t) => t.isCompleted).length;
      final totalTasks = tasks.length;
      final progressPercent = (project.progress * 100).toInt();

      final prompt =
          """
Tu es un coach en productivité bienveillant et motivant qui aide les gens à atteindre leurs objectifs.

Analyse ce projet et donne UN SEUL conseil court (maximum 2 phrases) pour aider l'utilisateur :

📋 Projet : "${project.title}"
📝 Description : ${project.description}
📊 Progression : $progressPercent%
⏰ Jours restants : ${project.daysRemaining} jour${project.daysRemaining.abs() > 1 ? 's' : ''}
${project.isOverdue ? '⚠️ EN RETARD' : ''}
✅ Tâches complétées : $completedTasks sur $totalTasks

Ton conseil doit être :
- Court et actionnable
- Motivant et positif
- Adapté à la situation (en retard, en avance, bloqué, etc.)
- En français naturel et amical

Réponds UNIQUEMENT avec le conseil, sans introduction.
""";

      final response = await _callOpenRouter(prompt);
      return response.trim();
    } catch (e) {
      print('Erreur IA getProjectAdvice: $e');
      return "Je suis là pour t'aider ! Lance-moi à nouveau pour des conseils. 🚀";
    }
  }

  /// Suggère des tâches intelligentes basées sur le titre et la description du projet
  Future<List<String>> suggestTasks({
    required String projectTitle,
    required String projectDescription,
  }) async {
    try {
      final prompt =
          """
Tu es un expert en découpage de projets et en productivité.

Projet : "$projectTitle"
Description : $projectDescription

Suggère exactement 5 étapes concrètes et actionnables pour réussir ce projet.

Règles :
- Chaque étape doit commencer par un verbe d'action
- Être spécifique et mesurable
- Ordonnées logiquement
- Courtes (maximum 8 mots par étape)

Format de réponse (une ligne par étape, sans numéros) :
Rechercher les meilleures ressources disponibles
Définir un planning réaliste
...

Réponds UNIQUEMENT avec les 5 étapes, une par ligne, sans numérotation ni introduction.
""";

      final response = await _callOpenRouter(prompt);
      return response
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .take(5)
          .toList();
    } catch (e) {
      print('Erreur IA suggestTasks: $e');
      return [];
    }
  }

  /// Message de motivation quotidien
  Future<String> getDailyMotivation() async {
    try {
      final prompt = """
Donne UNE phrase de motivation courte et percutante pour encourager quelqu'un à travailler sur ses projets aujourd'hui.

Style : positif, énergique, pas cliché.
Langue : français.
Longueur : maximum 15 mots.

Réponds UNIQUEMENT avec la phrase, sans guillemets.
""";

      final response = await _callOpenRouter(prompt);
      return response.trim();
    } catch (e) {
      print('Erreur motivation: $e');
      return "Fais de ton mieux aujourd'hui ! 💪";
    }
  }
}


