import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_helpers.dart';
import '../../core/app_theme.dart';
import '../../models/app_user.dart';
import '../../services/admin_user_service.dart';
import '../../widgets/app_confirm_dialog.dart';

class AdminUsersPage extends StatefulWidget {
  final Color accent;

  const AdminUsersPage({super.key, required this.accent});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final AdminUserService _service = AdminUserService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  late final Stream<List<AppUser>> _usersStream;
  String _search = '';
  String _roleFilter = 'Tümü';

  @override
  void initState() {
    super.initState();
    _usersStream = _service.watchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: _usersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _MessageCard(
            title: 'Hata oluştu',
            message: 'Kullanıcılar yüklenirken hata oluştu.',
            accent: widget.accent,
          );
        }

        final users = snapshot.data ?? [];
        final filtered = _filterUsers(users);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            children: [
              _Hero(
                accent: widget.accent,
                count: filtered.length,
                onAdd: () => _openUserSheet(context),
              ),
              const SizedBox(height: 14),
              _SearchAndFilter(
                accent: widget.accent,
                searchController: _searchController,
                searchFocus: _searchFocus,
                roleFilter: _roleFilter,
                onSearchChanged: (value) {
                  setState(() => _search = value);
                },
                onSearchCleared: () {
                  _searchController.clear();
                  setState(() => _search = '');
                  _searchFocus.requestFocus();
                },
                onRoleChanged: (value) {
                  setState(() => _roleFilter = value);
                },
              ),
              const SizedBox(height: 14),
              if (filtered.isEmpty)
                _MessageCard(
                  title: 'Kullanıcı bulunamadı',
                  message: 'Arama veya filtreye uygun kullanıcı yok.',
                  accent: widget.accent,
                  embedded: true,
                )
              else
                ...filtered.map(
                  (user) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _UserCard(
                      user: user,
                      accent: widget.accent,
                      onEdit: () => _openUserSheet(context, user: user),
                      onDelete: () => _confirmDelete(user),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<AppUser> _filterUsers(List<AppUser> users) {
    final searchKey = AppHelpers.normalizeKey(_search);
    final filterKey = AppHelpers.normalizeKey(_roleFilter);

    return users.where((user) {
      final roleMatch =
          filterKey == 'tumu' ||
          AppHelpers.normalizeKey(user.role) == filterKey;

      final userKey = AppHelpers.normalizeKey(
        '${user.name}_${user.role}_${user.number}_${user.className}_${user.branch}_${user.phone}',
      );

      final searchMatch = searchKey.isEmpty || userKey.contains(searchKey);

      return roleMatch && searchMatch;
    }).toList();
  }

  void _openUserSheet(BuildContext context, {AppUser? user}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserSheet(accent: widget.accent, user: user),
    );
  }

  Future<void> _confirmDelete(AppUser user) async {
    final ok = await showAppConfirmDialog(
      context: context,
      title: 'Kullanıcı pasife alınsın mı?',
      message:
          '${user.name} artık listelerde ve girişlerde aktif görünmeyecek. İstersen daha sonra kaydı tekrar düzenleyebilirsin.',
      confirmText: 'Pasife Al',
    );

    if (!ok) {
      return;
    }

    try {
      await _service.softDeleteUser(user);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kullanıcı silindi.')));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı silinirken hata oluştu.')),
      );
    }
  }
}

class _Hero extends StatelessWidget {
  final Color accent;
  final int count;
  final VoidCallback onAdd;

