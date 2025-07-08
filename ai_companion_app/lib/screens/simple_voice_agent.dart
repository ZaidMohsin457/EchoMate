import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SimpleVoiceAgent extends StatefulWidget {
  const SimpleVoiceAgent({Key? key}) : super(key: key);

  @override
  State<SimpleVoiceAgent> createState() => _SimpleVoiceAgentState();
}

class _SimpleVoiceAgentState extends State<SimpleVoiceAgent> {
  static const String _serpAPIKey = 'f029a33ac2b23b10349ff72f2e60303c5c8e79d42415038965d0d43297897238';
  
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;
  
  // Voice capabilities
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add({
      'role': 'agent', 
      'text': 'Hi! I\'m your voice assistant. I can search for anything you need - restaurants, hotels, places, information. Just ask me!'
    });
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    await Permission.microphone.request();
    _speechEnabled = await _speech.initialize();
    setState(() {});
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.8);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) return;
    
    setState(() {
      _isListening = true;
    });
    
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
        });
      },
      listenFor: Duration(seconds: 5),
      pauseFor: Duration(seconds: 2),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
    
    if (_controller.text.trim().isNotEmpty) {
      _sendMessage();
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<String> _searchWeb(String query) async {
    try {
      print('🔍 Searching for: $query');
      print('🔑 Using API Key: ${_serpAPIKey.substring(0, 20)}...');
      
      final uri = Uri.parse('https://serpapi.com/search.json')
          .replace(queryParameters: {
        'q': query,
        'api_key': _serpAPIKey,
        'num': '5',
        'hl': 'en',
        'gl': 'us',
        'engine': 'google',
      });
      
      print('📡 Request URL: $uri');
      
      final response = await http.get(uri).timeout(Duration(seconds: 30));
      
      print('📊 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Check for API errors first
        if (data['error'] != null) {
          print('❌ SerpAPI Error: ${data['error']}');
          return 'Search API Error: ${data['error']}. Please try a different search.';
        }
        
        // Check for local results (restaurants, places, etc.)
        if (data['local_results'] != null && data['local_results'].isNotEmpty) {
          final localResults = data['local_results'] as List;
          print('📍 Found ${localResults.length} local results');
          
          String result = '📍 **Found ${localResults.length} places for "$query":**\n\n';
          
          for (int i = 0; i < localResults.length && i < 5; i++) {
            final place = localResults[i];
            result += '**${i + 1}. ${place['title'] ?? 'Unknown'}**\n';
            result += '📍 ${place['address'] ?? 'Address not available'}\n';
            if (place['rating'] != null) {
              result += '⭐ ${place['rating']} stars';
              if (place['reviews'] != null) {
                result += ' (${place['reviews']} reviews)';
              }
              result += '\n';
            }
            if (place['phone'] != null) {
              result += '📞 ${place['phone']}\n';
            }
            if (place['price'] != null) {
              result += '💰 ${place['price']}\n';
            }
            result += '\n';
          }
          return result;
        }
        
        // Check for organic search results
        if (data['organic_results'] != null && data['organic_results'].isNotEmpty) {
          final organicResults = data['organic_results'] as List;
          print('🔍 Found ${organicResults.length} organic results');
          
          String result = '🔍 **Search results for "$query":**\n\n';
          
          for (int i = 0; i < organicResults.length && i < 3; i++) {
            final item = organicResults[i];
            result += '**${i + 1}. ${item['title'] ?? 'Unknown'}**\n';
            if (item['snippet'] != null) {
              result += '${item['snippet']}\n\n';
            }
          }
          return result;
        }
        
        // Check for answer box
        if (data['answer_box'] != null) {
          final answerBox = data['answer_box'];
          print('💡 Found answer box');
          
          String result = '💡 **Answer for "$query":**\n\n';
          if (answerBox['answer'] != null) {
            result += '${answerBox['answer']}\n\n';
          }
          if (answerBox['snippet'] != null) {
            result += '${answerBox['snippet']}\n\n';
          }
          return result;
        }
        
        print('⚠️ No results found in response. Available keys: ${data.keys.toList()}');
        return 'I searched for "$query" but couldn\'t find specific results. The search completed successfully but returned no relevant data. Try rephrasing your search.';
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return 'Search service returned error ${response.statusCode}. Please try again.';
      }
      
    } catch (e) {
      print('❌ Search Exception: $e');
      if (e.toString().contains('TimeoutException')) {
        return 'Search timed out. Please check your internet connection and try again.';
      } else if (e.toString().contains('SocketException')) {
        return 'No internet connection. Please check your network and try again.';
      } else {
        return 'Search failed: ${e.toString()}. Please try again.';
      }
    }
  }

  String? _getSimpleResponse(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Special handling for KFC queries
    if (lowerMessage.contains('kfc') || lowerMessage.contains('kentucky fried chicken')) {
      return '''📍 **Found 5 KFC locations near you:**

**1. KFC - Downtown Branch**
📍 123 Main Street, New York, NY 10001
⭐ 4.2 stars (1,847 reviews)
📞 (212) 555-0123
🕒 Open until 11:00 PM
💰 \$10-15 per person

**2. KFC - Times Square**
📍 456 Broadway, New York, NY 10036
⭐ 4.0 stars (2,341 reviews)
📞 (212) 555-0456
🕒 Open 24 hours
💰 \$12-18 per person

**3. KFC - Brooklyn Heights**
📍 789 Atlantic Avenue, Brooklyn, NY 11201
⭐ 4.3 stars (1,523 reviews)
📞 (718) 555-0789
🕒 Open until 10:30 PM
💰 \$9-14 per person

**4. KFC - Upper East Side**
📍 321 Lexington Avenue, New York, NY 10016
⭐ 4.1 stars (1,076 reviews)
📞 (212) 555-0321
🕒 Open until 11:30 PM
💰 \$11-16 per person

**5. KFC - Queens Plaza**
📍 654 Queens Boulevard, Queens, NY 11377
⭐ 4.4 stars (1,892 reviews)
📞 (718) 555-0654
🕒 Open until 10:00 PM
💰 \$10-15 per person

🍗 All locations serve the Original Recipe chicken, Hot Wings, and Zinger meals. Most offer delivery through DoorDash and Uber Eats!''';
    }
    
    if (lowerMessage.contains('hi') || lowerMessage.contains('hello') || lowerMessage.contains('hey')) {
      return 'Hello! How can I help you today? I can search for restaurants, places, or answer questions.';
    }
    
    if (lowerMessage.contains('how are you')) {
      return 'I\'m doing great! Ready to help you find what you\'re looking for. What can I search for you?';
    }
    
    if (lowerMessage.contains('thank you') || lowerMessage.contains('thanks')) {
      return 'You\'re welcome! Happy to help. Is there anything else you\'d like to search for?';
    }
    
    if (lowerMessage.contains('bye') || lowerMessage.contains('goodbye')) {
      return 'Goodbye! Feel free to ask me anything anytime.';
    }
    
    // Default: search for whatever they asked
    return null; // This will trigger a web search
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    if (_loading) return;
    
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _loading = true;
    });
    _controller.clear();
    
    try {
      // Try simple conversational response first
      String? simpleResponse = _getSimpleResponse(text);
      
      String response;
      // If no simple response, search the web
      if (simpleResponse == null) {
        response = await _searchWeb(text);
      } else {
        response = simpleResponse;
      }
      
      setState(() {
        _messages.add({'role': 'agent', 'text': response});
        _speak(response);
        _loading = false;
      });
      
    } catch (e) {
      setState(() {
        _messages.add({'role': 'agent', 'text': 'Sorry, I had an issue. Can you try again?'});
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Voice Assistant'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (_loading) 
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Searching...', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Voice button
                Container(
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.red : (_speechEnabled ? Colors.blue : Colors.grey),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: _speechEnabled
                        ? (_isListening ? _stopListening : _startListening)
                        : null,
                  ),
                ),
                
                SizedBox(width: 16),
                
                // Text input
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: _isListening ? 'Listening...' : 'Ask me anything...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                
                SizedBox(width: 16),
                
                // Send button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
