import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'announcements_screen.dart';
import 'login_screen.dart';

class RoleDashboardScreen extends StatefulWidget {
  final String role;
  final String name;
  final String number;

  const RoleDashboardScreen({
    super.key,
    required this.role,
    required this.name,
    required this.number,
  });

  @override
  State<RoleDashboardScreen> createState() => _RoleDashboardScreenState();
}

class _RoleDashboardScreenState extends State<RoleDashboardScreen> {
  int selectedIndex = 0;

  final menuItems = const [
    _RoleMenuData(Icons.dashboard_rounded, 'Dashboard'),
    _RoleMenuData(Icons.assignment_rounded, 'Ödevler'),
    _RoleMenuData(Icons.upload_file_rounded, 'Teslimler'),
    _RoleMenuData(Icons.campaign_rounded, 'Duyurular'),
    _RoleMenuData(Icons.person_rounded, 'Profil'),
  ];

  Color get mainColor {
    if (widget.role == 'Öğretmen') return const Color(0xFF06B6D4);
    if (widget.role == 'Veli') return const Color(0xFFF59E0B);
    return const Color(0xFF4F46E5);
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: isDesktop
            ? Row(
                children: [
                  _SidePanel(
                    role: widget.role,
                    name: widget.name,
                    number: widget.number,
                    color: mainColor,
                    selectedIndex: selectedIndex,
                    items: menuItems,
                    onSelect: (index) => setState(() => selectedIndex = index),
                    onLogout: logout,
                  ),
                  Expanded(
                    child: _RolePageHost(
                      selectedIndex: selectedIndex,
                      role: widget.role,
                      name: widget.name,
                      number: widget.number,
                      color: mainColor,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: _MobileHeader(
                      role: widget.role,
                      name: widget.name,
                      number: widget.number,
                      color: mainColor,
                      onLogout: logout,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                    child: _MobileMenu(
                      selectedIndex: selectedIndex,
                      items: menuItems,
                      color: mainColor,
                      onSelect: (index) => setState(() => selectedIndex = index),
                    ),
                  ),
                  Expanded(
                    child: _RolePageHost(
                      selectedIndex: selectedIndex,
                      role: widget.role,
                      name: widget.name,
                      number: widget.number,
                      color: mainColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _RoleMenuData {
  final IconData icon;
  final String title;

  const _RoleMenuData(this.icon, this.title);
}

class _SidePanel extends StatelessWidget {
  final String role;
  final String name;
  final String number;
  final Color color;
  final int selectedIndex;
  final List<_RoleMenuData> items;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const _SidePanel({
    required this.role,
    required this.name,
    required this.number,
    required this.color,
    required this.selectedIndex,
    required this.items,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: color,
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '$role Paneli',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No: $number',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          for (int i = 0; i < items.length; i++)
            _SideItem(
              icon: items[i].icon,
              title: items[i].title,
              active: selectedIndex == i,
              onTap: () => onSelect(i),
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Çıkış Yap'),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _SideItem({
    required this.icon,
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFF4F46E5) : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: active ? 1 : 0.75),
                    fontWeight: active ? FontWeight.w900 : FontWeight.w600,
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

class _MobileHeader extends StatelessWidget {
  final String role;
  final String name;
  final String number;
  final Color color;
  final VoidCallback onLogout;

  const _MobileHeader({
    required this.role,
    required this.name,
    required this.number,
    required this.color,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(Icons.school_rounded, color: color, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$role Paneli',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  '$name • No: $number',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            color: color,
          ),
        ],
      ),
    );
  }
}

class _MobileMenu extends StatelessWidget {
  final int selectedIndex;
  final List<_RoleMenuData> items;
  final Color color;
  final ValueChanged<int> onSelect;

  const _MobileMenu({
    required this.selectedIndex,
    required this.items,
    required this.color,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final active = selectedIndex == index;

          return ChoiceChip(
            selected: active,
            label: Text(items[index].title),
            avatar: Icon(
              items[index].icon,
              size: 18,
              color: active ? Colors.white : color,
            ),
            selectedColor: color,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: active ? Colors.white : const Color(0xFF374151),
              fontWeight: FontWeight.w800,
            ),
            onSelected: (_) => onSelect(index),
          );
        },
      ),
    );
  }
}

class _RolePageHost extends StatelessWidget {
  final int selectedIndex;
  final String role;
  final String name;
  final String number;
  final Color color;

  const _RolePageHost({
    required this.selectedIndex,
    required this.role,
    required this.name,
    required this.number,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('schoolNo', isEqualTo: number)
          .where('role', isEqualTo: role)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        String userDocId = '';
        String className = '';
        String linkedStudentNo = '';
        String branch = '';

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final doc = snapshot.data!.docs.first;
          final data = doc.data() as Map<String, dynamic>;

          userDocId = doc.id;
          className = data['className']?.toString() ?? '';
          linkedStudentNo = data['linkedStudentNo']?.toString() ?? '';
          branch = data['branch']?.toString() ?? '';
        }

        if (selectedIndex == 1) {
          return _AssignmentsPage(
            role: role,
            userDocId: userDocId,
            name: name,
            number: number,
            className: className,
            branch: branch,
            color: color,
          );
        }

        if (selectedIndex == 2) {
          return _SubmissionsPage(
            role: role,
            userDocId: userDocId,
            number: number,
            linkedStudentNo: linkedStudentNo,
            color: color,
          );
        }

        if (selectedIndex == 3) {
          return AnnouncementsScreen(
            role: role,
            name: name,
          );
        }

        if (selectedIndex == 4) {
          return _ProfilePage(
            role: role,
            name: name,
            number: number,
            className: className,
            linkedStudentNo: linkedStudentNo,
            branch: branch,
            color: color,
          );
        }

        return _DashboardPage(
          role: role,
          name: name,
          number: number,
          className: className,
          linkedStudentNo: linkedStudentNo,
          branch: branch,
          color: color,
        );
      },
    );
  }
}

class _DashboardPage extends StatelessWidget {
  final String role;
  final String name;
  final String number;
  final String className;
  final String linkedStudentNo;
  final String branch;
  final Color color;

  const _DashboardPage({
    required this.role,
    required this.name,
    required this.number,
    required this.className,
    required this.linkedStudentNo,
    required this.branch,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isStudent = role == 'Öğrenci';
    final isTeacher = role == 'Öğretmen';
    final isParent = role == 'Veli';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoş geldin, $name',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isStudent
                ? className.isEmpty
                    ? 'Ödevlerini ve teslim durumlarını buradan takip edebilirsin.'
                    : '$className sınıfındaki ödev ve teslim durumlarını takip edebilirsin.'
                : isTeacher
                    ? branch.isEmpty
                        ? 'Derslerine ödev verebilir ve teslimleri değerlendirebilirsin.'
                        : '$branch branşında ödev verebilir ve teslimleri değerlendirebilirsin.'
                    : linkedStudentNo.isEmpty
                        ? 'Öğrencinizin ödev ve teslim durumlarını buradan izleyebilirsiniz.'
                        : 'Bağlı öğrenci no: $linkedStudentNo',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth > 700
                  ? (constraints.maxWidth - 36) / 3
                  : constraints.maxWidth;

              return Wrap(
                spacing: 18,
                runSpacing: 18,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _StaticInfoCard(
                      title: isTeacher ? 'Ödev Oluşturma' : 'Ödev Takibi',
                      value: isTeacher ? 'Aktif' : 'Açık',
                      icon: Icons.assignment_rounded,
                      color: color,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _StaticInfoCard(
                      title: isTeacher ? 'Değerlendirme' : 'Teslim Durumu',
                      value: isTeacher ? 'Not + Yorum' : 'Takip Et',
                      icon: Icons.rate_review_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _StaticInfoCard(
                      title: isParent ? 'Gözlem Modu' : 'Hesap Durumu',
                      value: isParent ? 'Salt Okuma' : 'Aktif',
                      icon: isParent
                          ? Icons.visibility_rounded
                          : Icons.verified_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AssignmentsPage extends StatelessWidget {
  final String role;
  final String userDocId;
  final String name;
  final String number;
  final String className;
  final String branch;
  final Color color;

  const _AssignmentsPage({
    required this.role,
    required this.userDocId,
    required this.name,
    required this.number,
    required this.className,
    required this.branch,
    required this.color,
  });

  void openTeacherAssignmentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TeacherAssignmentSheet(
        teacherId: userDocId,
        teacherName: name,
        teacherBranch: branch,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = role == 'Öğretmen';

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
              Text(
                isTeacher ? 'Verdiğim Ödevler' : 'Ödevler',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              if (isTeacher)
                FilledButton.icon(
                  onPressed: userDocId.isEmpty
                      ? null
                      : () => openTeacherAssignmentSheet(context),
                  icon: const Icon(Icons.add_task_rounded),
                  label: const Text('Ödev Oluştur'),
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
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
          const SizedBox(height: 18),
          _PanelCard(
            title: isTeacher ? 'Öğretmen Ödevleri' : 'Ödev Listesi',
            child: _AssignmentsList(
              role: role,
              userDocId: userDocId,
              userNumber: number,
              className: className,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherAssignmentSheet extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final String teacherBranch;

  const _TeacherAssignmentSheet({
    required this.teacherId,
    required this.teacherName,
    required this.teacherBranch,
  });

  @override
  State<_TeacherAssignmentSheet> createState() => _TeacherAssignmentSheetState();
}

class _TeacherAssignmentSheetState extends State<_TeacherAssignmentSheet> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController dueDateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedLessonId;
  String? selectedLessonName;
  String? selectedClassName;

  String type = 'Metin';
  String status = 'Aktif';
  bool isSaving = false;

  final typeOptions = const ['Metin', 'Dosya', 'Link', 'PDF', 'PPTX'];
  final statusOptions = const ['Aktif', 'Teslim Bekliyor', 'Pasif'];

  @override
  void dispose() {
    titleController.dispose();
    dueDateController.dispose();
    descriptionController.dispose();
    super.dispose();
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

    dueDateController.text =
        '${selected.day.toString().padLeft(2, '0')}.${selected.month.toString().padLeft(2, '0')}.${selected.year}';
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

    if (selectedLessonId == null ||
        selectedLessonName == null ||
        selectedClassName == null) {
      showMessage('Ders seçmelisiniz.', isError: true);
      return;
    }

    if (dueDate.isEmpty) {
      showMessage('Son teslim tarihi seçmelisiniz.', isError: true);
      return;
    }

    setState(() => isSaving = true);

    try {
      await firestore.collection('assignments').add({
        'title': title,
        'lessonId': selectedLessonId,
        'lesson': selectedLessonName,
        'className': selectedClassName,
        'teacherId': widget.teacherId,
        'teacher': widget.teacherName,
        'teacherName': widget.teacherName,
        'teacherBranch':
            widget.teacherBranch.isEmpty ? 'Branş yok' : widget.teacherBranch,
        'dueDate': dueDate,
        'type': type,
        'status': status,
        'description': description,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ödev oluşturuldu'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      showMessage('Ödev oluşturulurken hata oluştu.', isError: true);
    } finally {
      if (mounted) setState(() => isSaving = false);
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
                  const Text(
                    'Yeni Ödev Oluştur',
                    style: TextStyle(
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
                  StreamBuilder<QuerySnapshot>(
                    stream: firestore
                        .collection('lessons')
                        .where('teacherId', isEqualTo: widget.teacherId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(14),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return const _MiniEmpty(
                          text: 'Dersler yüklenirken hata oluştu',
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return const _MiniEmpty(
                          text:
                              'Size atanmış ders yok. Admin Dersler ekranından bu öğretmene ders atamalı.',
                        );
                      }

                      final validLessonIds = docs.map((doc) => doc.id).toList();
                      final dropdownValue =
                          validLessonIds.contains(selectedLessonId)
                              ? selectedLessonId
                              : null;

                      return DropdownButtonFormField<String>(
                        value: dropdownValue,
                        decoration: _input('Ders Seç', Icons.menu_book_rounded),
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
                                  final className =
                                      data['className']?.toString() ?? '-';

                                  return Text(
                                    '$lessonName • $className',
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ),
                        ],
                        onChanged: (lessonId) {
                          if (lessonId == null) return;

                          final lessonDoc =
                              docs.firstWhere((doc) => doc.id == lessonId);
                          final data = lessonDoc.data() as Map<String, dynamic>;

                          setState(() {
                            selectedLessonId = lessonDoc.id;
                            selectedLessonName =
                                data['name']?.toString() ?? 'Ders';
                            selectedClassName =
                                data['className']?.toString() ?? '';
                          });
                        },
                      );
                    },
                  ),
                  if (selectedClassName != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'Seçilen sınıf: $selectedClassName',
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
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: _input('Ödev Türü', Icons.file_present_rounded),
                    items: [
                      for (final item in typeOptions)
                        DropdownMenuItem(value: item, child: Text(item)),
                    ],
                    onChanged: (v) => setState(() => type = v ?? 'Metin'),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: _input('Durum', Icons.toggle_on_rounded),
                    items: [
                      for (final item in statusOptions)
                        DropdownMenuItem(value: item, child: Text(item)),
                    ],
                    onChanged: (v) => setState(() => status = v ?? 'Aktif'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descriptionController,
                    maxLines: 5,
                    decoration:
                        _input('Ödev Açıklaması', Icons.description_rounded),
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
                      label:
                          Text(isSaving ? 'Kaydediliyor...' : 'Ödevi Kaydet'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
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

class _AssignmentsList extends StatelessWidget {
  final String role;
  final String userDocId;
  final String userNumber;
  final String className;
  final Color color;

  const _AssignmentsList({
    required this.role,
    required this.userDocId,
    required this.userNumber,
    required this.className,
    required this.color,
  });

  Stream<QuerySnapshot> get stream {
    if (role == 'Öğretmen' && userDocId.isNotEmpty) {
      return FirebaseFirestore.instance
          .collection('assignments')
          .where('teacherId', isEqualTo: userDocId)
          .snapshots();
    }

    if (role == 'Öğrenci' && className.isNotEmpty) {
      return FirebaseFirestore.instance
          .collection('assignments')
          .where('className', isEqualTo: className)
          .snapshots();
    }

    return FirebaseFirestore.instance
        .collection('assignments')
        .limit(20)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _MiniEmpty(text: 'Ödevler yükleniyor...');
        }

        if (snapshot.hasError) {
          return const _MiniEmpty(text: 'Ödevler yüklenirken hata oluştu');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const _MiniEmpty(text: 'Henüz ödev yok');
        }

        final docs = snapshot.data!.docs;

        return Column(
          children: [
            for (final doc in docs)
              _AssignmentTile(
                assignmentId: doc.id,
                data: doc.data() as Map<String, dynamic>,
                color: color,
                canSubmit: role == 'Öğrenci',
                userNumber: userNumber,
              ),
          ],
        );
      },
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  final String assignmentId;
  final Map<String, dynamic> data;
  final Color color;
  final bool canSubmit;
  final String userNumber;

  const _AssignmentTile({
    required this.assignmentId,
    required this.data,
    required this.color,
    required this.canSubmit,
    required this.userNumber,
  });

  void openSubmitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubmitAssignmentSheet(
        assignmentId: assignmentId,
        assignmentTitle: data['title']?.toString() ?? 'Ödev',
        lesson: data['lesson']?.toString() ?? '',
        className: data['className']?.toString() ?? '',
        teacherId: data['teacherId']?.toString() ?? '',
        teacherName: data['teacher']?.toString() ??
            data['teacherName']?.toString() ??
            '',
        studentNo: userNumber,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? '-';
    final lesson = data['lesson']?.toString() ?? '-';
    final dueDate = data['dueDate']?.toString() ?? '-';
    final description = data['description']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(Icons.assignment_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  '$lesson • Son Tarih: $dueDate',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description.isNotEmpty)
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (canSubmit)
            TextButton(
              onPressed: () => openSubmitSheet(context),
              child: const Text('Teslim Et'),
            ),
        ],
      ),
    );
  }
}

class _SubmitAssignmentSheet extends StatefulWidget {
  final String assignmentId;
  final String assignmentTitle;
  final String lesson;
  final String className;
  final String teacherId;
  final String teacherName;
  final String studentNo;

  const _SubmitAssignmentSheet({
    required this.assignmentId,
    required this.assignmentTitle,
    required this.lesson,
    required this.className,
    required this.teacherId,
    required this.teacherName,
    required this.studentNo,
  });

  @override
  State<_SubmitAssignmentSheet> createState() => _SubmitAssignmentSheetState();
}

class _SubmitAssignmentSheetState extends State<_SubmitAssignmentSheet> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final TextEditingController answerController = TextEditingController();
  final TextEditingController linkController = TextEditingController();

  bool isSaving = false;

  @override
  void dispose() {
    answerController.dispose();
    linkController.dispose();
    super.dispose();
  }

  Future<void> saveSubmission() async {
    if (isSaving) return;

    final answer = answerController.text.trim();
    final link = linkController.text.trim();

    if (answer.isEmpty && link.isEmpty) {
      showMessage('Metin cevabı veya link girilmelidir.', isError: true);
      return;
    }

    setState(() => isSaving = true);

    try {
      final existing = await firestore
          .collection('submissions')
          .where('assignmentId', isEqualTo: widget.assignmentId)
          .where('studentNo', isEqualTo: widget.studentNo)
          .limit(1)
          .get();

      final payload = {
        'assignmentId': widget.assignmentId,
        'assignmentTitle': widget.assignmentTitle,
        'lesson': widget.lesson,
        'className': widget.className,
        'teacherId': widget.teacherId,
        'teacherName': widget.teacherName,
        'studentNo': widget.studentNo,
        'answer': answer,
        'link': link,
        'status': 'Teslim Edildi',
        'grade': '',
        'feedback': '',
        'updatedAt': Timestamp.now(),
      };

      if (existing.docs.isNotEmpty) {
        await firestore
            .collection('submissions')
            .doc(existing.docs.first.id)
            .update({
          ...payload,
          'status': 'Güncellendi',
        });
      } else {
        await firestore.collection('submissions').add({
          ...payload,
          'createdAt': Timestamp.now(),
        });
      }

      if (!mounted) return;

      Navigator.pop(context);
      showMessage('Ödev teslim edildi');
    } catch (e) {
      showMessage('Teslim sırasında hata oluştu', isError: true);
    } finally {
      if (mounted) setState(() => isSaving = false);
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
                    widget.assignmentTitle,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: answerController,
                    maxLines: 6,
                    decoration:
                        _input('Metin Cevabı', Icons.description_rounded),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: linkController,
                    decoration:
                        _input('Dosya / Drive / GitHub Linki', Icons.link_rounded),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: isSaving ? null : saveSubmission,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file_rounded),
                      label:
                          Text(isSaving ? 'Teslim ediliyor...' : 'Ödevi Teslim Et'),
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

class _SubmissionsPage extends StatelessWidget {
  final String role;
  final String userDocId;
  final String number;
  final String linkedStudentNo;
  final Color color;

  const _SubmissionsPage({
    required this.role,
    required this.userDocId,
    required this.number,
    required this.linkedStudentNo,
    required this.color,
  });

  Stream<QuerySnapshot> get stream {
    if (role == 'Öğretmen') {
      return FirebaseFirestore.instance
          .collection('submissions')
          .where('teacherId', isEqualTo: userDocId)
          .snapshots();
    }

    if (role == 'Veli' && linkedStudentNo.isNotEmpty) {
      return FirebaseFirestore.instance
          .collection('submissions')
          .where('studentNo', isEqualTo: linkedStudentNo)
          .snapshots();
    }

    return FirebaseFirestore.instance
        .collection('submissions')
        .where('studentNo', isEqualTo: number)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final title = role == 'Öğretmen'
        ? 'Öğrenci Teslimleri'
        : role == 'Veli'
            ? 'Öğrenci Teslim Durumu'
            : 'Teslimlerim';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: _PanelCard(
        title: title,
        child: StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _MiniEmpty(text: 'Teslimler yükleniyor...');
            }

            if (snapshot.hasError) {
              return const _MiniEmpty(text: 'Teslimler yüklenirken hata oluştu');
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const _MiniEmpty(text: 'Henüz teslim yok');
            }

            final docs = snapshot.data!.docs;

            return Column(
              children: [
                for (final doc in docs)
                  _SubmissionTile(
                    id: doc.id,
                    data: doc.data() as Map<String, dynamic>,
                    color: color,
                    canGrade: role == 'Öğretmen',
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final Color color;
  final bool canGrade;

  const _SubmissionTile({
    required this.id,
    required this.data,
    required this.color,
    required this.canGrade,
  });

  void openGradeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GradeSubmissionSheet(
        submissionId: id,
        data: data,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = data['assignmentTitle']?.toString() ?? '-';
    final studentNo = data['studentNo']?.toString() ?? '-';
    final answer = data['answer']?.toString() ?? '';
    final link = data['link']?.toString() ?? '';
    final status = data['status']?.toString() ?? 'Teslim Edildi';
    final grade = data['grade']?.toString() ?? '';
    final feedback = data['feedback']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(Icons.upload_file_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'Öğrenci No: $studentNo • Durum: $status',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (answer.isNotEmpty)
                  Text(
                    'Cevap: $answer',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                if (link.isNotEmpty)
                  Text(
                    'Link: $link',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                if (grade.isNotEmpty || feedback.isNotEmpty)
                  Text(
                    'Not: ${grade.isEmpty ? '-' : grade} • Geri dönüş: ${feedback.isEmpty ? '-' : feedback}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
          if (canGrade)
            TextButton(
              onPressed: () => openGradeSheet(context),
              child: const Text('Değerlendir'),
            ),
        ],
      ),
    );
  }
}

class _GradeSubmissionSheet extends StatefulWidget {
  final String submissionId;
  final Map<String, dynamic> data;

  const _GradeSubmissionSheet({
    required this.submissionId,
    required this.data,
  });

  @override
  State<_GradeSubmissionSheet> createState() => _GradeSubmissionSheetState();
}

class _GradeSubmissionSheetState extends State<_GradeSubmissionSheet> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  late TextEditingController gradeController;
  late TextEditingController feedbackController;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    gradeController = TextEditingController(
      text: widget.data['grade']?.toString() ?? '',
    );

    feedbackController = TextEditingController(
      text: widget.data['feedback']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    gradeController.dispose();
    feedbackController.dispose();
    super.dispose();
  }

  Future<void> saveGrade() async {
    if (isSaving) return;

    final grade = gradeController.text.trim();
    final feedback = feedbackController.text.trim();

    if (grade.isEmpty) {
      showMessage('Not alanı boş bırakılamaz.', isError: true);
      return;
    }

    setState(() => isSaving = true);

    try {
      await firestore.collection('submissions').doc(widget.submissionId).update({
        'grade': grade,
        'feedback': feedback,
        'status': 'Değerlendirildi',
        'gradedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      if (!mounted) return;

      Navigator.pop(context);
      showMessage('Teslim değerlendirildi');
    } catch (e) {
      showMessage('Değerlendirme kaydedilirken hata oluştu', isError: true);
    } finally {
      if (mounted) setState(() => isSaving = false);
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
    final title = widget.data['assignmentTitle']?.toString() ?? 'Teslim';

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
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: gradeController,
                    keyboardType: TextInputType.number,
                    decoration: _input('Not / Puan', Icons.grade_rounded),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: feedbackController,
                    maxLines: 5,
                    decoration: _input(
                      'Geri Dönüş Açıklaması',
                      Icons.rate_review_rounded,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: isSaving ? null : saveGrade,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(isSaving ? 'Kaydediliyor...' : 'Notu Kaydet'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
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

class _ProfilePage extends StatelessWidget {
  final String role;
  final String name;
  final String number;
  final String className;
  final String linkedStudentNo;
  final String branch;
  final Color color;

  const _ProfilePage({
    required this.role,
    required this.name,
    required this.number,
    required this.className,
    required this.linkedStudentNo,
    required this.branch,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profil',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 20),
            _ProfileLine(Icons.person_rounded, 'Ad Soyad', name),
            _ProfileLine(Icons.badge_rounded, 'Rol', role),
            _ProfileLine(Icons.numbers_rounded, 'Numara', number),
            if (className.isNotEmpty)
              _ProfileLine(Icons.class_rounded, 'Sınıf', className),
            if (branch.isNotEmpty) _ProfileLine(Icons.work_rounded, 'Branş', branch),
            if (linkedStudentNo.isNotEmpty)
              _ProfileLine(
                Icons.child_care_rounded,
                'Bağlı Öğrenci No',
                linkedStudentNo,
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileLine(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StaticInfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 145,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _PanelCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MiniEmpty extends StatelessWidget {
  final String text;

  const _MiniEmpty({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w700,
        ),
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