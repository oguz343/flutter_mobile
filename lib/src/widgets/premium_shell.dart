import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/app_session.dart';
import '../core/app_theme.dart';

class PremiumShellItem {
  final String label;
  final IconData icon;
  final Widget child;

  const PremiumShellItem({
    required this.label,
    required this.icon,
    required this.child,
  });
}

class PremiumShell extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final List<PremiumShellItem> items;

  const PremiumShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.items,
  });

  @override
  State<PremiumShell> createState() => _PremiumShellState();
}

class _PremiumShellState extends State<PremiumShell> {
  late final PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goTo(int index) async {
    if (index == _index) {
      return;
    }

    setState(() => _index = index);

    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 330),
      curve: Curves.easeOutCubic,
    );
  }

  void _logout() {
    AppSession.clear();

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AppSession.currentUser;

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.accent.withValues(alpha: 0.13),
              const Color(0xFFF8FAFC),
              const Color(0xFFEFF6FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                child: _PremiumHeader(
                  title: widget.title,
                  subtitle: widget.subtitle,
                  accent: widget.accent,
                  name: user?.name ?? 'Kullanıcı',
                  number: user?.number ?? '-',
                  onLogout: _logout,
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (value) {
                    setState(() => _index = value);
                  },
                  children: widget.items.map((x) => x.child).toList(),
                ),
              ),
              const SizedBox(height: 104),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _PremiumFloatingDock(
        accent: widget.accent,
        items: widget.items,
        selectedIndex: _index,
        onTap: _goTo,
      ),
    );
  }
}

class _PremiumHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final String name;
  final String number;
  final VoidCallback onLogout;

  const _PremiumHeader({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.name,
    required this.number,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 430;

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          padding: EdgeInsets.all(compact ? 13 : 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.95),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.055),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 48 : 56,
                height: compact ? 48 : 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent,
                      AppTheme.cyan,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(21),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.25),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.dark,
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 18 : 21,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(maxWidth: 132),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.dark,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'No: $number',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onLogout,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFEF4444),
                      size: 21,
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

class _PremiumFloatingDock extends StatelessWidget {
  final Color accent;
  final List<PremiumShellItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _PremiumFloatingDock({
    required this.accent,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final width = MediaQuery.sizeOf(context).width;

    final compact = width < 390;
    final dockHeight = compact ? 76.0 : 82.0;
    final horizontalPadding = compact ? 8.0 : 10.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        bottomSafe > 0 ? 8 : 12,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 22,
            sigmaY: 22,
          ),
          child: Container(
            height: dockHeight,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.98),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: compact ? 7 : 8,
              ),
              child: Row(
                children: [
                  for (int i = 0; i < items.length; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 2 : 3,
                        ),
                        child: _DockItem(
                          accent: accent,
                          item: items[i],
                          selected: i == selectedIndex,
                          compact: compact,
                          onTap: () => onTap(i),
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
}

class _DockItem extends StatelessWidget {
  final Color accent;
  final PremiumShellItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _DockItem({
    required this.accent,
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = const Color(0xFF94A3B8);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 230),
      curve: Curves.easeOutCubic,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.18),
                  accent.withValues(alpha: 0.07),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: selected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: selected ? accent.withValues(alpha: 0.18) : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 3 : 5,
              vertical: compact ? 5 : 6,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 230),
                  width: compact ? 31 : 34,
                  height: compact ? 31 : 34,
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            colors: [
                              accent,
                              AppTheme.cyan,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: selected ? null : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.26),
                              blurRadius: 14,
                              offset: const Offset(0, 7),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    item.icon,
                    color: selected ? Colors.white : inactiveColor,
                    size: compact ? 17 : 18,
                  ),
                ),
                SizedBox(height: compact ? 3 : 4),
                Flexible(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? accent : inactiveColor,
                      fontWeight: FontWeight.w900,
                      fontSize: compact ? 9.2 : 10.4,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumPlaceholderPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<String> items;

  const PremiumPlaceholderPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent,
                  AppTheme.cyan,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.24),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppTheme.softShadow,
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppTheme.dark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}