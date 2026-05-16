import 'package:flutter/material.dart';

import '../../core/app_session.dart';
import '../../core/app_theme.dart';
import '../../services/parent_service.dart';

class ParentOverviewPage extends StatelessWidget {
  final Color accent;

  const ParentOverviewPage({super.key, required this.accent});

  @override
  Widget build(BuildContext context) {
    final parent = AppSession.currentUser;

    if (parent == null) {
      return _EmptyCard(
        accent: accent,
        title: 'Oturum bulunamadı',
        message: 'Lütfen tekrar giriş yapın.',
      );
    }

    return StreamBuilder<ParentStudentBundle>(
      stream: ParentService().watchParentStudent(parent),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data =
            snapshot.data ??
            const ParentStudentBundle(student: null, assignments: []);

        final student = data.student;

        if (student == null) {
          return _EmptyCard(
            accent: accent,
            title: 'Bağlı öğrenci yok',
            message:
                'Admin panelinden veli-öğrenci eşleştirmesini kontrol edin.',
          );
        }

        final ratio = data.totalAssignments == 0
            ? 0.0
            : data.submittedCount / data.totalAssignments;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            children: [
              _ReportHero(
                accent: accent,
                studentName: student.name,
                className: student.className,
                number: student.number,
                ratio: ratio,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Toplam',
                      value: data.totalAssignments.toString(),
                      icon: Icons.assignment_rounded,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStat(
                      label: 'Teslim',
                      value: data.submittedCount.toString(),
                      icon: Icons.upload_file_rounded,
                      color: AppTheme.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Bekleyen',
                      value: data.pendingCount.toString(),
                      icon: Icons.pending_actions_rounded,
                      color: AppTheme.red,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStat(
                      label: 'Notlanan',
                      value: data.evaluatedCount.toString(),
                      icon: Icons.verified_rounded,
                      color: AppTheme.cyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ParentInsightCard(
                accent: accent,
                total: data.totalAssignments,
                submitted: data.submittedCount,
                evaluated: data.evaluatedCount,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReportHero extends StatelessWidget {
  final Color accent;
  final String studentName;
  final String className;
  final String number;
  final double ratio;

  const _ReportHero({
    required this.accent,
    required this.studentName,
    required this.className,
    required this.number,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (ratio * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(38),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.24),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  Icons.family_restroom_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Veli Raporu',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 27,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$studentName • $className • No: $number',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 23),
          SizedBox(
            width: 132,
            height: 132,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 13,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  color: Colors.white,
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '%$percent',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 30,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Teslim tamamlama oranı',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.line),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 29,
              letterSpacing: 0,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.muted,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentInsightCard extends StatelessWidget {
  final Color accent;
  final int total;
  final int submitted;
  final int evaluated;

  const _ParentInsightCard({
    required this.accent,
    required this.total,
    required this.submitted,
    required this.evaluated,
  });

  @override
  Widget build(BuildContext context) {
    final message = total == 0
        ? 'Öğrencinin sınıfına henüz ödev verilmemiş.'
        : submitted == total
        ? 'Tüm ödevler teslim edilmiş. Harika gidiyor.'
        : '$total ödevden $submitted tanesi teslim edilmiş. Kalan ödevleri Durum sekmesinden takip edebilirsiniz.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.line),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.insights_rounded, color: accent),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Akıllı Özet',
                  style: TextStyle(
                    color: AppTheme.dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w800,
                    height: 1.45,
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

class _EmptyCard extends StatelessWidget {
  final Color accent;
  final String title;
  final String message;

  const _EmptyCard({
    required this.accent,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(18),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_rounded, color: accent, size: 44),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.dark,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
