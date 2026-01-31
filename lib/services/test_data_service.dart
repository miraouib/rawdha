import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/parent_model.dart';
import '../models/student_model.dart';
import '../models/rawdha_model.dart';
import '../models/payment_model.dart';
import '../models/school_level_model.dart';
import '../models/module_model.dart';
import 'school_service.dart';

class TestDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _maleFirstNames = [
    'أحمد', 'محمد', 'عمر', 'ياسين', 'يوسف', 'علي', 'إبراهيم', 'خالد', 'وليد', 'مروان',
    'كريم', 'حمزة', 'طه', 'إلياس', 'آدم', 'ريان', 'سفيان', 'عثمان', 'زيد', 'جاد',
    'أمين', 'سعد', 'صلاح', 'مصطفى', 'يحيى', 'زكرياء', 'عبد الله', 'هشام', 'رشيد', 'منير'
  ];

  final List<String> _femaleFirstNames = [
    'فاطمة', 'مريم', 'عائشة', 'زينب', 'ليلى', 'سارة', 'خديجة', 'نور', 'ياسمين', 'آية',
    'ريم', 'حنان', 'نادية', 'هدى', 'لمياء', 'أسماء', 'أميرة', 'سناء', 'شيماء', 'ابتسام',
    'منى', 'دنيا', 'إلهام', 'رجاء', 'نعيمة', 'بشرى', 'صفاء', 'هناء', 'وفاء', 'غزلان'
  ];

  final List<String> _lastNames = [
    'منصور', 'قدوري', 'بن علي', 'حمداوي', 'صادقي', 'علوي', 'إدريسي', 'وزاني', 'علامي', 'توبالي',
    'زيدي', 'سالم', 'قاسمي', 'بوعزيز', 'بن رحمة', 'داودي', 'فارس', 'جلال', 'نجم', 'بكري',
    'حيدر', 'سعيد', 'رزق', 'مرسي', 'طه', 'عباس', 'فضل', 'شاهين', 'زيدان', 'غالي'
  ];

  /// Clear all cache for a rawdha (placeholder - implement with LocalCacheService if needed)
  Future<void> seedLargeDataset(String rawdhaId) async {
    print('🧹 Cache clearing not implemented in this version');
    print('✅ Skipped cache clearing');
  }

  /// Clear all cache for a rawdha (placeholder - implement with LocalCacheService if needed)
  Future<void> clearTestData(String rawdhaId) async {
    print('🧹 Cache clearing not implemented in this version');
    print('✅ Skipped cache clearing');
  }
  /// Clear all cache for a rawdha (placeholder - implement with LocalCacheService if needed)
  Future<void> clearAllCache(String rawdhaId) async {
    print('🧹 Cache clearing not implemented in this version');
    print('✅ Skipped cache clearing');
  }

  /// Clear ALL cache globally (placeholder - implement with LocalCacheService if needed)
  Future<void> clearAllCacheGlobally() async {
    print('🧹 Global cache clearing not implemented in this version');
    print('✅ Skipped global cache clearing');
  }
}
