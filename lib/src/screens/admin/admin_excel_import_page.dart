import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_helpers.dart';
import '../../core/app_theme.dart';
import '../../services/admin_user_service.dart';

class AdminExcelImportPage extends StatefulWidget {
  final Color accent;

  const AdminExcelImportPage({super.key, required this.accent});

  @override
  State<AdminExcelImportPage> createState() => _AdminExcelImportPageState();
}

class _AdminExcelImportPageState extends State<AdminExcelImportPage> {
  final AdminUserService _service = AdminUserService();

  bool _loading = false;
  String _message = '';
  bool _success = false;

  final List<_ImportLog> _logs = [];

  Future<void> _pickAndImport() async {
    setState(() {
      _loading = true;
      _message = '';
      _logs.clear();
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _loading = false;
          _message = 'Dosya seçilmedi.';
          _success = false;
        });
        return;
      }

      final bytes = result.files.single.bytes;

      if (bytes == null || bytes.isEmpty) {
        setState(() {
          _loading = false;
          _message = 'Excel dosyası okunamadı.';
          _success = false;
        });
        return;
      }

      final excel = xls.Excel.decodeBytes(bytes);

      final drafts = _parseExcel(excel);

      if (drafts.isEmpty) {
        setState(() {
          _loading = false;
          _message =
              'Aktarılacak öğrenci bulunamadı. Excel başlıklarını ve verileri kontrol et.';
          _success = false;
        });
        return;
      }

      int added = 0;
      int skipped = 0;
      int failed = 0;

      for (final draft in drafts) {
        try {
          await _service.createUser(
            role: 'Öğrenci',
            name: draft.name,
            number: draft.number,
            password: draft.activationCode,
            tc: draft.tc,
            phone: draft.phone,
            className: draft.className,
            branch: '',
            linkedStudentNo: '',
          );

          added++;
          _logs.add(
            _ImportLog(
              title: draft.name,
              subtitle:
                  'No: ${draft.number} • Sınıf: ${draft.className} • Kod: ${draft.activationCode}',
              status: 'Eklendi',
              success: true,
              activationCode: draft.activationCode,
            ),
          );
        } on AdminUserException catch (e) {
          skipped++;
          _logs.add(
            _ImportLog(
              title: draft.name,
              subtitle: 'No: ${draft.number} • ${e.message}',
              status: 'Atlandı',
              success: false,
            ),
          );
        } catch (_) {
          failed++;
          _logs.add(
            _ImportLog(
              title: draft.name,
              subtitle: 'No: ${draft.number} • Beklenmeyen hata',
              status: 'Hata',
              success: false,
            ),
          );
        }
      }

