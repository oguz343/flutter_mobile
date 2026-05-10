import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';
import 'users_screen.dart';
import 'classes_screen.dart';
import 'lessons_screen.dart';
import 'announcements_screen.dart';
import 'password_requests_screen.dart';
import 'submissions_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;

  final pages = const [
    _DashboardHome(),
    UsersScreen(),
    ClassesScreen(),
    LessonsScreen(),
    SubmissionsScreen(),
    AnnouncementsScreen(
      role: 'Admin',
      name: 'Admin',
    ),
    PasswordRequestsScreen(),
  ];

  final menuItems = const [
    _AdminMenuData(Icons.dashboard_rounded, 'Dashboard'),
    _AdminMenuData(Icons.people_alt_rounded, 'Kullanıcılar'),
    _AdminMenuData(Icons.class_rounded, 'Sınıflar'),
    _AdminMenuData(Icons.menu_book_rounded, 'Dersler'),
    _AdminMenuData(Icons.upload_file_rounded, 'Teslimler'),
    _AdminMenuData(Icons.campaign_rounded, 'Duyurular'),
    _AdminMenuData(Icons.lock_reset_rounded, 'Şifre Talepleri'),
  ];

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 950;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      drawer: isDesktop
          ? null
          : _MobileDrawer(
              selectedIndex: selectedIndex,
              items: menuItems,
              onSelect: (index) {
                setState(() => selectedIndex = index);
                Navigator.pop(context);
              },
              onLogout: logout,
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop)
              _Sidebar(
                selectedIndex: selectedIndex,
                items: menuItems,
                onSelect: (index) => setState(() => selectedIndex = index),
                onLogout: logout,
              ),
            Expanded(
              child: Column(
                children: [
                  if (!isDesktop)
                    Builder(
                      builder: (context) => _MobileTopBar(
                        title: menuItems[selectedIndex].title,
                        onMenuTap: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                  Expanded(child: pages[selectedIndex]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMenuData {
  final IconData icon;
  final String title;

  const _AdminMenuData(this.icon, this.title);
}

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final List<_AdminMenuData> items;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.selectedIndex,
    required this.items,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Logo(),
          const SizedBox(height: 34),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (int i = 0; i < items.length; i++)
                    _MenuItem(
                      icon: items[i].icon,
                      title: items[i].title,
                      active: selectedIndex == i,
                      onTap: () => onSelect(i),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _MenuItem(
            icon: Icons.logout_rounded,
            title: 'Çıkış Yap',
            active: false,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  final int selectedIndex;
  final List<_AdminMenuData> items;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const _MobileDrawer({
    required this.selectedIndex,
    required this.items,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF111827),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const _Logo(),
              const SizedBox(height: 28),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (int i = 0; i < items.length; i++)
                        _MenuItem(
                          icon: items[i].icon,
                          title: items[i].title,
                          active: selectedIndex == i,
                          onTap: () => onSelect(i),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _MenuItem(
                icon: Icons.logout_rounded,
                title: 'Çıkış Yap',
                active: false,
                onTap: onLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onMenuTap;

  const _MobileTopBar({
    required this.title,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenuTap,
            icon: const Icon(Icons.menu_rounded),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        CircleAvatar(
          backgroundColor: Color(0xFF4F46E5),
          child: Icon(Icons.school_rounded, color: Colors.white),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Ödev Sistemi',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFF4F46E5) : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: active ? 1 : 0.78),
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
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

class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double statWidth;

            if (constraints.maxWidth > 1200) {
              statWidth = (constraints.maxWidth - 80) / 4;
            } else if (constraints.maxWidth > 700) {
              statWidth = (constraints.maxWidth - 60) / 2;
            } else {
              statWidth = constraints.maxWidth;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin Paneli',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kullanıcılar, sınıflar, dersler, duyurular ve teslimleri yönetin.',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Wrap(
                    spacing: 18,
                    runSpacing: 18,
                    children: [
                      SizedBox(
                        width: statWidth,
                        child: _CountStatCard(
                          title: 'Öğrenci',
                          icon: Icons.groups_rounded,
                          color: const Color(0xFF4F46E5),
                          stream: firestore
                              .collection('users')
                              .where('role', isEqualTo: 'Öğrenci')
                              .snapshots(),
                        ),
                      ),
                      SizedBox(
                        width: statWidth,
                        child: _CountStatCard(
                          title: 'Öğretmen',
                          icon: Icons.person_rounded,
                          color: const Color(0xFF06B6D4),
                          stream: firestore
                              .collection('users')
                              .where('role', isEqualTo: 'Öğretmen')
                              .snapshots(),
                        ),
                      ),
                      SizedBox(
                        width: statWidth,
                        child: _CountStatCard(
                          title: 'Ders',
                          icon: Icons.menu_book_rounded,
                          color: const Color(0xFFF59E0B),
                          stream: firestore.collection('lessons').snapshots(),
                        ),
                      ),
                      SizedBox(
                        width: statWidth,
                        child: _CountStatCard(
                          title: 'Teslim',
                          icon: Icons.upload_file_rounded,
                          color: const Color(0xFF10B981),
                          stream: firestore.collection('submissions').snapshots(),
                        ),
                      ),
                    ],
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

class _CountStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Stream<QuerySnapshot> stream;

  const _CountStatCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length.toString() : '...';

        return Container(
          height: 145,
          padding: const EdgeInsets.all(22),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        count,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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