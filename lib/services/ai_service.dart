import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/project.dart';
import '../models/task.dart';
import 'api_key.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  static const String _endpoint =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String _model = 'openai/gpt-oss-120b:free';

  // Méthode d'initialisation (pour compatibilité)
  void initialize() {
    // Rien à initialiser maintenant
  }

  Future<String> _callOpenRouter(String prompt) async {
    final headers = {
      'Authorization': 'Bearer $apikey',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://github.com/appexdev4/sessame.git',
    };

    final body = jsonEncode({
      'model': _model,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'max_tokens': 800,
      'temperature': 0.7,
    });

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: headers,
        body: body,
      );

      print('AI Service - Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'Pas de réponse';
      } else {
        final errorData = jsonDecode(response.body);
        print(
          'AI Service - Erreur: ${errorData['error']?['message'] ?? response.body}',
        );
        throw Exception('Erreur API (${response.statusCode})');
      }
    } catch (e) {
      print('AI Service - Exception: $e');
      rethrow;
    }
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
