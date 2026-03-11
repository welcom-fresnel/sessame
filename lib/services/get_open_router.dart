import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:sessame/services/api_key.dart';

import '../models/message.dart';
import '../models/project.dart';
import '../models/task.dart';

class AIUserVisibleException implements Exception {
  final String message;
  const AIUserVisibleException(this.message);

  @override
  String toString() => message;
}

Future<String> getOpenRouterResponse(
  String userInput, {
  List<Message>? conversationHistory,
  List<Project>? userProjects,
  Map<String, List<Task>>? projectTasks,
  bool allowPaidFallback = true,
}) async {
  const endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  if (apikey.isEmpty) {
    throw const AIUserVisibleException(
      'Cle API manquante. Ajoute API_KEY dans .env ou --dart-define puis relance.',
    );
  }

  final headers = {
    'Authorization': 'Bearer $apikey',
    'Content-Type': 'application/json',
    'HTTP-Referer': 'https://github.com/appexdev4/sessame.git',
    'X-Title': 'Sessame - Gestion de Projets',
  };

  String contextPrompt = '';
  if (userProjects != null && userProjects.isNotEmpty) {
    contextPrompt = '''
Tu es le meilleur ami de l'utilisateur.
Un pote de 20-25 ans : cool, motivant, un peu taquin, jamais mechant.

Ton role est d'aider l'utilisateur a avancer sur ses projets,
meme quand il procrastine ou qu'il est en retard.

CONTEXTE - Projets de l'utilisateur :
''';

    for (final project in userProjects) {
      final progressPercent = (project.progress * 100).toInt();
      final daysRemaining = project.daysRemaining;
      final tasks = projectTasks?[project.id] ?? [];
      final completedTasks = tasks.where((t) => t.isCompleted).length;
      final totalTasks = tasks.length;

      contextPrompt += '''
Projet : "${project.title}"
Description : ${project.description}
Progression : $progressPercent%
Jours restants : $daysRemaining jour${daysRemaining.abs() > 1 ? 's' : ''}${project.isOverdue ? ' EN RETARD' : ''}
Taches completees : $completedTasks sur $totalTasks
${project.status != 'en_cours' ? 'Statut : ${project.status}' : ''}

''';
    }

    contextPrompt += '''
Quand l'utilisateur te parle de ses projets ou te demande de l'aide :
- Sonne comme un message d'ami
- Sois motivant mais honnete
- Taquine legerement si l'utilisateur traine
- Encourage si l'utilisateur avance
- Sois court et actionnable
- Utilise un francais naturel
''';
  } else {
    contextPrompt = '''
Tu es le meilleur ami de l'utilisateur.
Un pote de 20-25 ans : cool, motivant, un peu taquin, jamais mechant.

L'utilisateur n'a pas encore de projets enregistres.
Aide-le a en creer ou reponds de maniere decontractee et amicale.
''';
  }

  final List<Map<String, String>> messages = [
    {'role': 'system', 'content': contextPrompt},
  ];

  if (conversationHistory != null && conversationHistory.isNotEmpty) {
    for (final msg in conversationHistory) {
      messages.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.content,
      });
    }
  }

  messages.add({'role': 'user', 'content': userInput});

  Future<String> makeRequest(String model) async {
    final body = jsonEncode({
      'model': model,
      'messages': messages,
      'max_tokens': 800,
      'temperature': 0.7,
    });

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(endpoint),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw const AIUserVisibleException(
        'La requete a expire. Verifie ta connexion puis reessaie.',
      );
    } on SocketException {
      throw const AIUserVisibleException(
        'Impossible de contacter le serveur. Verifie internet et reessaie.',
      );
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content']?.toString() ?? 'Pas de reponse';
    }

    final errorMessage = _extractErrorMessage(response.body);
    switch (response.statusCode) {
      case 400:
        throw AIUserVisibleException('Requete invalide. Detail: $errorMessage');
      case 401:
      case 403:
        throw const AIUserVisibleException(
          'Cle API invalide ou non autorisee. Verifie ta API_KEY.',
        );
      case 402:
        throw const AIUserVisibleException(
          'Credits OpenRouter insuffisants. Ajoute du credit ou change de modele.',
        );
      case 404:
        throw AIUserVisibleException('Modele indisponible. Detail: $errorMessage');
      case 408:
        throw const AIUserVisibleException(
          'Le serveur met trop de temps a repondre. Reessaie dans quelques instants.',
        );
      case 429:
        throw const AIUserVisibleException(
          'Trop de requetes pour le moment. Attends 30-60 secondes puis reessaie.',
        );
      default:
        if (response.statusCode >= 500) {
          throw const AIUserVisibleException(
            'Le service IA est temporairement indisponible. Reessaie dans quelques minutes.',
          );
        }
        throw AIUserVisibleException(
          'Erreur API (${response.statusCode}): $errorMessage',
        );
    }
  }

  final freeModels = <String>[
    'openai/gpt-oss-120b:free',
    'meta-llama/llama-3.2-3b-instruct:free',
    'google/gemini-flash-1.5:free',
    'mistralai/mistral-7b-instruct:free',
    'huggingface/zephyr-7b-beta:free',
  ];

  Exception? lastError;

  for (var i = 0; i < freeModels.length; i++) {
    try {
      return await makeRequest(freeModels[i]);
    } on Exception catch (e) {
      lastError = e;
      final s = e.toString().toLowerCase();
      final retriable = s.contains('429') || s.contains('indisponible') || s.contains('404');
      if (retriable && i < freeModels.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }
      rethrow;
    }
  }

  if (allowPaidFallback) {
    try {
      return await makeRequest('openai/gpt-4o-mini');
    } catch (e) {
      if (lastError is AIUserVisibleException) {
        throw lastError;
      }
      throw AIUserVisibleException('Erreur de connexion: ${lastError ?? e}');
    }
  }

  if (lastError is AIUserVisibleException) {
    throw lastError;
  }

  throw AIUserVisibleException(
    'Tous les modeles gratuits ont echoue. Erreur: ${lastError ?? 'Inconnue'}',
  );
}

String _extractErrorMessage(String responseBody) {
  try {
    final errorData = jsonDecode(responseBody);
    return errorData['error']?['message']?.toString() ?? responseBody;
  } catch (_) {
    return responseBody;
  }
}

