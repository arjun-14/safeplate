import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiService {
  /// Sends image to AWS Lambda function and returns the response
  static Future<Map<String, dynamic>> uploadImage({
    required File imageFile,
    required List<String> allergens,
  }) async {
    try {
      final imageBytes = await imageFile.readAsBytes();

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(apiEndpoint));

      // Add image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageFile.path.split('/').last,
        ),
      );

      // Add allergens as form data
      request.fields['allergens'] = allergens.join(',');

      // Optional: Add authorization header if using API key
      // request.headers['Authorization'] = 'Bearer YOUR_API_KEY';
      request.headers['Content-Type'] = 'multipart/form-data';

      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(streamedResponse);

      // Parse response
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Try to parse as JSON
        try {
          final Map<String, dynamic> jsonResponse =
              Map<String, dynamic>.from(
            _parseJsonResponse(response.body),
          );
          return {
            'success': true,
            'data': jsonResponse,
            'statusCode': response.statusCode,
          };
        } catch (e) {
          // If not JSON, return as plain text
          return {
            'success': true,
            'data': {'message': response.body},
            'statusCode': response.statusCode,
          };
        }
      } else {
        return {
          'success': false,
          'error': 'Upload failed with status ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } on SocketException catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.message}',
      };
    } on TimeoutException {
      return {
        'success': false,
        'error': 'Request timed out. Please try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error uploading image: $e',
      };
    }
  }

  /// Sends image as base64 JSON payload (key: `image_base64`) and returns parsed response
  static Future<Map<String, dynamic>> uploadImageBase64({
    required File imageFile,
    required List<String> allergens,
  }) async {
    final uri = Uri.parse(apiEndpoint);

    try {
      final imageBytes = await imageFile.readAsBytes();
      final String imgB64 = base64Encode(imageBytes);

      final payload = jsonEncode({
        'image_base64': imgB64,
        'allergens_to_avoid': allergens,
      });

      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: payload)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          return {
            'success': true,
            'data': data is Map<String, dynamic> ? data : {'result': data},
            'statusCode': response.statusCode,
          };
        } catch (e) {
          return {
            'success': true,
            'data': {'message': response.body},
            'statusCode': response.statusCode,
          };
        }
      }

      return {
        'success': false,
        'error': 'Upload failed with status ${response.statusCode}',
        'statusCode': response.statusCode,
      };
    } on SocketException catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.message}',
      };
    } on TimeoutException {
      return {
        'success': false,
        'error': 'Request timed out. Please try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error uploading image: $e',
      };
    }
  }

  /// Helper method to parse JSON response
  static dynamic _parseJsonResponse(String body) {
    try {
      return jsonDecode(body);
    } catch (e) {
      return {'message': body};
    }
  }
  
}
