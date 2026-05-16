import 'package:flutter/material.dart';

import '../../core/app_helpers.dart';
import '../../core/app_session.dart';
import '../../core/app_theme.dart';
import '../../models/submission_model.dart';
import '../../services/teacher_service.dart';
import '../../widgets/smart_link_text.dart';

class TeacherSubmissionsPage extends StatelessWidget {
  final Color accent;

  const TeacherSubmissionsPage({super.key, required this.accent});

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
            message: 'Teslimler yüklenirken hata oluştu.',
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

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            children: [
              _Hero(
                count: data.submissions.length,
                evaluated: data.evaluatedCount,
                accent: accent,
              ),
              const SizedBox(height: 16),
              if (data.submissions.isEmpty)
                _MessageCard(
                  title: 'Henüz teslim yok',
                  message: 'Öğrenciler ödev teslim ettiğinde burada görünecek.',
                  accent: accent,
                  embedded: true,
                )
              else
                ...data.submissions.map(
                  (submission) => Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: _SubmissionCard(
                      submission: submission,
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
  final int count;
  final int evaluated;
  final Color accent;

  const _Hero({
    required this.count,
    required this.evaluated,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final pending = count - evaluated;

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
              Icons.inbox_rounded,
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
                  'Teslimler',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 25,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count teslim • $evaluated notlandı • $pending bekliyor',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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

class _SubmissionCard extends StatelessWidget {
  final SubmissionModel submission;
  final Color accent;

  const _SubmissionCard({required this.submission, required this.accent});

  @override
  Widget build(BuildContext context) {
    final evaluated = submission.isEvaluated;
    final color = evaluated ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final studentName =
        submission.studentName.trim().isEmpty ||
            submission.studentName.trim() == '-'
        ? 'Öğrenci'
        : submission.studentName.trim();

    return Container(
      width: double.infinity,
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
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(19),
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
                      submission.title,
                      style: const TextStyle(
                        color: AppTheme.dark,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${submission.lessonName} • ${submission.className}',
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
                text: evaluated ? 'Notlandı' : 'Bekliyor',
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withValues(alpha: 0.16)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: accent.withValues(alpha: 0.16),
                  child: Icon(Icons.person_rounded, color: accent, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.dark,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'No: ${submission.studentNo} • Sınıf: ${submission.className}',
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
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniChip(
                text: 'Öğrenci No: ${submission.studentNo}',
                icon: Icons.person_rounded,
                color: accent,
              ),
              _MiniChip(
                text:
                    'Teslim: ${AppHelpers.formatDate(submission.submittedAt)}',
                icon: Icons.schedule_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.line),
            ),
            child: Text(
              submission.answer,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w700,
                height: 1.45,
                fontSize: 13,
              ),
            ),
          ),
          if (submission.link.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            SmartLinkText(link: submission.link, color: accent),
          ],
          if (submission.score.trim().isNotEmpty ||
              submission.feedback.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD1FAE5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (submission.score.trim().isNotEmpty)
                    Text(
                      'Not: ${submission.score}',
                      style: const TextStyle(
                        color: Color(0xFF047857),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  if (submission.feedback.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Geri dönüş: ${submission.feedback}',
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
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) =>
                      _EvaluateSheet(submission: submission, accent: accent),
                );
              },
              icon: const Icon(Icons.grade_rounded),
              label: Text(evaluated ? 'Notu Güncelle' : 'Not / Geri Dönüş Ver'),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluateSheet extends StatefulWidget {
  final SubmissionModel submission;
  final Color accent;

  const _EvaluateSheet({required this.submission, required this.accent});

  @override
  State<_EvaluateSheet> createState() => _EvaluateSheetState();
}

class _EvaluateSheetState extends State<_EvaluateSheet> {
  late final TextEditingController _scoreController;
  late final TextEditingController _feedbackController;

  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();

    _scoreController = TextEditingController(text: widget.submission.score);
    _feedbackController = TextEditingController(
      text: widget.submission.feedback,
    );
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final score = _scoreController.text.trim();
    final feedback = _feedbackController.text.trim();

    if (score.isEmpty && feedback.isEmpty) {
      setState(
        () =>
            _error = 'Not veya geri dönüş alanlarından en az biri dolu olmalı.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      await TeacherService().evaluateSubmission(
        submission: widget.submission,
        score: score,
        feedback: feedback,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Teslim değerlendirildi.')));
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: widget.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: Icon(Icons.grade_rounded, color: widget.accent),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      widget.submission.title,
                      style: const TextStyle(
                        color: AppTheme.dark,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_error.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Text(
                    _error,
                    style: const TextStyle(
                      color: Color(0xFF991B1B),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _scoreController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Not',
                  hintText: 'Örn: 100',
                  prefixIcon: Icon(Icons.score_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _feedbackController,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Geri Dönüş',
                  hintText: 'Öğrenciye geri dönüş yazın',
                  prefixIcon: Icon(Icons.feedback_rounded),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: widget.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Kaydet',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({required this.text, required this.color});

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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
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
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
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
    );

    if (embedded) {
      return card;
    }

    return Center(
      child: Padding(padding: const EdgeInsets.all(18), child: card),
    );
  }
}
