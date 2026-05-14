import 'package:flutter/material.dart';

import '../../core/app_helpers.dart';
import '../../core/app_session.dart';
import '../../core/app_theme.dart';
import '../../services/parent_service.dart';

class ParentAssignmentsStatusPage extends StatelessWidget {
  final Color accent;

  const ParentAssignmentsStatusPage({
    super.key,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final parent = AppSession.currentUser;

    if (parent == null) {
      return _Empty(accent: accent, text: 'Oturum bulunamadı.');
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

        final items = data.assignments;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            children: [
              _BoardHero(
                accent: accent,
                total: data.totalAssignments,
                pending: data.pendingCount,
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                _Empty(
                  accent: accent,
                  text: 'Öğrencinin sınıfına atanmış ödev bulunmuyor.',
                )
              else
                ...items.map(
                  (item) {
                    final submitted = item.submission != null;
                    final evaluated = item.submission?.isEvaluated ?? false;
                    final color = !submitted
                        ? AppTheme.red
                        : evaluated
                            ? AppTheme.green
                            : AppTheme.orange;

                    final status = !submitted
                        ? 'Teslim edilmedi'
                        : evaluated
                            ? 'Değerlendirildi'
                            : 'Teslim edildi';

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: AppTheme.softShadow,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(21),
                            ),
                            child: Icon(
                              !submitted
                                  ? Icons.pending_actions_rounded
                                  : evaluated
                                      ? Icons.verified_rounded
                                      : Icons.upload_file_rounded,
                              color: color,
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
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.assignment.lessonName} • Son: ${AppHelpers.formatDate(item.assignment.dueDate)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.muted,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                                if (!submitted) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Bu ödev henüz öğrenci tarafından teslim edilmemiş.',
                                    style: TextStyle(
                                      color: AppTheme.red,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w900,
                                fontSize: 10.5,
                              ),
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
      },
    );
  }
}

class _BoardHero extends StatelessWidget {
  final Color accent;
  final int total;
  final int pending;

  const _BoardHero({
    required this.accent,
    required this.total,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent,
                  AppTheme.orange,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              Icons.checklist_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ödev Durum Tahtası',
                  style: TextStyle(
                    color: AppTheme.dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 23,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$total toplam ödev • $pending teslim bekliyor',
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w800,
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
  final String text;

  const _Empty({
    required this.accent,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, color: accent, size: 44),
          const SizedBox(height: 12),
          Text(
            text,
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