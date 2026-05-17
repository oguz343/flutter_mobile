import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../services/admin_service.dart';

class AdminPasswordPage extends StatefulWidget {
  final Color accent;

  const AdminPasswordPage({super.key, required this.accent});

  @override
  State<AdminPasswordPage> createState() => _AdminPasswordPageState();
}

class _AdminPasswordPageState extends State<AdminPasswordPage> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _repeatController = TextEditingController();
  final _service = AdminService();

  bool _loading = false;
  bool _currentObscure = true;
  bool _newObscure = true;
  bool _repeatObscure = true;
  String _error = '';
  String _success = '';

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _repeatController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = '';
      _success = '';
    });

    try {
      await _service.changeAdminPassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
        repeatPassword: _repeatController.text,
      );

      _currentController.clear();
      _newController.clear();
      _repeatController.clear();

      if (!mounted) {
        return;
      }

      setState(() {
        _success = 'Admin şifresi başarıyla güncellendi.';
      });
    } on AdminServiceException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Şifre güncellenirken hata oluştu.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SecurityHero(accent: widget.accent),
              const SizedBox(height: 14),
              if (_success.isNotEmpty) ...[
                _StatusBox(
                  text: _success,
                  icon: Icons.check_circle_rounded,
                  color: AppTheme.green,
                ),
                const SizedBox(height: 12),
              ],
              if (_error.isNotEmpty) ...[
                _StatusBox(
                  text: _error,
                  icon: Icons.error_outline_rounded,
                  color: AppTheme.red,
                ),
                const SizedBox(height: 12),
              ],
              _PasswordCard(
                accent: widget.accent,
                loading: _loading,
                currentController: _currentController,
                newController: _newController,
                repeatController: _repeatController,
                currentObscure: _currentObscure,
                newObscure: _newObscure,
                repeatObscure: _repeatObscure,
                onToggleCurrent: () {
                  setState(() => _currentObscure = !_currentObscure);
                },
                onToggleNew: () {
                  setState(() => _newObscure = !_newObscure);
                },
                onToggleRepeat: () {
                  setState(() => _repeatObscure = !_repeatObscure);
                },
                onSave: _save,
              ),
              const SizedBox(height: 14),
              _InfoNote(accent: widget.accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityHero extends StatelessWidget {
  final Color accent;

  const _SecurityHero({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.line),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, AppTheme.cyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 31,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Şifresi',
                  style: TextStyle(
                    color: AppTheme.dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Panel güvenliği için admin şifresini buradan güncelleyin.',
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
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

class _PasswordCard extends StatelessWidget {
  final Color accent;
  final bool loading;
  final TextEditingController currentController;
  final TextEditingController newController;
  final TextEditingController repeatController;
  final bool currentObscure;
  final bool newObscure;
  final bool repeatObscure;
  final VoidCallback onToggleCurrent;
  final VoidCallback onToggleNew;
  final VoidCallback onToggleRepeat;
  final VoidCallback onSave;

  const _PasswordCard({
    required this.accent,
    required this.loading,
    required this.currentController,
    required this.newController,
    required this.repeatController,
    required this.currentObscure,
    required this.newObscure,
    required this.repeatObscure,
    required this.onToggleCurrent,
    required this.onToggleNew,
    required this.onToggleRepeat,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.line),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          _PasswordField(
            controller: currentController,
            obscure: currentObscure,
            label: 'Mevcut Şifre',
            hint: 'Mevcut admin şifresi',
            icon: Icons.lock_clock_rounded,
            onToggle: onToggleCurrent,
            action: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _PasswordField(
            controller: newController,
            obscure: newObscure,
            label: 'Yeni Şifre',
            hint: 'En az 6 karakter',
            icon: Icons.lock_reset_rounded,
            onToggle: onToggleNew,
            action: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _PasswordField(
            controller: repeatController,
            obscure: repeatObscure,
            label: 'Yeni Şifre Tekrar',
            hint: 'Yeni şifreyi tekrar yazın',
            icon: Icons.verified_user_rounded,
            onToggle: onToggleRepeat,
            action: TextInputAction.done,
            onSubmitted: (_) => loading ? null : onSave(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: loading ? null : onSave,
              icon: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(loading ? 'Güncelleniyor...' : 'Şifreyi Güncelle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
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

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final String label;
  final String hint;
  final IconData icon;
  final VoidCallback onToggle;
  final TextInputAction action;
  final ValueChanged<String>? onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onToggle,
    required this.action,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: action,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
          ),
        ),
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _StatusBox({
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  final Color accent;

  const _InfoNote({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_rounded, color: accent, size: 21),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Şifre değiştikten sonra eski admin şifresiyle giriş yapılamaz.',
              style: TextStyle(
                color: AppTheme.dark,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
