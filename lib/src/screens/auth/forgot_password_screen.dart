import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_helpers.dart';
import '../../core/app_theme.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _role = 'Öğrenci';
  bool _loading = false;
  String _error = '';
  String _success = '';

  final List<String> _roles = const [
    'Öğrenci',
    'Öğretmen',
    'Veli',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final number = AppHelpers.onlyDigits(_numberController.text);

    if (name.isEmpty) {
      setState(() {
        _error = 'Ad Soyad boş bırakılamaz.';
        _success = '';
      });
      return;
    }

    if (number.isEmpty) {
      setState(() {
        _error = 'Numara boş bırakılamaz.';
        _success = '';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
      _success = '';
    });

    try {
      await AuthService().sendPasswordRequest(
        role: _role,
        name: name,
        number: number,
        note: _noteController.text.trim(),
      );

      setState(() {
        _success =
            'Şifre talebin admine gönderildi. Admin onaylayınca geçici şifre verilecek.';
        _error = '';
      });
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
        _success = '';
      });
    } catch (_) {
      setState(() {
        _error = 'Talep gönderilirken hata oluştu.';
        _success = '';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(_role);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color,
              const Color(0xFF0F172A),
              const Color(0xFF020617),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 42,
                        offset: const Offset(0, 24),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const Spacer(),
                        ],
                      ),
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color,
                              AppTheme.cyan,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: AppTheme.coloredShadow(color),
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Şifremi Unuttum',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.dark,
                          fontWeight: FontWeight.w900,
                          fontSize: 27,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ad Soyad, rol ve numara uyuşursa talep admine gider. Not alanı isteğe bağlıdır.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.muted,
                          fontWeight: FontWeight.w800,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_error.isNotEmpty) ...[
                        _StateBox(
                          text: _error,
                          success: false,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (_success.isNotEmpty) ...[
                        _StateBox(
                          text: _success,
                          success: true,
                        ),
                        const SizedBox(height: 14),
                      ],
                      DropdownButtonFormField<String>(
                        value: _role,
                        items: _roles
                            .map(
                              (x) => DropdownMenuItem(
                                value: x,
                                child: Text(x),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _role = value;
                              _error = '';
                              _success = '';
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Rol',
                          prefixIcon: Icon(Icons.badge_rounded),
                        ),
                      ),
                      const SizedBox(height: 13),
                      TextField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Ad Soyad',
                          hintText: 'Sistemde kayıtlı ad soyad',
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                      ),
                      const SizedBox(height: 13),
                      TextField(
                        controller: _numberController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Numara',
                          hintText: 'Okul / kullanıcı numarası',
                          prefixIcon: Icon(Icons.tag_rounded),
                        ),
                      ),
                      const SizedBox(height: 13),
                      TextField(
                        controller: _noteController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Not',
                          hintText: 'İsteğe bağlı',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _send,
                          icon: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            _loading ? 'Gönderiliyor...' : 'Talep Gönder',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
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
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    final key = AppHelpers.normalizeKey(role);

    if (key == 'ogrenci') {
      return AppTheme.green;
    }

    if (key == 'ogretmen') {
      return AppTheme.cyan;
    }

    if (key == 'veli') {
      return AppTheme.orange;
    }

    return AppTheme.purple;
  }
}

class _StateBox extends StatelessWidget {
  final String text;
  final bool success;

  const _StateBox({
    required this.text,
    required this.success,
  });

  @override
  Widget build(BuildContext context) {
    final color = success ? AppTheme.green : AppTheme.red;
    final bg = success ? const Color(0xFFECFDF5) : const Color(0xFFFEE2E2);
    final border = success ? const Color(0xFFA7F3D0) : const Color(0xFFFCA5A5);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}