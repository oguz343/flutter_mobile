import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SubmissionsScreen extends StatefulWidget {
  const SubmissionsScreen({super.key});

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> updateSubmissionStatus(String id, String status) async {
    try {
      await firestore.collection('submissions').doc(id).update({
        'status': status,
        'checkedAt': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Teslim "$status" olarak güncellendi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teslim güncellenirken hata oluştu'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> deleteSubmission(String id) async {
    try {
      await firestore.collection('submissions').doc(id).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teslim silindi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teslim silinirken hata oluştu'),
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
                  const Text(
                    'Ödev Teslimleri',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Öğrencilerin gönderdiği ödev cevaplarını buradan kontrol edin.',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 26),
                  StreamBuilder<QuerySnapshot>(
                    stream: firestore
                        .collection('submissions')
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
                          title: 'Teslimler yüklenemedi',
                          description: 'Firestore bağlantısında bir sorun oluştu.',
                          color: Color(0xFFEF4444),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const _EmptyState(
                          icon: Icons.upload_file_rounded,
                          title: 'Henüz teslim yok',
                          description: 'Öğrenciler ödev teslim ettiğinde burada görünecek.',
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
                              child: _SubmissionCard(
                                id: doc.id,
                                data: doc.data() as Map<String, dynamic>,
                                onApprove: () => updateSubmissionStatus(
                                  doc.id,
                                  'Onaylandı',
                                ),
                                onReject: () => updateSubmissionStatus(
                                  doc.id,
                                  'Reddedildi',
                                ),
                                onDelete: () => deleteSubmission(doc.id),
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

class _SubmissionCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  const _SubmissionCard({
    required this.id,
    required this.data,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  Color get statusColor {
    final status = data['status']?.toString() ?? 'Teslim Edildi';

    if (status == 'Onaylandı') {
      return const Color(0xFF10B981);
    }

    if (status == 'Reddedildi') {
      return const Color(0xFFEF4444);
    }

    return const Color(0xFFF59E0B);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 520;

    final assignmentTitle = data['assignmentTitle']?.toString() ?? '-';
    final studentNo = data['studentNo']?.toString() ?? '-';
    final answer = data['answer']?.toString() ?? '';
    final link = data['link']?.toString() ?? '';
    final status = data['status']?.toString() ?? 'Teslim Edildi';

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
                  Icons.upload_file_rounded,
                  color: statusColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  assignmentTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _Line(Icons.numbers_rounded, 'Öğrenci No: $studentNo'),
          _Line(Icons.info_rounded, answer.isEmpty ? 'Metin cevap yok' : answer),
          _Line(Icons.link_rounded, link.isEmpty ? 'Link yok' : link),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w900,
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
              ],
            ),
        ],
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
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(icon, size: 19, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 3,
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