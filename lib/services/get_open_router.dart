import 'dart:convert';
import 'package:sessame/services/api_key.dart';
import 'package:http/http.dart' as http;
import '../models/project.dart';
import '../models/message.dart';
import '../models/task.dart';

Future<String> getOpenRouterResponse(
  String userInput, {
  List<Message>? conversationHistory,
  List<Project>? userProjects,
  Map<String, List<Task>>? projectTasks, // Map projectId -> tasks
  bool allowPaidFallback = true, // Par défaut, autoriser le fallback payant
}) async {
  const endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  final headers = {
    'Authorization': 'Bearer $apikey',
    'Content-Type': 'application/json',
    'HTTP-Referer': 'https://github.com/your-repo', // Optionnel mais recommandé
    'X-Title': 'Sessame - Gestion de Projets', // Pour les modèles gratuits
  };

  // Construire le contexte avec les projets de l'utilisateur
  String contextPrompt = '';
  if (userProjects != null && userProjects.isNotEmpty) {
    contextPrompt = '''
Tu es le meilleur ami de l'utilisateur.
Un pote de 20–25 ans : cool, motivant, un peu taquin, jamais méchant.

Ton rôle est d'aider l'utilisateur à avancer sur ses projets, 
même quand il procrastine ou qu'il est en retard.

CONTEXTE - Projets de l'utilisateur :
''';
    for (var project in userProjects) {
      final progressPercent = (project.progress * 100).toInt();
      final daysRemaining = project.daysRemaining;

      // Récupérer les tâches pour ce projet
      final tasks = projectTasks?[project.id] ?? [];
      final completedTasks = tasks.where((t) => t.isCompleted).length;
      final totalTasks = tasks.length;

      contextPrompt +=
          '''
📋 Projet : "${project.title}"
📝 Description : ${project.description}
📊 Progression : $progressPercent%
⏰ Jours restants : $daysRemaining jour${daysRemaining.abs() > 1 ? 's' : ''}${project.isOverdue ? ' ⚠️ EN RETARD' : ''}
✅ Tâches complétées : $completedTasks sur $totalTasks
${project.status != 'en_cours' ? '📌 Statut : ${project.status}' : ''}

''';
    }
    contextPrompt += '''
Quand l'utilisateur te parle de ses projets ou te demande de l'aide :

Ton message doit :
- Sonner comme un message d'ami (pas de ton pro)
- Être motivant mais honnête
- Taquiner légèrement si l'utilisateur traîne
- Encourager si l'utilisateur avance
- Être court et actionnable
- Utiliser un français naturel, jeune et amical
- Possiblement inclure une petite vanne ou provocation gentille 😏

⚠️ Règles importantes :
- Reste naturel et conversationnel
- Référence les projets de l'utilisateur quand c'est pertinent
- Sois son pote, pas son coach corporate

''';
  } else {
    contextPrompt = '''
Tu es le meilleur ami de l'utilisateur.
Un pote de 20–25 ans : cool, motivant, un peu taquin, jamais méchant.

L'utilisateur n'a pas encore de projets enregistrés. 
Tu peux l'aider à en créer ou répondre à ses questions générales de manière décontractée et amicale.

''';
  }

  // Construire l'historique de conversation
  final List<Map<String, String>> messages = [];

  // Ajouter le contexte système
  messages.add({'role': 'system', 'content': contextPrompt});

  // Ajouter l'historique de conversation (sans le dernier message utilisateur)
  if (conversationHistory != null && conversationHistory.isNotEmpty) {
    for (var msg in conversationHistory) {
      messages.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.content,
      });
    }
  }

  // Ajouter le message actuel de l'utilisateur
  messages.add({'role': 'user', 'content': userInput});

  // Fonction pour faire une requête avec un modèle spécifique
  Future<String> _makeRequest(String model) async {
    final body = jsonEncode({
      'model': model,
      'messages': messages,
      'max_tokens': 800,
      'temperature': 0.7,
    });

    final response = await http.post(
      Uri.parse(endpoint),
      headers: headers,
      body: body,
    );

    print('Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] ?? 'Pas de réponse';
    } else {
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['error']?['message'] ?? response.body;
      throw Exception('Erreur API (${response.statusCode}): $errorMessage');
    }
  }

  // Liste des modèles gratuits à essayer (par ordre de préférence)
  // Note: gpt-4o-mini n'est PAS gratuit sur OpenRouter, il est payant
  final List<String> freeModels = [
    'openai/gpt-oss-120b:free', // Modèle gratuit OpenAI (120B paramètres)
    'meta-llama/llama-3.2-3b-instruct:free', // Llama 3.2 3B (si disponible)
    'google/gemini-flash-1.5:free', // Gemini Flash (si disponible)
    'mistralai/mistral-7b-instruct:free', // Mistral 7B (si disponible)
    'huggingface/zephyr-7b-beta:free', // Zephyr 7B (si disponible)
  ];

  // Essayer chaque modèle gratuit jusqu'à ce qu'un fonctionne
  Exception? lastError;

  for (int i = 0; i < freeModels.length; i++) {
    try {
      print('Tentative avec le modèle: ${freeModels[i]}');
      return await _makeRequest(freeModels[i]);
    } on Exception catch (e) {
      final errorStr = e.toString();
      lastError = e;

      // Si erreur 429 (rate limit) ou 404 (policy), essayer le modèle suivant
      if (errorStr.contains('429') || errorStr.contains('404')) {
        print('Modèle ${freeModels[i]} indisponible, essai du suivant...');

        // Attendre un peu avant de réessayer (sauf pour le dernier)
        if (i < freeModels.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
        continue; // Essayer le modèle suivant
      } else {
        // Pour les autres erreurs, relancer directement
        rethrow;
      }
    }
  }

  // Si tous les modèles gratuits ont échoué
  if (allowPaidFallback) {
    // Essayer gpt-4o-mini (payant mais peu cher)
    print(
      'Tous les modèles gratuits ont échoué, essai avec gpt-4o-mini (payant ~\$0.15/1M tokens)...',
    );
    try {
      return await _makeRequest('openai/gpt-4o-mini');
    } catch (e2) {
      // Message d'erreur final
      if (lastError != null && lastError.toString().contains('429')) {
        throw Exception(
          'Tous les modèles gratuits ont atteint leur limite de requêtes. '
          'Veuillez patienter quelques instants avant de réessayer. '
          'Les modèles gratuits ont des limites de taux pour éviter les abus.',
        );
      }
      throw Exception('Erreur de connexion: ${lastError ?? e2}');
    }
  } else {
    // Si le fallback payant est désactivé, lancer une erreur
    if (lastError != null && lastError.toString().contains('429')) {
      throw Exception(
        'Tous les modèles gratuits ont atteint leur limite de requêtes. '
        'Veuillez patienter quelques instants avant de réessayer. '
        'Les modèles gratuits ont des limites de taux pour éviter les abus.',
      );
    }
    throw Exception(
      'Tous les modèles gratuits ont échoué. '
      'Erreur: ${lastError?.toString() ?? "Inconnue"}',
    );
  }
}
