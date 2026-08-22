class UserModel {
  final String id;
  final String email;
  final String name;
  final int age;
  final String gender;
  final double height;
  final double weight;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.age = 28,
    this.gender = 'Male',
    this.height = 175.0,
    this.weight = 70.0,
  });

  double get bmi {
    final heightM = height / 100.0;
    if (heightM <= 0) return 22.0;
    return double.parse((weight / (heightM * heightM)).toStringAsFixed(1));
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? 'User',
      age: json['age'] ?? 28,
      gender: json['gender'] ?? 'Male',
      height: (json['height'] as num?)?.toDouble() ?? 175.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 70.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
    };
  }

  UserModel copyWith({
    String? name,
    int? age,
    String? gender,
    double? height,
    double? weight,
  }) {
    return UserModel(
      id: id,
      email: email,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
    );
  }
}
