import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AnnouncementsScreen extends StatefulWidget {
  final String role;
  final String name;

  const AnnouncementsScreen({
    super.key,
    required this.role,
    required this.name,
  });

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool get isAdmin => normalizeText(widget.role) == 'admin';

  String normalizeText(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  bool canSeeAnnouncement({
    required String userRole,
    required String target,
  }) {
    final role = normalizeText(userRole);
    final targetText = normalizeText(target);

    if (role == 'admin') return true;

    if (targetText == 'tum okul' ||
        targetText == 'herkes' ||
        targetText == 'all') {
      return true;
    }

    if (role == 'ogrenci' &&
        (targetText == 'ogrenciler' || targetText == 'ogrenci')) {
      return true;
    }

    if (role == 'ogretmen' &&
        (targetText == 'ogretmenler' || targetText == 'ogretmen')) {
      return true;
    }

    if (role == 'veli' &&
        (targetText == 'veliler' || targetText == 'veli')) {
      return true;
    }

    return false;
  }

  void openCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnnouncementFormSheet(
        author: widget.name.isEmpty ? 'Admin' : widget.name,
      ),
    );
  }

  void openEditSheet(String id, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnnouncementFormSheet(
        announcementId: id,
        author: widget.name.isEmpty ? 'Admin' : widget.name,
        initialTitle: data['title']?.toString() ?? '',
        initialContent: data['content']?.toString() ?? '',
        initialTarget: data['target']?.toString() ?? 'Tüm Okul',
      ),
    );
  }

  Future<void> deleteAnnouncement(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Duyuru silinsin mi?'),
          content: const Text(
            'Bu işlem geri alınamaz. Duyuruyu silmek istediğine emin misin?',
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
      await firestore.collection('announcements').doc(id).delete();

      if (!mounted) return;

      showMessage('Duyuru silindi.');
    } catch (e) {
      showMessage('Duyuru silinirken hata oluştu.', isError: true);
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

  Color targetColor(String target) {
    final normalized = normalizeText(target);

    if (normalized == 'ogretmenler' || normalized == 'ogretmen') {
      return const Color(0xFF06B6D4);
    }

    if (normalized == 'ogrenciler' || normalized == 'ogrenci') {
      return const Color(0xFF4F46E5);
    }

    if (normalized == 'veliler' || normalized == 'veli') {
      return const Color(0xFFF59E0B);
    }

    return const Color(0xFF10B981);
  }

  IconData targetIcon(String target) {
    final normalized = normalizeText(target);

    if (normalized == 'ogretmenler' || normalized == 'ogretmen') {
      return Icons.person_rounded;
    }

    if (normalized == 'ogrenciler' || normalized == 'ogrenci') {
      return Icons.school_rounded;
    }

    if (normalized == 'veliler' || normalized == 'veli') {
      return Icons.family_restroom_rounded;
    }

    return Icons.campaign_rounded;
  }

  String pageSubtitle() {
    final role = normalizeText(widget.role);

    if (role == 'admin') {
      return 'Tüm duyuruları yönetin.';
    }

    if (role == 'ogretmen') {
      return 'Size ve tüm okula gönderilen duyurular.';
    }

    if (role == 'ogrenci') {
      return 'Size ve tüm okula gönderilen duyurular.';
    }

    if (role == 'veli') {
      return 'Size ve tüm okula gönderilen duyurular.';
    }

    return 'Duyuruları görüntüleyin.';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: openCreateSheet,
              backgroundColor: const Color(0xFF4F46E5),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Duyuru Ekle'),
            )
          : null,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Duyurular',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pageSubtitle(),
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (isAdmin)
                    FilledButton.icon(
                      onPressed: openCreateSheet,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Yeni Duyuru'),
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
              const SizedBox(height: 22),
              StreamBuilder<QuerySnapshot>(
                stream: firestore
                    .collection('announcements')
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
                      title: 'Duyurular yüklenemedi',
                      description: 'Firestore bağlantısında bir sorun oluştu.',
                      color: Color(0xFFEF4444),
                    );
                  }

                  final allDocs = snapshot.data?.docs ?? [];

                  final visibleDocs = allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final target = data['target']?.toString() ?? 'Tüm Okul';

                    return canSeeAnnouncement(
                      userRole: widget.role,
                      target: target,
                    );
                  }).toList();

                  if (visibleDocs.isEmpty) {
                    return _EmptyState(
                      icon: Icons.campaign_rounded,
                      title: 'Gösterilecek duyuru yok',
                      description: isAdmin
                          ? 'Yeni duyuru oluşturarak başlayabilirsiniz.'
                          : 'Size uygun duyuru olduğunda burada görünecek.',
                      color: const Color(0xFF4F46E5),
                    );
                  }

                  if (isSmall) {
                    return Column(
                      children: [
                        for (final doc in visibleDocs) ...[
                          Builder(
                            builder: (context) {
                              final data = doc.data() as Map<String, dynamic>;
                              final target =
                                  data['target']?.toString() ?? 'Tüm Okul';

                              return _AnnouncementCard(
                                title: data['title']?.toString() ?? 'Duyuru',
                                content: data['content']?.toString() ?? '',
                                author: data['author']?.toString() ?? 'Admin',
                                target: target,
                                color: targetColor(target),
                                icon: targetIcon(target),
                                isAdmin: isAdmin,
                                onEdit: () => openEditSheet(doc.id, data),
                                onDelete: () => deleteAnnouncement(doc.id),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visibleDocs.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 430,
                      mainAxisExtent: 305,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                    ),
                    itemBuilder: (context, index) {
                      final doc = visibleDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final target = data['target']?.toString() ?? 'Tüm Okul';

                      return _AnnouncementCard(
                        title: data['title']?.toString() ?? 'Duyuru',
                        content: data['content']?.toString() ?? '',
                        author: data['author']?.toString() ?? 'Admin',
                        target: target,
                        color: targetColor(target),
                        icon: targetIcon(target),
                        isAdmin: isAdmin,
                        onEdit: () => openEditSheet(doc.id, data),
                        onDelete: () => deleteAnnouncement(doc.id),
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

class AnnouncementFormSheet extends StatefulWidget {
  final String? announcementId;
  final String author;
  final String initialTitle;
  final String initialContent;
  final String initialTarget;

  const AnnouncementFormSheet({
    super.key,
    this.announcementId,
    required this.author,
    this.initialTitle = '',
    this.initialContent = '',
    this.initialTarget = 'Tüm Okul',
  });

  @override
  State<AnnouncementFormSheet> createState() => _AnnouncementFormSheetState();
}

class _AnnouncementFormSheetState extends State<AnnouncementFormSheet> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  late TextEditingController titleController;
  late TextEditingController contentController;

  String target = 'Tüm Okul';
  bool isSaving = false;

  bool get isEdit => widget.announcementId != null;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.initialTitle);
    contentController = TextEditingController(text: widget.initialContent);

    final allowedTargets = [
      'Tüm Okul',
      'Öğrenciler',
      'Öğretmenler',
      'Veliler',
    ];

    target = allowedTargets.contains(widget.initialTarget)
        ? widget.initialTarget
        : 'Tüm Okul';
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  Future<void> saveAnnouncement() async {
    if (isSaving) return;

    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (title.isEmpty) {
      showMessage('Duyuru başlığı boş bırakılamaz.', isError: true);
      return;
    }

    if (content.isEmpty) {
      showMessage('Duyuru içeriği boş bırakılamaz.', isError: true);
      return;
    }

    setState(() => isSaving = true);

    try {
      if (isEdit) {
        await firestore
            .collection('announcements')
            .doc(widget.announcementId)
            .update({
          'title': title,
          'content': content,
          'target': target,
          'author': widget.author.isEmpty ? 'Admin' : widget.author,
          'updatedAt': Timestamp.now(),
        });
      } else {
        await firestore.collection('announcements').add({
          'title': title,
          'content': content,
          'target': target,
          'author': widget.author.isEmpty ? 'Admin' : widget.author,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Duyuru güncellendi.' : 'Duyuru yayınlandı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      showMessage('Duyuru kaydedilirken hata oluştu.', isError: true);
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
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(32),
          ),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Duyuru Düzenle' : 'Yeni Duyuru',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Hedef kitle seçimine göre duyuru sadece ilgili role görünür.',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    decoration: _input(
                      'Başlık',
                      Icons.title_rounded,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: target,
                    decoration: _input(
                      'Hedef Kitle',
                      Icons.groups_rounded,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Tüm Okul',
                        child: Text('Tüm Okul'),
                      ),
                      DropdownMenuItem(
                        value: 'Öğrenciler',
                        child: Text('Öğrenciler'),
                      ),
                      DropdownMenuItem(
                        value: 'Öğretmenler',
                        child: Text('Öğretmenler'),
                      ),
                      DropdownMenuItem(
                        value: 'Veliler',
                        child: Text('Veliler'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        target = value ?? 'Tüm Okul';
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: contentController,
                    minLines: 5,
                    maxLines: 8,
                    decoration: _input(
                      'Duyuru İçeriği',
                      Icons.notes_rounded,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: isSaving ? null : saveAnnouncement,
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
                        isSaving
                            ? 'Kaydediliyor...'
                            : isEdit
                                ? 'Duyuruyu Güncelle'
                                : 'Duyuruyu Yayınla',
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

class _AnnouncementCard extends StatelessWidget {
  final String title;
  final String content;
  final String author;
  final String target;
  final Color color;
  final IconData icon;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AnnouncementCard({
    required this.title,
    required this.content,
    required this.author,
    required this.target,
    required this.color,
    required this.icon,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? 'Duyuru' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      author.isEmpty ? 'Admin' : author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              target,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            content.isEmpty ? '-' : content,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Düzenle'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
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
            textAlign: TextAlign.center,
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