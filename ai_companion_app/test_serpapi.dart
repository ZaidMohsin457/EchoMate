import 'dart:convert';
import 'dart:io';

void main() async {
  final String apiKey = 'f029a33ac2b23b10349ff72f2e60303c5c8e79d42415038965d0d43297897238';
  final String query = 'pizza near me';
  
  print('🔍 Testing SerpAPI with query: $query');
  
  final httpClient = HttpClient();
  
  try {
    final uri = Uri.parse('https://serpapi.com/search.json')
        .replace(queryParameters: {
      'q': query,
      'api_key': apiKey,
      'num': '5',
      'hl': 'en',
      'gl': 'us',
      'engine': 'google',
    });
    
    print('📡 Making request to: $uri');
    
    final request = await httpClient.getUrl(uri);
    final response = await request.close();
    
    print('📊 Response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody);
      
      print('✅ API Response Keys: ${data.keys.toList()}');
      
      if (data['local_results'] != null) {
        final localResults = data['local_results'] as List;
        print('📍 Found ${localResults.length} local results');
        
        if (localResults.isNotEmpty) {
          print('First result: ${localResults[0]['title']}');
          print('Address: ${localResults[0]['address']}');
          print('Rating: ${localResults[0]['rating']}');
        }
      }
      
      if (data['organic_results'] != null) {
        final organicResults = data['organic_results'] as List;
        print('🔍 Found ${organicResults.length} organic results');
        
        if (organicResults.isNotEmpty) {
          print('First result: ${organicResults[0]['title']}');
        }
      }
      
      if (data['error'] != null) {
        print('❌ API Error: ${data['error']}');
      }
      
    } else {
      print('❌ HTTP Error: ${response.statusCode}');
    }
    
  } catch (e) {
    print('❌ Exception: $e');
  } finally {
    httpClient.close();
  }
}
