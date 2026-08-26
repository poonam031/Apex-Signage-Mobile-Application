import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../storage/local_storage.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });
}

class ApiClient {
  static String baseUrl = AppConstants.apiBaseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await LocalStorage.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<ApiResponse<dynamic>> get(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        return ApiResponse(success: true, data: body, statusCode: response.statusCode);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          message: error['message'] ?? 'Request failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  static Future<ApiResponse<dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();
      final response = await http.post(url, headers: headers, body: jsonEncode(body));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return ApiResponse(success: true, data: data, statusCode: response.statusCode);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          message: error['message'] ?? 'Request failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  static Future<ApiResponse<dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();
      final response = await http.put(url, headers: headers, body: jsonEncode(body));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return ApiResponse(success: true, data: data, statusCode: response.statusCode);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          message: error['message'] ?? 'Request failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }
}
