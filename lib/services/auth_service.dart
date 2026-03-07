import 'api_client.dart';

class AuthService {
  /// Register a new user. Returns {user, token}.
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
    });
    final data = response['data'] as Map<String, dynamic>;
    await ApiClient.setToken(data['token']);
    return data;
  }

  /// Login with email and password. Returns {user, token}.
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    final data = response['data'] as Map<String, dynamic>;
    await ApiClient.setToken(data['token']);
    return data;
  }

  /// Get current authenticated user info.
  static Future<Map<String, dynamic>> getMe() async {
    final response = await ApiClient.get('/auth/me');
    return response['data'] as Map<String, dynamic>;
  }

  /// Mark user as onboarded.
  static Future<Map<String, dynamic>> completeOnboarding() async {
    final response = await ApiClient.patch('/auth/complete-onboarding');
    return response['data'] as Map<String, dynamic>;
  }

  /// Logout (client-side only — clears stored token).
  static Future<void> logout() async {
    await ApiClient.clearToken();
  }
}
