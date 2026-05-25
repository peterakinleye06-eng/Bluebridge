import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ─── CONFIGURATION ──────────────────────────────────────────────────────────
  // If running on Android emulator, use 10.0.2.2 (maps to your PC's localhost)
  // If running on a real Android device, set this to your PC's local IP address
  // Run `ipconfig` (Windows) or `ifconfig` (Mac/Linux) to find it
  // e.g. '192.168.1.105' — update this whenever your network changes
  static const String _androidDeviceIp = '192.168.0.146';
  // ────────────────────────────────────────────────────────────────────────────

  static String get baseUrl {
    // Production server on Render
    return 'https://bridgelink-server.onrender.com/api';
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'name': name}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  // SMS/OTP Authentication
  Future<Map<String, dynamic>> sendOTP(String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send OTP: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> verifyOTP(String phone, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'code': code}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('OTP verification failed: ${response.body}');
    }
  }

  // OAuth Authentication
  Future<Map<String, dynamic>> googleSignIn(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Google sign-in failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> appleSignIn(String identityToken, String? authorizationCode, String? user) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/apple'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identityToken': identityToken,
        'authorizationCode': authorizationCode,
        'user': user,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Apple sign-in failed: ${response.body}');
    }
  }

  // Password Reset
  Future<Map<String, dynamic>> forgotPassword({String? email, String? phone}) async {
    final body = email != null ? {'email': email} : {'phone': phone};
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Password reset request failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> resetPassword(String token, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Password reset failed: ${response.body}');
    }
  }

  Future<List<dynamic>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> product) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product),
    );
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('Failed to create product: \${response.body}');
  }

  Future<Map<String, dynamic>> createProductWithImage(
    Map<String, String> fields,
    String token, {
    dynamic imageFile,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/products'));
    request.headers['Authorization'] = 'Bearer \$token';
    request.fields.addAll(fields);
    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('Failed to create product: \${response.body}');
  }

  Future<Map<String, dynamic>> updateProduct(
    int id,
    Map<String, String> fields,
    String token, {
    dynamic imageFile,
  }) async {
    final request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/products/\$id'));
    request.headers['Authorization'] = 'Bearer \$token';
    request.fields.addAll(fields);
    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to update product: \${response.body}');
  }

  Future<void> deleteProduct(int id, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/products/\$id'),
      headers: {'Authorization': 'Bearer \$token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete product: \${response.body}');
    }
  }

  Future<List<dynamic>> getOrders(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load orders');
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status, String token) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    final error = jsonDecode(response.body);
    throw Exception(error['error'] ?? 'Failed to update order status');
  }

  Future<Map<String, dynamic>> getAnalytics(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/analytics/summary'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load analytics');
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> order) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(order),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create order');
    }
  }
}