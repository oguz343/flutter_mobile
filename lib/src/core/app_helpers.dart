import 'package:cloud_firestore/cloud_firestore.dart';

class AppHelpers {
  static String onlyDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static String normalizeKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll('/', '')
        .replaceAll('\\', '')
        .replaceAll('.', '')
        .replaceAll(':', '')
        .replaceAll(';', '')
        .replaceAll(',', '');
  }

  static String normalizeRoleForSave(String role) {
    final value = normalizeKey(role);

    if (value == 'ogrenci' || value == 'student') {
      return 'Öğrenci';
    }

    if (value == 'ogretmen' || value == 'teacher') {
      return 'Öğretmen';
    }

    if (value == 'veli' || value == 'parent') {
      return 'Veli';
    }

    if (value == 'admin') {
      return 'Admin';
    }

    return role.trim();
  }

  static String roleRoute(String role) {
    final value = normalizeKey(role);

    if (value == 'admin') {
      return '/admin';
    }

    if (value == 'ogretmen' || value == 'teacher') {
      return '/teacher';
    }

    if (value == 'veli' || value == 'parent') {
      return '/parent';
    }

    return '/student';
  }

  static String normalizeClassName(String value) {
    var text = value
        .trim()
        .toUpperCase()
        .replaceAll('SINIF', '')
        .replaceAll('ŞUBE', '')
        .replaceAll('SUBE', '')
        .replaceAll('_', '-')
        .replaceAll('/', '-')
        .replaceAll('\\', '-')
        .replaceAll('.', '-')
        .replaceAll(' ', '');

    final direct = RegExp(r'(9|10|11|12)[^\dA-F]*([A-F])').firstMatch(text);

    if (direct != null) {
      return '${direct.group(1)}-${direct.group(2)}';
    }

    final reverse = RegExp(r'([A-F])[^\dA-F]*(9|10|11|12)').firstMatch(text);

    if (reverse != null) {
      return '${reverse.group(2)}-${reverse.group(1)}';
    }

    return text;
  }

  static String getText(
    Map<String, dynamic> data,
    List<String> keys, {
    String defaultValue = '',
  }) {
    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return defaultValue;
  }

  static bool getBool(
    Map<String, dynamic> data,
    List<String> keys, {
    bool defaultValue = false,
  }) {
    for (final key in keys) {
      final value = data[key];

      if (value is bool) {
        return value;
      }

      if (value is int) {
        return value == 1;
      }

      if (value != null) {
        final text = value.toString().toLowerCase().trim();

        if (text == 'true' || text == '1' || text == 'evet') {
          return true;
        }

        if (text == 'false' || text == '0' || text == 'hayir') {
          return false;
        }
      }
    }

    return defaultValue;
  }

  static bool isDeleted(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return true;
    }

    final deleted = getBool(data, [
      'isDeleted',
      'IsDeleted',
      'deleted',
      'Deleted',
      'isArchived',
      'IsArchived',
      'archived',
      'Archived',
      'isHidden',
      'IsHidden',
      'hidden',
      'Hidden',
      'isRemoved',
      'IsRemoved',
      'removed',
      'Removed',
    ]);

    if (deleted) {
      return true;
    }

    if (hasAnyValue(data, [
      'deletedAt',
      'DeletedAt',
      'removedAt',
      'RemovedAt',
      'archivedAt',
      'ArchivedAt',
    ])) {
      return true;
    }

    final status = normalizeKey(getText(data, ['status', 'Status']));

    return status == 'silindi' ||
        status == 'deleted' ||
        status == 'arsivlendi' ||
        status == 'archived' ||
        status == 'pasif' ||
        status == 'inactive' ||
        status == 'iptal' ||
        status == 'cancelled' ||
        status == 'canceled';
  }

  static bool isInactive(Map<String, dynamic> data) {
    final hasActiveField = hasAnyValue(data, [
      'isActive',
      'IsActive',
      'active',
      'Active',
    ]);

    if (!hasActiveField) {
      return false;
    }

    return !getBool(data, [
      'isActive',
      'IsActive',
      'active',
      'Active',
    ], defaultValue: true);
  }

  static bool isDeletedOrInactive(Map<String, dynamic> data) {
    return isDeleted(data) || isInactive(data);
  }

  static bool hasAnyValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  static bool isPendingStatus(String status) {
    final value = normalizeKey(status);

    return value == 'bekliyor' ||
        value == 'pending' ||
        value == 'onaybekliyor' ||
        value == 'waiting' ||
        value.isEmpty;
  }

  static bool isEvaluatedStatus(String status) {
    final value = normalizeKey(status);

    return value.contains('deger') ||
        value.contains('evaluated') ||
        value == 'notverildi' ||
        value == 'graded';
  }

  static DateTime? getDate(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];

      if (value == null) {
        continue;
      }

      if (value is Timestamp) {
        return value.toDate();
      }

      if (value is DateTime) {
        return value;
      }

      final parsed = DateTime.tryParse(value.toString());

      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  static Timestamp? getTimestamp(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];

      if (value == null) {
        continue;
      }

      if (value is Timestamp) {
        return value;
      }

      if (value is DateTime) {
        return Timestamp.fromDate(value);
      }

      final parsed = DateTime.tryParse(value.toString());

      if (parsed != null) {
        return Timestamp.fromDate(parsed);
      }
    }

    return null;
  }

  static String formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day.$month.$year $hour:$minute';
  }

  static String buildRequestKey({
    required String role,
    required String number,
    required String userId,
  }) {
    final roleKey = normalizeKey(role);
    final numberKey = onlyDigits(number);

    if (roleKey.isNotEmpty && numberKey.isNotEmpty) {
      return '${roleKey}_$numberKey';
    }

    if (userId.trim().isNotEmpty) {
      return normalizeKey(userId);
    }

    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  static String buildSubmissionKey({
    required String assignmentId,
    required String studentNo,
    required String title,
    required String lessonName,
    required String className,
  }) {
    final assignmentKey = normalizeKey(assignmentId);
    final studentKey = onlyDigits(studentNo);

    if (assignmentKey.isNotEmpty && studentKey.isNotEmpty) {
      return '${assignmentKey}_$studentKey';
    }

    return normalizeKey('${title}_${studentNo}_${lessonName}_$className');
  }
}
