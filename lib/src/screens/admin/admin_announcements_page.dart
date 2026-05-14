import 'package:flutter/material.dart';

import '../../core/app_helpers.dart';
import '../../core/app_theme.dart';
import '../../models/announcement_model.dart';
import '../../services/admin_school_service.dart';

class AdminAnnouncementsPage extends StatelessWidget {
  final Color accent;

  const AdminAnnouncementsPage({
    super.key,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final service = AdminSchoolService();

    return StreamBuilder<AdminSchoolData>(
      stream: service.watchAnnouncementsData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return _MessageCard(
            title: 'Hata oluştu',
            message: 'Duyurular yüklenirken hata oluştu.',
            accent: accent,
          );
        }

        final data = snapshot.data ??
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
                count: data.announcements.length,
                onAdd: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _AnnouncementSheet(
                      accent: accent,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              if (data.announcements.isEmpty)
                _MessageCard(
                  title: 'Duyuru yok',
                  message: 'Yeni duyuru oluşturarak başlayın.',
                  accent: accent,
                  embedded: true,
                )
              else
                ...data.announcements.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AnnouncementCard(
                      item: item,
                      accent: accent,
                      onDelete: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Duyuru silinsin mi?'),
                              content: Text(
                                '${item.title} duyurusu pasif hale getirilecek.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Vazgeç'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Sil'),
                                ),
                              ],
                            );
                          },
                        );

                        if (ok == true) {
                          await service.deleteAnnouncement(item);
                        }
                      },
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
  final Color accent;
  final int count;
  final VoidCallback onAdd;

  const _Hero({
    required this.accent,
    required this.count,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent,
            const Color(0xFF06B6D4),
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
                  Icons.campaign_rounded,
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
                      'Duyurular',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 25,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$count duyuru yayında.',
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
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_alert_rounded),
              label: const Text('Yeni Duyuru Oluştur'),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: accent,
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
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel item;
  final Color accent;
  final VoidCallback onDelete;

  const _AnnouncementCard({
    required this.item,
    required this.accent,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  Icons.notifications_active_rounded,
                  color: accent,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: AppTheme.dark,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.target} • ${AppHelpers.formatDate(item.createdAt)}',
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
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_rounded,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
              item.content,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w700,
                height: 1.45,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementSheet extends StatefulWidget {
  final Color accent;

  const _AnnouncementSheet({
    required this.accent,
  });

  @override
  State<_AnnouncementSheet> createState() => _AnnouncementSheetState();
}

class _AnnouncementSheetState extends State<_AnnouncementSheet> {
  final AdminSchoolService _service = AdminSchoolService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  String _target = 'Tüm Okul';
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      await _service.createAnnouncement(
        title: _titleController.text,
        content: _contentController.text,
        target: _target,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Duyuru oluşturuldu.'),
        ),
      );
    } on AdminSchoolException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Duyuru oluşturulurken hata oluştu.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final targets = [
      'Tüm Okul',
      'Öğrenci',
      'Öğretmen',
      'Veli',
      'Admin',
    ];

    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
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
                      Icons.add_alert_rounded,
                      color: widget.accent,
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Text(
                      'Yeni Duyuru Oluştur',
                      style: TextStyle(
                        color: AppTheme.dark,
                        fontWeight: FontWeight.w900,
                        fontSize: 21,
                        letterSpacing: -0.5,
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
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  hintText: 'Duyuru başlığı',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _target,
                items: targets
                    .map(
                      (x) => DropdownMenuItem(
                        value: x,
                        child: Text(x),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _target = value);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Hedef',
                  prefixIcon: Icon(Icons.track_changes_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'İçerik',
                  hintText: 'Duyuru metni',
                  prefixIcon: Icon(Icons.notes_rounded),
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
                          'Duyuruyu Yayınla',
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
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_rounded,
            color: accent,
            size: 42,
          ),
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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: card,
      ),
    );
  }
}