import 'package:flutter/material.dart';

import '../../widgets/announcements_page.dart';
import '../../widgets/premium_shell.dart';
import 'parent_assignments_status_page.dart';
import 'parent_grades_page.dart';
import 'parent_overview_page.dart';

class ParentShell extends StatelessWidget {
  const ParentShell({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF59E0B);

    return const PremiumShell(
      title: 'Veli Paneli',
      subtitle: 'Bağlı öğrencinin sürecini takip edin.',
      accent: accent,
      items: [
        PremiumShellItem(
          label: 'Panel',
          icon: Icons.dashboard_rounded,
          child: ParentOverviewPage(
            accent: accent,
          ),
        ),
        PremiumShellItem(
          label: 'Durum',
          icon: Icons.checklist_rounded,
          child: ParentAssignmentsStatusPage(
            accent: accent,
          ),
        ),
        PremiumShellItem(
          label: 'Not',
          icon: Icons.grade_rounded,
          child: ParentGradesPage(
            accent: accent,
          ),
        ),
        PremiumShellItem(
          label: 'Duyuru',
          icon: Icons.campaign_rounded,
          child: AnnouncementsPage(
            role: 'Veli',
            accent: accent,
          ),
        ),
      ],
    );
  }
}