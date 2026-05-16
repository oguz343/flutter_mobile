import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/app_user.dart';
import '../../models/lesson_model.dart';
import '../../services/admin_school_service.dart';
import '../../services/admin_service.dart';

class AdminClassesLessonsPage extends StatelessWidget {
  final Color accent;

  const AdminClassesLessonsPage({super.key, required this.accent});

  @override
  Widget build(BuildContext context) {
    final service = AdminSchoolService();

    return StreamBuilder<AdminSchoolData>(
      stream: service.watchSchoolData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _MessageCard(
            title: 'Hata oluştu',
            message: 'Sınıf ve ders bilgileri yüklenirken hata oluştu.',
            accent: accent,
          );
        }

        final data =
            snapshot.data ??
            const AdminSchoolData(
              classes: [],
              lessons: [],
              teachers: [],
              announcements: [],
            );

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            children: [
              _Hero(
                accent: accent,
                classCount: data.classes.length,
                lessonCount: data.lessons.length,
                onAddClass: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) =>
                        _ClassSheet(accent: accent, teachers: data.teachers),
                  );
                },
                onAddLesson: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _LessonSheet(
                      accent: accent,
                      classes: data.classes,
                      teachers: data.teachers,
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              _SectionTitle(
                title: 'Sınıflar',
                subtitle: 'Tanımlı sınıflar ve sınıf öğretmenleri',
              ),
              const SizedBox(height: 10),
              if (data.classes.isEmpty)
                _MessageCard(
                  title: 'Sınıf yok',
                  message: 'Yeni sınıf ekleyerek başlayın.',
                  accent: accent,
                  embedded: true,
                )
              else
                ...data.classes.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ClassCard(
                      item: item,
                      accent: accent,
                      onEdit: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _ClassSheet(
                            accent: accent,
                            teachers: data.teachers,
                            schoolClass: item,
                          ),
                        );
                      },
                      onDelete: () => _confirmDeleteClass(
                        context: context,
                        item: item,
                        service: service,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              _SectionTitle(
                title: 'Dersler',
                subtitle: 'Sınıf, ders ve öğretmen eşleştirmeleri',
              ),
              const SizedBox(height: 10),
              if (data.lessons.isEmpty)
                _MessageCard(
                  title: 'Ders yok',
                  message: 'Yeni ders ekleyerek başlayın.',
                  accent: accent,
                  embedded: true,
                )
              else
                ...data.lessons.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LessonCard(
                      item: item,
                      accent: accent,
                      onEdit: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _LessonSheet(
                            accent: accent,
                            classes: data.classes,
                            teachers: data.teachers,
                            lesson: item,
                          ),
                        );
                      },
                      onDelete: () => _confirmDeleteLesson(
                        context: context,
                        item: item,
                        service: service,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteClass({
    required BuildContext context,
    required SchoolClassModel item,
    required AdminSchoolService service,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sınıf silinsin mi?'),
          content: Text('${item.name} sınıfı pasif hale getirilecek.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (ok != true) {
      return;
    }

    await service.deleteClass(item);
  }

  Future<void> _confirmDeleteLesson({
    required BuildContext context,
    required LessonModel item,
    required AdminSchoolService service,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ders silinsin mi?'),
          content: Text('${item.name} dersi pasif hale getirilecek.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (ok != true) {
      return;
    }

    await service.deleteLesson(item);
  }
}

class _Hero extends StatelessWidget {
  final Color accent;
  final int classCount;
  final int lessonCount;
  final VoidCallback onAddClass;
  final VoidCallback onAddLesson;

  const _Hero({
    required this.accent,
    required this.classCount,
    required this.lessonCount,
    required this.onAddClass,
    required this.onAddLesson,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, const Color(0xFF06B6D4)],
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(23),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
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
                      'Sınıflar ve Dersler',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$classCount sınıf • $lessonCount ders tanımlı.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
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
          if (compact)
            Column(
              children: [
                _HeroButton(
                  icon: Icons.add_home_work_rounded,
                  label: 'Sınıf Ekle',
                  onTap: onAddClass,
                  accent: accent,
                ),
                const SizedBox(height: 10),
                _HeroButton(
                  icon: Icons.add_task_rounded,
                  label: 'Ders Ekle',
                  onTap: onAddLesson,
                  accent: accent,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _HeroButton(
                    icon: Icons.add_home_work_rounded,
                    label: 'Sınıf Ekle',
                    onTap: onAddClass,
                    accent: accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeroButton(
                    icon: Icons.add_task_rounded,
                    label: 'Ders Ekle',
                    onTap: onAddLesson,
                    accent: accent,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color accent;

  const _HeroButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: accent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final SchoolClassModel item;
  final Color accent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClassCard({
    required this.item,
    required this.accent,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final teacher = item.teacherName.trim().isEmpty ? '-' : item.teacherName;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.line),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.apartment_rounded, color: accent),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: AppTheme.dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sınıf öğretmeni: $teacher',
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: Icon(Icons.edit_rounded, color: accent),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final LessonModel item;
  final Color accent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LessonCard({
    required this.item,
    required this.accent,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final teacher = item.teacherName.trim().isEmpty ? '-' : item.teacherName;
    final branch = item.branch.trim().isEmpty ? '-' : item.branch;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.line),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFF06B6D4),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: AppTheme.dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.className} • $teacher • $branch',
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: Icon(Icons.edit_rounded, color: accent),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }
}

class _ClassSheet extends StatefulWidget {
  final Color accent;
  final List<AppUser> teachers;
  final SchoolClassModel? schoolClass;

  const _ClassSheet({
    required this.accent,
    required this.teachers,
    this.schoolClass,
  });

  @override
  State<_ClassSheet> createState() => _ClassSheetState();
}

class _ClassSheetState extends State<_ClassSheet> {
  final AdminSchoolService _service = AdminSchoolService();

  late String _className;
  AppUser? _teacher;
  bool _loading = false;
  String _error = '';

  bool get editing => widget.schoolClass != null;

  @override
  void initState() {
    super.initState();

    _className = widget.schoolClass?.name ?? '9-A';

    final teacherNo = widget.schoolClass?.teacherNo ?? '';

    if (teacherNo.isNotEmpty) {
      for (final teacher in widget.teachers) {
        if (teacher.number == teacherNo) {
          _teacher = teacher;
          break;
        }
      }
    }
  }

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      if (editing) {
        await _service.updateClass(
          schoolClass: widget.schoolClass!,
          className: _className,
          classTeacher: _teacher,
        );
      } else {
        await _service.createClass(
          className: _className,
          classTeacher: _teacher,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(editing ? 'Sınıf güncellendi.' : 'Sınıf eklendi.'),
        ),
      );
    } on AdminSchoolException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'İşlem sırasında hata oluştu.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = <String>[
      for (final grade in ['9', '10', '11', '12'])
        for (final section in ['A', 'B', 'C', 'D', 'E', 'F']) '$grade-$section',
    ];

    final value = classes.contains(_className) ? _className : classes.first;

    return _BottomSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetTitle(
            accent: widget.accent,
            icon: Icons.apartment_rounded,
            title: editing ? 'Sınıf Düzenle' : 'Yeni Sınıf Ekle',
          ),
          const SizedBox(height: 16),
          if (_error.isNotEmpty) ...[
            _ErrorBox(text: _error),
            const SizedBox(height: 12),
          ],
          DropdownButtonFormField<String>(
            initialValue: value,
            items: classes
                .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _className = value);
              }
            },
            decoration: const InputDecoration(
              labelText: 'Sınıf',
              prefixIcon: Icon(Icons.apartment_rounded),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AppUser?>(
            initialValue: _teacher,
            items: [
              const DropdownMenuItem<AppUser?>(
                value: null,
                child: Text('Sınıf öğretmeni yok'),
              ),
              ...widget.teachers.map(
                (teacher) => DropdownMenuItem<AppUser?>(
                  value: teacher,
                  child: Text('${teacher.name} • ${teacher.branch}'),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => _teacher = value);
            },
            decoration: const InputDecoration(
              labelText: 'Sınıf Öğretmeni',
              prefixIcon: Icon(Icons.co_present_rounded),
            ),
          ),
          const SizedBox(height: 16),
          _SaveButton(
            accent: widget.accent,
            loading: _loading,
            text: editing ? 'Kaydet' : 'Sınıf Ekle',
            onTap: _save,
          ),
        ],
      ),
    );
  }
}

class _LessonSheet extends StatefulWidget {
  final Color accent;
  final List<SchoolClassModel> classes;
  final List<AppUser> teachers;
  final LessonModel? lesson;

