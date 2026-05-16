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

    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = AppSession.currentUser;
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 760;

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _ShellBackdrop(accent: widget.accent),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 22 : 14,
                    wide ? 16 : 10,
                    wide ? 22 : 14,
                    10,
                  ),
                  child: _PremiumHeader(
                    title: widget.title,
                    subtitle: widget.subtitle,
                    accent: widget.accent,
                    name: user?.name ?? 'Kullanıcı',
                    number: user?.number ?? '-',
                    activeLabel: widget.items[_index].label,
                    activeIcon: widget.items[_index].icon,
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
                    children: widget.items
                        .map(
                          (x) => _PremiumPageStage(
                            accent: widget.accent,
                            icon: x.icon,
                            label: x.label,
                            child: x.child,
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 106),
              ],
            ),
          ),
        ],
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

class _PremiumPageStage extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String label;
  final Widget child;

  const _PremiumPageStage({
    required this.accent,
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;

    return Padding(
      padding: EdgeInsets.fromLTRB(wide ? 22 : 12, 0, wide ? 22 : 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(wide ? 34 : 28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(wide ? 34 : 28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF101828).withValues(alpha: 0.08),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _StageCardPatternPainter(accent)),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: _FloatingStageBadge(
                    accent: accent,
                    icon: icon,
                    label: label,
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: IgnorePointer(
                    child: Row(
                      children: [
                        _StageMiniChip(
                          color: accent,
                          icon: Icons.layers_rounded,
                          text: 'Kart görünümü',
                        ),
                        const SizedBox(width: 8),
                        _StageMiniChip(
                          color: AppTheme.cyan,
                          icon: Icons.swipe_rounded,
                          text: 'Kaydırmalı',
                        ),
                      ],
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StageCardPatternPainter extends CustomPainter {
  final Color accent;

  const _StageCardPatternPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final wash = Paint()
      ..shader =
          RadialGradient(
            colors: [
              accent.withValues(alpha: 0.12),
              AppTheme.cyan.withValues(alpha: 0.05),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.12, size.height * 0.04),
              radius: size.width * 0.9,
            ),
          );

    canvas.drawRect(Offset.zero & size, wash);

    final cardPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.34)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rects = [
      Rect.fromLTWH(size.width - 126, 72, 98, 58),
      Rect.fromLTWH(22, size.height - 112, 104, 58),
      Rect.fromLTWH(size.width - 156, size.height - 88, 126, 52),
    ];

    for (final rect in rects) {
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));
      canvas.drawRRect(rrect, cardPaint);
      canvas.drawRRect(rrect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StageCardPatternPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

class _FloatingStageBadge extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String label;

  const _FloatingStageBadge({
    required this.accent,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF101828).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accent, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageMiniChip extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _StageMiniChip({
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShellBackdrop extends StatelessWidget {
  final Color accent;

  const _ShellBackdrop({required this.accent});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(accent, Colors.white, 0.78)!,
            const Color(0xFFF7F9FC),
            const Color(0xFFEEF4FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(
        painter: _ShellPatternPainter(accent),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ShellPatternPainter extends CustomPainter {
  final Color accent;

  const _ShellPatternPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final topPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          accent.withValues(alpha: 0.14),
          AppTheme.cyan.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.48));

    final topPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.58,
        size.height * 0.34,
        0,
        size.height * 0.24,
      )
      ..close();

    canvas.drawPath(topPath, topPaint);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.38)
      ..strokeWidth = 1;

    const gap = 34.0;
    for (double x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * 0.42, size.height * 0.42),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShellPatternPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

class _PremiumHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final String name;
  final String number;
  final String activeLabel;
  final IconData activeIcon;
  final VoidCallback onLogout;

  const _PremiumHeader({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.name,
    required this.number,
    required this.activeLabel,
    required this.activeIcon,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 430;

    return ClipRRect(
      borderRadius: BorderRadius.circular(compact ? 26 : 30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(compact ? 13 : 17),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(compact ? 26 : 30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.98)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF101828).withValues(alpha: 0.09),
                blurRadius: 34,
                offset: const Offset(0, 18),
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
                    colors: [accent, AppTheme.cyan, AppTheme.green],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(compact ? 18 : 21),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(activeIcon, color: Colors.white, size: 27),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.dark,
                              fontWeight: FontWeight.w900,
                              fontSize: compact ? 18 : 21,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        if (!compact) ...[
                          const SizedBox(width: 8),
                          _HeaderPill(
                            text: activeLabel,
                            icon: Icons.auto_awesome_rounded,
                            color: accent,
                          ),
                        ],
                      ],
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
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.12),
                        AppTheme.cyan.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: accent.withValues(alpha: 0.16)),
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
                      color: AppTheme.red.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.red.withValues(alpha: 0.12),
                      ),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: AppTheme.red,
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

class _HeaderPill extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _HeaderPill({
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
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
    final dockHeight = compact ? 78.0 : 84.0;
    final horizontalPadding = compact ? 8.0 : 10.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomSafe > 0 ? 8 : 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: dockHeight,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.98)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF101828).withValues(alpha: 0.15),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
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
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: selected ? accent.withValues(alpha: 0.18) : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(21),
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
                  width: compact ? 32 : 36,
                  height: compact ? 32 : 36,
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            colors: [accent, AppTheme.cyan, AppTheme.green],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: selected ? null : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(13),
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
                      fontSize: compact ? 9.0 : 10.2,
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
                colors: [accent, AppTheme.cyan],
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
                  child: Icon(icon, color: Colors.white, size: 34),
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
                          letterSpacing: 0,
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
                border: Border.all(color: AppTheme.line),
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
                    child: Icon(Icons.auto_awesome_rounded, color: accent),
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
