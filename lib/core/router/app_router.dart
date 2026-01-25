import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/auth/screens/manager_login_screen.dart';
import '../../features/auth/screens/parent_login_screen.dart'; // Import this
import '../../features/auth/screens/manager_registration_screen.dart';
import '../../features/manager/dashboard/dashboard_screen.dart';
import '../../features/manager/students/student_list_screen.dart';
import '../../features/manager/students/manager_absence_list_screen.dart';
import '../../features/manager/students/student_form_screen.dart'; // Import form
import '../../features/manager/students/student_detail_screen.dart'; // Import detail
import '../../features/manager/parents/parent_list_screen.dart';
import '../guards/subscription_guard.dart';

import '../../features/manager/parents/parent_form_screen.dart'; // Import form
import '../../features/manager/finance/finance_dashboard_screen.dart';
import '../../features/manager/finance/finance_revenue_screen.dart';
import '../../features/manager/finance/finance_expenses_screen.dart';
import '../../features/manager/finance/finance_unpaid_screen.dart';
import '../../features/manager/finance/expense_form_screen.dart'; // Import expense form
import '../../features/manager/finance/revenue_form_screen.dart'; // Import revenue form
import '../../features/manager/finance/parent_payment_history_screen.dart'; // Import payment history
import '../../features/manager/modules/module_list_screen.dart';
import '../../features/manager/announcements/announcement_list_screen.dart';
import '../../features/manager/school/school_management_screen.dart';
import '../../features/manager/settings/school_config_screen.dart';
import '../../features/manager/settings/restore_data_screen.dart'; // Import
import '../../features/manager/settings/test_data_screen.dart'; // Import test data screen
import '../../features/manager/settings/contact_developer_screen.dart'; // Import
import '../../features/manager/employees/hr_management_screen.dart';
import '../../features/parent/dashboard/parent_dashboard_screen.dart';
import '../../features/parent/students/student_modules_screen.dart';
import '../../features/parent/students/student_history_screen.dart';
import '../../features/parent/students/parent_absence_form_screen.dart';
import '../../features/parent/payments/parent_payment_unpaid_screen.dart';
import '../../features/parent/announcements/parent_announcement_screen.dart';
import '../../features/parent/dashboard/parent_school_detail_screen.dart';
import '../../models/student_model.dart';
import '../../models/parent_model.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Role Selection (Home)
      GoRoute(
        path: '/',
        name: 'role_selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),

      // Manager Auth
      GoRoute(
        path: '/login/manager',
        name: 'manager_login',
        builder: (context, state) => const ManagerLoginScreen(),
        routes: [
          GoRoute(
            path: 'register',
            name: 'manager_registration',
            builder: (context, state) => const ManagerRegistrationScreen(),
          ),
        ],
      ),
      
      // Parent Auth (Added)
      GoRoute(
        path: '/login/parent',
        name: 'parent_login',
        builder: (context, state) => const ParentLoginScreen(),
      ),

      // Manager Dashboard & Features
      GoRoute(
        path: '/dashboard',
        name: 'manager_dashboard',
        builder: (context, state) => const SubscriptionGuard(
          isParent: false,
          child: ManagerDashboardScreen(),
        ),
        routes: [
          GoRoute(
            path: 'student-detail',
            name: 'student_detail',
            builder: (context, state) {
               final student = state.extra as StudentModel;
               return StudentDetailScreen(student: student);
            }
          ),
          GoRoute(
            path: 'parent-payment-history',
            name: 'parent_payment_history',
            builder: (context, state) {
               final parent = state.extra as ParentModel;
               return ParentPaymentHistoryScreen(parent: parent);
            }
          ),
          GoRoute(
            path: 'students',
            name: 'student_list',
            builder: (context, state) => const StudentListScreen(),
            routes: [
               GoRoute(
                 path: 'add',
                 name: 'student_add',
                 builder: (context, state) => const StudentFormScreen(),
               ),
               GoRoute(
                 path: 'edit',
                 name: 'student_edit',
                 builder: (context, state) {
                    final student = state.extra as StudentModel;
                    return StudentFormScreen(student: student);
                 }
               )
            ],
          ),
          GoRoute(
            path: 'parents',
            name: 'parent_list',
            builder: (context, state) => const ParentListScreen(),
            routes: [
               GoRoute(
                 path: 'add',
                 name: 'parent_add',
                 builder: (context, state) => const ParentFormScreen(),
               ),
               GoRoute(
                 path: 'edit',
                 name: 'parent_edit',
                 builder: (context, state) {
                    final parent = state.extra as ParentModel;
                    return ParentFormScreen(parent: parent);
                 }
               ),
               GoRoute(
                 name: 'parent_announcements',
                 path: 'announcements',
                 builder: (context, state) => const ParentAnnouncementScreen(),
               ),
            ],
          ),
          GoRoute(
            path: 'finance',
            name: 'finance_dashboard',
            builder: (context, state) => const FinanceDashboardScreen(),
            routes: [
               GoRoute(
                 path: 'revenue',
                 name: 'finance_revenue',
                 builder: (context, state) => const FinanceRevenueScreen(),
               ),
               GoRoute(
                 path: 'expenses',
                 name: 'finance_expenses',
                 builder: (context, state) => const FinanceExpensesScreen(),
               ),
               GoRoute(
                 path: 'unpaid',
                 name: 'finance_unpaid',
                 builder: (context, state) => const FinanceUnpaidScreen(),
               ),
               GoRoute(
                 path: 'expense/add', // Add expense
                 name: 'expense_add',
                 builder: (context, state) => const ExpenseFormScreen(),
               ),
               GoRoute(
                 path: 'revenue/add', // Add revenue
                 name: 'revenue_add',
                 builder: (context, state) {
                    final parentId = state.extra as String?;
                    return RevenueFormScreen(parentId: parentId);
                 },
               ),
            ],
          ),
          GoRoute(
            path: 'modules',
            name: 'module_list',
            builder: (context, state) => const ModuleListScreen(),
          ),
          GoRoute(
            path: 'announcements',
            name: 'announcement_list',
            builder: (context, state) => const AnnouncementListScreen(),
          ),
          GoRoute(
            path: 'school-config', // Classes Management
            name: 'school_management',
            builder: (context, state) => const SchoolManagementScreen(),
          ),
          GoRoute(
            path: 'settings', // Global Config
            name: 'school_settings',
            builder: (context, state) => const SchoolConfigScreen(),
            routes: [
               GoRoute(
                 path: 'restore',
                 name: 'restore_data',
                 builder: (context, state) => const RestoreDataScreen(),
               ),
               GoRoute(
                 path: 'test-data',
                 name: 'test_data',
                 builder: (context, state) => const TestDataScreen(),
               ),
            ],
          ),
           GoRoute(
            path: 'hr', 
            name: 'hr_management',
            builder: (context, state) => const HRManagementScreen(),
          ),
          GoRoute(
            path: 'student-absences',
            name: 'manager_absences',
            builder: (context, state) => const ManagerAbsenceListScreen(),
          ),
        ],
      ),

      GoRoute(
        path: '/contact-developer',
        name: 'contact_developer',
        builder: (context, state) => const ContactDeveloperScreen(),
      ),

      // Parent Dashboard & Features
      GoRoute(
        path: '/parent/dashboard',
        name: 'parent_dashboard',
        builder: (context, state) {
          final parent = state.extra as ParentModel;
          return SubscriptionGuard(
            isParent: true,
            child: ParentDashboardScreen(parent: parent),
          );
        },
        routes: [
           GoRoute(
            path: 'modules',
            name: 'student_modules',
            builder: (context, state) {
              final student = state.extra as StudentModel;
              return StudentModulesScreen(student: student);
            },
            routes: [
              GoRoute(
                path: 'history',
                name: 'student_history',
                builder: (context, state) {
                  final student = state.extra as StudentModel;
                  return StudentHistoryScreen(student: student);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'absence',
            name: 'parent_report_absence',
            builder: (context, state) {
              final student = state.extra as StudentModel;
              return ParentAbsenceFormScreen(student: student);
            },
          ),
          GoRoute(
            path: 'payments-unpaid',
            name: 'parent_payments_unpaid',
            builder: (context, state) {
              final parent = state.extra as ParentModel;
              return ParentPaymentUnpaidScreen(parent: parent);
            },
          ),
          GoRoute(
            path: 'school-details',
            name: 'parent_school_details',
            builder: (context, state) => const ParentSchoolDetailScreen(),
          ),
        ],
      ),
    ],
  );
});
