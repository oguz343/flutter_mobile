import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PasswordRequestsScreen extends StatefulWidget {
  const PasswordRequestsScreen({super.key});

  @override
  State<PasswordRequestsScreen> createState() => _PasswordRequestsScreenState();
}

class _PasswordRequestsScreenState extends State<PasswordRequestsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> updateRequestStatus(String id, String status) async {
    try {
      await firestore.collection('password_requests').doc(id).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Talep $status olarak güncellendi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      showMessage('Talep güncellenirken hata oluştu', isError: true);
    }
  }

  Future<void> deleteRequest(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Talep silinsin mi?'),
          content: const Text(
            'Bu şifre talebi silinecek. Bu işlem geri alınamaz.',
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
      await firestore.collection('password_requests').doc(id).delete();

      if (!mounted) return;

      showMessage('Talep silindi');
    } catch (e) {
      showMessage('Talep silinirken hata oluştu', isError: true);
    }
  }

  void openAddRequestSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddPasswordRequestSheet(),
    );
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
                            'Şifre Talepleri',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Şifre sıfırlama isteklerini yönetin.',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        onPressed: openAddRequestSheet,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Test Talebi Ekle'),
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
                        .collection('password_requests')
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
                          title: 'Talepler yüklenemedi',
                          description:
                              'Firestore bağlantısında bir sorun oluştu.',
                          color: Color(0xFFEF4444),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const _EmptyState(
                          icon: Icons.lock_reset_rounded,
                          title: 'Henüz şifre talebi yok',
                          description:
                              'Şifre sıfırlama talepleri burada görünecek.',
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
                              child: _RequestCard(
                                id: doc.id,
                                data: doc.data() as Map<String, dynamic>,
                                onApprove: () => updateRequestStatus(
                                  doc.id,
                                  'Onaylandı',
                                ),
                                onReject: () => updateRequestStatus(
                                  doc.id,
                                  'Reddedildi',
                                ),
                                onDelete: () => deleteRequest(doc.id),
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

class _RequestCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  const _RequestCard({
    required this.id,
    required this.data,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  Color get statusColor {
    final status = data['status']?.toString() ?? 'Bekliyor';

    if (status == 'Onaylandı') return const Color(0xFF10B981);
    if (status == 'Reddedildi') return const Color(0xFFEF4444);

    return const Color(0xFFF59E0B);
  }

  IconData get roleIcon {
    final role = data['role']?.toString() ?? '';

    if (role == 'Öğretmen') return Icons.person_rounded;
    if (role == 'Veli') return Icons.family_restroom_rounded;

    return Icons.school_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 520;

    final name = data['name']?.toString() ?? 'Bilinmeyen Kullanıcı';
    final number = data['number']?.toString() ??
        data['schoolNo']?.toString() ??
        data['userNo']?.toString() ??
        '-';
    final role = data['role']?.toString() ?? 'Öğrenci';
    final status = data['status']?.toString() ?? 'Bekliyor';
    final note =
        data['note']?.toString() ?? 'Şifre sıfırlama talebi oluşturuldu.';

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
                backgroundColor: statusColor.withValues(alpha: 0.12),
                child: Icon(
                  roleIcon,
                  color: statusColor,
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
                  if (value == 'approve') onApprove();
                  if (value == 'reject') onReject();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'approve',
                    child: Text('Onayla'),
                  ),
                  PopupMenuItem(
                    value: 'reject',
                    child: Text('Reddet'),
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
          _Line(Icons.badge_rounded, 'No: $number'),
          _Line(Icons.person_rounded, 'Rol: $role'),
          _Line(Icons.info_rounded, note),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (isMobile)
            Column(
              children: [
                _ActionButton(
                  title: 'Onayla',
                  icon: Icons.check_rounded,
                  color: const Color(0xFF10B981),
                  onPressed: status == 'Onaylandı' ? null : onApprove,
                ),
                const SizedBox(height: 10),
                _ActionButton(
                  title: 'Reddet',
                  icon: Icons.close_rounded,
                  color: const Color(0xFFEF4444),
                  onPressed: status == 'Reddedildi' ? null : onReject,
                ),
                const SizedBox(height: 10),
                _ActionButton(
                  title: 'Sil',
                  icon: Icons.delete_rounded,
                  color: const Color(0xFF6B7280),
                  onPressed: onDelete,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    title: 'Onayla',
                    icon: Icons.check_rounded,
                    color: const Color(0xFF10B981),
                    onPressed: status == 'Onaylandı' ? null : onApprove,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    title: 'Reddet',
                    icon: Icons.close_rounded,
                    color: const Color(0xFFEF4444),
                    onPressed: status == 'Reddedildi' ? null : onReject,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    title: 'Sil',
                    icon: Icons.delete_rounded,
                    color: const Color(0xFF6B7280),
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AddPasswordRequestSheet extends StatefulWidget {
  const _AddPasswordRequestSheet();

  @override
  State<_AddPasswordRequestSheet> createState() =>
      _AddPasswordRequestSheetState();
}

class _AddPasswordRequestSheetState extends State<_AddPasswordRequestSheet> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  String role = 'Öğrenci';
  bool isSaving = false;

  @override
  void dispose() {
    nameController.dispose();
    numberController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> saveRequest() async {
    if (isSaving) return;

    final name = nameController.text.trim();
    final number = numberController.text.trim();
    final note = noteController.text.trim();

    if (name.isEmpty) {
      showMessage('Ad soyad boş bırakılamaz.', isError: true);
      return;
    }

    if (number.isEmpty) {
      showMessage('Numara boş bırakılamaz.', isError: true);
      return;
    }

    setState(() => isSaving = true);

    try {
      await firestore.collection('password_requests').add({
        'name': name,
        'number': number,
        'role': role,
        'status': 'Bekliyor',
        'note': note.isEmpty ? 'Şifre sıfırlama talebi oluşturuldu.' : note,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifre talebi Firebase’e kaydedildi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      showMessage('Talep kaydedilirken hata oluştu.', isError: true);
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
                    'Şifre Talebi Oluştur',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: _input('Rol', Icons.badge_rounded),
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
                      setState(() {
                        role = v ?? 'Öğrenci';
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameController,
                    decoration: _input('Ad Soyad', Icons.person_rounded),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: numberController,
                    keyboardType: TextInputType.number,
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
                    controller: noteController,
                    maxLines: 4,
                    decoration: _input(
                      'Açıklama',
                      Icons.description_rounded,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: isSaving ? null : saveRequest,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        isSaving ? 'Kaydediliyor...' : 'Talebi Kaydet',
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

class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(title),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: const Color(0xFF9CA3AF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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