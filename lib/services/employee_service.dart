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

  /// Récupérer tous les employés
  Stream<List<EmployeeModel>> getEmployees() {
    return _employeesCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => EmployeeModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    });
  }

  /// Récupérer un employé par ID
  Future<EmployeeModel?> getEmployee(String employeeId) async {
    final doc = await _employeesCollection.doc(employeeId).get();
    if (!doc.exists) return null;
    return EmployeeModel.fromFirestore(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
  }

  /// Créer un employé
  Future<String> createEmployee(EmployeeModel employee) async {
    final docRef = await _employeesCollection.add(employee.toFirestore());
    return docRef.id;
  }

  /// Mettre à jour un employé
  Future<void> updateEmployee(EmployeeModel employee) async {
    await _employeesCollection
        .doc(employee.employeeId)
        .update(employee.toFirestore());
  }

  /// Supprimer un employé
  Future<void> deleteEmployee(String employeeId) async {
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
  Stream<List<EmployeeAbsenceModel>> getEmployeeAbsences(String employeeId) {
    return _absencesCollection
        .where('employeeId', isEqualTo: employeeId)
        .snapshots()
        .map((snapshot) {
      final absences = snapshot.docs
          .map((doc) => EmployeeAbsenceModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
      
      // Tri en mémoire (plus simple que de gérer les index Firestore)
      absences.sort((a, b) => b.startDate.compareTo(a.startDate));
      
      return absences;
    });
  }

  /// Ajouter une absence
  Future<String> addAbsence(EmployeeAbsenceModel absence) async {
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
  Future<void> deleteAbsence(String absenceId) async {
    await _absencesCollection.doc(absenceId).delete();
  }

  /// Compter les employés présents aujourd'hui
  Future<int> countPresentEmployees() async {
    final allEmployees = await _employeesCollection.get();
    final totalCount = allEmployees.docs.length;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Récupérer les absences en cours
    final absences = await _absencesCollection
        .where('startDate', isLessThanOrEqualTo: today.toIso8601String())
        .get();
    
    int absentCount = 0;
    for (var doc in absences.docs) {
      final absence = EmployeeAbsenceModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
      if (absence.isCurrentlyAbsent) {
        absentCount++;
      }
    }
    
    return totalCount - absentCount;
  }

  /// Compter les employés absents aujourd'hui
  Future<int> countAbsentEmployees() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final absences = await _absencesCollection
        .where('startDate', isLessThanOrEqualTo: today.toIso8601String())
        .get();
    
    int absentCount = 0;
    for (var doc in absences.docs) {
      final absence = EmployeeAbsenceModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
      if (absence.isCurrentlyAbsent) {
        absentCount++;
      }
    }
    
    return absentCount;
  }
}
