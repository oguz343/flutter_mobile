import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool isImporting = false;

  void openAddUserSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddUserSheet(),
    );
  }

  void openEditUserSheet(String id, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditUserSheet(
        userId: id,
        data: data,
      ),
    );
  }

  String generateActivationCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();

    return List.generate(
      6,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<void> renewActivationCode(String id) async {
    final code = generateActivationCode();

    try {
      await firestore.collection('users').doc(id).update({
        'activationCode': code,
        'mustChangePassword': true,
        'password': '',
        'passwordUpdatedAt': null,
        'updatedAt': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yeni aktivasyon kodu: $code'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      showMessage('Kod yenilenirken hata oluştu.', isError: true);
    }
  }

  Future<void> deleteUser(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kullanıcı silinsin mi?'),
          content: const Text(
            'Bu işlem geri alınamaz. Kullanıcıyı silmek istediğine emin misin?',
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
      await firestore.collection('users').doc(id).delete();

      if (!mounted) return;

      showMessage('Kullanıcı silindi.');
    } catch (e) {
      showMessage('Kullanıcı silinirken hata oluştu.', isError: true);
    }
  }

  String cellText(dynamic cell) {
    if (cell == null) return '';

    final value = cell.value;

    if (value == null) return '';

    var text = value.toString().trim();

    text = text
        .replaceAll('TextCellValue(', '')
        .replaceAll('IntCellValue(', '')
        .replaceAll('DoubleCellValue(', '')
        .replaceAll('BoolCellValue(', '')
        .replaceAll('DateCellValue(', '')
        .replaceAll('FormulaCellValue(', '');

    if (text.endsWith(')')) {
      text = text.substring(0, text.length - 1);
    }

    return text.trim();
  }

  Future<void> importStudentsFromExcel() async {
    if (isImporting) return;

    try {
      setState(() => isImporting = true);

      final fp.FilePickerResult? result =
          await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final Uint8List? bytes = result.files.single.bytes;

      if (bytes == null) {
        showMessage('Dosya okunamadı. Lütfen tekrar deneyin.', isError: true);
        return;
      }

      final excel = excel_lib.Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        showMessage('Excel dosyasında sayfa bulunamadı.', isError: true);
        return;
      }

      final sheet = excel.tables.values.first;
      final rows = sheet.rows;

      if (rows.length <= 1) {
        showMessage('Excel dosyasında öğrenci satırı yok.', isError: true);
        return;
      }

      int addedCount = 0;
      WriteBatch batch = firestore.batch();
      int batchCounter = 0;

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];

        final name = row.isNotEmpty ? cellText(row[0]) : '';
        final tc = row.length > 1 ? cellText(row[1]) : '';
        final schoolNo = row.length > 2 ? cellText(row[2]) : '';
        final className = row.length > 3 ? cellText(row[3]) : '';
        final parentPhone = row.length > 4 ? cellText(row[4]) : '';

        if (name.isEmpty || schoolNo.isEmpty) {
          continue;
        }

        final activationCode = generateActivationCode();
        final docRef = firestore.collection('users').doc();

        batch.set(docRef, {
          'name': name,
          'tc': tc,
          'schoolNo': schoolNo,
          'phone': parentPhone,
          'className': className,
          'linkedStudentNo': '',
          'branch': '',
          'role': 'Öğrenci',
          'activationCode': activationCode,
          'mustChangePassword': true,
          'password': '',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        addedCount++;
        batchCounter++;

        if (batchCounter == 450) {
          await batch.commit();
          batch = firestore.batch();
          batchCounter = 0;
        }
      }

      if (addedCount == 0) {
        showMessage('Aktarılacak geçerli öğrenci bulunamadı.', isError: true);
        return;
      }

      if (batchCounter > 0) {
        await batch.commit();
      }

      if (!mounted) return;

      showMessage('$addedCount öğrenci Excel’den aktarıldı.');
    } catch (e) {
      showMessage('Excel aktarımı sırasında hata oluştu: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => isImporting = false);
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

  _UserItem buildUserItem(Map<String, dynamic> data) {
    final className = data['className']?.toString() ?? '';
    final linkedStudentNo = data['linkedStudentNo']?.toString() ?? '';
    final branch = data['branch']?.toString() ?? '';
    final role = data['role']?.toString() ?? '';

    String detail = role;

    if (role == 'Öğretmen' && branch.isNotEmpty) {
      detail = 'Branş: $branch';
    } else if (className.isNotEmpty) {
      detail = className;
    } else if (linkedStudentNo.isNotEmpty) {
      detail = 'Bağlı öğrenci: $linkedStudentNo';
    }

    return _UserItem(
      data['name']?.toString() ?? '',
      role,
      data['schoolNo']?.toString() ?? '',
      detail,
      data['phone']?.toString() ?? '',
      data['activationCode']?.toString() ?? '',
      data['mustChangePassword'] == true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 14 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kullanıcılar',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Öğrenci, öğretmen ve veli hesaplarını yönetin.',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: isImporting ? null : importStudentsFromExcel,
                        icon: isImporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.table_chart_rounded),
                        label: Text(
                          isImporting ? 'Aktarılıyor...' : 'Excel İçe Aktar',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: openAddUserSheet,
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Kullanıcı Ekle'),
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
                ],
              ),
              const SizedBox(height: 16),
              const _ExcelInfoCard(),
              const SizedBox(height: 24),
              StreamBuilder<QuerySnapshot>(
                stream: firestore
                    .collection('users')
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
                      title: 'Kullanıcılar yüklenemedi',
                      description: 'Firestore bağlantısında bir sorun oluştu.',
                      color: Color(0xFFEF4444),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const _EmptyState(
                      icon: Icons.people_alt_rounded,
                      title: 'Henüz kullanıcı yok',
                      description:
                          'Kullanıcı ekleyerek veya Excel içe aktararak başlayabilirsiniz.',
                      color: Color(0xFF4F46E5),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  if (isSmall) {
                    return Column(
                      children: [
                        for (final doc in docs) ...[
                          Builder(
                            builder: (context) {
                              final data = doc.data() as Map<String, dynamic>;

                              return _UserCard(
                                userId: doc.id,
                                user: buildUserItem(data),
                                onEdit: () => openEditUserSheet(doc.id, data),
                                onDelete: () => deleteUser(doc.id),
                                onRenewCode: () => renewActivationCode(doc.id),
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                        ],
                      ],
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 420,
                      mainAxisExtent: 355,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                    ),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return _UserCard(
                        userId: doc.id,
                        user: buildUserItem(data),
                        onEdit: () => openEditUserSheet(doc.id, data),
                        onDelete: () => deleteUser(doc.id),
                        onRenewCode: () => renewActivationCode(doc.id),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExcelInfoCard extends StatelessWidget {
  const _ExcelInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.18),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_rounded, color: Color(0xFF10B981)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Excel formatı: Ad Soyad | T.C. | Okul No | Sınıf | Veli Telefonu. İlk satır başlık olmalı.',
              style: TextStyle(
                color: Color(0xFF047857),
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserItem {
  final String name;
  final String role;
  final String number;
  final String detail;
  final String phone;
  final String activationCode;
  final bool mustChangePassword;

  _UserItem(
    this.name,
    this.role,
    this.number,
    this.detail,
    this.phone,
    this.activationCode,
    this.mustChangePassword,
  );
}

class _UserCard extends StatelessWidget {
  final String userId;
  final _UserItem user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRenewCode;

  const _UserCard({
    required this.userId,
    required this.user,
    required this.onEdit,
    required this.onDelete,
    required this.onRenewCode,
  });

  Color get roleColor {
    switch (user.role) {
      case 'Öğretmen':
        return const Color(0xFF06B6D4);
      case 'Veli':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF4F46E5);
    }
  }

  IconData get roleIcon {
    switch (user.role) {
      case 'Öğretmen':
        return Icons.person_rounded;
      case 'Veli':
        return Icons.family_restroom_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final codeText = user.activationCode.isEmpty ? 'Yok' : user.activationCode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: roleColor.withValues(alpha: 0.12),
                child: Icon(
                  roleIcon,
                  color: roleColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isEmpty ? '-' : user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      user.role.isEmpty ? '-' : user.role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _InfoLine(
            Icons.numbers_rounded,
            'No: ${user.number.isEmpty ? '-' : user.number}',
          ),
          _InfoLine(
            Icons.info_rounded,
            user.detail.isEmpty ? '-' : user.detail,
          ),
          _InfoLine(
            Icons.phone_rounded,
            user.phone.isEmpty ? '-' : user.phone,
          ),
          _InfoLine(
            Icons.key_rounded,
            'Aktivasyon: $codeText',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Düzenle'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: roleColor,
                    side: BorderSide(color: roleColor),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    if (codeText == 'Yok') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kopyalanacak aktivasyon kodu yok'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    Clipboard.setData(
                      ClipboardData(text: codeText),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Aktivasyon kodu kopyalandı'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Kopyala'),
                  style: FilledButton.styleFrom(
                    backgroundColor: roleColor,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRenewCode,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Kod Yenile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_rounded, size: 18),
                  label: const Text('Sil'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

class _AddUserSheet extends StatefulWidget {
  const _AddUserSheet();

  @override
  State<_AddUserSheet> createState() => _AddUserSheetState();
}

class _AddUserSheetState extends State<_AddUserSheet> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController tcController = TextEditingController();
  final TextEditingController noController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController linkedStudentController = TextEditingController();
  final TextEditingController branchController = TextEditingController();

  String role = 'Öğrenci';
  String? selectedClassName;
  bool isSaving = false;

  String generateActivationCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();

    return List.generate(
      6,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  @override
  void dispose() {
    nameController.dispose();
    tcController.dispose();
    noController.dispose();
    phoneController.dispose();
    linkedStudentController.dispose();
    branchController.dispose();
    super.dispose();
  }

  Future<void> saveUser() async {
    if (isSaving) return;

    final name = nameController.text.trim();
    final tc = tcController.text.trim();
    final no = noController.text.trim();
    final phone = phoneController.text.trim();
    final linkedStudent = linkedStudentController.text.trim();
    final branch = branchController.text.trim();

    if (name.isEmpty) {
      showMessage('Ad soyad boş bırakılamaz.', isError: true);
      return;
    }

    if (tc.length != 11) {
      showMessage('T.C. kimlik numarası 11 haneli olmalıdır.', isError: true);
      return;
    }

    if (no.isEmpty) {
      showMessage('Numara boş bırakılamaz.', isError: true);
      return;
    }

    if (role == 'Öğrenci' && selectedClassName == null) {
      showMessage('Öğrenci için sınıf seçmelisiniz.', isError: true);
      return;
    }

    if (role == 'Öğretmen' && branch.isEmpty) {
      showMessage('Öğretmen için branş girilmelidir.', isError: true);
      return;
    }

    if (role != 'Öğrenci' && phone.length != 10) {
      showMessage(
        'Telefon numarası 10 haneli olmalıdır. Örn: 5551234567',
        isError: true,
      );
      return;
    }

    if (role == 'Veli' && linkedStudent.isEmpty) {
      showMessage(
        'Veli için bağlı öğrenci numarası girilmelidir.',
        isError: true,
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final activationCode = generateActivationCode();

      await firestore.collection('users').add({
        'name': name,
        'tc': tc,
        'schoolNo': no,
        'phone': phone,
        'className': role == 'Öğrenci' ? selectedClassName : '',
        'linkedStudentNo': role == 'Veli' ? linkedStudent : '',
        'branch': role == 'Öğretmen' ? branch : '',
        'role': role,
        'activationCode': activationCode,
        'mustChangePassword': true,
        'password': '',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Kullanıcı kaydedildi. Aktivasyon kodu: $activationCode'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      showMessage('Kullanıcı kaydedilirken hata oluştu.', isError: true);
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
    return _UserFormShell(
      title: 'Yeni Kullanıcı Ekle',
      role: role,
      nameController: nameController,
      tcController: tcController,
      noController: noController,
      phoneController: phoneController,
      linkedStudentController: linkedStudentController,
      branchController: branchController,
      selectedClassName: selectedClassName,
      isSaving: isSaving,
      buttonText: 'Kaydet ve Aktivasyon Kodu Oluştur',
      onRoleChanged: (value) {
        setState(() {
          role = value;
          noController.clear();
          phoneController.clear();
          linkedStudentController.clear();
          branchController.clear();
          selectedClassName = null;
        });
      },
      onClassChanged: (value) {
        setState(() {
          selectedClassName = value;
        });
      },
      onSave: saveUser,
    );
  }
}

class _EditUserSheet extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> data;

  const _EditUserSheet({
    required this.userId,
    required this.data,
  });

  @override
  State<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends State<_EditUserSheet> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  late TextEditingController nameController;
  late TextEditingController tcController;
  late TextEditingController noController;
  late TextEditingController phoneController;
  late TextEditingController linkedStudentController;
  late TextEditingController branchController;

  late String role;
  String? selectedClassName;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    role = widget.data['role']?.toString() ?? 'Öğrenci';
    selectedClassName = widget.data['className']?.toString().isNotEmpty == true
        ? widget.data['className'].toString()
        : null;

    nameController = TextEditingController(
      text: widget.data['name']?.toString() ?? '',
    );
    tcController = TextEditingController(
      text: widget.data['tc']?.toString() ?? '',
    );
    noController = TextEditingController(
      text: widget.data['schoolNo']?.toString() ?? '',
    );
    phoneController = TextEditingController(
      text: widget.data['phone']?.toString() ?? '',
    );
    linkedStudentController = TextEditingController(
      text: widget.data['linkedStudentNo']?.toString() ?? '',
    );
    branchController = TextEditingController(
      text: widget.data['branch']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    tcController.dispose();
    noController.dispose();
    phoneController.dispose();
    linkedStudentController.dispose();
    branchController.dispose();
    super.dispose();
  }

  Future<void> updateUser() async {
    if (isSaving) return;

    final name = nameController.text.trim();
    final tc = tcController.text.trim();
    final no = noController.text.trim();
    final phone = phoneController.text.trim();
    final linkedStudent = linkedStudentController.text.trim();
    final branch = branchController.text.trim();

    if (name.isEmpty) {
      showMessage('Ad soyad boş bırakılamaz.', isError: true);
      return;
    }

    if (tc.length != 11) {
      showMessage('T.C. kimlik numarası 11 haneli olmalıdır.', isError: true);
      return;
    }

    if (no.isEmpty) {
      showMessage('Numara boş bırakılamaz.', isError: true);
      return;
    }

    if (role == 'Öğrenci' && selectedClassName == null) {
      showMessage('Öğrenci için sınıf seçmelisiniz.', isError: true);
      return;
    }

    if (role == 'Öğretmen' && branch.isEmpty) {
      showMessage('Öğretmen için branş girilmelidir.', isError: true);
      return;
    }

    if (role != 'Öğrenci' && phone.length != 10) {
      showMessage(
        'Telefon numarası 10 haneli olmalıdır. Örn: 5551234567',
        isError: true,
      );
      return;
    }

    if (role == 'Veli' && linkedStudent.isEmpty) {
      showMessage(
        'Veli için bağlı öğrenci numarası girilmelidir.',
        isError: true,
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      await firestore.collection('users').doc(widget.userId).update({
        'name': name,
        'tc': tc,
        'schoolNo': no,
        'phone': phone,
        'className': role == 'Öğrenci' ? selectedClassName : '',
        'linkedStudentNo': role == 'Veli' ? linkedStudent : '',
        'branch': role == 'Öğretmen' ? branch : '',
        'role': role,
        'updatedAt': Timestamp.now(),
      });

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı güncellendi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      showMessage('Kullanıcı güncellenirken hata oluştu.', isError: true);
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
    return _UserFormShell(
      title: 'Kullanıcıyı Düzenle',
      role: role,
      nameController: nameController,
      tcController: tcController,
      noController: noController,
      phoneController: phoneController,
      linkedStudentController: linkedStudentController,
      branchController: branchController,
      selectedClassName: selectedClassName,
      isSaving: isSaving,
      buttonText: 'Değişiklikleri Kaydet',
      onRoleChanged: (value) {
        setState(() {
          role = value;
          selectedClassName = null;
          linkedStudentController.clear();
          branchController.clear();
        });
      },
      onClassChanged: (value) {
        setState(() {
          selectedClassName = value;
        });
      },
      onSave: updateUser,
    );
  }
}

class _UserFormShell extends StatelessWidget {
  final String title;
  final String role;
  final TextEditingController nameController;
  final TextEditingController tcController;
  final TextEditingController noController;
  final TextEditingController phoneController;
  final TextEditingController linkedStudentController;
  final TextEditingController branchController;
  final String? selectedClassName;
  final bool isSaving;
  final String buttonText;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String?> onClassChanged;
  final VoidCallback onSave;

  const _UserFormShell({
    required this.title,
    required this.role,
    required this.nameController,
    required this.tcController,
    required this.noController,
    required this.phoneController,
    required this.linkedStudentController,
    required this.branchController,
    required this.selectedClassName,
    required this.isSaving,
    required this.buttonText,
    required this.onRoleChanged,
    required this.onClassChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final firestore = FirebaseFirestore.instance;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFFF6F7FB),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(32),
          ),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 620,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: _input(
                      'Rol',
                      Icons.badge_rounded,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Öğrenci',
                        child: Text('Öğrenci'),
                      ),
                      DropdownMenuItem(
                        value: 'Öğretmen',
                        child: Text('Öğretmen'),
                      ),
                      DropdownMenuItem(
                        value: 'Veli',
                        child: Text('Veli'),
                      ),
                    ],
                    onChanged: (v) {
                      onRoleChanged(v ?? 'Öğrenci');
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameController,
                    decoration: _input(
                      'Ad Soyad',
                      Icons.person_rounded,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: tcController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    decoration: _input(
                      'T.C. Kimlik No',
                      Icons.credit_card_rounded,
                    ).copyWith(
                      helperText: '11 haneli olmalıdır',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: noController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                    decoration: _input(
                      role == 'Öğrenci'
                          ? 'Okul Numarası'
                          : role == 'Öğretmen'
                              ? 'Öğretmen Numarası'
                              : 'Veli Numarası',
                      Icons.numbers_rounded,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: _input(
                      role == 'Öğrenci'
                          ? 'Veli Telefonu: 5XXXXXXXXX'
                          : 'Telefon: 5XXXXXXXXX',
                      Icons.phone_rounded,
                    ),
                  ),
                  if (role == 'Öğretmen') ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: branchController,
                      decoration: _input(
                        'Branş: Örn Matematik',
                        Icons.work_rounded,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (role == 'Öğrenci')
                    StreamBuilder<QuerySnapshot>(
                      stream: firestore
                          .collection('classes')
                          .orderBy('grade')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(14),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
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
                            text:
                                'Önce Sınıflar ekranından sınıf eklemelisiniz.',
                            backgroundColor: Color(0xFFFFF7ED),
                            textColor: Color(0xFF9A3412),
                          );
                        }

                        final classNames = docs
                            .map((doc) {
                              final data =
                                  doc.data() as Map<String, dynamic>;
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
                          decoration: _input(
                            'Sınıf Seç',
                            Icons.class_rounded,
                          ),
                          items: [
                            for (final className in classNames)
                              DropdownMenuItem(
                                value: className,
                                child: Text(className),
                              ),
                          ],
                          onChanged: onClassChanged,
                        );
                      },
                    ),
                  if (role == 'Veli')
                    TextField(
                      controller: linkedStudentController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(12),
                      ],
                      decoration: _input(
                        'Bağlı Öğrenci Numarası',
                        Icons.child_care_rounded,
                      ),
                    ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: isSaving ? null : onSave,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        isSaving ? 'Kaydediliyor...' : buttonText,
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

  InputDecoration _input(
    String label,
    IconData icon,
  ) {
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

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontWeight: FontWeight.w600,
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