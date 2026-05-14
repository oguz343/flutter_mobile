import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'src/core/app_theme.dart';
import 'src/screens/admin/admin_shell.dart';
import 'src/screens/auth/change_password_screen.dart';
import 'src/screens/auth/forgot_password_screen.dart';
import 'src/screens/auth/login_screen.dart';
import 'src/screens/parent/parent_shell.dart';
import 'src/screens/student/student_shell.dart';
import 'src/screens/teacher/teacher_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const HomeworkApp());
}

class HomeworkApp extends StatelessWidget {
  const HomeworkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ödev Sistemi',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (_) => const LoginScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/change-password': (_) => const ChangePasswordScreen(),
        '/admin': (_) => const AdminShell(),
        '/teacher': (_) => const TeacherShell(),
        '/student': (_) => const StudentShell(),
        '/parent': (_) => const ParentShell(),
      },
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
      };
}