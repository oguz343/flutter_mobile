import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  void openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AssignmentFormSheet(),
    );
  }

  void openEditSheet(String id, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignmentFormSheet(
        assignmentId: id,
        initialData: data,
      ),
    );
  }

  Future<void> deleteAssignment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ödev silinsin mi?'),
          content: const Text('Bu ödev silinecek. Bu işlem geri alınamaz.'),
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
      await firestore.collection('assignments').doc(id).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ödev silindi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ödev silinirken hata oluştu'),
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
                            'Ödevler',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Öğrencilere verilen ödevleri yönetin.',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        onPressed: openAddSheet,
                        icon: const Icon(Icons.add_task_rounded),
                        label: const Text('Ödev Oluştur'),
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
                        .collection('assignments')
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
                          title: 'Ödevler yüklenemedi',
                          description:
                              'Firestore bağlantısında bir sorun oluştu.',
                          color: Color(0xFFEF4444),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const _EmptyState(
                          icon: Icons.assignment_rounded,
                          title: 'Henüz ödev yok',
                          description:
                              'Yeni ödev oluşturarak başlayabilirsiniz.',
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
                              child: _AssignmentCard(
                                id: doc.id,
                                data: doc.data() as Map<String, dynamic>,
                                onEdit: () => openEditSheet(
                                  doc.id,
                                  doc.data() as Map<String, dynamic>,
                                ),
                                onDelete: () => deleteAssignment(doc.id),
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

class _AssignmentCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AssignmentCard({
    required this.id,
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  Color get color {
    final lesson = data['lesson']?.toString().toLowerCase() ?? '';

    if (lesson.contains('fizik')) return const Color(0xFF06B6D4);
    if (lesson.contains('edebiyat')) return const Color(0xFFF59E0B);
    if (lesson.contains('kimya')) return const Color(0xFF10B981);
    if (lesson.contains('biyoloji')) return const Color(0xFFEF4444);

    return const Color(0xFF4F46E5);
  }

  Color get statusColor {
    final status = data['status']?.toString() ?? '';

    if (status == 'Aktif') return const Color(0xFF10B981);
    if (status == 'Pasif') return const Color(0xFFEF4444);

    return const Color(0xFFF59E0B);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    final title = data['title']?.toString() ?? '-';
    final lesson = data['lesson']?.toString() ?? '-';
    final className = data['className']?.toString() ?? '-';
    final teacher = data['teacher']?.toString() ?? 'Atanmadı';
    final teacherBranch = data['teacherBranch']?.toString() ?? 'Branş yok';
    final dueDate = data['dueDate']?.toString() ?? '-';
    final type = data['type']?.toString() ?? 'Metin';
    final status = data['status']?.toString() ?? 'Aktif';

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
                  Icons.assignment_rounded,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
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
          _Line(Icons.menu_book_rounded, 'Ders: $lesson'),
          _Line(Icons.class_rounded, 'Sınıf: $className'),
          _Line(Icons.person_rounded, 'Öğretmen: $teacher'),
          _Line(Icons.work_rounded, 'Branş: $teacherBranch'),
          _Line(Icons.calendar_month_rounded, 'Son Tarih: $dueDate'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Badge(text: type, color: color),
              _Badge(text: status, color: statusColor),
            ],
          ),
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

class _AssignmentFormSheet extends StatefulWidget {
  final String? assignmentId;
  final Map<String, dynamic>? initialData;

  const _AssignmentFormSheet({
    this.assignmentId,
    this.initialData,
  });

  @override
  State<_AssignmentFormSheet> createState() => _AssignmentFormSheetState();
}

class _AssignmentFormSheetState extends State<_AssignmentFormSheet> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  late TextEditingController titleController;
  late TextEditingController dueDateController;
  late TextEditingController descriptionController;

  String? selectedClassName;

  String? selectedLessonId;
  String? selectedLessonName;

  String? selectedTeacherId;
  String? selectedTeacherName;
  String? selectedTeacherBranch;

  String type = 'Metin';
  String status = 'Aktif';
  bool isSaving = false;

  bool get isEdit => widget.assignmentId != null;

  final typeOptions = const [
    'Metin',
    'Dosya',
    'Link',
    'PDF',
    'PPTX',
  ];

  final statusOptions = const [
    'Aktif',
    'Teslim Bekliyor',
    'Pasif',
  ];

  @override
  void initState() {
    super.initState();

    final data = widget.initialData;

    titleController = TextEditingController(
      text: data?['title']?.toString() ?? '',
    );

    dueDateController = TextEditingController(
      text: data?['dueDate']?.toString() ?? '',
    );

    descriptionController = TextEditingController(
      text: data?['description']?.toString() ?? '',
    );

    selectedClassName = data?['className']?.toString().isNotEmpty == true
        ? data!['className'].toString()
        : null;

    selectedLessonId = data?['lessonId']?.toString().isNotEmpty == true
        ? data!['lessonId'].toString()
        : null;

    selectedLessonName = data?['lesson']?.toString().isNotEmpty == true
        ? data!['lesson'].toString()
        : null;

    selectedTeacherId = data?['teacherId']?.toString().isNotEmpty == true
        ? data!['teacherId'].toString()
        : null;

    selectedTeacherName = data?['teacher']?.toString().isNotEmpty == true
        ? data!['teacher'].toString()
        : null;

    selectedTeacherBranch =
        data?['teacherBranch']?.toString().isNotEmpty == true
            ? data!['teacherBranch'].toString()
            : null;

    final typeValue = data?['type']?.toString();
    if (typeValue != null && typeOptions.contains(typeValue)) {
      type = typeValue;
    }

    final statusValue = data?['status']?.toString();
    if (statusValue != null && statusOptions.contains(statusValue)) {
      status = statusValue;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    dueDateController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  String teacherBranchFromData(Map<String, dynamic> data) {
    final branch = data['branch']?.toString() ??
        data['teacherBranch']?.toString() ??
        data['subject']?.toString() ??
        '';

    if (branch.trim().isEmpty) return 'Branş yok';
    return branch.trim();
  }

  Future<void> saveAssignment() async {
    if (isSaving) return;

    final title = titleController.text.trim();
    final dueDate = dueDateController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty) {
      showMessage('Ödev başlığı boş bırakılamaz.', isError: true);
      return;
    }

    if (selectedClassName == null || selectedClassName!.isEmpty) {
      showMessage('Sınıf seçmelisiniz.', isError: true);
      return;
    }

    if (selectedLessonId == null ||
        selectedLessonName == null ||
        selectedLessonName!.isEmpty) {
      showMessage('Ders seçmelisiniz.', isError: true);
      return;
    }

    if (selectedTeacherId == null ||
        selectedTeacherName == null ||
        selectedTeacherName!.isEmpty) {
      showMessage('Öğretmen seçmelisiniz.', isError: true);
      return;
    }

    if (dueDate.isEmpty) {
      showMessage('Son teslim tarihi boş bırakılamaz.', isError: true);
      return;
    }

    setState(() => isSaving = true);

    try {
      final payload = {
        'title': title,
        'lessonId': selectedLessonId,
        'lesson': selectedLessonName,
        'className': selectedClassName,
        'teacherId': selectedTeacherId,
        'teacher': selectedTeacherName,
        'teacherBranch': selectedTeacherBranch ?? 'Branş yok',
        'dueDate': dueDate,
        'type': type,
        'status': status,
        'description': description,
        'updatedAt': Timestamp.now(),
      };

      if (isEdit) {
        await firestore
            .collection('assignments')
            .doc(widget.assignmentId)
            .update(payload);
      } else {
        await firestore.collection('assignments').add({
          ...payload,
          'createdAt': Timestamp.now(),
        });
      }

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'Ödev güncellendi' : 'Ödev Firebase’e kaydedildi',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      showMessage(
        isEdit
            ? 'Ödev güncellenirken hata oluştu.'
            : 'Ödev kaydedilirken hata oluştu.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> pickDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: now,
    );

    if (selected == null) return;

    final text =
        '${selected.day.toString().padLeft(2, '0')}.${selected.month.toString().padLeft(2, '0')}.${selected.year}';

    setState(() {
      dueDateController.text = text;
    });
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
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Ödevi Düzenle' : 'Yeni Ödev Oluştur',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: titleController,
                    decoration: _input('Ödev Başlığı', Icons.title_rounded),
                  ),
                  const SizedBox(height: 14),

                  // SINIF SEÇ
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
                            DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            selectedClassName = v;
                            selectedLessonId = null;
                            selectedLessonName = null;
                          });
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // DERS SEÇ
                  if (selectedClassName == null)
                    const _WarningBox(
                      text: 'Dersleri görmek için önce sınıf seçmelisiniz.',
                      backgroundColor: Color(0xFFFFF7ED),
                      textColor: Color(0xFF9A3412),
                    )
                  else
                    StreamBuilder<QuerySnapshot>(
                      stream: firestore
                          .collection('lessons')
                          .where('className', isEqualTo: selectedClassName)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(14),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (snapshot.hasError) {
                          return const _WarningBox(
                            text: 'Dersler yüklenemedi.',
                            backgroundColor: Color(0xFFFEE2E2),
                            textColor: Color(0xFF991B1B),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return const _WarningBox(
                            text:
                                'Bu sınıfa ait ders yok. Önce Dersler ekranından bu sınıfa ders ekleyin.',
                            backgroundColor: Color(0xFFFFF7ED),
                            textColor: Color(0xFF9A3412),
                          );
                        }

                        final validLessonIds = docs.map((doc) => doc.id).toList();

                        final dropdownValue =
                            validLessonIds.contains(selectedLessonId)
                                ? selectedLessonId
                                : null;

                        return DropdownButtonFormField<String>(
                          value: dropdownValue,
                          decoration: _input(
                            'Ders Seç',
                            Icons.menu_book_rounded,
                          ),
                          items: [
                            for (final doc in docs)
                              DropdownMenuItem(
                                value: doc.id,
                                child: Builder(
                                  builder: (context) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;

                                    final lessonName =
                                        data['name']?.toString() ?? 'Ders';
                                    final teacherName =
                                        data['teacherName']?.toString() ??
                                            data['teacher']?.toString() ??
                                            'Öğretmen yok';

                                    return Text(
                                      '$lessonName • $teacherName',
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                              ),
                          ],
                          onChanged: (lessonId) {
                            if (lessonId == null) return;

                            final lessonDoc = docs.firstWhere(
                              (doc) => doc.id == lessonId,
                            );

                            final data =
                                lessonDoc.data() as Map<String, dynamic>;

                            setState(() {
                              selectedLessonId = lessonDoc.id;
                              selectedLessonName =
                                  data['name']?.toString() ?? 'Ders';

                              if (data['teacherId'] != null &&
                                  data['teacherId'].toString().isNotEmpty) {
                                selectedTeacherId =
                                    data['teacherId'].toString();
                                selectedTeacherName =
                                    data['teacherName']?.toString() ??
                                        data['teacher']?.toString() ??
                                        'Öğretmen';
                                selectedTeacherBranch =
                                    data['teacherBranch']?.toString() ??
                                        'Branş yok';
                              }
                            });
                          },
                        );
                      },
                    ),

                  const SizedBox(height: 14),

                  // ÖĞRETMEN SEÇ
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

                      final validTeacherIds =
                          docs.map((doc) => doc.id).toList();

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
                            selectedTeacherBranch =
                                teacherBranchFromData(data);
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

                  const SizedBox(height: 14),
                  TextField(
                    controller: dueDateController,
                    readOnly: true,
                    onTap: pickDate,
                    decoration: _input(
                      'Son Teslim Tarihi',
                      Icons.calendar_month_rounded,
                    ).copyWith(
                      hintText: 'Tarih seçmek için tıkla',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: _input('Ödev Türü', Icons.file_present_rounded),
                    items: [
                      for (final item in typeOptions)
                        DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ),
                    ],
                    onChanged: (v) => setState(() => type = v ?? 'Metin'),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: _input('Durum', Icons.toggle_on_rounded),
                    items: [
                      for (final item in statusOptions)
                        DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ),
                    ],
                    onChanged: (v) => setState(() => status = v ?? 'Aktif'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descriptionController,
                    maxLines: 5,
                    decoration: _input(
                      'Ödev Açıklaması',
                      Icons.description_rounded,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: isSaving ? null : saveAssignment,
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
                                : 'Ödevi Kaydet',
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
      padding: const EdgeInsets.only(bottom: 10),
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

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
        ),
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