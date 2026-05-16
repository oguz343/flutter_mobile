import 'package:flutter/material.dart';

import '../../widgets/announcements_page.dart';
import '../../widgets/premium_shell.dart';
import 'teacher_assignments_page.dart';
import 'teacher_dashboard_page.dart';
import 'teacher_submissions_page.dart';

class TeacherShell extends StatelessWidget {
  const TeacherShell({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF06B6D4);

    return const PremiumShell(
      title: 'Öğretmen Paneli',
      subtitle: 'Dersleriniz, ödevleriniz ve teslimleriniz.',
      accent: accent,
      items: [
        PremiumShellItem(
          label: 'Panel',
          icon: Icons.dashboard_rounded,
          child: TeacherDashboardPage(accent: accent),
        ),
        PremiumShellItem(
          label: 'Ödev',
          icon: Icons.assignment_rounded,
          child: TeacherAssignmentsPage(accent: accent),
        ),
        PremiumShellItem(
          label: 'Teslim',
          icon: Icons.inbox_rounded,
          child: TeacherSubmissionsPage(accent: accent),
        ),
        PremiumShellItem(
          label: 'Duyuru',
          icon: Icons.campaign_rounded,
          child: AnnouncementsPage(role: 'Öğretmen', accent: accent),
        ),
      ],
    );
  }
}
