import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  void openAddLessonSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LessonFormSheet(),
    );
  }

  void openEditLessonSheet(String id, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LessonFormSheet(
        lessonId: id,
        initialData: data,
      ),
    );
  }

  Future<void> deleteLesson(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ders silinsin mi?'),
          content: const Text('Bu ders silinecek. Bu işlem geri alınamaz.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
              ),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await firestore.collection('lessons').doc(id).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ders silindi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ders silinirken hata oluştu'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double cardWidth;

            if (constraints.maxWidth > 1200) {
              cardWidth = (constraints.maxWidth - 80) / 3;
            } else if (constraints.maxWidth > 700) {
              cardWidth = (constraints.maxWidth - 60) / 2;
            } else {
              cardWidth = constraints.maxWidth;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dersler',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Dersleri sınıf ve öğretmenlerle eşleştirin.',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        onPressed: openAddLessonSheet,
                        icon: const Icon(Icons.add_box_rounded),
                        label: const Text('Ders Oluştur'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  StreamBuilder<QuerySnapshot>(
                    stream: firestore
                        .collection('lessons')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return const _EmptyState(
                          icon: Icons.error_rounded,
                          title: 'Dersler yüklenemedi',
                          description:
                              'Firestore bağlantısında bir sorun oluştu.',
                          color: Color(0xFFEF4444),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const _EmptyState(
                          icon: Icons.menu_book_rounded,
                          title: 'Henüz ders yok',
                          description:
                              'Yeni ders oluşturarak başlayabilirsiniz.',
                          color: Color(0xFF4F46E5),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      return Wrap(
                        spacing: 18,
                        runSpacing: 18,
                        children: [
                          for (final doc in docs)
                            SizedBox(
                              width: cardWidth,
                              child: _LessonCard(
                                id: doc.id,
                                data: doc.data() as Map<String, dynamic>,
                                onEdit: () => openEditLessonSheet(
                                  doc.id,
                                  doc.data() as Map<String, dynamic>,
                                ),
                                onDelete: () => deleteLesson(doc.id),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LessonCard({
    required this.id,
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  Color get color {
    final lessonName = data['name']?.toString().toLowerCase() ?? '';

    if (lessonName.contains('fizik')) return const Color(0xFF06B6D4);
    if (lessonName.contains('edebiyat')) return const Color(0xFFF59E0B);
    if (lessonName.contains('kimya')) return const Color(0xFF10B981);
    if (lessonName.contains('biyoloji')) return const Color(0xFFEF4444);

    return const Color(0xFF4F46E5);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    final name = data['name']?.toString() ?? '-';
    final className = data['className']?.toString() ?? '-';
    final teacherName = data['teacherName']?.toString() ?? 'Atanmadı';
    final teacherBranch = data['teacherBranch']?.toString() ?? 'Branş yok';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                  PopupMenuItem(value: 'delete', child: Text('Sil')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Line(Icons.class_rounded, 'Sınıf: $className'),
          _Line(Icons.person_rounded, 'Öğretmen: $teacherName'),
          _Line(Icons.work_rounded, 'Branş: $teacherBranch'),
          const SizedBox(height: 18),
          if (isMobile)
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Düzenle'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_rounded),
                    label: const Text('Sil'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Düzenle'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_rounded),
                      label: const Text('Sil'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LessonFormSheet extends StatefulWidget {
  final String? lessonId;
  final Map<String, dynamic>? initialData;

  const _LessonFormSheet({
    this.lessonId,
    this.initialData,
  });

  @override
  State<_LessonFormSheet> createState() => _LessonFormSheetState();
}

class _LessonFormSheetState extends State<_LessonFormSheet> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final TextEditingController customLessonController = TextEditingController();

  String lesson = 'Matematik';
  String? selectedClassName;

  String? selectedTeacherId;
  String? selectedTeacherName;
  String? selectedTeacherBranch;

  bool isSaving = false;

  bool get isEdit => widget.lessonId != null;

  final lessonOptions = const [
    'Matematik',
    'Fizik',
    'Kimya',
    'Biyoloji',
    'Edebiyat',
    'Tarih',
    'Coğrafya',
    'İngilizce',
    'Din Kültürü',
    'Beden Eğitimi',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();

    final data = widget.initialData;
    final lessonName = data?['name']?.toString() ?? 'Matematik';

    if (lessonOptions.contains(lessonName)) {
      lesson = lessonName;
    } else {
      lesson = 'Diğer';
      customLessonController.text = lessonName;
    }

    selectedClassName = data?['className']?.toString().isNotEmpty == true
        ? data!['className'].toString()
        : null;

    selectedTeacherId = data?['teacherId']?.toString().isNotEmpty == true
        ? data!['teacherId'].toString()
        : null;

    selectedTeacherName = data?['teacherName']?.toString().isNotEmpty == true
        ? data!['teacherName'].toString()
        : null;

    selectedTeacherBranch =
        data?['teacherBranch']?.toString().isNotEmpty == true
            ? data!['teacherBranch'].toString()
            : null;
  }

  @override
  void dispose() {
    customLessonController.dispose();
    super.dispose();
  }

  Future<void> saveLesson() async {
    if (isSaving) return;

    final selectedLesson =
        lesson == 'Diğer' ? customLessonController.text.trim() : lesson;

    if (selectedLesson.isEmpty) {
      showMessage('Ders adı boş bırakılamaz.', isError: true);
      return;
    }

    if (selectedClassName == null || selectedClassName!.isEmpty) {
      showMessage('Sınıf seçmelisiniz.', isError: true);
      return;
    }

    if (selectedTeacherId == null ||
        selectedTeacherName == null ||
        selectedTeacherName!.isEmpty) {
      showMessage('Öğretmen seçmelisiniz.', isError: true);
      return;
    }

    setState(() => isSaving = true);

    try {
      final payload = {
        'name': selectedLesson,
        'className': selectedClassName,
        'teacherId': selectedTeacherId,
        'teacherName': selectedTeacherName,
        'teacherBranch': selectedTeacherBranch ?? 'Branş yok',
        'updatedAt': Timestamp.now(),
      };

      if (isEdit) {
        await firestore.collection('lessons').doc(widget.lessonId).update(payload);
      } else {
        await firestore.collection('lessons').add({
          ...payload,
          'createdAt': Timestamp.now(),
        });
      }

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'Ders güncellendi' : 'Ders Firebase’e kaydedildi',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      showMessage(
        isEdit
            ? 'Ders güncellenirken hata oluştu.'
            : 'Ders kaydedilirken hata oluştu.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFEF4444) : null,
      ),
    );
  }

  String teacherBranchFromData(Map<String, dynamic> data) {
    final branch = data['branch']?.toString() ??
        data['teacherBranch']?.toString() ??
        data['subject']?.toString() ??
        data['detail']?.toString() ??
        '';

    if (branch.trim().isEmpty) return 'Branş yok';
    return branch.trim();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFFF6F7FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Dersi Düzenle' : 'Yeni Ders Oluştur',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: lesson,
                    decoration: _input('Ders', Icons.menu_book_rounded),
                    items: [
                      for (final item in lessonOptions)
                        DropdownMenuItem(value: item, child: Text(item)),
                    ],
                    onChanged: (v) {
                      setState(() {
                        lesson = v ?? 'Matematik';
                      });
                    },
                  ),
                  if (lesson == 'Diğer') ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: customLessonController,
                      decoration: _input(
                        'Ders Adı',
                        Icons.edit_note_rounded,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  StreamBuilder<QuerySnapshot>(
                    stream: firestore
                        .collection('classes')
                        .orderBy('grade')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(14),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return const _WarningBox(
                          text: 'Sınıflar yüklenemedi.',
                          backgroundColor: Color(0xFFFEE2E2),
                          textColor: Color(0xFF991B1B),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return const _WarningBox(
                          text: 'Önce Sınıflar ekranından sınıf eklemelisiniz.',
                          backgroundColor: Color(0xFFFFF7ED),
                          textColor: Color(0xFF9A3412),
                        );
                      }

                      final classNames = docs
                          .map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return data['name']?.toString() ?? '';
                          })
                          .where((name) => name.isNotEmpty)
                          .toSet()
                          .toList();

                      classNames.sort();

                      final dropdownValue =
                          classNames.contains(selectedClassName)
                              ? selectedClassName
                              : null;

                      return DropdownButtonFormField<String>(
                        value: dropdownValue,
                        decoration: _input('Sınıf', Icons.class_rounded),
                        items: [
                          for (final item in classNames)
                            DropdownMenuItem(value: item, child: Text(item)),
                        ],
                        onChanged: (v) {
                          setState(() {
                            selectedClassName = v;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  StreamBuilder<QuerySnapshot>(
                    stream: firestore
                        .collection('users')
                        .where('role', isEqualTo: 'Öğretmen')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(14),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return const _WarningBox(
                          text: 'Öğretmenler yüklenemedi.',
                          backgroundColor: Color(0xFFFEE2E2),
                          textColor: Color(0xFF991B1B),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return const _WarningBox(
                          text:
                              'Önce Kullanıcılar ekranından öğretmen eklemelisiniz.',
                          backgroundColor: Color(0xFFFFF7ED),
                          textColor: Color(0xFF9A3412),
                        );
                      }

                      final validTeacherIds = docs.map((doc) => doc.id).toList();

                      final dropdownValue =
                          validTeacherIds.contains(selectedTeacherId)
                              ? selectedTeacherId
                              : null;

                      return DropdownButtonFormField<String>(
                        value: dropdownValue,
                        decoration: _input(
                          'Öğretmen Seç',
                          Icons.person_rounded,
                        ),
                        items: [
                          for (final doc in docs)
                            DropdownMenuItem(
                              value: doc.id,
                              child: Builder(
                                builder: (context) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final name =
                                      data['name']?.toString() ?? 'İsimsiz';
                                  final branch = teacherBranchFromData(data);

                                  return Text(
                                    '$name • $branch',
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ),
                        ],
                        onChanged: (teacherId) {
                          if (teacherId == null) return;

                          final teacherDoc = docs.firstWhere(
                            (doc) => doc.id == teacherId,
                          );

                          final data =
                              teacherDoc.data() as Map<String, dynamic>;

                          setState(() {
                            selectedTeacherId = teacherDoc.id;
                            selectedTeacherName =
                                data['name']?.toString() ?? 'İsimsiz';
                            selectedTeacherBranch = teacherBranchFromData(data);
                          });
                        },
                      );
                    },
                  ),
                  if (selectedTeacherName != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'Seçilen öğretmen: $selectedTeacherName • ${selectedTeacherBranch ?? 'Branş yok'}',
                        style: const TextStyle(
                          color: Color(0xFF4338CA),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: isSaving ? null : saveLesson,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        isSaving
                            ? 'Kaydediliyor...'
                            : isEdit
                                ? 'Değişiklikleri Kaydet'
                                : 'Dersi Kaydet',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _WarningBox extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const _WarningBox({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Line(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(icon, size: 19, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(28),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ],
  );
}