  const _Hero({required this.accent, required this.count, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, const Color(0xFF06B6D4)],
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
                  Icons.groups_rounded,
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
                      'Kullanıcılar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 25,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$count kullanıcı listeleniyor.',
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
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Yeni Kullanıcı Ekle'),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilter extends StatelessWidget {
  final Color accent;
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final String roleFilter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final ValueChanged<String> onRoleChanged;

  const _SearchAndFilter({
    required this.accent,
    required this.searchController,
    required this.searchFocus,
    required this.roleFilter,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final roles = ['Tümü', 'Öğrenci', 'Öğretmen', 'Veli', 'Admin'];

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            focusNode: searchFocus,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Ara',
              hintText: 'Ad, numara, sınıf, branş...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Aramayı temizle',
                      onPressed: onSearchCleared,
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: roleFilter,
            items: roles
                .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onRoleChanged(value);
              }
            },
            decoration: const InputDecoration(
              labelText: 'Rol filtresi',
              prefixIcon: Icon(Icons.filter_alt_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  final Color accent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.accent,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final roleKey = AppHelpers.normalizeKey(user.role);
    final roleColor = roleKey == 'ogrenci'
        ? const Color(0xFF10B981)
        : roleKey == 'ogretmen'
        ? const Color(0xFF06B6D4)
        : roleKey == 'veli'
        ? const Color(0xFFF59E0B)
        : accent;

    final detail = roleKey == 'ogrenci'
        ? 'Sınıf: ${user.className.isEmpty ? '-' : user.className}'
        : roleKey == 'ogretmen'
        ? 'Branş: ${user.branch.isEmpty ? '-' : user.branch}'
        : roleKey == 'veli'
        ? 'Bağlı öğrenci: ${user.linkedStudentNo.isEmpty ? '-' : user.linkedStudentNo}'
        : 'Admin hesabı';

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(
              roleKey == 'ogrenci'
                  ? Icons.backpack_rounded
                  : roleKey == 'ogretmen'
                  ? Icons.co_present_rounded
                  : roleKey == 'veli'
                  ? Icons.family_restroom_rounded
                  : Icons.admin_panel_settings_rounded,
              color: roleColor,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.role} • No: ${user.number}',
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: Icon(Icons.edit_rounded, color: accent),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }
}

class _UserSheet extends StatefulWidget {
  final Color accent;
  final AppUser? user;

  const _UserSheet({required this.accent, this.user});

  @override
  State<_UserSheet> createState() => _UserSheetState();
}

class _UserSheetState extends State<_UserSheet> {
  final AdminUserService _service = AdminUserService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _tcController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _linkedStudentNoController =
      TextEditingController();

  String _role = 'Öğrenci';
  String _className = '9-A';
  bool _loading = false;
  String _error = '';

  bool get editing => widget.user != null;

  @override
  void initState() {
    super.initState();

    final user = widget.user;

    if (user != null) {
      _role = user.role.isEmpty ? 'Öğrenci' : user.role;
      _nameController.text = user.name;
      _numberController.text = user.number;
      _tcController.text = user.tc;
      _phoneController.text = user.phone;
      _branchController.text = user.branch;
      _linkedStudentNoController.text = user.linkedStudentNo;

      if (user.className.trim().isNotEmpty) {
        _className = AppHelpers.normalizeClassName(user.className);
      }
    } else {
      _passwordController.text = _service.generateActivationCode();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _passwordController.dispose();
    _tcController.dispose();
    _phoneController.dispose();
    _branchController.dispose();
    _linkedStudentNoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      if (editing) {
        await _service.updateUser(
          user: widget.user!,
          role: _role,
          name: _nameController.text,
          number: _numberController.text,
          tc: _tcController.text,
          phone: _phoneController.text,
          className: _role == 'Öğrenci' ? _className : '',
          branch: _role == 'Öğretmen' ? _branchController.text : '',
          linkedStudentNo: _role == 'Veli'
              ? _linkedStudentNoController.text
              : '',
        );
      } else {
        await _service.createUser(
          role: _role,
          name: _nameController.text,
          number: _numberController.text,
          password: _passwordController.text,
          tc: _tcController.text,
          phone: _phoneController.text,
          className: _role == 'Öğrenci' ? _className : '',
          branch: _role == 'Öğretmen' ? _branchController.text : '',
          linkedStudentNo: _role == 'Veli'
              ? _linkedStudentNoController.text
              : '',
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editing ? 'Kullanıcı güncellendi.' : 'Kullanıcı eklendi.',
          ),
        ),
      );
    } on AdminUserException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'İşlem sırasında hata oluştu.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _copyActivationCode() async {
    await Clipboard.setData(ClipboardData(text: _passwordController.text));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aktivasyon kodu kopyalandı.')),
    );
  }

