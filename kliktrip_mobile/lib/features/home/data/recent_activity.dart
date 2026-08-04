import 'package:flutter/material.dart';

class RecentActivity {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const RecentActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class RecentActivityService {
  static final RecentActivityService _instance = RecentActivityService._();
  static RecentActivityService get instance => _instance;
  RecentActivityService._();

  final List<RecentActivity> _activities = [];

  List<RecentActivity> get activities => List.unmodifiable(_activities);

  void add(RecentActivity activity) {
    _activities.removeWhere((a) => a.id == activity.id);
    _activities.insert(0, activity);
    if (_activities.length > 5) {
      _activities.removeLast();
    }
  }
}
