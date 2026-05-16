import 'package:flutter/material.dart';

import '../../core/app_helpers.dart';
import '../../core/app_session.dart';
import '../../core/app_theme.dart';
import '../../models/lesson_model.dart';
import '../../services/teacher_service.dart';

class TeacherAssignmentsPage extends StatelessWidget {
  final Color accent;

  const TeacherAssignmentsPage({super.key, required this.accent});

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
            message: 'Ödevler yüklenirken hata oluştu.',
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
                count: data.assignments.length,
                accent: accent,
                canCreate: data.lessons.isNotEmpty,
                onCreate: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _CreateAssignmentSheet(
                      accent: accent,
                      lessons: data.lessons,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              if (data.lessons.isEmpty)
                _MessageCard(
                  title: 'Size atanmış ders bulunmuyor.',
                  message:
                      'Ödev oluşturmak için önce admin tarafından size ders atanmalı.',
                  accent: accent,
                  embedded: true,
                )
              else if (data.assignments.isEmpty)
                _MessageCard(
                  title: 'Henüz ödev oluşturmadınız.',
                  message:
                      'Yeni ödev oluştur butonuyla ilk ödevi ekleyebilirsiniz.',
                  accent: accent,
                  embedded: true,
                )
              else
                ...data.assignments.map(
                  (assignment) => Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: _AssignmentCard(
                      title: assignment.title,
                      description: assignment.description,
                      lesson: assignment.lessonName,
                      className: assignment.className,
                      dueDate: assignment.dueDate,
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
  final Color accent;
  final bool canCreate;
  final VoidCallback onCreate;

  const _Hero({
    required this.count,
    required this.accent,
    required this.canCreate,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, AppTheme.cyan, AppTheme.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
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
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$count ödev listeleniyor.',
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
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: canCreate ? onCreate : null,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                canCreate ? 'Yeni Ödev Oluştur' : 'Ders Ataması Bekleniyor',
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: accent,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.38),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.84),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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

class _AssignmentCard extends StatelessWidget {
  final String title;
  final String description;
  final String lesson;
  final String className;
  final DateTime? dueDate;
  final Color accent;

  const _AssignmentCard({
    required this.title,
    required this.description,
    required this.lesson,
    required this.className,
    required this.dueDate,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.line),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.dark,
              fontWeight: FontWeight.w900,
              fontSize: 17,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description.trim().isEmpty ? '-' : description,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w700,
              height: 1.45,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniChip(
                text: lesson,
                icon: Icons.menu_book_rounded,
                color: accent,
              ),
              _MiniChip(
                text: className,
                icon: Icons.apartment_rounded,
                color: const Color(0xFF4F46E5),
              ),
              _MiniChip(
                text: 'Son: ${AppHelpers.formatDate(dueDate)}',
                icon: Icons.schedule_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateAssignmentSheet extends StatefulWidget {
  final Color accent;
  final List<LessonModel> lessons;

  const _CreateAssignmentSheet({required this.accent, required this.lessons});

  @override
  State<_CreateAssignmentSheet> createState() => _CreateAssignmentSheetState();
}

class _CreateAssignmentSheetState extends State<_CreateAssignmentSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final Set<String> _selectedLessonIds = <String>{};
  DateTime? _dueDate;
  String _fileType = 'Metin / Link';
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();

    if (widget.lessons.isNotEmpty) {
      _selectedLessonIds.add(widget.lessons.first.id);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 59),
    );

    if (time == null) {
      setState(() {
        _dueDate = DateTime(date.year, date.month, date.day, 23, 59);
      });
      return;
    }

    setState(() {
      _dueDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final teacher = AppSession.currentUser;

    if (teacher == null) {
      setState(() => _error = 'Oturum bulunamadı.');
      return;
    }

    if (_selectedLessonIds.isEmpty) {
      setState(() => _error = 'En az bir ders ataması seçmelisiniz.');
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'Ödev başlığı boş bırakılamaz.');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      await TeacherService().createHomeworkForLessonAssignments(
        teacher: teacher,
        selectedLessonIds: _selectedLessonIds.toList(),
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: _dueDate,
        fileType: _fileType,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ödev oluşturuldu.')));
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                    child: Icon(Icons.add_task_rounded, color: widget.accent),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Text(
                      'Yeni Ödev Oluştur',
                      style: TextStyle(
                        color: AppTheme.dark,
                        fontWeight: FontWeight.w900,
                        fontSize: 21,
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
                    border: Border.all(color: Color(0xFFFECACA)),
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
              _LessonMultiSelect(
                lessons: widget.lessons,
                selectedLessonIds: _selectedLessonIds,
                accent: widget.accent,
                onChanged: (lessonId, selected) {
                  setState(() {
                    if (selected) {
                      _selectedLessonIds.add(lessonId);
                    } else {
                      _selectedLessonIds.remove(lessonId);
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Ödev Başlığı',
                  hintText: 'Örn: Fonksiyonlar çalışma kağıdı',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Ödev açıklamasını yazın',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _fileType,
                items: const [
                  DropdownMenuItem(
                    value: 'Metin / Link',
                    child: Text('Metin / Link'),
                  ),
                  DropdownMenuItem(
                    value: 'PDF / Dosya',
                    child: Text('PDF / Dosya'),
                  ),
                  DropdownMenuItem(
                    value: 'Serbest Teslim',
                    child: Text('Serbest Teslim'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _fileType = value ?? 'Metin / Link');
                },
                decoration: const InputDecoration(
                  labelText: 'Teslim Türü',
                  prefixIcon: Icon(Icons.attach_file_rounded),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Son Teslim Tarihi',
                    prefixIcon: Icon(Icons.schedule_rounded),
                  ),
                  child: Text(
                    _dueDate == null
                        ? 'Tarih seçilmedi'
                        : AppHelpers.formatDate(_dueDate),
                    style: const TextStyle(
                      color: AppTheme.dark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
                          'Ödevi Oluştur',
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

class _LessonMultiSelect extends StatelessWidget {
  final List<LessonModel> lessons;
  final Set<String> selectedLessonIds;
  final Color accent;
  final void Function(String lessonId, bool selected) onChanged;

  const _LessonMultiSelect({
    required this.lessons,
    required this.selectedLessonIds,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Ders/Sınıf Seç',
        prefixIcon: Icon(Icons.menu_book_rounded),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bu ödev seçilen her sınıf için ayrı oluşturulacak.',
            style: TextStyle(
              color: AppTheme.muted,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          if (lessons.isEmpty)
            const Text(
              'Size atanmış ders bulunmuyor.',
              style: TextStyle(
                color: AppTheme.muted,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            ...lessons.map((lesson) {
              final selected = selectedLessonIds.contains(lesson.id);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onChanged(lesson.id, !selected),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected
                          ? accent.withValues(alpha: 0.10)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected ? accent : AppTheme.line,
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: selected,
                          activeColor: accent,
                          onChanged: (value) {
                            onChanged(lesson.id, value ?? false);
                          },
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson.displayLessonName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.dark,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Sınıf: ${lesson.displayClassName} • Branş: ${lesson.displayBranch}',
                                maxLines: 2,
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
                  ),
                ),
              );
            }),
          const SizedBox(height: 2),
          Text(
            'Seçilen ders atamaları: ${selectedLessonIds.length}',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(22),
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
