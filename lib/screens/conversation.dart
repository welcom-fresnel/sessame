import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/get_open_router.dart';
import '../models/message.dart';
import '../models/task.dart';
import '../providers/conversation_provider.dart';
import '../providers/project_provider.dart';
import '../services/database_service.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});
  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final convProvider = context.read<ConversationProvider>();
      if (convProvider.conversations.isEmpty) {
        convProvider.createNewConversation();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _createNewConversation() async {
    await context.read<ConversationProvider>().createNewConversation();
  }

  void _switchConversation(int index) {
    context.read<ConversationProvider>().switchConversation(index);
    Navigator.pop(context); // Fermer le drawer
    _scrollToBottom();
  }

  Future<void> _deleteConversation(int index) async {
    final convProvider = context.read<ConversationProvider>();
    if (index < convProvider.conversations.length) {
      await convProvider.deleteConversation(
        convProvider.conversations[index].id,
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Écris quelque chose d\'abord !')),
      );
      return;
    }

    final convProvider = context.read<ConversationProvider>();
    final projectProvider = context.read<ProjectProvider>();

    if (convProvider.conversations.isEmpty) {
      await _createNewConversation();
    }

    final userMessage = _controller.text.trim();
    _controller.clear();

    // Ajouter le message de l'utilisateur
    final userMsg = Message(
      content: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );
    await convProvider.addMessage(userMsg);
    setState(() => _isLoading = true);
    _scrollToBottom();

    try {
      // Obtenir les projets de l'utilisateur et l'historique
      final currentConv = convProvider.currentConversation;
      final conversationHistory = currentConv?.messages ?? [];
      // Exclure le dernier message (celui qu'on vient d'ajouter) pour l'historique
      final historyForAI = conversationHistory.length > 1
          ? conversationHistory.sublist(0, conversationHistory.length - 1)
          : <Message>[];

      final userProjects = projectProvider.projects;

      // Récupérer les tâches pour chaque projet
      final Map<String, List<Task>> projectTasksMap = {};
      final dbService = DatabaseService();
      for (var project in userProjects) {
        try {
          final tasks = await dbService.getTasksByProject(project.id);
          projectTasksMap[project.id] = tasks;
        } catch (e) {
          print(
            'Erreur lors de la récupération des tâches pour ${project.id}: $e',
          );
          projectTasksMap[project.id] = [];
        }
      }

      // Obtenir la réponse de l'IA avec le contexte
      String aiResponse = await getOpenRouterResponse(
        userMessage,
        conversationHistory: historyForAI,
        userProjects: userProjects,
        projectTasks: projectTasksMap,
      );

      // Ajouter la réponse de l'IA
      final aiMsg = Message(
        content: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );
      await convProvider.addMessage(aiMsg);
      setState(() => _isLoading = false);
      _scrollToBottom();
    } catch (e) {
      final errorMsg = Message(
        content: '❌ ${_getFriendlyError(e)}',
        isUser: false,
        timestamp: DateTime.now(),
      );
      await convProvider.addMessage(errorMsg);
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }


  String _getFriendlyError(Object error) {
    if (error is AIUserVisibleException) return error.message;

    final text = error.toString();
    final lowered = text.toLowerCase();

    if (lowered.contains('api_key') || lowered.contains('api key')) {
      return 'Cle API manquante ou invalide. Verifie API_KEY puis relance.';
    }
    if (lowered.contains('timeout') || lowered.contains('expire')) {
      return 'La requete a expire. Verifie ta connexion puis reessaie.';
    }
    if (lowered.contains('socket') || lowered.contains('internet')) {
      return 'Impossible de joindre le serveur. Verifie internet et reessaie.';
    }
    if (lowered.contains('429') || lowered.contains('trop de requetes')) {
      return 'Limite de requetes atteinte. Attends un peu puis reessaie.';
    }
    if (lowered.contains('402') || lowered.contains('credit')) {
      return 'Credits IA insuffisants. Ajoute du credit OpenRouter.';
    }
    if (lowered.contains('401') || lowered.contains('403')) {
      return 'Cle API non autorisee. Verifie ta configuration OpenRouter.';
    }

    return 'Erreur IA: ${text.replaceFirst('Exception: ', '')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConversationProvider>(
      builder: (context, convProvider, child) {
        final currentConv = convProvider.currentConversation;
        final currentMessages = currentConv?.messages ?? [];

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F0F),
          appBar: AppBar(
            title: Text(
              currentConv?.title ?? 'Conversation avec sessame',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'Menu',
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                onPressed: () => _createNewConversation(),
                tooltip: 'Nouvelle conversation',
              ),
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Retour',
              ),
            ],
          ),
          drawer: _buildDrawer(),
          body: Column(
            children: [
              // Zone des messages
              Expanded(
                child: currentMessages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 80,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Commence une conversation...',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: currentMessages.length,
                        itemBuilder: (context, index) {
                          final message = currentMessages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
              ),

              // Indicateur de chargement
              if (_isLoading)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.deepPurpleAccent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Sessame réfléchit...',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Zone de saisie
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.white),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Écris ton message...',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.deepPurpleAccent, Colors.purple],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurpleAccent.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                          ),
                          onPressed: _isLoading ? null : _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Consumer<ConversationProvider>(
      builder: (context, convProvider, child) {
        return Drawer(
          backgroundColor: const Color(0xFF0F0F0F),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.deepPurpleAccent,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Conversations',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: Colors.deepPurpleAccent,
                        ),
                        onPressed: () async {
                          await _createNewConversation();
                          if (context.mounted) Navigator.pop(context);
                        },
                        tooltip: 'Nouvelle conversation',
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10),

                // Liste des conversations
                Expanded(
                  child: convProvider.conversations.isEmpty
                      ? Center(
                          child: Text(
                            'Aucune conversation',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: convProvider.conversations.length,
                          itemBuilder: (context, index) {
                            final conv = convProvider.conversations[index];
                            final isSelected =
                                index == convProvider.currentConversationIndex;
                            final dateStr = DateFormat(
                              'dd/MM/yyyy',
                            ).format(conv.updatedAt);

                            return Dismissible(
                              key: Key(conv.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: Colors.red.withValues(alpha: 0.2),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                              onDismissed: (_) => _deleteConversation(index),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.deepPurpleAccent.withValues(
                                          alpha: 0.2,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.deepPurpleAccent.withValues(
                                            alpha: 0.5,
                                          )
                                        : Colors.transparent,
                                  ),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurpleAccent.withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.chat_rounded,
                                      color: isSelected
                                          ? Colors.deepPurpleAccent
                                          : Colors.white.withValues(alpha: 0.5),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    conv.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.7),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        conv.preview,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.4,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateStr,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () => _switchConversation(index),
                                  trailing: PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert_rounded,
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    color: const Color(0xFF1A1A1A),
                                    onSelected: (value) async {
                                      if (value == 'delete') {
                                        await _deleteConversation(index);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Supprimer',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Footer avec statistiques
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat(
                        Icons.chat_bubble_outline,
                        '${convProvider.conversations.length}',
                        'Conversations',
                      ),
                      _buildStat(
                        Icons.message_outlined,
                        '${convProvider.conversations.fold<int>(0, (sum, conv) => sum + conv.messages.length)}',
                        'Messages',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.deepPurpleAccent, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Message message) {
    final timeStr = DateFormat('HH:mm').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology_rounded,
                size: 16,
                color: Colors.deepPurpleAccent,
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? const LinearGradient(
                        colors: [Colors.deepPurpleAccent, Colors.purple],
                      )
                    : null,
                color: message.isUser
                    ? null
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 5),
                  bottomRight: Radius.circular(message.isUser ? 5 : 20),
                ),
                border: Border.all(
                  color: message.isUser
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

