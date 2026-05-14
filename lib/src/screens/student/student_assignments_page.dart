import 'package:flutter/material.dart';

import '../../core/app_session.dart';
import '../../core/app_theme.dart';
import '../../models/assignment_model.dart';
import '../../services/student_assignment_service.dart';
import '../../widgets/smart_link_text.dart';

class StudentAssignmentsPage extends StatelessWidget {
  final Color accent;

  const StudentAssignmentsPage({
    super.key,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final user = AppSession.currentUser;

    if (user == null) {
      return _MessagePage(
        title: 'Oturum bulunamadı',
        message: 'Lütfen tekrar giriş yapın.',
        accent: accent,
      );
    }

    final service = StudentAssignmentService();

    return StreamBuilder<List<StudentAssignmentBundle>>(
      stream: service.watchAssignmentsForStudent(user),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return _MessagePage(
            title: 'Hata oluştu',
            message: 'Ödevler yüklenirken hata oluştu.',
            accent: accent,
          );
        }

        final items = snapshot.data ?? [];

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Hero(
                count: items.length,
                className: user.className,
                accent: accent,
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                _MessagePage(
                  title: 'Henüz ödev yok',
                  message: 'Sınıfınıza atanmış aktif ödev bulunmuyor.',
                  accent: accent,
                  embedded: true,
                )
              else
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: _AssignmentCard(
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
  final int count;
  final String className;
  final Color accent;

  const _Hero({
    required this.count,
    required this.className,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedClass = className.trim().isEmpty ? '-' : className;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent,
            AppTheme.cyan,
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
              Icons.assignment_rounded,
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
                  'Ödevlerim',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 25,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$normalizedClass sınıfı için $count ödev listeleniyor.',
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

class _AssignmentCard extends StatelessWidget {
  final StudentAssignmentBundle item;
  final Color accent;

  const _AssignmentCard({
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
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: accent,
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
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              assignment.description,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w700,
                height: 1.45,
                fontSize: 13,
              ),
            ),
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
                text: 'Son: ${_formatDate(assignment.dueDate)}',
                icon: Icons.schedule_rounded,
                color: const Color(0xFFF59E0B),
              ),
              _MiniChip(
                text: assignment.fileType,
                icon: Icons.attach_file_rounded,
                color: const Color(0xFF4F46E5),
              ),
            ],
          ),
          if (submission != null) ...[
            const SizedBox(height: 12),
            _SubmissionInfo(
              score: submission.score,
              feedback: submission.feedback,
              link: submission.link,
              submittedAt: submission.submittedAt,
              evaluated: submission.isEvaluated,
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
                  builder: (_) => _SubmitSheet(
                    assignment: assignment,
                    accent: accent,
                  ),
                );
              },
              icon: Icon(
                submitted ? Icons.edit_document : Icons.upload_file_rounded,
              ),
              label: Text(
                submitted ? 'Teslimi Güncelle' : 'Ödev Teslim Et',
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day.$month.$year $hour:$minute';
  }
}

class _SubmissionInfo extends StatelessWidget {
  final String score;
  final String feedback;
  final String link;
  final DateTime? submittedAt;
  final bool evaluated;

  const _SubmissionInfo({
    required this.score,
    required this.feedback,
    required this.link,
    required this.submittedAt,
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
            evaluated ? 'Değerlendirme' : 'Teslim bilgisi',
            style: TextStyle(
              color:
                  evaluated ? const Color(0xFF047857) : const Color(0xFF92400E),
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Teslim: ${_formatDate(submittedAt)}',
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          if (link.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            SmartLinkText(
              link: link,
              color: const Color(0xFF2563EB),
            ),
          ],
          if (score.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              'Not: $score',
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
          if (feedback.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              'Geri dönüş: $feedback',
              style: const TextStyle(
                color: Color(0xFF334155),
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

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day.$month.$year $hour:$minute';
  }
}

class _SubmitSheet extends StatefulWidget {
  final AssignmentModel assignment;
  final Color accent;

  const _SubmitSheet({
    required this.assignment,
    required this.accent,
  });

  @override
  State<_SubmitSheet> createState() => _SubmitSheetState();
}

class _SubmitSheetState extends State<_SubmitSheet> {
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _answerController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final user = AppSession.currentUser;

    if (user == null) {
      setState(() => _error = 'Oturum bulunamadı.');
      return;
    }

    final answer = _answerController.text.trim();
    final link = _linkController.text.trim();

    if (answer.isEmpty && link.isEmpty) {
      setState(
        () => _error = 'Cevap veya link alanlarından en az biri dolu olmalı.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      await StudentAssignmentService().submitAssignment(
        student: user,
        assignment: widget.assignment,
        answer: answer,
        link: link,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ödev teslim edildi.'),
        ),
      );
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
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(34),
          ),
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
                  color: const Color(0xFFE2E8F0),
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
                    child: Icon(
                      Icons.upload_file_rounded,
                      color: widget.accent,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ödev Teslim Et',
                          style: TextStyle(
                            color: AppTheme.dark,
                            fontWeight: FontWeight.w900,
                            fontSize: 21,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.assignment.title,
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
                controller: _answerController,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Cevap',
                  hintText: 'Ödev cevabınızı yazın',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _linkController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Link',
                  hintText: 'İsteğe bağlı dosya/link adresi',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
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
                          'Teslimi Gönder',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
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

class _MessagePage extends StatelessWidget {
  final String title;
  final String message;
  final Color accent;
  final bool embedded;

  const _MessagePage({
    required this.title,
    required this.message,
    required this.accent,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Icon(
              Icons.inbox_rounded,
              color: accent,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.dark,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 7),
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
      return content;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: content,
      ),
    );
  }
}