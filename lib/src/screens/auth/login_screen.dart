import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_helpers.dart';
import '../../core/app_session.dart';
import '../../core/app_theme.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();

  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final AnimationController _ambientController;
  late final AnimationController _panelController;

  String _role = 'Öğrenci';
  bool _loading = false;
  bool _obscure = true;
  String _error = '';

  final List<_RoleOption> _roles = const [
    _RoleOption(
      label: 'Öğrenci',
      icon: Icons.backpack_rounded,
      gradient: [
        Color(0xFF10B981),
        Color(0xFF06B6D4),
      ],
    ),
    _RoleOption(
      label: 'Öğretmen',
      icon: Icons.co_present_rounded,
      gradient: [
        Color(0xFF06B6D4),
        Color(0xFF2563EB),
      ],
    ),
    _RoleOption(
      label: 'Veli',
      icon: Icons.family_restroom_rounded,
      gradient: [
        Color(0xFFF59E0B),
        Color(0xFFF97316),
      ],
    ),
    _RoleOption(
      label: 'Admin',
      icon: Icons.admin_panel_settings_rounded,
      gradient: [
        Color(0xFF4F46E5),
        Color(0xFF9333EA),
      ],
    ),
  ];

  _RoleOption get _selectedRole {
    return _roles.firstWhere(
      (x) => x.label == _role,
      orElse: () => _roles.first,
    );
  }

  @override
  void initState() {
    super.initState();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _panelController.dispose();
    _numberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final result = await _authService.login(
        role: _role,
        number: _numberController.text,
        password: _passwordController.text,
      );

      AppSession.setUser(result.user);

      if (!mounted) {
        return;
      }

      if (result.requiresPasswordChange) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/change-password',
          (route) => false,
        );
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppHelpers.roleRoute(result.user.role),
        (route) => false,
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(
        () => _error = 'Giriş yapılırken hata oluştu. Bilgileri kontrol et.',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = _selectedRole;
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 760;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _ambientController,
        builder: (context, _) {
          final t = _ambientController.value * pi * 2;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(
                    role.gradient.first,
                    const Color(0xFF020617),
                    0.10,
                  )!,
                  const Color(0xFF0F172A),
                  Color.lerp(
                    role.gradient.last,
                    const Color(0xFF020617),
                    0.15,
                  )!,
                ],
                begin: Alignment(
                  cos(t) * 0.7,
                  sin(t) * 0.7,
                ),
                end: Alignment(
                  -cos(t) * 0.7,
                  -sin(t) * 0.7,
                ),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: -90 + sin(t) * 28,
                  top: 80 + cos(t) * 18,
                  child: _GlowBlob(
                    color: role.gradient.first,
                    size: compact ? 220 : 340,
                  ),
                ),
                Positioned(
                  right: -110 + cos(t) * 24,
                  bottom: 110 + sin(t) * 18,
                  child: _GlowBlob(
                    color: role.gradient.last,
                    size: compact ? 260 : 390,
                  ),
                ),
                Positioned(
                  top: -80,
                  right: size.width * 0.22,
                  child: _GlowBlob(
                    color: Colors.white,
                    size: compact ? 150 : 240,
                    opacity: 0.08,
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        compact ? 16 : 34,
                        18,
                        compact ? 16 : 34,
                        24,
                      ),
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _panelController,
                          curve: Curves.easeOut,
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _panelController,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 1100,
                            ),
                            child: compact
                                ? Column(
                                    children: [
                                      _BrandPanel(
                                        role: role,
                                        compact: true,
                                      ),
                                      const SizedBox(height: 16),
                                      _LoginCard(
                                        roles: _roles,
                                        role: _role,
                                        selectedRole: role,
                                        numberController: _numberController,
                                        passwordController:
                                            _passwordController,
                                        loading: _loading,
                                        obscure: _obscure,
                                        error: _error,
                                        onRoleChanged: (value) {
                                          setState(() {
                                            _role = value;
                                            _error = '';
                                            _numberController.clear();
                                            _passwordController.clear();
                                          });
                                        },
                                        onToggleObscure: () {
                                          setState(() => _obscure = !_obscure);
                                        },
                                        onLogin: _login,
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: _BrandPanel(
                                          role: role,
                                          compact: false,
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      SizedBox(
                                        width: 440,
                                        child: _LoginCard(
                                          roles: _roles,
                                          role: _role,
                                          selectedRole: role,
                                          numberController: _numberController,
                                          passwordController:
                                              _passwordController,
                                          loading: _loading,
                                          obscure: _obscure,
                                          error: _error,
                                          onRoleChanged: (value) {
                                            setState(() {
                                              _role = value;
                                              _error = '';
                                              _numberController.clear();
                                              _passwordController.clear();
                                            });
                                          },
                                          onToggleObscure: () {
                                            setState(
                                              () => _obscure = !_obscure,
                                            );
                                          },
                                          onLogin: _login,
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
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  final _RoleOption role;
  final bool compact;

  const _BrandPanel({
    required this.role,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 22 : 34),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: compact ? 0.10 : 0.08),
        borderRadius: BorderRadius.circular(38),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBrand(role: role),
          SizedBox(height: compact ? 28 : 54),
          Text(
            'Ödev Sistemi',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 38 : 58,
              height: 0.95,
              letterSpacing: -2.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Öğrenci, öğretmen, veli ve admin için tek merkezli premium okul yönetim deneyimi.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
              fontSize: compact ? 14 : 17,
              height: 1.55,
            ),
          ),
          SizedBox(height: compact ? 24 : 42),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _FeaturePill(
                icon: Icons.swipe_rounded,
                text: 'Swipe panel',
              ),
              _FeaturePill(
                icon: Icons.flash_on_rounded,
                text: 'Canlı veri',
              ),
              _FeaturePill(
                icon: Icons.security_rounded,
                text: 'Rol güvenliği',
              ),
              _FeaturePill(
                icon: Icons.auto_awesome_rounded,
                text: 'Premium arayüz',
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 44),
            Row(
              children: [
                _MiniMetric(
                  value: '4',
                  label: 'Rol',
                  color: role.gradient.first,
                ),
                const SizedBox(width: 12),
                _MiniMetric(
                  value: '∞',
                  label: 'Canlı takip',
                  color: role.gradient.last,
                ),
                const SizedBox(width: 12),
                _MiniMetric(
                  value: '100%',
                  label: 'Mobil',
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TopBrand extends StatelessWidget {
  final _RoleOption role;

  const _TopBrand({
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: role.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: role.gradient.first.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Icon(
            role.icon,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Okul Yönetimi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${role.label} girişi hazır',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  final List<_RoleOption> roles;
  final String role;
  final _RoleOption selectedRole;
  final TextEditingController numberController;
  final TextEditingController passwordController;
  final bool loading;
  final bool obscure;
  final String error;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onToggleObscure;
  final VoidCallback onLogin;

  const _LoginCard({
    required this.roles,
    required this.role,
    required this.selectedRole,
    required this.numberController,
    required this.passwordController,
    required this.loading,
    required this.obscure,
    required this.error,
    required this.onRoleChanged,
    required this.onToggleObscure,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = AppHelpers.normalizeKey(role) == 'admin';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(38),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 44,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LoginHeader(role: selectedRole),
          const SizedBox(height: 18),
          _RoleGrid(
            roles: roles,
            selected: role,
            onChanged: onRoleChanged,
          ),
          const SizedBox(height: 18),
          if (error.isNotEmpty) ...[
            _ErrorBanner(text: error),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: numberController,
            keyboardType: isAdmin ? TextInputType.text : TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: isAdmin
                ? null
                : [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
            decoration: InputDecoration(
              labelText: isAdmin ? 'Admin No' : 'Numara',
              hintText: isAdmin ? '0000' : 'Okul / kullanıcı numarası',
              prefixIcon: const Icon(Icons.tag_rounded),
            ),
          ),
          const SizedBox(height: 13),
          TextField(
            controller: passwordController,
            obscureText: obscure,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => loading ? null : onLogin(),
            decoration: InputDecoration(
              labelText: 'Şifre',
              hintText: 'Şifrenizi yazın',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscure
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: loading
                  ? null
                  : () {
                      Navigator.of(context).pushNamed('/forgot-password');
                    },
              icon: const Icon(Icons.help_outline_rounded, size: 18),
              label: const Text('Şifremi unuttum'),
              style: TextButton.styleFrom(
                foregroundColor: selectedRole.gradient.first,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: selectedRole.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: selectedRole.gradient.first.withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: loading ? null : onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.7,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login_rounded),
                          SizedBox(width: 10),
                          Text(
                            'Giriş Yap',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SecurityNote(color: selectedRole.gradient.first),
        ],
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  final _RoleOption role;

  const _LoginHeader({
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: role.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            role.icon,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Giriş Paneli',
                style: TextStyle(
                  color: AppTheme.dark,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${role.label} hesabınızla devam edin.',
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleGrid extends StatelessWidget {
  final List<_RoleOption> roles;
  final String selected;
  final ValueChanged<String> onChanged;

  const _RoleGrid({
    required this.roles,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: roles.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.35,
      ),
      itemBuilder: (context, index) {
        final role = roles[index];
        final active = role.label == selected;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(
                    colors: role.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: active ? null : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? Colors.transparent : const Color(0xFFE2E8F0),
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: role.gradient.first.withValues(alpha: 0.20),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onChanged(role.label),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: Row(
                  children: [
                    Icon(
                      role.icon,
                      color: active ? Colors.white : role.gradient.first,
                      size: 23,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        role.label,
                        style: TextStyle(
                          color: active ? Colors.white : AppTheme.dark,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String text;

  const _ErrorBanner({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFCA5A5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFF991B1B),
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF991B1B),
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

class _SecurityNote extends StatelessWidget {
  final Color color;

  const _SecurityNote({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_user_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'İlk girişte verilen geçici şifre değiştirilebilir. Yetkisiz giriş engellenir.',
              style: TextStyle(
                color: AppTheme.dark,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeaturePill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 17,
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MiniMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color == Colors.white ? Colors.white : color,
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: -0.8,
              ),
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _GlowBlob({
    required this.color,
    required this.size,
    this.opacity = 0.20,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: opacity),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: opacity),
              blurRadius: size * 0.38,
              spreadRadius: size * 0.12,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleOption {
  final String label;
  final IconData icon;
  final List<Color> gradient;

  const _RoleOption({
    required this.label,
    required this.icon,
    required this.gradient,
  });
}