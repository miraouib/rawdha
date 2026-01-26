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
        monthlyFee: 100 + (rand.nextInt(10) * 10).toDouble(), // 100 to 200
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

    // 4. Create sample modules for each level (Sept 1 to March 15)
    final modulesData = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final year = now.month < 9 ? now.year - 1 : now.year;
    final startDateLimit = DateTime(year, 9, 1);
    final endDateLimit = DateTime(year + 1, 3, 15);

    // --- Level 3 (3 years): 10 days per module ---
    final level3Topics = [
      {'title': 'الألوان', 'letter': 'أ', 'word': 'ألوان', 'color': 'متعدد'},
      {'title': 'الدائرة', 'letter': 'د', 'word': 'دائرة', 'color': 'أزرق'},
      {'title': 'الخط المستقيم', 'letter': 'خ', 'word': 'خط', 'color': 'أحمر'},
      {'title': 'المربع', 'letter': 'م', 'word': 'مربع', 'color': 'أصفر'},
      {'title': 'الفواكه', 'letter': 'ف', 'word': 'فواكه', 'color': 'أخضر'},
      {'title': 'الحيوانات', 'letter': 'ح', 'word': 'حيوان', 'color': 'برتقالي'},
      {'title': 'عائلتي', 'letter': 'ع', 'word': 'عائلة', 'color': 'وردي'},
    ];

    // --- Level 4 (4 years): 7 days per module ---
    final arabicLetters = ['أ', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي'];
    
    final level4Topics = List.generate(10, (i) => {
      'title': 'حرف ${arabicLetters[i]} ورقم ${i + 1}',
      'letter': arabicLetters[i],
      'word': 'كلمة تبدأ بـ ${arabicLetters[i]}',
      'number': '${i + 1}',
      'color': 'لون ${i + 1}',
    });

    // --- Level 5 (5 years): 3 days per module ---
    final level5Topics = List.generate(arabicLetters.length, (i) => {
      'title': 'وحدة مكثفة: حرف ${arabicLetters[i]}',
      'letter': arabicLetters[i],
      'word': 'جملة بحرف ${arabicLetters[i]}',
      'number': '${i + 1}',
      'color': 'لون مميز',
    });

    final levelConfigs = [
      {'levelId': levels[0], 'duration': 10, 'topics': level3Topics},
      {'levelId': levels[1], 'duration': 7, 'topics': level4Topics},
      {'levelId': levels[2], 'duration': 3, 'topics': level5Topics},
    ];

    for (var config in levelConfigs) {
      DateTime currentStart = startDateLimit;
      final levelId = config['levelId'] as String;
      final duration = config['duration'] as int;
      final topics = config['topics'] as List<Map<String, String>>;
      int topicIndex = 0;

      while (currentStart.isBefore(endDateLimit)) {
        DateTime currentEnd = currentStart.add(Duration(days: duration - 1));
        if (currentEnd.isAfter(endDateLimit)) currentEnd = endDateLimit;

        final theme = topics[topicIndex % topics.length];
        final module = ModuleModel(
          id: '', // Generated by Firestore
          rawdhaId: rawdhaId,
          title: theme['title']!,
          description: 'Progression pédagogique pour le niveau',
          levelId: levelId,
          startDate: currentStart,
          endDate: currentEnd,
          letter: theme['letter'] ?? '',
          word: theme['word'] ?? '',
          number: theme['number'] ?? '',
          color: theme['color'] ?? '',
        );
        modulesData.add(module.toFirestore());

        currentStart = currentStart.add(Duration(days: duration));
        topicIndex++;
      }
    }

    // 5. Create Payments for each parent (Current Month)
    final paymentsData = <Map<String, dynamic>>[];
    for (var parent in parents) {
      final payment = PaymentModel(
        id: '', // Firestore will generate
        rawdhaId: rawdhaId,
        parentId: parent.id,
        amount: parent.monthlyFee ?? 150,
        expectedAmount: parent.monthlyFee ?? 150,
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

    // Delete all modules
    final modulesSnapshot = await _firestore
        .collection('modules')
        .where('rawdhaId', isEqualTo: rawdhaId)
        .get();

    for (var doc in modulesSnapshot.docs) {
      await doc.reference.delete();
    }
    print('✅ Deleted ${modulesSnapshot.docs.length} modules');

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
