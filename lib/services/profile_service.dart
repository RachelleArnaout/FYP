import '../models/user_profile.dart';
import 'api_client.dart';

class ProfileService {
  /// Get the current user's profile.
  static Future<UserProfile> getProfile() async {
    final response = await ApiClient.get('/profile');
    final data = response['data'] as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }

  /// Update the current user's profile.
  static Future<UserProfile> updateProfile(UserProfile profile) async {
    final response = await ApiClient.put('/profile', body: profile.toJson());
    final data = response['data'] as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }
}