  const _LessonSheet({
    required this.accent,
    required this.classes,
    required this.teachers,
    this.lesson,
  });

  @override
  State<_LessonSheet> createState() => _LessonSheetState();
}

class _LessonSheetState extends State<_LessonSheet> {
  final AdminSchoolService _service = AdminSchoolService();
  final TextEditingController _lessonController = TextEditingController();

  String _className = '9-A';
  final List<String> _selectedClassNames = [];
  AppUser? _teacher;
  bool _loading = false;
  String _error = '';

  bool get editing => widget.lesson != null;

  @override
  void initState() {
    super.initState();

    final lesson = widget.lesson;

    if (lesson != null) {
      _lessonController.text = lesson.name;
      _className = lesson.className;
      _selectedClassNames
        ..clear()
        ..add(lesson.className);

      for (final teacher in widget.teachers) {
        if (teacher.number == lesson.teacherNo) {
          _teacher = teacher;
          break;
        }
      }
    } else if (widget.classes.isNotEmpty) {
      _className = widget.classes.first.name;
      _selectedClassNames
        ..clear()
        ..add(widget.classes.first.name);
    } else {
      _selectedClassNames
        ..clear()
        ..add(_className);
    }
  }

  @override
  void dispose() {
    _lessonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      if (editing) {
        await _service.updateLesson(
          lesson: widget.lesson!,
          lessonName: _lessonController.text,
          className: _className,
          teacher: _teacher,
        );
      } else {
        final result = await _service.createLesson(
          lessonName: _lessonController.text,
          className: _selectedClassNames.isEmpty
              ? ''
              : _selectedClassNames.first,
          classNames: _selectedClassNames,
          teacher: _teacher,
        );

        if (!mounted) {
          return;
        }

        Navigator.of(context).pop();

        final message = result.hasSkipped
            ? 'Bazı ders atamaları zaten mevcut olduğu için atlandı.'
            : result.createdCount == 1
            ? 'Ders eklendi.'
            : '${result.createdCount} ders ataması eklendi.';

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        return;
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(editing ? 'Ders güncellendi.' : 'Ders eklendi.'),
        ),
      );
    } on AdminSchoolException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'İşlem sırasında hata oluştu.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openClassPicker(List<String> classOptions) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final selected = _selectedClassNames.toSet();

