import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'admin_dashboard.dart';
import 'role_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final TextEditingController numberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String selectedRole = 'Öğrenci';
  bool isLoading = false;
  bool obscurePassword = true;

  final roles = const [
    _RoleOption(
      title: 'Öğrenci',
      icon: Icons.school_rounded,
      color: Color(0xFF4F46E5),
    ),
    _RoleOption(
      title: 'Öğretmen',
      icon: Icons.person_rounded,
      color: Color(0xFF06B6D4),
    ),
    _RoleOption(
      title: 'Veli',
      icon: Icons.family_restroom_rounded,
      color: Color(0xFFF59E0B),
    ),
    _RoleOption(
      title: 'Admin',
      icon: Icons.admin_panel_settings_rounded,
      color: Color(0xFF111827),
    ),
  ];

  Color get mainColor {
    return roles.firstWhere((role) => role.title == selectedRole).color;
  }

  IconData get mainIcon {
    return roles.firstWhere((role) => role.title == selectedRole).icon;
  }

  @override
  void dispose() {
    numberController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (isLoading) return;

    final number = numberController.text.trim();
    final password = passwordController.text.trim();

    if (number.isEmpty || password.isEmpty) {
      showMessage('Numara ve şifre boş bırakılamaz.', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      if (selectedRole == 'Admin') {
        if (number == '0000' && password == 'admin123') {
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
          return;
        }

        showMessage('Admin bilgileri hatalı.', isError: true);
        return;
      }

      final userQuery = await firestore
          .collection('users')
          .where('schoolNo', isEqualTo: number)
          .where('role', isEqualTo: selectedRole)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        showMessage('Bu bilgilere ait kullanıcı bulunamadı.', isError: true);
        return;
      }

      final userDoc = userQuery.docs.first;
      final data = userDoc.data();

      final name = data['name']?.toString() ?? selectedRole;
      final activationCode = data['activationCode']?.toString() ?? '';
      final savedPassword = data['password']?.toString() ?? '';
      final mustChangePassword = data['mustChangePassword'] == true;

      if (mustChangePassword) {
        if (password != activationCode) {
          showMessage('Aktivasyon kodu hatalı.', isError: true);
          return;
        }

        if (!mounted) return;

        await openCreatePasswordSheet(
          userId: userDoc.id,
          role: selectedRole,
          name: name,
          number: number,
        );

        return;
      }

      if (savedPassword.isEmpty) {
        showMessage(
          'Bu hesap için şifre oluşturulmamış. Aktivasyon kodu ile giriş yapın.',
          isError: true,
        );
        return;
      }

      if (password != savedPassword) {
        showMessage('Şifre hatalı.', isError: true);
        return;
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoleDashboardScreen(
            role: selectedRole,
            name: name,
            number: number,
          ),
        ),
      );
    } catch (e) {
      showMessage('Giriş yapılırken hata oluştu.', isError: true);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> openCreatePasswordSheet({
    required String userId,
    required String role,
    required String name,
    required String number,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePasswordSheet(
        userId: userId,
        role: role,
        name: name,
        number: number,
      ),
    );

    if (result == true && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoleDashboardScreen(
            role: role,
            name: name,
            number: number,
          ),
        ),
      );
    }
  }

  void showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFEF4444) : mainColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 950;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F172A),
              Color(0xFF111827),
              Color(0xFF312E81),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                top: -80,
                left: -80,
                child: _GlowCircle(
                  size: 260,
                  color: Color(0xFF6366F1),
                ),
              ),
              const Positioned(
                bottom: -100,
                right: -90,
                child: _GlowCircle(
                  size: 310,
                  color: Color(0xFF06B6D4),
                ),
              ),
              const Positioned(
                top: 140,
                right: 100,
                child: _GlowCircle(
                  size: 150,
                  color: Color(0xFFF59E0B),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: isDesktop
                        ? Row(
                            children: [
                              const Expanded(
                                child: _HeroPanel(),
                              ),
                              const SizedBox(width: 34),
                              SizedBox(
                                width: 450,
                                child: _LoginCard(
                                  selectedRole: selectedRole,
                                  roles: roles,
                                  mainColor: mainColor,
                                  mainIcon: mainIcon,
                                  numberController: numberController,
                                  passwordController: passwordController,
                                  obscurePassword: obscurePassword,
                                  isLoading: isLoading,
                                  onRoleChanged: (role) {
                                    setState(() {
                                      selectedRole = role;
                                      numberController.clear();
                                      passwordController.clear();
                                    });
                                  },
                                  onTogglePassword: () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                  onLogin: login,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              const _MobileBrand(),
                              const SizedBox(height: 22),
                              _LoginCard(
                                selectedRole: selectedRole,
                                roles: roles,
                                mainColor: mainColor,
                                mainIcon: mainIcon,
                                numberController: numberController,
                                passwordController: passwordController,
                                obscurePassword: obscurePassword,
                                isLoading: isLoading,
                                onRoleChanged: (role) {
                                  setState(() {
                                    selectedRole = role;
                                    numberController.clear();
                                    passwordController.clear();
                                  });
                                },
                                onTogglePassword: () {
                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                                onLogin: login,
                              ),
                            ],
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

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 650,
      padding: const EdgeInsets.all(42),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(38),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.school_rounded,
                  color: Color(0xFF4F46E5),
                  size: 30,
                ),
              ),
              SizedBox(width: 14),
              Text(
                'Ödev Sistemi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Text(
            'Okul yönetimi,\nödev takibi ve teslim\nkontrolü tek panelde.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 50,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Admin, öğretmen, öğrenci ve veli hesapları için modern ve güvenli giriş ekranı.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 18,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 34),
          const Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _FeaturePill(
                icon: Icons.assignment_turned_in_rounded,
                text: 'Ödev teslim',
              ),
              _FeaturePill(
                icon: Icons.grade_rounded,
                text: 'Not & geri dönüş',
              ),
              _FeaturePill(
                icon: Icons.groups_rounded,
                text: 'Rol bazlı panel',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileBrand extends StatelessWidget {
  const _MobileBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 34,
          backgroundColor: Colors.white,
          child: Icon(
            Icons.school_rounded,
            color: Color(0xFF4F46E5),
            size: 36,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Ödev Sistemi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Okul, ödev ve teslim yönetimi',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  final String selectedRole;
  final List<_RoleOption> roles;
  final Color mainColor;
  final IconData mainIcon;
  final TextEditingController numberController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;

  const _LoginCard({
    required this.selectedRole,
    required this.roles,
    required this.mainColor,
    required this.mainIcon,
    required this.numberController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onRoleChanged,
    required this.onTogglePassword,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = selectedRole == 'Admin';

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 50,
            offset: const Offset(0, 28),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 42,
              backgroundColor: mainColor.withValues(alpha: 0.12),
              child: Icon(
                mainIcon,
                color: mainColor,
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Giriş Yap',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              isAdmin
                  ? 'Admin paneline erişmek için giriş yap.'
                  : '$selectedRole paneline erişmek için bilgilerini gir.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Rol Seçimi',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: roles.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 70,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final role = roles[index];
              final active = selectedRole == role.title;

              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onRoleChanged(role.title),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: active
                        ? role.color.withValues(alpha: 0.12)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? role.color : const Color(0xFFE5E7EB),
                      width: active ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: active
                            ? role.color
                            : role.color.withValues(alpha: 0.10),
                        child: Icon(
                          role.icon,
                          color: active ? Colors.white : role.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          role.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: active ? role.color : const Color(0xFF374151),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          TextField(
            controller: numberController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
            decoration: _input(
              isAdmin
                  ? 'Admin Numarası'
                  : selectedRole == 'Öğrenci'
                      ? 'Okul Numarası'
                      : selectedRole == 'Öğretmen'
                          ? 'Öğretmen Numarası'
                          : 'Veli Numarası',
              Icons.numbers_rounded,
              mainColor,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            onSubmitted: (_) => onLogin(),
            decoration: _input(
              isAdmin ? 'Admin Şifresi' : 'Şifre / Aktivasyon Kodu',
              Icons.lock_rounded,
              mainColor,
            ).copyWith(
              suffixIcon: IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: mainColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAdmin
                      ? 'Admin: 0000 / admin123'
                      : 'İlk girişte aktivasyon kodunu kullan.',
                  style: TextStyle(
                    color: mainColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onLogin,
              icon: isLoading
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(
                isLoading ? 'Giriş yapılıyor...' : 'Panele Giriş Yap',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: mainColor,
                disabledBackgroundColor: mainColor.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _input(
    String label,
    IconData icon,
    Color color,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: color),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: color, width: 2),
      ),
    );
  }
}

class _CreatePasswordSheet extends StatefulWidget {
  final String userId;
  final String role;
  final String name;
  final String number;

  const _CreatePasswordSheet({
    required this.userId,
    required this.role,
    required this.name,
    required this.number,
  });

  @override
  State<_CreatePasswordSheet> createState() => _CreatePasswordSheetState();
}

class _CreatePasswordSheetState extends State<_CreatePasswordSheet> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatPasswordController = TextEditingController();

  bool isSaving = false;
  bool obscurePassword = true;
  bool obscureRepeat = true;

  @override
  void dispose() {
    passwordController.dispose();
    repeatPasswordController.dispose();
    super.dispose();
  }

  Future<void> savePassword() async {
    if (isSaving) return;

    final password = passwordController.text.trim();
    final repeat = repeatPasswordController.text.trim();

    if (password.length < 4) {
      showMessage('Şifre en az 4 karakter olmalıdır.', isError: true);
      return;
    }

    if (password != repeat) {
      showMessage('Şifreler eşleşmiyor.', isError: true);
      return;
    }

    setState(() => isSaving = true);

    try {
      await firestore.collection('users').doc(widget.userId).update({
        'password': password,
        'mustChangePassword': false,
        'activationCode': '',
        'passwordUpdatedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      showMessage('Şifre oluşturulurken hata oluştu.', isError: true);
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
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF4F46E5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: const BoxDecoration(
          color: Color(0xFFF6F7FB),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(34),
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: Color(0xFFEEF2FF),
                    child: Icon(
                      Icons.lock_reset_rounded,
                      color: Color(0xFF4F46E5),
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Yeni Şifre Oluştur',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.name} hesabı için kalıcı şifre oluştur.',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: _input(
                      'Yeni Şifre',
                      Icons.lock_rounded,
                    ).copyWith(
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: repeatPasswordController,
                    obscureText: obscureRepeat,
                    onSubmitted: (_) => savePassword(),
                    decoration: _input(
                      'Yeni Şifre Tekrar',
                      Icons.lock_outline_rounded,
                    ).copyWith(
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscureRepeat = !obscureRepeat;
                          });
                        },
                        icon: Icon(
                          obscureRepeat
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: isSaving ? null : savePassword,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        isSaving ? 'Kaydediliyor...' : 'Şifreyi Oluştur',
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
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 19),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.28),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.46),
              blurRadius: 90,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleOption {
  final String title;
  final IconData icon;
  final Color color;

  const _RoleOption({
    required this.title,
    required this.icon,
    required this.color,
  });
}