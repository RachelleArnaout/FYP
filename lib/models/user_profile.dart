class UserProfile {
  String ageRange;
  String profession;
  String industry;
  String degree;
  List<String> lifestyleTypes;
  String livingSituation;
  String energyPattern;
  int dailyFreeTime; // in minutes
  String stressBaseline;
  List<String> stressSources;
  String workloadIntensity;
  String motivationDriver;
  String failureResponse;
  String structurePreference;
  List<String> topValues;
  List<String> identityStatements;
  List<String> constraints;
  List<String> badHabits;
  String? currentLifePhase;

  UserProfile({
    this.ageRange = '',
    this.profession = '',
    this.industry = '',
    this.degree = '',
    this.lifestyleTypes = const [],
    this.livingSituation = '',
    this.energyPattern = 'morning',
    this.dailyFreeTime = 60,
    this.stressBaseline = 'medium',
    this.stressSources = const [],
    this.workloadIntensity = 'medium',
    this.motivationDriver = 'achievement',
    this.failureResponse = 'resilient',
    this.structurePreference = 'balanced',
    this.topValues = const [],
    this.identityStatements = const [],
    this.constraints = const [],
    this.badHabits = const [],
    this.currentLifePhase,
  });

  Map<String, dynamic> toJson() {
    return {
      'ageRange': ageRange,
      'profession': profession,
      'industry': industry,
      'degree': degree,
      'lifestyleTypes': lifestyleTypes,
      'livingSituation': livingSituation,
      'energyPattern': energyPattern,
      'dailyFreeTime': dailyFreeTime,
      'stressBaseline': stressBaseline,
      'stressSources': stressSources,
      'workloadIntensity': workloadIntensity,
      'motivationDriver': motivationDriver,
      'failureResponse': failureResponse,
      'structurePreference': structurePreference,
      'topValues': topValues,
      'identityStatements': identityStatements,
      'constraints': constraints,
      'badHabits': badHabits,
      'currentLifePhase': currentLifePhase,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      ageRange: json['ageRange'] ?? '',
      profession: json['profession'] ?? '',
      industry: json['industry'] ?? '',
      degree: json['degree'] ?? '',
      lifestyleTypes: List<String>.from(json['lifestyleTypes'] ?? []),
      livingSituation: json['livingSituation'] ?? '',
      energyPattern: json['energyPattern'] ?? 'morning',
      dailyFreeTime: json['dailyFreeTime'] ?? 60,
      stressBaseline: json['stressBaseline'] ?? 'medium',
      stressSources: List<String>.from(json['stressSources'] ?? []),
      workloadIntensity: json['workloadIntensity'] ?? 'medium',
      motivationDriver: json['motivationDriver'] ?? 'achievement',
      failureResponse: json['failureResponse'] ?? 'resilient',
      structurePreference: json['structurePreference'] ?? 'balanced',
      topValues: List<String>.from(json['topValues'] ?? []),
      identityStatements: List<String>.from(json['identityStatements'] ?? []),
      constraints: List<String>.from(json['constraints'] ?? []),
      badHabits: List<String>.from(json['badHabits'] ?? []),
      currentLifePhase: json['currentLifePhase'],
    );
  }
}
