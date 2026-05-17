import 'package:flutter/material.dart';

import '../../widgets/premium_shell.dart';
import 'admin_announcements_page.dart';
import 'admin_classes_lessons_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_excel_import_page.dart';
import 'admin_password_page.dart';
import 'admin_password_requests_page.dart';
import 'admin_users_page.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF4F46E5);

    return const PremiumShell(
      title: 'Admin Paneli',
      subtitle: 'Okul yönetimini tek yerden kontrol edin.',
      accent: accent,
      items: [
        PremiumShellItem(
          label: 'Panel',
          icon: Icons.dashboard_rounded,
          child: AdminDashboardPage(accent: accent),
        ),
        PremiumShellItem(
          label: 'Kullanıcı',
          icon: Icons.groups_rounded,
          child: AdminUsersPage(accent: accent),
        ),
        PremiumShellItem(
          label: 'Okul',
          icon: Icons.apartment_rounded,
          child: AdminClassesLessonsPage(accent: accent),
        ),
        PremiumShellItem(
          label: 'Excel',
          icon: Icons.table_chart_rounded,
          child: AdminExcelImportPage(accent: accent),
        ),
        PremiumShellItem(
          label: 'Duyuru',
          icon: Icons.campaign_rounded,
          child: AdminAnnouncementsPage(accent: accent),
        ),
        PremiumShellItem(
          label: 'Talepler',
          icon: Icons.lock_reset_rounded,
          child: AdminPasswordRequestsPage(accent: accent),
        ),
        PremiumShellItem(
          label: 'Şifre',
          icon: Icons.security_rounded,
          child: AdminPasswordPage(accent: accent),
        ),
      ],
    );
  }
}
