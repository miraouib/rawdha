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

  Future<void> seedLargeDataset(String rawdhaId) async {
    final rand = Random();
    
    // Levels Reference (Fixed IDs with rawdhaId prefix to match SchoolService)
    final levels = [
      '${rawdhaId}_${SchoolLevelModel.level3Id}', 
      '${rawdhaId}_${SchoolLevelModel.level4Id}', 
      '${rawdhaId}_${SchoolLevelModel.level5Id}'
    ];

    // 1. Initialize Levels if missing
    final schoolService = SchoolService();
    await schoolService.initializeDefaultLevels(rawdhaId);

    final parents = <ParentModel>[];
    final parentRefs = <DocumentReference>[];

    // 2. Create 100 Parents
    for (int i = 0; i < 100; i++) {
      final firstName = _maleFirstNames[rand.nextInt(_maleFirstNames.length)];
      final lastName = _lastNames[rand.nextInt(_lastNames.length)];
      final spouseName = _femaleFirstNames[rand.nextInt(_femaleFirstNames.length)];
      
      final parentDoc = _firestore.collection('parents').doc();
      final familyCode = '${firstName[0]}${10000 + rand.nextInt(90000)}';
      
      final prefixes = ['2', '5', '9'];
      final phone = '${prefixes[rand.nextInt(prefixes.length)]}${rand.nextInt(10000000).toString().padLeft(7, '0')}';
      final spousePhone = '${prefixes[rand.nextInt(prefixes.length)]}${rand.nextInt(10000000).toString().padLeft(7, '0')}';

      final parent = ParentModel(
        id: parentDoc.id,
        rawdhaId: rawdhaId,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        familyCode: familyCode,
        spouseName: spouseName,
        spousePhone: spousePhone,
        createdAt: DateTime.now(),
        studentIds: [],
        monthlyFee: 1500 + (rand.nextInt(10) * 100).toDouble(), // 1500 to 2400
      );
      
      parents.add(parent);
      parentRefs.add(parentDoc);
    }

    // 3. Create 160 Students
    final studentsData = <Map<String, dynamic>>[];
    final studentIds = <String>[];
    
    for (int i = 0; i < 160; i++) {
      // Pick a random parent
      final parentIndex = rand.nextInt(parents.length);
      final parent = parents[parentIndex];
      
      final isBoy = rand.nextBool();
      final firstName = isBoy 
          ? _maleFirstNames[rand.nextInt(_maleFirstNames.length)]
          : _femaleFirstNames[rand.nextInt(_femaleFirstNames.length)];
      
      final studentId = _firestore.collection('students').doc().id;
      final student = StudentModel(
        studentId: studentId,
        rawdhaId: rawdhaId,
        firstName: firstName,
        lastName: parent.lastName,
        gender: isBoy ? 'boy' : 'girl',
        parentIds: [parent.id],
        levelId: levels[rand.nextInt(levels.length)],
        encryptedMonthlyFee: '',
        monthlyFee: parent.monthlyFee ?? 2000,
        createdAt: DateTime.now(),
        birthdate: DateTime.now().subtract(Duration(days: 1000 + rand.nextInt(1000))),
        parentName: '${parent.firstName} ${parent.lastName}',
        parentPhone: parent.phone,
      );
      
      studentsData.add(student.toFirestore()..['id'] = studentId);
      studentIds.add(studentId);
      
      // Keep track of student link (local update for batch later)
      parent.studentIds.add(studentId);
    }

    // 4. Create sample modules for each level (Current week)
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 4)); // Monday to Friday
    
    final modulesData = <Map<String, dynamic>>[];
    final moduleThemes = [
      {'title': 'Les Fruits', 'letter': 'F', 'number': '3', 'color': 'Rouge', 'word': 'Fraise'},
      {'title': 'Les Animaux', 'letter': 'A', 'number': '5', 'color': 'Marron', 'word': 'Lion'},
      {'title': 'L\'Espace', 'letter': 'E', 'number': '0', 'color': 'Noir', 'word': 'Étoile'},
    ];

    for (int i = 0; i < levels.length; i++) {
      final theme = moduleThemes[i % moduleThemes.length];
      final module = ModuleModel(
        id: '', // Generated by Firestore
        rawdhaId: rawdhaId,
        title: theme['title']!,
        description: 'Programme de la semaine sur ${theme['title']}',
        levelId: levels[i],
        startDate: startOfWeek,
        endDate: endOfWeek,
        letter: theme['letter']!,
        word: theme['word']!,
        number: theme['number']!,
        color: theme['color']!,
      );
      modulesData.add(module.toFirestore());
    }

    // 5. Create Payments for each parent (Current Month)
    final paymentsData = <Map<String, dynamic>>[];
    for (var parent in parents) {
      final payment = PaymentModel(
        id: '', // Firestore will generate
        rawdhaId: rawdhaId,
        parentId: parent.id,
        amount: parent.monthlyFee ?? 2000,
        expectedAmount: parent.monthlyFee ?? 2000,
        date: now,
        month: now.month,
        year: now.year,
        createdAt: now,
        parentName: '${parent.firstName} ${parent.lastName}',
        parentFamilyCode: parent.familyCode,
      );
      paymentsData.add(payment.toFirestore());
    }

    // 5. Execute in batches
    WriteBatch batch = _firestore.batch();
    int count = 0;

    // Parents
    for (int i = 0; i < parents.length; i++) {
      batch.set(parentRefs[i], parents[i].toMap());
      count++;
      if (count >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }

    // Students
    for (var s in studentsData) {
      final id = s['id'];
      s.remove('id');
      batch.set(_firestore.collection('students').doc(id), s);
      count++;
      if (count >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }

    // Payments
    for (var p in paymentsData) {
      batch.set(_firestore.collection('payments').doc(), p);
      count++;
      if (count >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }

    // Modules
    for (var m in modulesData) {
      batch.set(_firestore.collection('modules').doc(), m);
      count++;
      if (count >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }

    await batch.commit();
    
    // Invalidate cache to force refresh
    print('🔄 Invalidating cache...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (var key in keys) {
        if (key.contains('cached_parents') || key.contains('cached_students')) {
          await prefs.remove(key);
        }
      }
      print('✅ Cache invalidated');
    } catch (e) {
      print('⚠️ Cache invalidation skipped: $e');
    }
  }

  /// Clear all test data for a rawdha
  Future<void> clearTestData(String rawdhaId) async {
    print('🗑️ Clearing all test data for rawdha: $rawdhaId');

    // Delete all students
    final studentsSnapshot = await _firestore
        .collection('students')
        .where('rawdhaId', isEqualTo: rawdhaId)
        .get();

    for (var doc in studentsSnapshot.docs) {
      await doc.reference.delete();
    }
    print('✅ Deleted ${studentsSnapshot.docs.length} students');

    // Delete all parents
    final parentsSnapshot = await _firestore
        .collection('parents')
        .where('rawdhaId', isEqualTo: rawdhaId)
        .get();

    for (var doc in parentsSnapshot.docs) {
      await doc.reference.delete();
    }
    print('✅ Deleted ${parentsSnapshot.docs.length} parents');

    // Delete all payments
    final paymentsSnapshot = await _firestore
        .collection('payments')
        .where('rawdhaId', isEqualTo: rawdhaId)
        .get();

    for (var doc in paymentsSnapshot.docs) {
      await doc.reference.delete();
    }
    print('✅ Deleted ${paymentsSnapshot.docs.length} payments');

    print('🎉 All test data cleared!');
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
