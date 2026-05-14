import 'package:flutter/material.dart';

import '../../core/app_helpers.dart';
import '../../core/app_session.dart';
import '../../core/app_theme.dart';
import '../../services/parent_service.dart';
import '../../services/student_assignment_service.dart';
import '../../widgets/smart_link_text.dart';

class ParentStudentStatusPage extends StatelessWidget {
  final Color accent;

  const ParentStudentStatusPage({
    super.key,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final parent = AppSession.currentUser;

    if (parent == null) {
      return _MessageCard(
        title: 'Oturum bulunamadı',
        message: 'Lütfen tekrar giriş yapın.',
        accent: accent,
      );
    }

    final service = ParentService();

    return StreamBuilder<ParentStudentBundle>(
      stream: service.watchParentStudent(parent),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return _MessageCard(
            title: 'Hata oluştu',
            message: 'Veli bilgileri yüklenirken hata oluştu.',
            accent: accent,
          );
        }

        final data = snapshot.data ??
            const ParentStudentBundle(
              student: null,
              assignments: [],
            );

        final student = data.student;

        if (student == null) {
          return _MessageCard(
            title: 'Bağlı öğrenci bulunamadı',
            message:
                'Bu veli hesabına bağlı öğrenci bulunamadı. Admin panelinden veli-öğrenci eşleştirmesini kontrol edin.',
            accent: accent,
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Hero(
                studentName: student.name,
                studentNo: student.number,
                className: student.className,
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
                    title: 'Toplam Ödev',
                    value: data.totalAssignments.toString(),
                    icon: Icons.assignment_rounded,
                    color: accent,
                  ),
                  _StatCard(
                    title: 'Teslim',
                    value: data.submittedCount.toString(),
                    icon: Icons.upload_file_rounded,
                    color: const Color(0xFF4F46E5),
                  ),
                  _StatCard(
                    title: 'Bekleyen',
                    value: data.pendingCount.toString(),
                    icon: Icons.pending_actions_rounded,
                    color: const Color(0xFFEF4444),
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
              const _SectionTitle(
                title: 'Ödev ve Teslim Durumu',
                subtitle: 'Bağlı öğrencinin ödev, teslim, not ve geri dönüşleri',
              ),
              const SizedBox(height: 10),
              if (data.assignments.isEmpty)
                _MessageCard(
                  title: 'Henüz ödev yok',
                  message: 'Bağlı öğrencinin sınıfına atanmış ödev bulunmuyor.',
                  accent: accent,
                  embedded: true,
                )
              else
                ...data.assignments.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: _AssignmentStatusCard(
                      item: item,
                      accent: accent,
                    ),
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
  final String studentName;
  final String studentNo;
  final String className;
  final Color accent;

  const _Hero({
    required this.studentName,
    required this.studentNo,
    required this.className,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final classText = className.trim().isEmpty ? '-' : className;
    final noText = studentNo.trim().isEmpty ? '-' : studentNo;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent,
            const Color(0xFFF97316),
          ],
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
              Icons.family_restroom_rounded,
              color: Colors.white,
              size: 33,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Öğrenci Durumu',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 25,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$studentName • No: $noText • Sınıf: $classText',
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
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.dark,
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: -0.8,
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

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

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
            letterSpacing: -0.5,
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

class _AssignmentStatusCard extends StatelessWidget {
  final StudentAssignmentBundle item;
  final Color accent;

  const _AssignmentStatusCard({
    required this.item,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final assignment = item.assignment;
    final submission = item.submission;

    final submitted = submission != null;
    final evaluated = submission?.isEvaluated ?? false;

    final statusText = !submitted
        ? 'Teslim edilmedi'
        : evaluated
            ? 'Değerlendirildi'
            : 'Teslim edildi';

    final statusColor = !submitted
        ? const Color(0xFFEF4444)
        : evaluated
            ? const Color(0xFF10B981)
            : const Color(0xFFF59E0B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Icon(
                  evaluated
                      ? Icons.verified_rounded
                      : submitted
                          ? Icons.upload_file_rounded
                          : Icons.pending_actions_rounded,
                  color: statusColor,
                ),
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
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${assignment.lessonName} • ${assignment.className}',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(
                text: statusText,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniChip(
                text: 'Öğretmen: ${assignment.teacherName}',
                icon: Icons.co_present_rounded,
                color: accent,
              ),
              _MiniChip(
                text: 'Son: ${AppHelpers.formatDate(assignment.dueDate)}',
                icon: Icons.schedule_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
          if (submission != null) ...[
            const SizedBox(height: 12),
            _SubmissionDetail(
              submittedAt: submission.submittedAt,
              answer: submission.answer,
              link: submission.link,
              score: submission.score,
              feedback: submission.feedback,
              evaluated: submission.isEvaluated,
            ),
          ],
        ],
      ),
    );
  }
}

class _SubmissionDetail extends StatelessWidget {
  final DateTime? submittedAt;
  final String answer;
  final String link;
  final String score;
  final String feedback;
  final bool evaluated;

  const _SubmissionDetail({
    required this.submittedAt,
    required this.answer,
    required this.link,
    required this.score,
    required this.feedback,
    required this.evaluated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: evaluated ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: evaluated ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            evaluated ? 'Öğretmen Değerlendirmesi' : 'Teslim Bilgisi',
            style: TextStyle(
              color:
                  evaluated ? const Color(0xFF047857) : const Color(0xFF92400E),
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Teslim tarihi: ${AppHelpers.formatDate(submittedAt)}',
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          if (answer.trim().isNotEmpty && answer.trim() != '-') ...[
            const SizedBox(height: 7),
            Text(
              'Cevap: $answer',
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          if (link.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            SmartLinkText(
              link: link,
              color: const Color(0xFF2563EB),
            ),
          ],
          if (score.trim().isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              'Puan: $score',
              style: const TextStyle(
                color: Color(0xFF047857),
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
          if (feedback.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              'Geri dönüş: $feedback',
              style: const TextStyle(
                color: Color(0xFF047857),
                fontWeight: FontWeight.w800,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
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

class _MiniChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _MiniChip({
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String title;
  final String message;
  final Color accent;
  final bool embedded;

  const _MessageCard({
    required this.title,
    required this.message,
    required this.accent,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.softShadow,
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_rounded,
            color: accent,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
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
              height: 1.4,
            ),
          ),
        ],
      ),
    );

    if (embedded) {
      return card;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: card,
      ),
    );
  }
}