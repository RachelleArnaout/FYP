class LifeArea {
  String id;
  String name;
  String icon;
  bool isActive;
  int priority; // 1-8, lower is higher priority
  String description;

  LifeArea({
    required this.id,
    required this.name,
    required this.icon,
    this.isActive = false,
    this.priority = 0,
    this.description = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'isActive': isActive,
      'priority': priority,
      'description': description,
    };
  }

  factory LifeArea.fromJson(Map<String, dynamic> json) {
    return LifeArea(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      isActive: json['isActive'] ?? false,
      priority: json['priority'] ?? 0,
      description: json['description'] ?? '',
    );
  }
}