        return _BottomSheetFrame(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SheetTitle(
                    accent: widget.accent,
                    icon: Icons.apartment_rounded,
                    title: 'Sınıf Seçimi',
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: classOptions.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final className = classOptions[index];
                        final checked = selected.contains(className);

                        return CheckboxListTile(
                          value: checked,
                          contentPadding: EdgeInsets.zero,
                          activeColor: widget.accent,
                          title: Text(className),
                          onChanged: (value) {
                            setModalState(() {
                              if (value ?? false) {
                                selected.add(className);
                              } else {
                                selected.remove(className);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SaveButton(
                    accent: widget.accent,
                    loading: false,
                    text: 'Seçimi Kaydet',
                    onTap: () {
                      Navigator.of(context).pop(selected.toList());
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _selectedClassNames
        ..clear()
        ..addAll(result);

      if (_selectedClassNames.isNotEmpty) {
        _className = _selectedClassNames.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final classOptions = widget.classes.isEmpty
        ? <String>[
            for (final grade in ['9', '10', '11', '12'])
              for (final section in ['A', 'B', 'C', 'D', 'E', 'F'])
                '$grade-$section',
          ]
        : widget.classes.map((x) => x.name).toList();

    final classValue = classOptions.contains(_className)
        ? _className
        : classOptions.first;
    final selectedClasses = _selectedClassNames
        .where((className) => classOptions.contains(className))
        .toList();

    return _BottomSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetTitle(
            accent: widget.accent,
            icon: Icons.menu_book_rounded,
            title: editing ? 'Ders Düzenle' : 'Yeni Ders Ekle',
          ),
          const SizedBox(height: 16),
          if (_error.isNotEmpty) ...[
            _ErrorBox(text: _error),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _lessonController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Ders Adı',
              hintText: 'Örn: Matematik',
              prefixIcon: Icon(Icons.title_rounded),
            ),
          ),
          const SizedBox(height: 12),
          if (editing)
            DropdownButtonFormField<String>(
              initialValue: classValue,
              items: classOptions
                  .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _className = value;
                    _selectedClassNames
                      ..clear()
                      ..add(value);
                  });
                }
              },
              decoration: const InputDecoration(
                labelText: 'Sınıf',
                prefixIcon: Icon(Icons.apartment_rounded),
              ),
            )
          else
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openClassPicker(classOptions),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Sınıflar',
                  prefixIcon: Icon(Icons.apartment_rounded),
                  suffixIcon: Icon(Icons.keyboard_arrow_down_rounded),
                ),
                child: selectedClasses.isEmpty
                    ? const Text('En az bir sınıf seçin')
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedClasses
                            .map(
                              (className) => Chip(
                                label: Text(className),
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                            .toList(),
                      ),
              ),
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AppUser?>(
            initialValue: _teacher,
            items: widget.teachers
                .map(
                  (teacher) => DropdownMenuItem<AppUser?>(
                    value: teacher,
                    child: Text('${teacher.name} • ${teacher.branch}'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() => _teacher = value);
            },
            decoration: const InputDecoration(
              labelText: 'Öğretmen',
              prefixIcon: Icon(Icons.co_present_rounded),
            ),
          ),
          const SizedBox(height: 16),
          _SaveButton(
            accent: widget.accent,
            loading: _loading,
            text: editing ? 'Kaydet' : 'Ders Ekle',
            onTap: _save,
          ),
        ],
      ),
    );
  }
}

class _BottomSheetFrame extends StatelessWidget {
  final Widget child;

  const _BottomSheetFrame({required this.child});

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
          child: child,
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String title;

  const _SheetTitle({
    required this.accent,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(19),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppTheme.dark,
                  fontWeight: FontWeight.w900,
                  fontSize: 21,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  final Color accent;
  final bool loading;
  final String text;
  final VoidCallback onTap;

  const _SaveButton({
    required this.accent,
    required this.loading,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(19),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 23,
                height: 23,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String text;

  const _ErrorBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF991B1B),
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
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
    return Column(
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
      child: Padding(padding: const EdgeInsets.all(18), child: card),
    );
  }
}
