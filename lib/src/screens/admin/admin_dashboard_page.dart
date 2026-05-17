import 'package:flutter/material.dart';

import '../../core/app_helpers.dart';
import '../../core/app_theme.dart';
import '../../services/admin_service.dart';
import '../../widgets/premium_shell.dart';

class AdminDashboardPage extends StatelessWidget {
  final Color accent;

  const AdminDashboardPage({super.key, required this.accent});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AdminDashboardBundle>(
      stream: AdminService().watchDashboard(),
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

        final recentRequests = data.passwordRequests.take(3).toList();
        final recentSubmissions = data.submissions.take(3).toList();
        final recentAnnouncements = data.announcements.take(3).toList();
        final completion = data.submissions.isEmpty
            ? 0.0
            : data.evaluatedSubmissionCount / data.submissions.length;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Hero(
                accent: accent,
                requestCount: data.pendingPasswordRequestCount,
                totalUsers: data.users.length,
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width > 760 ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.18,
                children: [
                  _StatCard(
                    title: 'Öğrenci',
                    value: data.students.length.toString(),
                    icon: Icons.backpack_rounded,
                    color: const Color(0xFF7C3AED),
                  ),
                  _StatCard(
                    title: 'Öğretmen',
                    value: data.teachers.length.toString(),
                    icon: Icons.co_present_rounded,
                    color: const Color(0xFF10B981),
                  ),
                  _StatCard(
                    title: 'Sınıf',
                    value: data.classes.length.toString(),
                    icon: Icons.auto_stories_rounded,
                    color: const Color(0xFFFF8A3D),
                  ),
                  _StatCard(
                    title: 'Aktif Ödev',
                    value: data.pendingSubmissionCount.toString(),
                    icon: Icons.assignment_turned_in_rounded,
                    color: const Color(0xFF3B82F6),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _CompletionCard(
                accent: accent,
                progress: completion,
                evaluated: data.evaluatedSubmissionCount,
                total: data.submissions.length,
              ),
              const SizedBox(height: 16),
              _DashboardPanel(
                title: 'Yaklaşan Görevler',
                action: 'Tümünü Gör',
                child: recentRequests.isEmpty && recentSubmissions.isEmpty
                    ? _SmallEmpty(
                        text: 'Bekleyen görev yok, sistem sakin görünüyor.',
                        accent: accent,
                      )
                    : Column(
                        children: [
                          ...recentRequests.map(
                            (item) => _TaskTile(
                              icon: Icons.lock_reset_rounded,
                              title: item.name,
                              subtitle: '${item.role} • No: ${item.number}',
                              trailing: item.status,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                          ...recentSubmissions.map(
                            (item) => _TaskTile(
                              icon: item.isEvaluated
                                  ? Icons.verified_rounded
                                  : Icons.inbox_rounded,
                              title: item.title,
                              subtitle:
                                  'Öğrenci No: ${item.studentNo} • ${AppHelpers.formatDate(item.submittedAt)}',
                              trailing:
                                  item.isEvaluated ? 'Notlandı' : 'Bekliyor',
                              color: item.isEvaluated
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              _DashboardPanel(
                title: 'Son Duyurular',
                action: 'Tümünü Gör',
                child: recentAnnouncements.isEmpty
                    ? _SmallEmpty(text: 'Henüz duyuru yok.', accent: accent)
                    : Column(
                        children: recentAnnouncements
                            .map(
                              (item) => _TaskTile(
                                icon: Icons.campaign_rounded,
                                title: item.title,
                                subtitle:
                                    '${item.target} • ${AppHelpers.formatDate(item.createdAt)}',
                                trailing: 'Duyuru',
                                color: const Color(0xFF6366F1),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 16),
              _QuickActionsStrip(
                accent: accent,
                lessons: data.lessons.length,
                announcements: data.announcements.length,
                parents: data.parents.length,
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
  final int totalUsers;

  const _Hero({
    required this.accent,
    required this.requestCount,
    required this.totalUsers,
  });

  @override
  Widget build(BuildContext context) {
    final text = requestCount == 0
        ? 'Bekleyen şifre talebi yok.'
        : '$requestCount şifre talebi bekliyor.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8EEF7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: -44,
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, const Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.coloredShadow(accent),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hoş geldiniz, Admin',
                      style: TextStyle(
                        color: AppTheme.dark,
                        fontWeight: FontWeight.w900,
                        fontSize: 23,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$text Toplam $totalUsers kullanıcı kayıtlı.',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EEF7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.dark,
              fontWeight: FontWeight.w900,
              fontSize: 25,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.muted,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  final Color accent;
  final double progress;
  final int evaluated;
  final int total;

  const _CompletionCard({
    required this.accent,
    required this.progress,
    required this.evaluated,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, const Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.coloredShadow(accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ödev Tamamlama Oranı',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Son durum',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 122,
            child: CustomPaint(
              painter: _CompletionPainter(progress: progress),
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '%$percent',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            total == 0
                ? 'Henüz teslim verisi yok.'
                : '$evaluated teslim değerlendirildi, ${total - evaluated} teslim bekliyor.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionPainter extends CustomPainter {
  final double progress;

  const _CompletionPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = <Offset>[
      Offset(0, size.height * .58),
      Offset(size.width * .18, size.height * .68),
      Offset(size.width * .36, size.height * .48),
      Offset(size.width * .54, size.height * .54),
      Offset(size.width * .72, size.height * (.46 - progress * .20)),
      Offset(size.width, size.height * (.38 - progress * .18)),
    ];

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }

    final fillPath = Path()
      ..addPath(linePath, Offset.zero)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dotPaint = Paint()..color = Colors.white;
    for (final point in points) {
      canvas.drawCircle(point, 3.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompletionPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _DashboardPanel extends StatelessWidget {
  final String title;
  final String action;
  final Widget child;

  const _DashboardPanel({
    required this.title,
    required this.action,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8EEF7)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                action,
                style: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final Color color;

  const _TaskTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? '-' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _Pill(text: trailing, color: color),
        ],
      ),
    );
  }
}

class _QuickActionsStrip extends StatelessWidget {
  final Color accent;
  final int lessons;
  final int announcements;
  final int parents;

  const _QuickActionsStrip({
    required this.accent,
    required this.lessons,
    required this.announcements,
    required this.parents,
  });

  @override
  Widget build(BuildContext context) {
    final shell = PremiumShellNavigator.maybeOf(context);
    final actions = [
      (Icons.person_add_alt_1_rounded, 'Kullanıcı', accent, 1),
      (Icons.groups_rounded, 'Sınıf', const Color(0xFF3B82F6), 2),
      (Icons.menu_book_rounded, 'Ders $lessons', const Color(0xFF10B981), 2),
      (Icons.table_chart_rounded, 'Excel', const Color(0xFFF59E0B), 3),
      (
        Icons.campaign_rounded,
        'Duyuru $announcements',
        const Color(0xFFEF4444),
        4,
      ),
      (Icons.family_restroom_rounded, 'Veli $parents', const Color(0xFF8B5CF6), 1),
      (Icons.lock_reset_rounded, 'Talep', const Color(0xFF06B6D4), 5),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8EEF7)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hızlı İşlemler',
            style: TextStyle(
              color: AppTheme.dark,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: actions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = actions[index];

                return SizedBox(
                  width: 68,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => shell?.goTo(item.$4),
                      borderRadius: BorderRadius.circular(18),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 43,
                            height: 43,
                            decoration: BoxDecoration(
                              color: item.$3.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(item.$1, color: item.$3, size: 21),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.dark,
                              fontWeight: FontWeight.w900,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10.2,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.10)),
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