      setState(() {
        _loading = false;
        _success = failed == 0;
        _message =
            '$added öğrenci eklendi • $skipped atlandı • $failed hata oluştu';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _success = false;
        _message = 'Excel aktarılırken hata oluştu: $e';
      });
    }
  }

  List<_StudentDraft> _parseExcel(xls.Excel excel) {
    final drafts = <_StudentDraft>[];

    if (excel.tables.isEmpty) {
      return drafts;
    }

    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName];

    if (sheet == null || sheet.rows.isEmpty) {
      return drafts;
    }

    final firstRow = sheet.rows.first;
    final hasHeader = _looksLikeHeader(firstRow);

    final headerMap = <String, int>{};

    if (hasHeader) {
      for (int i = 0; i < firstRow.length; i++) {
        final key = AppHelpers.normalizeKey(_cellText(firstRow[i]));
        if (key.isNotEmpty) {
          headerMap[key] = i;
        }
      }
    }

    final startIndex = hasHeader ? 1 : 0;

    for (int r = startIndex; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];

      if (row.every((cell) => _cellText(cell).trim().isEmpty)) {
        continue;
      }

      final name = hasHeader
          ? _getByAliases(row, headerMap, [
              'adsoyad',
              'adi',
              'ad',
              'isim',
              'ogrenciadi',
              'ogrenciadsoyad',
              'name',
              'fullname',
            ])
          : _cellText(row.isNotEmpty ? row[0] : null);

      final number = hasHeader
          ? _getByAliases(row, headerMap, [
              'numara',
              'no',
              'ogrencino',
              'ogrencinumara',
              'okulno',
              'schoolno',
              'studentno',
              'number',
            ])
          : _cellText(row.length > 1 ? row[1] : null);

      final classNameRaw = hasHeader
          ? _getByAliases(row, headerMap, [
              'sinif',
              'sınıf',
              'sube',
              'şube',
              'sinifsube',
              'sınıfşube',
              'class',
              'classname',
            ])
          : _cellText(row.length > 2 ? row[2] : null);

      final tc = hasHeader
          ? _getByAliases(row, headerMap, [
              'tc',
              'tckimlik',
              'kimlik',
              'identity',
            ])
          : _cellText(row.length > 3 ? row[3] : null);

      final phone = hasHeader
          ? _getByAliases(row, headerMap, [
              'telefon',
              'phone',
              'tel',
              'gsm',
              'cep',
            ])
          : _cellText(row.length > 4 ? row[4] : null);

      final cleanName = name.trim();
      final cleanNumber = AppHelpers.onlyDigits(number);
      final cleanClass = AppHelpers.normalizeClassName(classNameRaw);
      final cleanTc = AppHelpers.onlyDigits(tc);
      final cleanPhone = _normalizePhone(phone);
      final activationCode = _service.generateActivationCode();

      if (cleanName.isEmpty || cleanNumber.isEmpty || cleanClass.isEmpty) {
        _logs.add(
          _ImportLog(
            title: cleanName.isEmpty ? 'Satır ${r + 1}' : cleanName,
            subtitle: 'Ad Soyad, numara veya sınıf eksik.',
            status: 'Atlandı',
            success: false,
          ),
        );
        continue;
      }

      drafts.add(
        _StudentDraft(
          name: cleanName,
          number: cleanNumber,
          className: cleanClass,
          tc: cleanTc,
          phone: cleanPhone,
          activationCode: activationCode,
        ),
      );
    }

    return drafts;
  }

  bool _looksLikeHeader(List<dynamic> row) {
    final joined = row.map(_cellText).join(' ').toLowerCase();

    return joined.contains('ad') ||
        joined.contains('soyad') ||
        joined.contains('numara') ||
        joined.contains('sınıf') ||
        joined.contains('sinif') ||
        joined.contains('class') ||
        joined.contains('student');
  }

  String _getByAliases(
    List<dynamic> row,
    Map<String, int> headerMap,
    List<String> aliases,
  ) {
    for (final alias in aliases) {
      final key = AppHelpers.normalizeKey(alias);

      if (headerMap.containsKey(key)) {
        final index = headerMap[key]!;

        if (index >= 0 && index < row.length) {
          return _cellText(row[index]);
        }
      }
    }

    return '';
  }

  String _cellText(dynamic cell) {
    final value = cell?.value;

    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  String _normalizePhone(String value) {
    var digits = AppHelpers.onlyDigits(value);

    if (digits.isEmpty) {
      return '';
    }

    if (!digits.startsWith('0')) {
      digits = '0$digits';
    }

    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }

    if (digits.length < 11) {
      return digits;
    }

    return '0 (${digits.substring(1, 4)}) ${digits.substring(4, 7)} ${digits.substring(7, 9)} ${digits.substring(9, 11)}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      child: Column(
        children: [
          _Hero(
            accent: widget.accent,
            loading: _loading,
            onPick: _pickAndImport,
          ),
          const SizedBox(height: 16),
          _InfoCard(accent: widget.accent),
          const SizedBox(height: 16),
          if (_message.isNotEmpty)
            _ResultBox(message: _message, success: _success),
          if (_message.isNotEmpty) const SizedBox(height: 16),
          if (_logs.isEmpty)
            _EmptyCard(accent: widget.accent)
          else
            ..._logs.map(
              (log) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LogCard(log: log, accent: widget.accent),
              ),
            ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final Color accent;
  final bool loading;
  final VoidCallback onPick;

  const _Hero({
    required this.accent,
    required this.loading,
    required this.onPick,
  });

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
                  Icons.table_chart_rounded,
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
                      'Excel Öğrenci Aktar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '.xlsx dosyasından öğrencileri otomatik ekle.',
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
            height: 54,
            child: ElevatedButton.icon(
              onPressed: loading ? null : onPick,
              icon: loading
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : const Icon(Icons.upload_file_rounded),
              label: Text(loading ? 'Aktarılıyor...' : 'Excel Dosyası Seç'),
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

class _InfoCard extends StatelessWidget {
  final Color accent;

  const _InfoCard({required this.accent});

  @override
  Widget build(BuildContext context) {
    final items = [
      'Başlıklar desteklenir: Ad Soyad, Numara, Sınıf, TC, Telefon',
      'Başlık yoksa sıra: Ad Soyad | Numara | Sınıf | TC | Telefon',
      'Sınıf biçimleri otomatik düzelir: 11B, 11-B, 11/B, 11 b',
      'Her öğrenci için otomatik 6 haneli aktivasyon kodu üretilir.',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.line),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Excel Formatı',
            style: TextStyle(
              color: AppTheme.dark,
              fontWeight: FontWeight.w900,
              fontSize: 19,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, color: accent, size: 19),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        height: 1.35,
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

class _ResultBox extends StatelessWidget {
  final String message;
  final bool success;

  const _ResultBox({required this.message, required this.success});

  @override
  Widget build(BuildContext context) {
    final color = success ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.warning_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final Color accent;

  const _EmptyCard({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.line),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Icon(Icons.table_rows_rounded, color: accent, size: 42),
          const SizedBox(height: 12),
          const Text(
            'Henüz aktarım yapılmadı',
            style: TextStyle(
              color: AppTheme.dark,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Excel seçtiğinde sonuçlar burada listelenecek.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final _ImportLog log;
  final Color accent;

  const _LogCard({required this.log, required this.accent});

  @override
  Widget build(BuildContext context) {
    final color = log.success
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.line),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              log.success ? Icons.check_rounded : Icons.close_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.title,
                  style: const TextStyle(
                    color: AppTheme.dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  log.subtitle,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              log.status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
          if (log.activationCode.trim().isNotEmpty) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Kodu kopyala',
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: log.activationCode),
                );

                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Aktivasyon kodu kopyalandı.')),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              color: accent,
            ),
          ],
        ],
      ),
    );
  }
}

class _StudentDraft {
  final String name;
  final String number;
  final String className;
  final String tc;
  final String phone;
  final String activationCode;

  const _StudentDraft({
    required this.name,
    required this.number,
    required this.className,
    required this.tc,
    required this.phone,
    required this.activationCode,
  });
}

class _ImportLog {
  final String title;
  final String subtitle;
  final String status;
  final bool success;
  final String activationCode;

  const _ImportLog({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.success,
    this.activationCode = '',
  });
}
