import 'package:flutter/material.dart';

import '../../core/app_helpers.dart';
import '../../core/app_session.dart';
import '../../core/app_theme.dart';
import '../../services/teacher_service.dart';

class TeacherDashboardPage extends StatelessWidget {
  final Color accent;

  const TeacherDashboardPage({super.key, required this.accent});

  @override
  Widget build(BuildContext context) {
    final teacher = AppSession.currentUser;

    if (teacher == null) {
      return _MessageCard(
        title: 'Oturum bulunamadı',
        message: 'Lütfen tekrar giriş yapın.',
        accent: accent,
      );
    }

    final service = TeacherService();

    return StreamBuilder<TeacherDashboardBundle>(
      stream: service.watchTeacherDashboard(teacher),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _MessageCard(
            title: 'Hata oluştu',
            message: 'Dashboard yüklenirken hata oluştu.',
            accent: accent,
          );
        }

        final data =
            snapshot.data ??
            const TeacherDashboardBundle(
              lessons: [],
              assignments: [],
              submissions: [],
            );

        final recentSubmissions = data.submissions.take(4).toList();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Hero(
                teacherName: teacher.name,
                branch: teacher.branch,
                accent: accent,
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _StatCard(
                    title: 'Ders',
                    value: data.lessons.length.toString(),
                    icon: Icons.menu_book_rounded,
                    color: accent,
                  ),
                  _StatCard(
                    title: 'Ödev',
                    value: data.assignments.length.toString(),
                    icon: Icons.assignment_rounded,
                    color: const Color(0xFF4F46E5),
                  ),
                  _StatCard(
                    title: 'Teslim',
                    value: data.submissions.length.toString(),
                    icon: Icons.inbox_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  _StatCard(
                    title: 'Notlanan',
                    value: data.evaluatedCount.toString(),
                    icon: Icons.verified_rounded,
                    color: const Color(0xFF10B981),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'Derslerim',
                subtitle: 'Size atanmış dersler',
              ),
              const SizedBox(height: 10),
              if (data.lessons.isEmpty)
                _SmallEmpty(
                  text: 'Henüz size atanmış ders görünmüyor.',
                  accent: accent,
                )
              else
                ...data.lessons
                    .take(5)
                    .map(
                      (lesson) => _LessonRow(
                        title: lesson.name,
                        subtitle: '${lesson.className} • ${lesson.branch}',
                        accent: accent,
                      ),
                    ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'Son Teslimler',
                subtitle: 'Öğrencilerden gelen son teslimler',
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
  final String teacherName;
  final String branch;
  final Color accent;

  const _Hero({
    required this.teacherName,
    required this.branch,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final branchText = branch.trim().isEmpty ? '-' : branch;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, AppTheme.cyan],
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
              Icons.co_present_rounded,
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
                  'Öğretmen Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$teacherName • Branş: $branchText',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
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
          ),
        ),
      ],
    );
  }
}

class _LessonRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;

  const _LessonRow({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
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
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(Icons.menu_book_rounded, color: accent),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              evaluated ? 'Notlandı' : 'Bekliyor',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ],
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
