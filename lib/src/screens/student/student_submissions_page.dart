import 'package:flutter/material.dart';

import '../../core/app_helpers.dart';
import '../../core/app_session.dart';
import '../../core/app_theme.dart';
import '../../services/student_assignment_service.dart';
import '../../widgets/smart_link_text.dart';

class StudentSubmissionsPage extends StatelessWidget {
  final Color accent;

  const StudentSubmissionsPage({super.key, required this.accent});

  @override
  Widget build(BuildContext context) {
    final student = AppSession.currentUser;

    if (student == null) {
      return _EmptyState(
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

        final all = snapshot.data ?? [];
        final submitted = all.where((x) => x.submission != null).toList();
        final evaluated = submitted
            .where((x) => x.submission?.isEvaluated ?? false)
            .length;
        final waiting = submitted.length - evaluated;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            children: [
              _Hero(
                accent: accent,
                total: submitted.length,
                evaluated: evaluated,
                waiting: waiting,
              ),
              const SizedBox(height: 16),
              if (submitted.isEmpty)
                _EmptyState(
                  accent: accent,
                  title: 'Henüz teslim yok',
                  message:
                      'Ödev teslim ettiğinde burada timeline olarak görünecek.',
                )
              else
                ...submitted.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _SubmissionTimelineCard(item: item, accent: accent),
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
  final int total;
  final int evaluated;
  final int waiting;

  const _Hero({
    required this.accent,
    required this.total,
    required this.evaluated,
    required this.waiting,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: -32,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, AppTheme.cyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.upload_file_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Teslim Geçmişim',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 27,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '$total teslim • $evaluated notlandı • $waiting öğretmen değerlendirmesi bekliyor',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _HeroMetric(
                    value: total.toString(),
                    label: 'Teslim',
                    color: accent,
                  ),
                  const SizedBox(width: 10),
                  _HeroMetric(
                    value: evaluated.toString(),
                    label: 'Notlanan',
                    color: AppTheme.green,
                  ),
                  const SizedBox(width: 10),
                  _HeroMetric(
                    value: waiting.toString(),
                    label: 'Bekleyen',
                    color: AppTheme.orange,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _HeroMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 82,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 23,
              ),
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.74),
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionTimelineCard extends StatelessWidget {
  final StudentAssignmentBundle item;
  final Color accent;

  const _SubmissionTimelineCard({required this.item, required this.accent});

  @override
  Widget build(BuildContext context) {
    final assignment = item.assignment;
    final submission = item.submission!;
    final evaluated = submission.isEvaluated;
    final color = evaluated ? AppTheme.green : AppTheme.orange;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.line),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  evaluated
                      ? Icons.verified_rounded
                      : Icons.hourglass_top_rounded,
                  color: color,
                ),
              ),
              Container(
                width: 3,
                height: 72,
                margin: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.title,
                  style: const TextStyle(
                    color: AppTheme.dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${assignment.lessonName} • ${assignment.className}',
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoStrip(
                  icon: Icons.schedule_rounded,
                  label: 'Teslim',
                  value: AppHelpers.formatDate(submission.submittedAt),
                  color: accent,
                ),
                if (submission.link.trim().isNotEmpty) ...[
                  const SizedBox(height: 9),
                  SmartLinkText(link: submission.link, color: accent),
                ],
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.line),
                  ),
                  child: Text(
                    submission.answer.trim().isEmpty ? '-' : submission.answer,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (evaluated)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Puan: ${submission.score.trim().isEmpty ? '-' : submission.score}',
                          style: const TextStyle(
                            color: Color(0xFF047857),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        if (submission.feedback.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            submission.feedback,
                            style: const TextStyle(
                              color: Color(0xFF047857),
                              fontWeight: FontWeight.w800,
                              height: 1.35,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  _StatusBanner(
                    text: 'Öğretmen değerlendirmesi bekleniyor',
                    color: AppTheme.orange,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoStrip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.dark,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBanner({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          Icon(Icons.pending_actions_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color accent;
  final String title;
  final String message;

  const _EmptyState({
    required this.accent,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, color: accent, size: 46),
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
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
