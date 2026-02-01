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

  static List<LifeArea> getDefaultAreas() {
    return [
      LifeArea(
        id: 'academic',
        name: 'Academic Growth',
        icon: '📚',
        description: 'Learning, studying, and intellectual development',
      ),
      LifeArea(
        id: 'professional',
        name: 'Professional Growth',
        icon: '💼',
        description: 'Career development and workplace skills',
      ),
      LifeArea(
        id: 'mental',
        name: 'Mental & Emotional Well-being',
        icon: '🧠',
        description: 'Mental health, emotional balance, and mindfulness',
      ),
      LifeArea(
        id: 'physical',
        name: 'Physical Health',
        icon: '💪',
        description: 'Exercise, nutrition, and physical wellness',
      ),
      LifeArea(
        id: 'social',
        name: 'Social Skills & Relationships',
        icon: '👥',
        description: 'Friendships, networking, and social connections',
      ),
      LifeArea(
        id: 'spiritual',
        name: 'Spiritual or Inner Growth',
        icon: '🕉️',
        description: 'Spirituality, values, and purpose',
      ),
      LifeArea(
        id: 'creative',
        name: 'Creativity & Self-expression',
        icon: '🎨',
        description: 'Creative pursuits and artistic expression',
      ),
      LifeArea(
        id: 'financial',
        name: 'Financial Discipline',
        icon: '💰',
        description: 'Money management and financial planning',
      ),
    ];
  }
}
