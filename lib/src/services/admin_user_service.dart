import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_helpers.dart';
import '../models/app_user.dart';
import 'admin_service.dart';

class AdminUserException implements Exception {
  final String message;

  const AdminUserException(this.message);

  @override
  String toString() => message;
}

class AdminUserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<AppUser>> watchUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      final result = <AppUser>[];
      final seen = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (AppHelpers.isDeleted(data)) {
          continue;
        }

        final user = AppUser.fromDoc(doc);

        if (user.role.trim().isEmpty || user.number.trim().isEmpty) {
          continue;
        }

        final key = AppHelpers.normalizeKey('${user.role}_${user.number}');

        if (seen.contains(key)) {
          continue;
        }

        seen.add(key);
        result.add(user);
      }

      result.sort((a, b) {
        final roleCompare = a.role.compareTo(b.role);

        if (roleCompare != 0) {
          return roleCompare;
        }

        return a.name.compareTo(b.name);
      });

      return result;
    });
  }

  Stream<List<PasswordRequestModel>> watchPasswordRequests() {
    return _db.collection('passwordRequests').snapshots().asyncMap((_) async {
      return AdminService().loadPasswordRequests();
    });
  }

  Future<void> createUser({
    required String role,
    required String name,
    required String number,
    required String password,
    required String tc,
    required String phone,
    required String className,
    required String branch,
    required String linkedStudentNo,
  }) async {
    final cleanRole = AppHelpers.normalizeRoleForSave(role);
    final cleanName = name.trim();
    final cleanNumber = AppHelpers.onlyDigits(number);
    final cleanActivationCode = password.trim();
    final cleanTc = AppHelpers.onlyDigits(tc);
    final cleanPhone = phone.trim();
    final cleanClassName = AppHelpers.normalizeClassName(className);
    final cleanBranch = branch.trim();
    final cleanLinkedStudentNo = AppHelpers.onlyDigits(linkedStudentNo);

    if (cleanRole.isEmpty) {
      throw const AdminUserException('Rol seçmelisiniz.');
    }

    if (cleanName.isEmpty) {
      throw const AdminUserException('Ad Soyad boş bırakılamaz.');
    }

    if (cleanNumber.isEmpty) {
      throw const AdminUserException('Numara boş bırakılamaz.');
    }

    if (cleanActivationCode.isEmpty) {
      throw const AdminUserException('Aktivasyon kodu boş bırakılamaz.');
    }

    if (cleanTc.isNotEmpty && cleanTc.length != 11) {
      throw const AdminUserException('TC kimlik numarası 11 hane olmalı.');
    }

    if (AppHelpers.normalizeKey(cleanRole) == 'ogrenci' &&
        cleanClassName.isEmpty) {
      throw const AdminUserException('Öğrenci için sınıf seçmelisiniz.');
    }

    if (AppHelpers.normalizeKey(cleanRole) == 'ogretmen' &&
        cleanBranch.isEmpty) {
      throw const AdminUserException('Öğretmen için branş yazmalısınız.');
    }

    if (AppHelpers.normalizeKey(cleanRole) == 'veli' &&
        cleanLinkedStudentNo.isEmpty) {
      throw const AdminUserException(
        'Veli için bağlı öğrenci numarası yazmalısınız.',
      );
    }

    final exists = await numberExists(cleanNumber);

    if (exists) {
      throw const AdminUserException(
        'Bu numarayla kayıtlı bir kullanıcı zaten var.',
      );
    }

    final now = Timestamp.now();

    final data = <String, dynamic>{
      'role': cleanRole,
      'Role': cleanRole,
      'name': cleanName,
      'Name': cleanName,
      'number': cleanNumber,
      'Number': cleanNumber,
      'schoolNo': cleanNumber,
      'SchoolNo': cleanNumber,
      'password': '',
      'Password': '',
      'activationCode': cleanActivationCode,
      'ActivationCode': cleanActivationCode,
      'mustChangePassword': true,
      'MustChangePassword': true,
      'tc': cleanTc,
      'TC': cleanTc,
      'phone': cleanPhone,
      'Phone': cleanPhone,
      'className': cleanClassName,
      'ClassName': cleanClassName,
      'class': cleanClassName,
      'Class': cleanClassName,
      'branch': cleanBranch,
      'Branch': cleanBranch,
      'teacherBranch': cleanBranch,
      'TeacherBranch': cleanBranch,
      'linkedStudentNo': cleanLinkedStudentNo,
      'LinkedStudentNo': cleanLinkedStudentNo,
      'isDeleted': false,
      'IsDeleted': false,
      'isActive': true,
      'IsActive': true,
      'createdAt': now,
      'CreatedAt': now,
      'updatedAt': now,
      'UpdatedAt': now,
    };

    await _db.collection('users').add(data);
  }

  Future<void> updateUser({
    required AppUser user,
    required String role,
    required String name,
    required String number,
    required String tc,
    required String phone,
    required String className,
    required String branch,
    required String linkedStudentNo,
  }) async {
    final cleanRole = AppHelpers.normalizeRoleForSave(role);
    final cleanName = name.trim();
    final cleanNumber = AppHelpers.onlyDigits(number);
    final cleanTc = AppHelpers.onlyDigits(tc);
    final cleanPhone = phone.trim();
    final cleanClassName = AppHelpers.normalizeClassName(className);
    final cleanBranch = branch.trim();
    final cleanLinkedStudentNo = AppHelpers.onlyDigits(linkedStudentNo);

    if (cleanName.isEmpty) {
      throw const AdminUserException('Ad Soyad boş bırakılamaz.');
    }

    if (cleanNumber.isEmpty) {
      throw const AdminUserException('Numara boş bırakılamaz.');
    }

    if (cleanTc.isNotEmpty && cleanTc.length != 11) {
      throw const AdminUserException('TC kimlik numarası 11 hane olmalı.');
    }

    final exists = await numberExists(cleanNumber, exceptUserId: user.id);

    if (exists) {
      throw const AdminUserException(
        'Bu numarayla kayıtlı başka bir kullanıcı zaten var.',
      );
    }

    await _db.collection('users').doc(user.id).set({
      'role': cleanRole,
      'Role': cleanRole,
      'name': cleanName,
      'Name': cleanName,
      'number': cleanNumber,
      'Number': cleanNumber,
      'schoolNo': cleanNumber,
      'SchoolNo': cleanNumber,
      'tc': cleanTc,
      'TC': cleanTc,
      'phone': cleanPhone,
      'Phone': cleanPhone,
      'className': cleanClassName,
      'ClassName': cleanClassName,
      'class': cleanClassName,
      'Class': cleanClassName,
      'branch': cleanBranch,
      'Branch': cleanBranch,
      'teacherBranch': cleanBranch,
      'TeacherBranch': cleanBranch,
      'linkedStudentNo': cleanLinkedStudentNo,
      'LinkedStudentNo': cleanLinkedStudentNo,
      'updatedAt': Timestamp.now(),
      'UpdatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> softDeleteUser(AppUser user) async {
    await _db.collection('users').doc(user.id).set({
      'isDeleted': true,
      'IsDeleted': true,
      'isActive': false,
      'IsActive': false,
      'deletedAt': Timestamp.now(),
      'DeletedAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'UpdatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<bool> numberExists(String number, {String? exceptUserId}) async {
    final cleanNumber = AppHelpers.onlyDigits(number);

    if (cleanNumber.isEmpty) {
      return false;
    }

    final snapshot = await _db.collection('users').get();

    for (final doc in snapshot.docs) {
      if (exceptUserId != null && doc.id == exceptUserId) {
        continue;
      }

      final data = doc.data();

      if (AppHelpers.isDeleted(data)) {
        continue;
      }

      final currentNumber = AppHelpers.onlyDigits(
        AppHelpers.getText(data, [
          'number',
          'Number',
          'schoolNo',
          'SchoolNo',
          'studentNo',
          'StudentNo',
          'teacherNo',
          'TeacherNo',
          'adminNo',
          'AdminNo',
        ]),
      );

      if (currentNumber == cleanNumber) {
        return true;
      }
    }

    return false;
  }

  Future<String> approvePasswordRequest(PasswordRequestModel request) async {
    final newPassword = _generateTempPassword();

    final user = await _findUserByRoleAndNumber(
      role: request.role,
      number: request.number,
    );

    if (user == null) {
      throw const AdminUserException('Bu talebe ait kullanıcı bulunamadı.');
    }

    final now = Timestamp.now();

    await _db.collection('users').doc(user.id).set({
      'password': newPassword,
      'Password': newPassword,
      'activationCode': newPassword,
      'ActivationCode': newPassword,
      'mustChangePassword': true,
      'MustChangePassword': true,
      'updatedAt': now,
      'UpdatedAt': now,
    }, SetOptions(merge: true));

    await _updatePasswordRequestStatus(
      request: request,
      status: 'Onaylandı',
      extra: {
        'newPassword': newPassword,
        'NewPassword': newPassword,
        'completedAt': now,
        'CompletedAt': now,
      },
    );

    return newPassword;
  }

  Future<void> rejectPasswordRequest(PasswordRequestModel request) async {
    await _updatePasswordRequestStatus(
      request: request,
      status: 'Reddedildi',
      extra: {'rejectedAt': Timestamp.now(), 'RejectedAt': Timestamp.now()},
    );
  }

  Future<AppUser?> _findUserByRoleAndNumber({
    required String role,
    required String number,
  }) async {
    final roleKey = AppHelpers.normalizeKey(role);
    final numberKey = AppHelpers.onlyDigits(number);

    final snapshot = await _db.collection('users').get();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      if (AppHelpers.isDeleted(data)) {
        continue;
      }

      final user = AppUser.fromDoc(doc);

      final userRoleKey = AppHelpers.normalizeKey(user.role);
      final userNumberKey = AppHelpers.onlyDigits(user.number);

      if (userRoleKey == roleKey && userNumberKey == numberKey) {
        return user;
      }
    }

    return null;
  }

  Future<void> _updatePasswordRequestStatus({
    required PasswordRequestModel request,
    required String status,
    required Map<String, dynamic> extra,
  }) async {
    final update = <String, dynamic>{
      'status': status,
      'Status': status,
      'isActive': false,
      'IsActive': false,
      'updatedAt': Timestamp.now(),
      'UpdatedAt': Timestamp.now(),
      ...extra,
    };

    final collections = ['passwordRequests', 'password_requests'];

    for (final collection in collections) {
      try {
        final directDoc = await _db
            .collection(collection)
            .doc(request.id)
            .get();

        if (directDoc.exists) {
          await directDoc.reference.set(update, SetOptions(merge: true));
        }
      } catch (_) {}

      try {
        final snapshot = await _db.collection(collection).get();

        for (final doc in snapshot.docs) {
          final data = doc.data();

          final role = AppHelpers.normalizeKey(
            AppHelpers.getText(data, ['role', 'Role']),
          );

          final number = AppHelpers.onlyDigits(
            AppHelpers.getText(data, [
              'number',
              'Number',
              'schoolNo',
              'SchoolNo',
              'studentNo',
              'StudentNo',
            ]),
          );

          if (role == AppHelpers.normalizeKey(request.role) &&
              number == AppHelpers.onlyDigits(request.number)) {
            await doc.reference.set(update, SetOptions(merge: true));
          }
        }
      } catch (_) {}
    }
  }

  String _generateTempPassword() {
    return generateActivationCode();
  }

  String generateActivationCode() {
    final random = Random();
    final number = 100000 + random.nextInt(900000);

    return number.toString();
  }
}
