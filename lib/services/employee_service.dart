import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/employee_model.dart';
import '../../models/employee_absence_model.dart';

/// Service de gestion des employés
class EmployeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection des employés
  CollectionReference get _employeesCollection =>
      _firestore.collection('employees');

  /// Collection des absences
  CollectionReference get _absencesCollection =>
      _firestore.collection('employee_absences');

  /// Récupérer tous les employés d'une rawdha
  Stream<List<EmployeeModel>> getEmployees(String rawdhaId) {
    return _employeesCollection
        .snapshots() // Fetch all to catch legacy data
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EmployeeModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          // Filter by rawdha (including 'default' legacy)
          .where((e) => e.rawdhaId == rawdhaId || e.rawdhaId == 'default')
          .toList();
    });
  }

  /// Récupérer un employé par ID
  Future<EmployeeModel?> getEmployee(String rawdhaId, String employeeId) async {
    final doc = await _employeesCollection.doc(employeeId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    if (data['rawdhaId'] != rawdhaId) return null;
    return EmployeeModel.fromFirestore(
      data,
      doc.id,
    );
  }

  /// Créer un employé
  Future<String> createEmployee(EmployeeModel employee, String rawdhaId) async {
    final docRef = await _employeesCollection.add(employee.toFirestore());
    return docRef.id;
  }

  /// Mettre à jour un employé
  Future<void> updateEmployee(EmployeeModel employee, String rawdhaId) async {
    await _employeesCollection
        .doc(employee.employeeId)
        .update(employee.toFirestore());
  }

  /// Supprimer un employé
  Future<void> deleteEmployee(String rawdhaId, String employeeId) async {
    // Supprimer l'employé
    await _employeesCollection.doc(employeeId).delete();
    
    // Supprimer toutes ses absences
    final absences = await _absencesCollection
        .where('employeeId', isEqualTo: employeeId)
        .get();
    
    for (var doc in absences.docs) {
      await doc.reference.delete();
    }
  }

  /// Récupérer les absences d'un employé
  Stream<List<EmployeeAbsenceModel>> getEmployeeAbsences(String rawdhaId, String employeeId) {
    return _absencesCollection
        .snapshots() // Fetch all to catch legacy data without rawdhaId
        .map((snapshot) {
      final absences = snapshot.docs
          .map((doc) => EmployeeAbsenceModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          // Filter by rawdha (including 'default' legacy) and employeeId
          .where((a) => (a.rawdhaId == rawdhaId || a.rawdhaId == 'default') && a.employeeId == employeeId)
          .toList();
      
      // Tri en mémoire (plus simple que de gérer les index Firestore)
      absences.sort((a, b) => b.startDate.compareTo(a.startDate));
      
      return absences;
    });
  }

  /// Récupérer TOUTES les absences d'une rawdha (Stream)
  Stream<List<EmployeeAbsenceModel>> getAllAbsencesStream(String rawdhaId) {
    return _absencesCollection
        .snapshots() // Fetch all to catch legacy data without rawdhaId
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EmployeeAbsenceModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .where((a) => a.rawdhaId == rawdhaId || a.rawdhaId == 'default')
          .toList();
    });
  }

  /// Ajouter une absence
  Future<String> addAbsence(String rawdhaId, EmployeeAbsenceModel absence) async {
    final docRef = await _absencesCollection.add(absence.toFirestore());
    return docRef.id;
  }

  /// Mettre à jour une absence
  Future<void> updateAbsence(EmployeeAbsenceModel absence) async {
    await _absencesCollection
        .doc(absence.absenceId)
        .update(absence.toFirestore());
  }

  /// Supprimer une absence
  Future<void> deleteAbsence(String rawdhaId, String absenceId) async {
    await _absencesCollection.doc(absenceId).delete();
  }

  /// Compter les employés présents aujourd'hui pour une rawdha
  Future<int> countPresentEmployees(String rawdhaId) async {
    final allEmployees = await _employeesCollection
        .where('rawdhaId', isEqualTo: rawdhaId)
        .get();
    final totalCount = allEmployees.docs.length;
    
    final now = DateTime.now();
    
    // Récupérer toutes les absences (car les legacy n'ont pas de rawdhaId)
    final absencesDocs = await _absencesCollection.get();
    
    int absentCount = 0;
    for (var doc in absencesDocs.docs) {
      final absence = EmployeeAbsenceModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
      // Filter in-memory: match rawdha (or default) and currently absent
      if ((absence.rawdhaId == rawdhaId || absence.rawdhaId == 'default') && absence.isCurrentlyAbsent) {
        absentCount++;
      }
    }
    
    return totalCount - absentCount;
  }

  /// Compter les employés absents aujourd'hui pour une rawdha
  Future<int> countAbsentEmployees(String rawdhaId) async {
    final absencesDocs = await _absencesCollection.get();
    
    int absentCount = 0;
    for (var doc in absencesDocs.docs) {
      final absence = EmployeeAbsenceModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
      // Filter in-memory: match rawdha (or default) and currently absent
      if ((absence.rawdhaId == rawdhaId || absence.rawdhaId == 'default') && absence.isCurrentlyAbsent) {
        absentCount++;
      }
    }
    
    return absentCount;
  }
}