  void _renewActivationCode() {
    setState(() {
      _passwordController.text = _service.generateActivationCode();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final roles = ['Öğrenci', 'Öğretmen', 'Veli', 'Admin'];
    final classes = <String>[
      for (final grade in ['9', '10', '11', '12'])
        for (final section in ['A', 'B', 'C', 'D', 'E', 'F']) '$grade-$section',
    ];

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
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
                  color: AppTheme.line,
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
                      editing
                          ? Icons.edit_rounded
                          : Icons.person_add_alt_1_rounded,
                      color: widget.accent,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      editing ? 'Kullanıcı Düzenle' : 'Yeni Kullanıcı Ekle',
                      style: const TextStyle(
                        color: AppTheme.dark,
                        fontWeight: FontWeight.w900,
                        fontSize: 21,
                        letterSpacing: 0,
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
              DropdownButtonFormField<String>(
                initialValue: roles.contains(_role) ? _role : 'Öğrenci',
                items: roles
                    .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _role = value);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  prefixIcon: Icon(Icons.badge_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  hintText: 'Kullanıcının adı soyadı',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _numberController,
                keyboardType: _role == 'Admin'
                    ? TextInputType.text
                    : TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: _role == 'Admin'
                    ? null
                    : [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: _role == 'Admin'
                      ? 'Admin No / Kullanıcı Adı'
                      : 'Numara',
                  hintText: _role == 'Admin'
                      ? 'Örn: 0000'
                      : 'Okul / kullanıcı numarası',
                  prefixIcon: const Icon(Icons.tag_rounded),
                ),
              ),
              if (!editing) ...[
                const SizedBox(height: 12),
                _ActivationCodeCard(
                  code: _passwordController.text,
                  accent: widget.accent,
                  onCopy: _copyActivationCode,
                  onRenew: _renewActivationCode,
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _tcController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: const InputDecoration(
                  labelText: 'TC',
                  hintText: '11 hane',
                  prefixIcon: Icon(Icons.credit_card_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [TurkishPhoneInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  hintText: '0 (5xx) xxx xx xx',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
              ),
              if (_role == 'Öğrenci') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: classes.contains(_className)
                      ? _className
                      : classes.first,
                  items: classes
                      .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _className = value);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Sınıf',
                    prefixIcon: Icon(Icons.apartment_rounded),
                  ),
                ),
              ],
              if (_role == 'Öğretmen') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _branchController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Branş',
                    hintText: 'Örn: Matematik',
                    prefixIcon: Icon(Icons.menu_book_rounded),
                  ),
                ),
              ],
              if (_role == 'Veli') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _linkedStudentNoController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Bağlı Öğrenci Numarası',
                    hintText: 'Velinin göreceği öğrencinin numarası',
                    prefixIcon: Icon(Icons.family_restroom_rounded),
                  ),
                ),
              ],
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
                      : Text(
                          editing ? 'Kaydet' : 'Kullanıcı Ekle',
                          style: const TextStyle(fontWeight: FontWeight.w900),
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

class _ActivationCodeCard extends StatelessWidget {
  final String code;
  final Color accent;
  final VoidCallback onCopy;
  final VoidCallback onRenew;

  const _ActivationCodeCard({
    required this.code,
    required this.accent,
    required this.onCopy,
    required this.onRenew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.key_rounded, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aktivasyon Kodu',
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  code,
                  style: const TextStyle(
                    color: AppTheme.dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Yeni kod üret',
            onPressed: onRenew,
            icon: const Icon(Icons.refresh_rounded),
            color: const Color(0xFF64748B),
          ),
          IconButton.filled(
            tooltip: 'Kopyala',
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded),
            style: IconButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class TurkishPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = AppHelpers.onlyDigits(newValue.text);

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    if (!digits.startsWith('0')) {
      digits = '0$digits';
    }

    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }

    final buffer = StringBuffer();

    buffer.write('0');

    if (digits.length > 1) {
      final part = digits.substring(1, digits.length.clamp(1, 4));
      buffer.write(' ($part');
      if (part.length == 3) {
        buffer.write(')');
      }
    }

    if (digits.length > 4) {
      buffer.write(' ${digits.substring(4, digits.length.clamp(4, 7))}');
    }

    if (digits.length > 7) {
      buffer.write(' ${digits.substring(7, digits.length.clamp(7, 9))}');
    }

    if (digits.length > 9) {
      buffer.write(' ${digits.substring(9, digits.length.clamp(9, 11))}');
    }

    final text = buffer.toString();

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
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
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        children: [
          Icon(Icons.info_rounded, color: accent, size: 42),
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
      child: Padding(padding: const EdgeInsets.all(18), child: card),
    );
  }
}
