import 'package:flutter/material.dart';

import '../../core/app_helpers.dart';
import '../../core/app_session.dart';
import '../../core/app_theme.dart';
import '../../services/student_assignment_service.dart';

class StudentDashboardPage extends StatelessWidget {
  final Color accent;

  const StudentDashboardPage({
    super.key,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final student = AppSession.currentUser;

    if (student == null) {
      return _Empty(
        accent: accent,
        title: 'Oturum bulunamadı',
        message: 'Lütfen tekrar giriş yapın.',
      );
    }

    return StreamBuilder<List<StudentAssignmentBundle>>(
      stream: StudentAssignmentService().watchAssignmentsForStudent(student),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];
        final submitted = items.where((x) => x.submission != null).length;
        final evaluated =
            items.where((x) => x.submission?.isEvaluated ?? false).length;
        final pending = items.length - submitted;
        final progress = items.isEmpty ? 0.0 : submitted / items.length;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            children: [
              _StudentHero(
                accent: accent,
                name: student.name,
                className: student.className,
                progress: progress,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _GlassStat(
                      title: 'Ödev',
                      value: items.length.toString(),
                      icon: Icons.assignment_rounded,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GlassStat(
                      title: 'Teslim',
                      value: submitted.toString(),
                      icon: Icons.upload_file_rounded,
                      color: AppTheme.cyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _GlassStat(
                      title: 'Bekleyen',
                      value: pending.toString(),
                      icon: Icons.pending_actions_rounded,
                      color: AppTheme.red,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GlassStat(
                      title: 'Notlanan',
                      value: evaluated.toString(),
                      icon: Icons.verified_rounded,
                      color: AppTheme.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _MissionCard(
                accent: accent,
                items: items.take(3).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StudentHero extends StatelessWidget {
  final Color accent;
  final String name;
  final String className;
  final double progress;

  const _StudentHero({
    required this.accent,
    required this.name,
    required this.className,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF052E2B),
        borderRadius: BorderRadius.circular(38),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.25),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 145,
              height: 145,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 28,
            bottom: 8,
            child: Icon(
              Icons.school_rounded,
              color: Colors.white.withValues(alpha: 0.08),
              size: 120,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent,
                      AppTheme.cyan,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  Icons.backpack_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Merhaba, $name',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 27,
                  letterSpacing: -0.9,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$className sınıfı görev alanına hoş geldin.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 12,
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  color: accent,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'Teslim tamamlama: %$percent',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassStat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _GlassStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(31),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 29),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 30,
              letterSpacing: -1,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.muted,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final Color accent;
  final List<StudentAssignmentBundle> items;

  const _MissionCard({
    required this.accent,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bugünkü Görev Alanı',
            style: TextStyle(
              color: AppTheme.dark,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Son ödevlerin ve teslim durumların',
            style: TextStyle(
              color: AppTheme.muted,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Şimdilik aktif görev yok.',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          else
            ...items.map(
              (item) {
                final submitted = item.submission != null;
                final color = submitted ? AppTheme.green : AppTheme.orange;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        submitted
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: color,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.assignment.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.dark,
                                fontWeight: FontWeight.w900,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${item.assignment.lessonName} • ${AppHelpers.formatDate(item.assignment.dueDate)}',
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
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final Color accent;
  final String title;
  final String message;

  const _Empty({
    required this.accent,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(18),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_rounded, color: accent, size: 44),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.dark,
                fontWeight: FontWeight.w900,
                fontSize: 20,
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