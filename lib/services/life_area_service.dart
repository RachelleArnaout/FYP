import '../models/life_area.dart';
import 'api_client.dart';

class LifeAreaService {
  /// Get all life areas for the current user.
  static Future<List<LifeArea>> getAll() async {
    final response = await ApiClient.get('/life-areas');
    final data = response['data'] as List<dynamic>;
    return data
        .map((e) => LifeArea.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get only active life areas.
  static Future<List<LifeArea>> getActive() async {
    final response = await ApiClient.get('/life-areas/active');
    final data = response['data'] as List<dynamic>;
    return data
        .map((e) => LifeArea.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get a single life area by ID.
  static Future<LifeArea> getById(String id) async {
    final response = await ApiClient.get('/life-areas/$id');
    final data = response['data'] as Map<String, dynamic>;
    return LifeArea.fromJson(data);
  }

  /// Create a new life area.
  static Future<LifeArea> create(LifeArea area) async {
    final response = await ApiClient.post('/life-areas', body: {
      'name': area.name,
      'icon': area.icon,
      'isActive': area.isActive,
      'priority': area.priority,
      'description': area.description,
    });
    final data = response['data'] as Map<String, dynamic>;
    return LifeArea.fromJson(data);
  }

  /// Update an existing life area.
  static Future<LifeArea> update(String id, LifeArea area) async {
    final response = await ApiClient.put('/life-areas/$id', body: {
      'name': area.name,
      'icon': area.icon,
      'isActive': area.isActive,
      'priority': area.priority,
      'description': area.description,
    });
    final data = response['data'] as Map<String, dynamic>;
    return LifeArea.fromJson(data);
  }

  /// Toggle life area active status.
  static Future<LifeArea> toggleActive(String id) async {
    final response = await ApiClient.patch('/life-areas/$id/toggle');
    final data = response['data'] as Map<String, dynamic>;
    return LifeArea.fromJson(data);
  }

  /// Delete a life area.
  static Future<void> delete(String id) async {
    await ApiClient.delete('/life-areas/$id');
  }
}
