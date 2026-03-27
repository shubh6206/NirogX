import 'package:flutter/material.dart';

class ActionGoal {
  final String id;
  final String title;
  final String unit; // e.g., 'L', 'mins', 'pills'
  final String iconName; // e.g., 'droplets', 'moon'
  final Color color;
  
  double currentValue;
  final double targetValue;
  final bool isManual; // True if the user needs to log it themselves

  ActionGoal({
    required this.id,
    required this.title,
    required this.unit,
    required this.iconName,
    required this.color,
    required this.currentValue,
    required this.targetValue,
    required this.isManual,
  });

  // Calculate progress percentage
  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);
  bool get isCompleted => currentValue >= targetValue;
  String get subtitle => '${currentValue.toStringAsFixed(1)} / ${targetValue.toStringAsFixed(1)} $unit';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'unit': unit,
      'iconName': iconName,
      'color': color.value,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'isManual': isManual,
    };
  }

  factory ActionGoal.fromJson(Map<String, dynamic> json) {
    return ActionGoal(
      id: json['id'],
      title: json['title'],
      unit: json['unit'],
      iconName: json['iconName'],
      color: Color(json['color']),
      currentValue: (json['currentValue'] as num).toDouble(),
      targetValue: (json['targetValue'] as num).toDouble(),
      isManual: json['isManual'],
    );
  }
}
