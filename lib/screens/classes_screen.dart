import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  void openAddClassSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ClassFormSheet(),
    );
  }

  void openEditClassSheet(String id, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClassFormSheet(
        classId: id,
        initialData: data,
      ),
    );
  }

  Future<void> deleteClass(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sınıf silinsin mi?'),
          content: const Text(
            'Bu sınıf silinecek. Bu işlem geri alınamaz.',
          ),
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
      await firestore.collection('classes').doc(id).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sınıf silindi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sınıf silinirken hata oluştu'),
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
            final isMobile = constraints.maxWidth < 700;

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
                            'Sınıflar',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Okuldaki sınıf ve şube bilgilerini yönetin.',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        onPressed: openAddClassSheet,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Sınıf Ekle'),
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
                        .collection('classes')
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
                          title: 'Sınıflar yüklenemedi',
                          description:
                              'Firestore bağlantısında bir sorun oluştu.',
                          color: Color(0xFFEF4444),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const _EmptyState(
                          icon: Icons.class_rounded,
                          title: 'Henüz sınıf yok',
                          description: 'Yeni sınıf ekleyerek başlayabilirsiniz.',
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
                              child: _ClassCard(
                                id: doc.id,
                                data: doc.data() as Map<String, dynamic>,
                                isMobile: isMobile,
                                onEdit: () => openEditClassSheet(
                                  doc.id,
                                  doc.data() as Map<String, dynamic>,
                                ),
                                onDelete: () => deleteClass(doc.id),
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

class _ClassCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final bool isMobile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClassCard({
    required this.id,
    required this.data,
    required this.isMobile,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['name']?.toString() ?? '-';
    final grade = data['grade']?.toString() ?? '-';
    final branch = data['branch']?.toString() ?? '-';
    final teacher = data['teacher']?.toString() ?? 'Atanmadı';
    final teacherBranch = data['teacherBranch']?.toString() ?? 'Branş yok';
    final capacity = data['capacity']?.toString() ?? '0';
    final studentCount = data['studentCount']?.toString() ?? '0';

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
                backgroundColor:
                    const Color(0xFF4F46E5).withValues(alpha: 0.12),
                child: const Icon(
                  Icons.class_rounded,
                  color: Color(0xFF4F46E5),
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
                    fontSize: 26,
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
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Düzenle'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Sil'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Line(Icons.school_rounded, 'Seviye: $grade'),
          _Line(Icons.abc_rounded, 'Şube: $branch'),
          _Line(Icons.person_rounded, 'Sınıf Öğretmeni: $teacher'),
          _Line(Icons.work_rounded, 'Branş: $teacherBranch'),
          _Line(Icons.groups_rounded, 'Öğrenci: $studentCount / $capacity'),
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
                      foregroundColor: const Color(0xFF4F46E5),
                      side: const BorderSide(color: Color(0xFF4F46E5)),
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
                        foregroundColor: const Color(0xFF4F46E5),
                        side: const BorderSide(color: Color(0xFF4F46E5)),
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

class _ClassFormSheet extends StatefulWidget {
  final String? classId;
  final Map<String, dynamic>? initialData;

  const _ClassFormSheet({
    this.classId,
    this.initialData,
  });

  @override
  State<_ClassFormSheet> createState() => _ClassFormSheetState();
}

class _ClassFormSheetState extends State<_ClassFormSheet> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  late TextEditingController capacityController;
  late TextEditingController studentCountController;

  String grade = '9';
  String branch = 'A';

  String? selectedTeacherId;
  String? selectedTeacherName;
  String? selectedTeacherBranch;

  bool isSaving = false;

  bool get isEdit => widget.classId != null;

  @override
  void initState() {
    super.initState();

    final data = widget.initialData;

    grade = data?['grade']?.toString() ?? '9';
    branch = data?['branch']?.toString() ?? 'A';

    selectedTeacherId = data?['teacherId']?.toString().isNotEmpty == true
        ? data!['teacherId'].toString()
        : null;

    selectedTeacherName = data?['teacher']?.toString().isNotEmpty == true &&
            data?['teacher']?.toString() != 'Atanmadı'
        ? data!['teacher'].toString()
        : null;

    selectedTeacherBranch =
        data?['teacherBranch']?.toString().isNotEmpty == true
            ? data!['teacherBranch'].toString()
            : null;

    capacityController = TextEditingController(
      text: data?['capacity']?.toString() ?? '30',
    );

    studentCountController = TextEditingController(
      text: data?['studentCount']?.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    capacityController.dispose();
    studentCountController.dispose();
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

  Future<void> saveClass() async {
    if (isSaving) return;

    final capacityText = capacityController.text.trim();
    final studentCountText = studentCountController.text.trim();

    final capacity = int.tryParse(capacityText);
    final studentCount = int.tryParse(studentCountText);

    if (capacity == null || capacity <= 0) {
      showMessage('Kapasite geçerli bir sayı olmalıdır.', isError: true);
      return;
    }

    if (studentCount == null || studentCount < 0) {
      showMessage('Öğrenci sayısı geçerli bir sayı olmalıdır.', isError: true);
      return;
    }

    if (studentCount > capacity) {
      showMessage('Öğrenci sayısı kapasiteden büyük olamaz.', isError: true);
      return;
    }

    if (selectedTeacherId == null ||
        selectedTeacherName == null ||
        selectedTeacherName!.isEmpty) {
      showMessage('Sınıf öğretmeni seçmelisiniz.', isError: true);
      return;
    }

    setState(() => isSaving = true);

    try {
      final className = '$grade-$branch';

      final payload = {
        'name': className,
        'grade': grade,
        'branch': branch,
        'teacherId': selectedTeacherId,
        'teacher': selectedTeacherName,
        'teacherBranch': selectedTeacherBranch ?? 'Branş yok',
        'capacity': capacity,
        'studentCount': studentCount,
        'updatedAt': Timestamp.now(),
      };

      if (isEdit) {
        await firestore.collection('classes').doc(widget.classId).update(payload);
      } else {
        await firestore.collection('classes').add({
          ...payload,
          'createdAt': Timestamp.now(),
        });
      }

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'Sınıf güncellendi' : 'Sınıf Firebase’e kaydedildi',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      showMessage(
        isEdit
            ? 'Sınıf güncellenirken hata oluştu.'
            : 'Sınıf kaydedilirken hata oluştu.',
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

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final className = '$grade-$branch';

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
                    isEdit ? 'Sınıfı Düzenle' : 'Yeni Sınıf Ekle',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: grade,
                    decoration: _input('Sınıf Seviyesi', Icons.school_rounded),
                    items: const [
                      DropdownMenuItem(value: '9', child: Text('9')),
                      DropdownMenuItem(value: '10', child: Text('10')),
                      DropdownMenuItem(value: '11', child: Text('11')),
                      DropdownMenuItem(value: '12', child: Text('12')),
                    ],
                    onChanged: (v) => setState(() => grade = v ?? '9'),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: branch,
                    decoration: _input('Şube', Icons.abc_rounded),
                    items: const [
                      DropdownMenuItem(value: 'A', child: Text('A')),
                      DropdownMenuItem(value: 'B', child: Text('B')),
                      DropdownMenuItem(value: 'C', child: Text('C')),
                      DropdownMenuItem(value: 'D', child: Text('D')),
                      DropdownMenuItem(value: 'E', child: Text('E')),
                    ],
                    onChanged: (v) => setState(() => branch = v ?? 'A'),
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
                          'Sınıf Öğretmeni Seç',
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
                                  final teacherBranch =
                                      teacherBranchFromData(data);

                                  return Text(
                                    '$name • $teacherBranch',
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
                    controller: capacityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: _input('Kapasite', Icons.groups_rounded),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: studentCountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: _input('Öğrenci Sayısı', Icons.people_rounded),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Sınıf adı: $className',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4338CA),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: isSaving ? null : saveClass,
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
                                : 'Sınıfı Kaydet',
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