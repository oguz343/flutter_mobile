import 'package:flutter/material.dart';

import '../../core/app_helpers.dart';
import '../../core/app_theme.dart';
import '../../services/admin_service.dart';

class AdminDashboardPage extends StatelessWidget {
  final Color accent;

  const AdminDashboardPage({super.key, required this.accent});

  @override
  Widget build(BuildContext context) {
    final service = AdminService();

    return StreamBuilder<AdminDashboardBundle>(
      stream: service.watchDashboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _MessageCard(
            title: 'Hata oluştu',
            message: 'Admin dashboard yüklenirken hata oluştu.',
            accent: accent,
          );
        }

        final data =
            snapshot.data ??
            const AdminDashboardBundle(
              users: [],
              students: [],
              teachers: [],
              parents: [],
              admins: [],
              classes: [],
              lessons: [],
              announcements: [],
              submissions: [],
              passwordRequests: [],
            );

        final recentRequests = data.passwordRequests.take(4).toList();
        final recentSubmissions = data.submissions.take(4).toList();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Hero(
                accent: accent,
                requestCount: data.pendingPasswordRequestCount,
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width > 760 ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: [
                  _StatCard(
                    title: 'Öğrenci',
                    value: data.students.length.toString(),
                    icon: Icons.backpack_rounded,
                    color: const Color(0xFF10B981),
                  ),
                  _StatCard(
                    title: 'Öğretmen',
                    value: data.teachers.length.toString(),
                    icon: Icons.co_present_rounded,
                    color: const Color(0xFF06B6D4),
                  ),
                  _StatCard(
                    title: 'Veli',
                    value: data.parents.length.toString(),
                    icon: Icons.family_restroom_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  _StatCard(
                    title: 'Admin',
                    value: data.admins.length.toString(),
                    icon: Icons.admin_panel_settings_rounded,
                    color: accent,
                  ),
                  _StatCard(
                    title: 'Sınıf',
                    value: data.classes.length.toString(),
                    icon: Icons.apartment_rounded,
                    color: const Color(0xFF8B5CF6),
                  ),
                  _StatCard(
                    title: 'Ders',
                    value: data.lessons.length.toString(),
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFF2563EB),
                  ),
                  _StatCard(
                    title: 'Duyuru',
                    value: data.announcements.length.toString(),
                    icon: Icons.campaign_rounded,
                    color: const Color(0xFFEF4444),
                  ),
                  _StatCard(
                    title: 'Şifre Talebi',
                    value: data.pendingPasswordRequestCount.toString(),
                    icon: Icons.lock_reset_rounded,
                    color: const Color(0xFFDC2626),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionTitle(
                title: 'Sistem Özeti',
                subtitle: 'Mevcut canlı kayıt durumları',
              ),
              const SizedBox(height: 10),
              _WideSummaryCard(
                accent: accent,
                totalUsers: data.users.length,
                totalSubmissions: data.submissions.length,
                evaluated: data.evaluatedSubmissionCount,
                pending: data.pendingSubmissionCount,
              ),
              const SizedBox(height: 18),
              _SectionTitle(
                title: 'Bekleyen Şifre Talepleri',
                subtitle: 'Admin müdahalesi bekleyen talepler',
              ),
              const SizedBox(height: 10),
              if (recentRequests.isEmpty)
                _SmallEmpty(
                  text: 'Bekleyen şifre talebi bulunmuyor.',
                  accent: accent,
                )
              else
                ...recentRequests.map(
                  (item) => _RequestRow(item: item, accent: accent),
                ),
              const SizedBox(height: 18),
              _SectionTitle(
                title: 'Son Teslimler',
                subtitle: 'Öğrenci teslim hareketleri',
              ),
              const SizedBox(height: 10),
              if (recentSubmissions.isEmpty)
                _SmallEmpty(text: 'Henüz teslim bulunmuyor.', accent: accent)
              else
                ...recentSubmissions.map(
                  (item) => _SubmissionRow(
                    title: item.title,
                    subtitle:
                        'Öğrenci No: ${item.studentNo} • ${AppHelpers.formatDate(item.submittedAt)}',
                    evaluated: item.isEvaluated,
                    accent: accent,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  final Color accent;
  final int requestCount;

  const _Hero({required this.accent, required this.requestCount});

  @override
  Widget build(BuildContext context) {
    final text = requestCount == 0
        ? 'Sistemde bekleyen şifre talebi yok.'
        : '$requestCount bekleyen şifre talebi var.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, const Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.24),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(23),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 25,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.line),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.dark,
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: 0,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.muted,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _WideSummaryCard extends StatelessWidget {
  final Color accent;
  final int totalUsers;
  final int totalSubmissions;
  final int evaluated;
  final int pending;

  const _WideSummaryCard({
    required this.accent,
    required this.totalUsers,
    required this.totalSubmissions,
    required this.evaluated,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        children: [
          _SummaryLine(
            icon: Icons.groups_rounded,
            label: 'Toplam aktif kullanıcı',
            value: totalUsers.toString(),
            color: accent,
          ),
          const Divider(height: 22),
          _SummaryLine(
            icon: Icons.inbox_rounded,
            label: 'Toplam teslim',
            value: totalSubmissions.toString(),
            color: const Color(0xFFF59E0B),
          ),
          const Divider(height: 22),
          _SummaryLine(
            icon: Icons.verified_rounded,
            label: 'Değerlendirilmiş teslim',
            value: evaluated.toString(),
            color: const Color(0xFF10B981),
          ),
          const Divider(height: 22),
          _SummaryLine(
            icon: Icons.pending_actions_rounded,
            label: 'Bekleyen teslim',
            value: pending.toString(),
            color: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.dark,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.dark,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.muted,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _RequestRow extends StatelessWidget {
  final PasswordRequestModel item;
  final Color accent;

  const _RequestRow({required this.item, required this.accent});

  @override
  Widget build(BuildContext context) {
    final color = item.isPending
        ? const Color(0xFFEF4444)
        : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(Icons.lock_reset_rounded, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: AppTheme.dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.role} • No: ${item.number} • ${AppHelpers.formatDate(item.createdAt)}',
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _Pill(text: item.status, color: color),
        ],
      ),
    );
  }
}

class _SubmissionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool evaluated;
  final Color accent;

  const _SubmissionRow({
    required this.title,
    required this.subtitle,
    required this.evaluated,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = evaluated ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              evaluated ? Icons.verified_rounded : Icons.inbox_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _Pill(text: evaluated ? 'Notlandı' : 'Bekliyor', color: color),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

class _SmallEmpty extends StatelessWidget {
  final String text;
  final Color accent;

  const _SmallEmpty({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.line),
        boxShadow: AppTheme.softShadow,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.muted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String title;
  final String message;
  final Color accent;

  const _MessageCard({
    required this.title,
    required this.message,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(18),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_rounded, color: accent, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.dark,
                fontWeight: FontWeight.w900,
                fontSize: 19,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
