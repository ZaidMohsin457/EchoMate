import 'dart:convert';
import 'package:http/http.dart' as http;

class AIChatService {
  static const String _serpAPIKey = 'f029a33ac2b23b10349ff72f2e60303c5c8e79d42415038965d0d43297897238'; // Your actual SerpAPI key

  Future<String> generateResponse(String userMessage) async {
    print('=== AI SERVICE DEBUG ===');
    print('Input message: $userMessage');
    
    try {
      // Always try web search first for any meaningful query
      print('Attempting web search for: $userMessage');
      final searchResponse = await _searchWeb(userMessage);
      print('Search response: $searchResponse');
      
      if (searchResponse != null && searchResponse.isNotEmpty) {
        print('Web search successful, returning: ${searchResponse.substring(0, 100)}...');
        return searchResponse;
      }
      
      print('Web search failed, falling back to contextual response');
      // Fall back to contextual response
      final contextualResponse = _getContextualResponse(userMessage);
      print('Contextual response: $contextualResponse');
      return contextualResponse;
    } catch (e) {
      print('AI Service error: $e');
      return _getContextualResponse(userMessage);
    }
  }

  Future<String?> _searchWeb(String query) async {
    try {
      print('=== SERPAPI DEBUG ===');
      print('Making SerpAPI request for: $query');
      print('API Key: ${_serpAPIKey.substring(0, 10)}...');
      
      final uri = Uri.parse('https://serpapi.com/search.json')
          .replace(queryParameters: {
        'q': query,
        'api_key': _serpAPIKey,
        'num': '3',
        'hl': 'en',
        'gl': 'us',
      });
      
      print('SerpAPI URL: $uri');
      
      final response = await http.get(uri);
      print('SerpAPI response status: ${response.statusCode}');
      print('SerpAPI response body length: ${response.body.length}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('SerpAPI response keys: ${data.keys.toList()}');
        
        // Check for error in response
        if (data['error'] != null) {
          print('SerpAPI error: ${data['error']}');
          return null;
        }
        
        // Check for direct answer box
        if (data['answer_box'] != null) {
          final answerBox = data['answer_box'];
          print('Found answer box: ${answerBox.keys.toList()}');
          if (answerBox['answer'] != null) {
            return '📋 **Direct Answer:** ${answerBox['answer']}\n\nSource: ${answerBox['displayed_link'] ?? 'Search Results'}';
          }
        }
        
        // Check for knowledge graph
        if (data['knowledge_graph'] != null) {
          final kg = data['knowledge_graph'];
          print('Found knowledge graph: ${kg.keys.toList()}');
          final title = kg['title'] ?? '';
          final description = kg['description'] ?? '';
          if (title.isNotEmpty && description.isNotEmpty) {
            return '🔍 **About $title:**\n$description';
          }
        }
        
        // Check for local results (restaurants, etc.)
        if (data['local_results'] != null) {
          final localResults = data['local_results'] as List?;
          print('Found local results: ${localResults?.length ?? 0} items');
          if (localResults != null && localResults.isNotEmpty) {
            String response = '� **Local Results for "$query":**\n\n';
            
            for (int i = 0; i < localResults.length && i < 3; i++) {
              final result = localResults[i];
              final title = result['title'] ?? '';
              final rating = result['rating'] ?? '';
              final address = result['address'] ?? '';
              
              if (title.isNotEmpty) {
                response += '**${i + 1}. $title**\n';
                if (rating.isNotEmpty) response += '⭐ Rating: $rating\n';
                if (address.isNotEmpty) response += '📍 $address\n\n';
              }
            }
            
            return response;
          }
        }
        
        // Get organic search results
        final results = data['organic_results'] as List?;
        print('Found organic results: ${results?.length ?? 0} items');
        if (results != null && results.isNotEmpty) {
          String response = '� **Search Results for "$query":**\n\n';
          
          // Add up to 3 results
          for (int i = 0; i < results.length && i < 3; i++) {
            final result = results[i];
            final title = result['title'] ?? '';
            final snippet = result['snippet'] ?? '';
            
            if (title.isNotEmpty) {
              response += '**${i + 1}. $title**\n';
              if (snippet.isNotEmpty) {
                response += '$snippet\n\n';
              }
            }
          }
          
          return response;
        }
        
        // If no specific results, return a search status message
        return '🔍 I searched for "$query" but couldn\'t find specific results. The search completed but returned no relevant information. Please try a different search term!';
      } else {
        print('SerpAPI HTTP error: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('SerpAPI exception: $e');
      return null;
    }
  }

  String _getContextualResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    // Restaurant-specific responses with more variety
    if (message.contains('hi') || message.contains('hello') || message.contains('hey')) {
      final greetings = [
        'Hello! I\'m your AI assistant. What can I help you with today?',
        'Hi there! I\'m here to help you with restaurants, food orders, and any questions you have. What\'s on your mind?',
        'Hey! I can help you find restaurants, search the web, or chat about anything. How can I assist you?'
      ];
      return greetings[DateTime.now().millisecond % greetings.length];
    }
    
    if (message.contains('restaurant') || message.contains('food') || message.contains('eat')) {
      final foodResponses = [
        'I can help you find amazing restaurants! What type of cuisine are you craving? I can search for reviews and recommendations.',
        'Looking for a place to eat? Tell me what you\'re in the mood for and I\'ll help you find the perfect spot!',
        'Food time! What kind of restaurant are you looking for? I can search for menus, prices, and reviews.'
      ];
      return foodResponses[DateTime.now().millisecond % foodResponses.length];
    }
    
    if (message.contains('search') || message.contains('find') || message.contains('look')) {
      return 'I can search the web for anything you need! Restaurant info, general knowledge, current events - just tell me what you\'re looking for.';
    }
    
    if (message.contains('how are you') || message.contains('how\'s it going')) {
      return 'I\'m doing great, thank you for asking! I\'m here and ready to help you with restaurants, web searches, or just chat. What would you like to do?';
    }
    
    if (message.contains('thank')) {
      return 'You\'re very welcome! Is there anything else I can help you with today?';
    }
    
    // More dynamic general responses
    final generalResponses = [
      'That\'s interesting! I can help you search for more information about that, or assist with restaurant recommendations. What would you prefer?',
      'I\'m here to help! Whether you need restaurant suggestions, want me to search for information, or just want to chat - I\'m ready.',
      'Tell me more about what you\'re looking for! I can search the web, recommend restaurants, or help with any questions you have.',
      'I\'d love to help you with that! I can search for information online or help you find great places to eat. What sounds good?'
    ];
    
    return generalResponses[DateTime.now().millisecond % generalResponses.length];
  }
}
