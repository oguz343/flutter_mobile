import 'package:flutter/material.dart';

import '../../core/app_helpers.dart';
import '../../core/app_theme.dart';
import '../../services/admin_service.dart';
import '../../services/admin_user_service.dart';

class AdminPasswordRequestsPage extends StatelessWidget {
  final Color accent;

  const AdminPasswordRequestsPage({
    super.key,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final adminService = AdminService();

    return StreamBuilder<AdminDashboardBundle>(
      stream: adminService.watchDashboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return _MessageCard(
            title: 'Hata oluştu',
            message: 'Şifre talepleri yüklenirken hata oluştu.',
            accent: accent,
          );
        }

        final data = snapshot.data ??
            const AdminDashboardBundle(
              users: [],
              students: [],
              teachers: [],
              parents: [],
              admins: [],
              classes: [],
              lessons: [],
              announcements: [],
              submissions: [],
              passwordRequests: [],
            );

        final requests = data.passwordRequests;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            children: [
              _Hero(
                accent: accent,
                count: data.pendingPasswordRequestCount,
              ),
              const SizedBox(height: 16),
              if (requests.isEmpty)
                _MessageCard(
                  title: 'Şifre talebi yok',
                  message: 'Kullanıcılar talep gönderdiğinde burada görünecek.',
                  accent: accent,
                  embedded: true,
                )
              else
                ...requests.map(
                  (request) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RequestCard(
                      request: request,
                      accent: accent,
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

  const _Hero({
    required this.accent,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final text = count == 0
        ? 'Bekleyen talep bulunmuyor.'
        : '$count bekleyen talep var.';

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
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(23),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
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
                  'Şifre Talepleri',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 25,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
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
    );
  }
}

class _RequestCard extends StatefulWidget {
  final PasswordRequestModel request;
  final Color accent;

  const _RequestCard({
    required this.request,
    required this.accent,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  final AdminUserService _service = AdminUserService();

  bool _loading = false;

  Future<void> _approve() async {
    setState(() => _loading = true);

    try {
      final newPassword = await _service.approvePasswordRequest(widget.request);

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Talep onaylandı'),
            content: Text(
              'Yeni geçici şifre: $newPassword\n\nKullanıcı bu şifreyle giriş yapıp yeni şifre belirleyecek.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tamam'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception:', '').trim(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _reject() async {
    setState(() => _loading = true);

    try {
      await _service.rejectPasswordRequest(widget.request);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Talep reddedildi.'),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Talep reddedilirken hata oluştu.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final pending = request.isPending;
    final color = pending ? const Color(0xFFEF4444) : const Color(0xFF10B981);

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
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Icon(
                  Icons.lock_reset_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.name,
                      style: const TextStyle(
                        color: AppTheme.dark,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${request.role} • No: ${request.number}',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _Pill(
                text: request.status,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniChip(
                text: AppHelpers.formatDate(request.createdAt),
                icon: Icons.schedule_rounded,
                color: widget.accent,
              ),
              if (request.note.trim().isNotEmpty)
                _MiniChip(
                  text: request.note,
                  icon: Icons.notes_rounded,
                  color: const Color(0xFFF59E0B),
                ),
            ],
          ),
          if (pending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _reject,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Reddet'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(
                          color: Color(0xFFFCA5A5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _approve,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Onayla'),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: widget.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
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

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _MiniChip({
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
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