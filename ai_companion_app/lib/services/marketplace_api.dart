import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class MarketplaceApi {
  static const String baseUrl = 'http://localhost:8000/api/marketplace/products/';
  static const String createUrl = 'http://localhost:8000/api/marketplace/products/create/';

  static Future<List<Map<String, dynamic>>> fetchProducts({String? token}) async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load products');
    }
  }

  static Future<Map<String, dynamic>> createProduct({
    required String title,
    required String description,
    required String price,
    File? imageFile,
    Uint8List? webImage,
    String? imageName,
    String? token,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse(createUrl));
    
    // Add form fields
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['price'] = price;
    request.fields['category_id'] = '1'; // Default category ID
    
    // Add image if provided
    if (kIsWeb && webImage != null && imageName != null) {
      // For web, use bytes
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        webImage,
        filename: imageName,
      ));
    } else if (!kIsWeb && imageFile != null) {
      // For mobile, use file path
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }
    
    // Add auth header if token provided
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    
    if (response.statusCode == 201) {
      return json.decode(responseBody);
    } else {
      throw Exception('Failed to create product: $responseBody');
    }
  }

  static Future<bool> deleteProduct(int productId, {String? token}) async {
    final response = await http.delete(
      Uri.parse('http://localhost:8000/api/marketplace/products/$productId/delete/'),
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    );
    return response.statusCode == 204;
  }

  static Future<Map<String, dynamic>> createOrder({
    required int productId,
    required int quantity,
    required String buyerEmail,
    String? buyerPhone,
    String? deliveryAddress,
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse('http://localhost:8000/api/marketplace/orders/create/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'product_id': productId,
        'quantity': quantity,
        'buyer_email': buyerEmail,
        'buyer_phone': buyerPhone ?? '',
        'delivery_address': deliveryAddress ?? '',
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create order: ${response.body}');
    }
  }
}
