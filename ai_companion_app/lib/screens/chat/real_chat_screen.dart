import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/chat_models.dart';
import '../../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final String aiFriendType;
  final String friendName;

  const ChatScreen({
    super.key,
    required this.aiFriendType,
    required this.friendName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  
  ChatSession? _currentSession;
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    
    try {
      final session = await _apiService.startChatSession(widget.aiFriendType);
      if (session != null) {
        _currentSession = session;
        final messages = await _apiService.getChatMessages(session.id);
        setState(() {
          _messages = messages;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing chat: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _currentSession == null || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final response = await _apiService.sendMessage(_currentSession!.id, content);
      if (response != null) {
        final userMessage = Message.fromJson(response['user_message']);
        final aiResponse = Message.fromJson(response['ai_response']);
        
        setState(() {
          _messages.add(userMessage);
          _messages.add(aiResponse);
        });
        
        _scrollToBottom();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.friendName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _ChatBubble(
                        message: message,
                        onSearchResultTap: _launchUrl,
                      );
                    },
                  ),
                ),
                _buildMessageInput(),
              ],
            ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, 
                  vertical: 12,
                ),
              ),
              maxLines: null,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _isSending ? null : _sendMessage,
            mini: true,
            child: _isSending 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => SearchDialog(apiService: _apiService),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _ChatBubble extends StatelessWidget {
  final Message message;
  final Function(String) onSearchResultTap;

  const _ChatBubble({
    required this.message,
    required this.onSearchResultTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isFromUser;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(isUser),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.content,
                    style: GoogleFonts.poppins(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (message.metadata.isNotEmpty && message.metadata['results'] != null)
                  _buildSearchResults(message.metadata['results']),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _buildAvatar(isUser),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser ? Colors.blue : Colors.orange,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSearchResults(List<dynamic> results) {
    if (results.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: results.take(3).map<Widget>((result) {
          final searchResult = SearchResult.fromJson(result);
          return Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              title: Text(
                searchResult.title,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                searchResult.snippet,
                style: GoogleFonts.poppins(fontSize: 10),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.open_in_new, size: 16),
              onTap: () => onSearchResultTap(searchResult.link),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class SearchDialog extends StatefulWidget {
  final ApiService apiService;

  const SearchDialog({super.key, required this.apiService});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'general';
  List<SearchResult> _results = [];
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Search Places', style: GoogleFonts.poppins()),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search for hotels, restaurants, etc.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'general', child: Text('General')),
                DropdownMenuItem(value: 'hotels', child: Text('Hotels')),
                DropdownMenuItem(value: 'restaurants', child: Text('Restaurants')),
                DropdownMenuItem(value: 'attractions', child: Text('Attractions')),
              ],
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
            const SizedBox(height: 16),
            if (_isSearching)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _performSearch,
                child: const Text('Search'),
              ),
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Results:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    return ListTile(
                      title: Text(result.title, style: const TextStyle(fontSize: 12)),
                      subtitle: Text(result.snippet, style: const TextStyle(fontSize: 10)),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () async {
                        final Uri uri = Uri.parse(result.link);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final response = await widget.apiService.searchPlaces(
        _searchController.text.trim(),
        _selectedType,
        null,
      );

      if (response != null && response['results'] != null) {
        final List<dynamic> resultsData = response['results'];
        setState(() {
          _results = resultsData
              .map((json) => SearchResult.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search error: $e')),
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }
}
