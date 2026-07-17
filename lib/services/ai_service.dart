import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../models/task.dart';

class PremiumAIAdviceStep {
  final String title;
  final String description;

  const PremiumAIAdviceStep({required this.title, required this.description});
}

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  /// À remplacer par ton URL après le déploiement
  static const String _backendUrl = 'https://sessame.onrender.com'; // Replace with your Railway URL
  static const String _model = 'gpt-4o-mini';



  // Méthode d'initialisation (pour compatibilité)
  void initialize() {
    // Rien à initialiser maintenant
  }

  Future<String> _callchatgpt(String prompt) async {
    return _callchatgptWithMessages(
      [
        {"role": "user", "content": prompt},
      ],
    );
  }

  Future<String> _callchatgptWithMessages(
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
            Uri.parse("$_backendUrl/api/chatgpt"),
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
    return _callchatgptWithMessages(
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

      final response = await _callchatgpt(prompt);
      return response.trim();
    } catch (e) {
      print('Erreur IA getProjectAdvice: $e');
      return "Je suis là pour t'aider ! Lance-moi à nouveau pour des conseils. 🚀";
    }
  }

  Future<List<PremiumAIAdviceStep>> getPremiumProjectAdviceSteps({
    required Project project,
    required List<Task> tasks,
  }) async {
    try {
      final completedTasks = tasks.where((t) => t.isCompleted).length;
      final totalTasks = tasks.length;
      final progressPercent = (project.progress * 100).toInt();

      // Construire les listes de titres avant l'appel pour respecter la règle "ne jamais reproposer"
      final completedTaskTitles = tasks
          .where((t) => t.isCompleted)
          .map((t) => t.title.replaceAll('\n', ' ').trim())
          .toList();

      final remainingTaskTitles = tasks
          .where((t) => !t.isCompleted)
          .map((t) => t.title.replaceAll('\n', ' ').trim())
          .toList();

            final prompt =
              """
          Tu es un coach projet premium, direct et très concret. Tu ne fais jamais de blabla motivationnel générique.

          CONTEXTE PROJET
          Titre : ${project.title}
          Description : ${project.description}
          Progression : $progressPercent%
          Jours restants : ${project.daysRemaining} jour${project.daysRemaining.abs() > 1 ? 's' : ''}
          Statut : ${project.isOverdue ? 'EN RETARD' : 'dans les temps'}
          Tâches déjà complétées ($completedTasks/$totalTasks) : ${completedTaskTitles.isNotEmpty ? completedTaskTitles.join(', ') : 'Aucune'}
          Tâches restantes non terminées : ${remainingTaskTitles.isNotEmpty ? remainingTaskTitles.join(', ') : 'Aucune'}

          MISSION
          Propose exactement 5 étapes concrètes et actionnables pour faire avancer ce projet.

          RÈGLES STRICTES
          - Ne jamais reproposer une étape déjà couverte par les tâches complétées ou restantes listées ci-dessus
          - Les 5 étapes doivent être dans un ordre logique d'exécution (dépendances respectées)
          - Si le projet est EN RETARD : la première étape doit être une action de rattrapage ou de recadrage (pas une étape normale de progression)
          - Si la progression est à 0% ou proche : commencer par une étape de cadrage/démarrage concrète
          - Chaque titre : 3 à 7 mots, commence par un verbe d'action à l'infinitif
          - Chaque détail : 1 à 2 phrases maximum, dit précisément QUOI faire, avec QUOI/QUI, et quel résultat attendu — jamais de conseil vague type "prends le temps de réfléchir"
          - Langue : français naturel, ton direct, zéro superflu
          - Aucun texte avant la première étape, aucun texte après la dernière
          - Respecte EXACTEMENT le format ci-dessous, sans emoji, sans markdown, sans numérotation manuelle

          FORMAT DE SORTIE OBLIGATOIRE (rien d'autre)
          TITRE: [titre étape 1]
          DETAIL: [détail étape 1]
          ---
          TITRE: [titre étape 2]
          DETAIL: [détail étape 2]
          ---
          TITRE: [titre étape 3]
          DETAIL: [détail étape 3]
          ---
          TITRE: [titre étape 4]
          DETAIL: [détail étape 4]
          ---
          TITRE: [titre étape 5]
          DETAIL: [détail étape 5]
          """;
      final response = await _callchatgptWithMessages(
        [
          {"role": "user", "content": prompt},
        ],
        maxTokens: 1200,
        temperature: 0.65,
      );

      final steps = _parsePremiumSteps(response);
      if (steps.isNotEmpty) return steps.take(5).toList();

      return [
        const PremiumAIAdviceStep(
          title: 'Identifier la priorité immédiate',
          description:
              'Choisis l’action qui fera le plus avancer le projet aujourd’hui. Note ce qui doit être terminé, fixe un résultat clair, puis commence uniquement par cette action avant de passer au reste.',
        ),
      ];
    } catch (e) {
      print('Erreur IA getPremiumProjectAdviceSteps: $e');
      return [
        const PremiumAIAdviceStep(
          title: 'Reprendre avec une action simple',
          description:
              'Commence par relire l’objectif du projet, choisis une petite tâche faisable maintenant, puis termine-la avant d’en ajouter une autre. Cela permet de relancer l’avancement sans pression.',
        ),
      ];
    }
  }

  List<PremiumAIAdviceStep> _parsePremiumSteps(String response) {
    // Split en blocs en tolérant des espaces et lignes vides autour des séparateurs '---'
    final separator = RegExp(r"\n\s*---\s*\n");
    final blocks = response.split(separator);
    final steps = <PremiumAIAdviceStep>[];

    for (final block in blocks) {
      final trimmedBlock = block.trim();
      if (trimmedBlock.isEmpty) continue;

      final lines = trimmedBlock
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      String? title;
      String? detail;

      for (final line in lines) {
        if (line.toUpperCase().startsWith('TITRE:')) {
          title = line.substring(6).trim();
        } else if (line.toUpperCase().startsWith('DETAIL:')) {
          detail = line.substring(7).trim();
        } else if (detail != null) {
          detail = '$detail ${line.trim()}';
        }
      }

      if (title != null && title.isNotEmpty && detail != null && detail.isNotEmpty) {
        steps.add(PremiumAIAdviceStep(title: title, description: detail));
      }
    }

    return steps;
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

      final response = await _callchatgpt(prompt);
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

      final response = await _callchatgpt(prompt);
      return response.trim();
    } catch (e) {
      print('Erreur motivation: $e');
      return "Fais de ton mieux aujourd'hui ! 💪";
    }
  }
}


