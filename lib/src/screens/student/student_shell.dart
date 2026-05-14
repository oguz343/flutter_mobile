import 'package:flutter/material.dart';

import '../../widgets/announcements_page.dart';
import '../../widgets/premium_shell.dart';
import 'student_assignments_page.dart';
import 'student_dashboard_page.dart';
import 'student_submissions_page.dart';

class StudentShell extends StatelessWidget {
  const StudentShell({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF10B981);

    return const PremiumShell(
      title: 'Öğrenci Paneli',
      subtitle: 'Ödevlerini takip et, teslimlerini yönet.',
      accent: accent,
      items: [
        PremiumShellItem(
          label: 'Panel',
          icon: Icons.dashboard_rounded,
          child: StudentDashboardPage(
            accent: accent,
          ),
        ),
        PremiumShellItem(
          label: 'Ödev',
          icon: Icons.assignment_rounded,
          child: StudentAssignmentsPage(
            accent: accent,
          ),
        ),
        PremiumShellItem(
          label: 'Teslim',
          icon: Icons.timeline_rounded,
          child: StudentSubmissionsPage(
            accent: accent,
          ),
        ),
        PremiumShellItem(
          label: 'Duyuru',
          icon: Icons.campaign_rounded,
          child: AnnouncementsPage(
            role: 'Öğrenci',
            accent: accent,
          ),
        ),
      ],
    );
  }
}