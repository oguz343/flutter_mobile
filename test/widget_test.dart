import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mobile/src/core/app_session.dart';
import 'package:flutter_mobile/src/core/app_theme.dart';
import 'package:flutter_mobile/src/screens/teacher/teacher_assignments_page.dart';

void main() {
  testWidgets('Teacher assignments page shows login message without session', (
    tester,
  ) async {
    AppSession.clear();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: TeacherAssignmentsPage(accent: AppTheme.purple),
        ),
      ),
    );

    expect(find.text('Oturum bulunamadı'), findsOneWidget);
    expect(find.text('Lütfen tekrar giriş yapın.'), findsOneWidget);
  });
}
