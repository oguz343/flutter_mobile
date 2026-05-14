import 'package:flutter/material.dart';

import '../../core/app_session.dart';
import '../../core/app_theme.dart';
import '../../services/parent_service.dart';
import '../../widgets/smart_link_text.dart';

class ParentGradesPage extends StatelessWidget {
  final Color accent;

  const ParentGradesPage({
    super.key,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final parent = AppSession.currentUser;

    if (parent == null) {
      return _Empty(
        accent: accent,
        title: 'Oturum bulunamadı',
        message: 'Lütfen tekrar giriş yapın.',
      );
    }

    return StreamBuilder<ParentStudentBundle>(
      stream: ParentService().watchParentStudent(parent),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ??
            const ParentStudentBundle(
              student: null,
              assignments: [],
            );

        final graded = data.assignments
            .where((x) => x.submission?.isEvaluated ?? false)
            .toList();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            children: [
              _GradesHero(
                accent: accent,
                count: graded.length,
              ),
              const SizedBox(height: 16),
              if (graded.isEmpty)
                _Empty(
                  accent: accent,
                  title: 'Henüz not yok',
                  message:
                      'Öğretmen değerlendirme yaptığında not ve geri dönüşler burada görünecek.',
                )
              else
                ...graded.map(
                  (item) {
                    final submission = item.submission!;

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: AppTheme.softShadow,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: AppTheme.green.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Icon(
                                  Icons.grade_rounded,
                                  color: AppTheme.green,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.assignment.title,
                                      style: const TextStyle(
                                        color: AppTheme.dark,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.assignment.lessonName} • ${item.assignment.className}',
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.green.withValues(alpha: 0.11),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  submission.score.trim().isEmpty
                                      ? '-'
                                      : submission.score,
                                  style: const TextStyle(
                                    color: AppTheme.green,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFFA7F3D0),
                              ),
                            ),
                            child: Text(
                              submission.feedback.trim().isEmpty
                                  ? 'Geri dönüş yazılmamış.'
                                  : submission.feedback,
                              style: const TextStyle(
                                color: Color(0xFF047857),
                                fontWeight: FontWeight.w800,
                                height: 1.4,
                              ),
                            ),
                          ),
                          if (submission.link.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            SmartLinkText(
                              link: submission.link,
                              color: accent,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GradesHero extends StatelessWidget {
  final Color accent;
  final int count;

  const _GradesHero({
    required this.accent,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF10B981),
            Color(0xFF06B6D4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: AppTheme.green.withValues(alpha: 0.24),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 37,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Not Karnesi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 27,
                    letterSpacing: -0.9,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count ödev öğretmen tarafından değerlendirildi.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontWeight: FontWeight.w800,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.grade_rounded, color: accent, size: 46),
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