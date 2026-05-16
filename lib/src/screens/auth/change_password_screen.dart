import 'package:flutter/material.dart';

import '../../core/app_helpers.dart';
import '../../core/app_session.dart';
import '../../core/app_theme.dart';
import '../../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _againController = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String _error = '';

  @override
  void dispose() {
    _passwordController.dispose();
    _againController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final user = AppSession.currentUser;

    if (user == null) {
      setState(() => _error = 'Oturum bulunamadı. Tekrar giriş yapın.');
      return;
    }

    final password = _passwordController.text.trim();
    final again = _againController.text.trim();

    if (password.isEmpty || again.isEmpty) {
      setState(() => _error = 'Şifre alanları boş bırakılamaz.');
      return;
    }

    if (password.length < 4) {
      setState(() => _error = 'Yeni şifre en az 4 karakter olmalı.');
      return;
    }

    if (password != again) {
      setState(() => _error = 'Şifreler eşleşmiyor.');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final updated = await AuthService().changePassword(
        user: user,
        newPassword: password,
      );

      AppSession.setUser(updated);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppHelpers.roleRoute(updated.role),
        (route) => false,
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Şifre değiştirilirken hata oluştu.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AppSession.currentUser;
    final role = user?.role ?? 'Kullanıcı';
    final color = _roleColor(role);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, const Color(0xFF0F172A), const Color(0xFF020617)],
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
                constraints: const BoxConstraints(maxWidth: 470),
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
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, AppTheme.cyan],
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
                        'Yeni Şifre Belirle',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.dark,
                          fontWeight: FontWeight.w900,
                          fontSize: 27,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Güvenlik için ilk girişte şifreni değiştirmen gerekiyor.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.muted,
                          fontWeight: FontWeight.w800,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_error.isNotEmpty) ...[
                        _ErrorBox(text: _error),
                        const SizedBox(height: 14),
                      ],
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Yeni Şifre',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => _obscure = !_obscure);
                            },
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 13),
                      TextField(
                        controller: _againController,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _loading ? null : _save(),
                        decoration: const InputDecoration(
                          labelText: 'Yeni Şifre Tekrar',
                          prefixIcon: Icon(Icons.verified_user_rounded),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _save,
                          icon: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(
                            _loading ? 'Kaydediliyor...' : 'Şifreyi Kaydet',
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

class _ErrorBox extends StatelessWidget {
  final String text;

  const _ErrorBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF991B1B),
          fontWeight: FontWeight.w900,
          fontSize: 12.5,
        ),
      ),
    );
  }
}
