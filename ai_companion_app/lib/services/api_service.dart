import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/chat_models.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Future<Response> register(
    String username,
    String email,
    String password,
    String password2,
  ) {
    return _dio.post(
      '$baseUrl/api/auth/register/',
      data: {
        'username': username,
        'email': email,
        'password': password,
        'password2': password2,
      },
    );
  }

  Future<bool> login(String username, String password) async {
    try {
      print('Attempting login with username: $username');
      final response = await _dio.post(
        '$baseUrl/api/auth/login/',
        data: {'username': username, 'password': password},
      );
      print('Login response status: ${response.statusCode}');
      print('Login response data: ${response.data}');
      if (response.statusCode == 200 && response.data['access'] != null) {
        await _storage.write(key: 'access', value: response.data['access']);
        await _storage.write(key: 'refresh', value: response.data['refresh']);
        return true;
      }
    } catch (e) {
      print('Login error: $e');
      if (e is DioException) {
        print('Login error response: ${e.response?.data}');
        print('Login error status: ${e.response?.statusCode}');
      }
    }
    return false;
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await _dio.get('$baseUrl/api/auth/profile/');
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print('Get profile error: $e');
    }
    return null;
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('$baseUrl/api/auth/profile/', data: data);
      return response.statusCode == 200;
    } catch (e) {
      print('Update profile error: $e');
    }
    return false;
  }

  Future<bool> uploadAvatar(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post(
        '$baseUrl/api/users/upload-avatar/',
        data: formData,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Upload avatar error: $e');
    }
    return false;
  }

  // Preferences functionality
  Future<Map<String, dynamic>?> getPreferences() async {
    try {
      final response = await _dio.get('$baseUrl/api/auth/preferences/');
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print('Get preferences error: $e');
    }
    return null;
  }

  Future<bool> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      final response = await _dio.put(
        '$baseUrl/api/auth/preferences/',
        data: {'graph': preferences},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Update preferences error: $e');
    }
    return false;
  }

  // Chat functionality
  Future<ChatSession?> startChatSession(String aiFriendType) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/chat/sessions/start/',
        data: {'ai_friend_type': aiFriendType},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ChatSession.fromJson(response.data);
      }
    } catch (e) {
      print('Start chat session error: $e');
    }
    return null;
  }

  Future<List<ChatSession>> getChatSessions() async {
    try {
      final response = await _dio.get('$baseUrl/api/chat/sessions/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ChatSession.fromJson(json)).toList();
      }
    } catch (e) {
      print('Get chat sessions error: $e');
    }
    return [];
  }

  Future<List<Message>> getChatMessages(int sessionId) async {
    try {
      final response = await _dio.get('$baseUrl/api/chat/sessions/$sessionId/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Message.fromJson(json)).toList();
      }
    } catch (e) {
      print('Get chat messages error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> sendMessage(int sessionId, String content) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/chat/sessions/$sessionId/send/',
        data: {'content': content},
      );
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print('Send message error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> searchPlaces(
    String query, 
    String type, 
    String? location
  ) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/chat/search/',
        data: {
          'query': query,
          'type': type,
          'location': location,
        },
      );
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print('Search places error: $e');
    }
    return null;
  }

  Future<bool> deleteChatSession(int sessionId) async {
    try {
      final response = await _dio.delete('$baseUrl/api/chat/sessions/$sessionId/delete/');
      return response.statusCode == 204;
    } catch (e) {
      print('Delete chat session error: $e');
    }
    return false;
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    _dio.options.headers.remove('Authorization');
  }

  Future<bool> testConnection() async {
    try {
      print('Testing connection to: $baseUrl/api/auth/test/');
      final response = await _dio.get('$baseUrl/api/auth/test/');
      print('Test response: ${response.data}');
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      if (e is DioException) {
        print('Connection test error response: ${e.response?.data}');
        print('Connection test error status: ${e.response?.statusCode}');
      }
      return false;
    }
  }
}
