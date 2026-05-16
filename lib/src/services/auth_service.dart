import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../core/app_helpers.dart';
import '../models/app_user.dart';

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

class LoginResult {
  final AppUser user;
  final bool requiresPasswordChange;

  const LoginResult({required this.user, required this.requiresPasswordChange});
}

class AuthService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _adminNumber = '0000';
  static const String _adminPassword = 'admin123';

  Future<LoginResult> login({
    required String role,
    required String number,
    required String password,
  }) async {
    final cleanRole = AppHelpers.normalizeRoleForSave(role);
    final cleanNumber = number.trim();
    final cleanPassword = password.trim();

    if (cleanRole.isEmpty) {
      throw const AuthException('Rol seçmelisiniz.');
    }

    if (cleanNumber.isEmpty) {
      throw const AuthException('Numara boş bırakılamaz.');
    }

    if (cleanPassword.isEmpty) {
      throw const AuthException('Şifre boş bırakılamaz.');
    }

    final roleKey = AppHelpers.normalizeKey(cleanRole);
    final cleanNumberDigits = AppHelpers.onlyDigits(cleanNumber);

    final user = await findUserByRoleAndNumber(
      role: cleanRole,
      number: cleanNumber,
    );

    if (user == null) {
      throw const AuthException(
        'Bu role ve numaraya ait kullanıcı bulunamadı.',
      );
    }

    if (user.isDeleted) {
      throw const AuthException('Bu kullanıcı pasif veya silinmiş görünüyor.');
    }

    /*
      ÖNEMLİ:
      Admin kaydı Firebase'de varsa, MVC'deki admin giriş bilgileriyle girişe izin veriyoruz.
      Bu kayıt yoksa zaten yukarıda user == null olur ve giriş yapmaz.
      Yani kayıtsız/hayali admin girişi yok.
    */
    if (roleKey == 'admin' &&
        cleanNumberDigits == _adminNumber &&
        cleanPassword == _adminPassword) {
      return LoginResult(
        user: user.copyWith(
          role: 'Admin',
          number: _adminNumber,
          password: _adminPassword,
          mustChangePassword: false,
          activationCode: '',
        ),
        requiresPasswordChange: false,
      );
    }

    final activationMatches =
        user.activationCode.trim().isNotEmpty &&
        AppHelpers.normalizeKey(user.activationCode) ==
            AppHelpers.normalizeKey(cleanPassword);

    final passwordMatches = _passwordMatches(
      storedPassword: user.password,
      enteredPassword: cleanPassword,
    );

    if (user.mustChangePassword) {
      if (activationMatches || passwordMatches) {
        return LoginResult(user: user, requiresPasswordChange: true);
      }

      throw const AuthException(
        'İlk giriş için aktivasyon kodunuzu girmeniz gerekiyor.',
      );
    }

    if (passwordMatches) {
      return LoginResult(user: user, requiresPasswordChange: false);
    }

    if (activationMatches) {
      return LoginResult(user: user, requiresPasswordChange: true);
    }

    throw const AuthException('Şifre hatalı. Bilgilerinizi kontrol edin.');
  }

  bool _passwordMatches({
    required String storedPassword,
    required String enteredPassword,
  }) {
    final stored = storedPassword.trim();
    final entered = enteredPassword.trim();

    if (stored.isEmpty || entered.isEmpty) {
      return false;
    }

    if (_verifyPbkdf2Password(entered, stored)) {
      return true;
    }

    if (stored == entered) {
      return true;
    }

    if (AppHelpers.normalizeKey(stored) == AppHelpers.normalizeKey(entered)) {
      return true;
    }

    return false;
  }

  bool _verifyPbkdf2Password(String enteredPassword, String storedHash) {
    const prefix = 'PBKDF2_V1';
    final parts = storedHash.split(r'$');

    if (parts.length != 4 || parts.first != prefix) {
      return false;
    }

    final iterations = int.tryParse(parts[1]);

    if (iterations == null || iterations <= 0) {
      return false;
    }

    try {
      final salt = base64Decode(parts[2]);
      final expectedHash = base64Decode(parts[3]);
      final actualHash = _pbkdf2Sha256(
        password: utf8.encode(enteredPassword),
        salt: salt,
        iterations: iterations,
        length: expectedHash.length,
      );

      return _constantTimeEquals(actualHash, expectedHash);
    } catch (_) {
      return false;
    }
  }

  Uint8List _pbkdf2Sha256({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int length,
  }) {
    final hmac = Hmac(sha256, password);
    final blockCount = (length / hmac.convert(<int>[]).bytes.length).ceil();
    final output = BytesBuilder(copy: false);

    for (var blockIndex = 1; blockIndex <= blockCount; blockIndex++) {
      final blockSalt = <int>[
        ...salt,
        (blockIndex >> 24) & 0xff,
        (blockIndex >> 16) & 0xff,
        (blockIndex >> 8) & 0xff,
        blockIndex & 0xff,
      ];

      var u = hmac.convert(blockSalt).bytes;
      final block = List<int>.from(u);

      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;

        for (var j = 0; j < block.length; j++) {
          block[j] ^= u[j];
        }
      }

      output.add(block);
    }

    return Uint8List.fromList(output.toBytes().take(length).toList());
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }

    var diff = 0;

    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }

    return diff == 0;
  }

  Future<AppUser?> findUserByRoleAndNumber({
    required String role,
    required String number,
  }) async {
    final roleKey = AppHelpers.normalizeKey(role);
    final loginKey = AppHelpers.normalizeKey(number);
    final numberKey = AppHelpers.onlyDigits(number);

    final collections = roleKey == 'admin'
        ? <String>['users', 'admins', 'admin']
        : <String>['users'];

    for (final collection in collections) {
      try {
        final snapshot = await _db.collection(collection).get();

        for (final doc in snapshot.docs) {
          final data = doc.data();

          if (AppHelpers.isDeleted(data)) {
            continue;
          }

          var user = AppUser.fromDoc(doc);

          var userRole = AppHelpers.getText(data, [
            'role',
            'Role',
            'userRole',
            'UserRole',
          ]);

          if (userRole.trim().isEmpty) {
            userRole = user.role;
          }

          if ((collection == 'admins' || collection == 'admin') &&
              userRole.trim().isEmpty) {
            userRole = 'Admin';
          }

          final userRoleKey = AppHelpers.normalizeKey(userRole);

          if (userRoleKey != roleKey) {
            continue;
          }

          final possibleLoginValues = <String>[
            AppHelpers.getText(data, ['schoolNo', 'SchoolNo']),
            AppHelpers.getText(data, ['number', 'Number']),
            AppHelpers.getText(data, ['studentNo', 'StudentNo']),
            AppHelpers.getText(data, ['teacherNo', 'TeacherNo']),
            AppHelpers.getText(data, ['adminNo', 'AdminNo']),
            AppHelpers.getText(data, ['adminNumber', 'AdminNumber']),
            AppHelpers.getText(data, ['username', 'Username']),
            AppHelpers.getText(data, ['userName', 'UserName']),
            AppHelpers.getText(data, ['login', 'Login']),
            AppHelpers.getText(data, ['loginId', 'LoginId']),
            AppHelpers.getText(data, ['email', 'Email']),
          ];

          final matchesLogin = possibleLoginValues.any((value) {
            final valueKey = AppHelpers.normalizeKey(value);
            final valueDigits = AppHelpers.onlyDigits(value);

            if (roleKey == 'admin') {
              return valueKey == loginKey ||
                  (numberKey.isNotEmpty && valueDigits == numberKey);
            }

            return numberKey.isNotEmpty && valueDigits == numberKey;
          });

          if (!matchesLogin) {
            continue;
          }

          final password = AppHelpers.getText(data, [
            'password',
            'Password',
            'passwordHash',
            'PasswordHash',
            'hash',
            'Hash',
            'adminPassword',
            'AdminPassword',
            'pass',
            'Pass',
            'sifre',
            'Sifre',
            'şifre',
            'Şifre',
          ]);

          final activationCode = AppHelpers.getText(data, [
            'activationCode',
            'ActivationCode',
            'activation',
            'Activation',
            'code',
            'Code',
          ]);

          final mustChangePassword = AppHelpers.getBool(data, [
            'mustChangePassword',
            'MustChangePassword',
            'firstLogin',
            'FirstLogin',
            'isFirstLogin',
            'IsFirstLogin',
          ]);

          final realNumber = AppHelpers.onlyDigits(
            AppHelpers.getText(data, [
              'schoolNo',
              'SchoolNo',
              'number',
              'Number',
              'studentNo',
              'StudentNo',
              'teacherNo',
              'TeacherNo',
              'adminNo',
              'AdminNo',
              'adminNumber',
              'AdminNumber',
            ]),
          );

          user = user.copyWith(
            role: AppHelpers.normalizeRoleForSave(userRole),
            number: realNumber.isNotEmpty ? realNumber : number,
            password: password,
            activationCode: activationCode,
            mustChangePassword: mustChangePassword,
          );

          return user;
        }
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  Future<AppUser?> findUserByRoleNameAndNumber({
    required String role,
    required String name,
    required String number,
  }) async {
    final roleKey = AppHelpers.normalizeKey(role);
    final nameKey = AppHelpers.normalizeKey(name);
    final numberKey = AppHelpers.onlyDigits(number);

    final snapshot = await _db.collection('users').get();

    for (final doc in snapshot.docs) {
      final user = AppUser.fromDoc(doc);

      if (user.isDeleted) {
        continue;
      }

      final userRoleKey = AppHelpers.normalizeKey(user.role);
      final userNameKey = AppHelpers.normalizeKey(user.name);
      final userNumberKey = AppHelpers.onlyDigits(user.number);

      if (userRoleKey == roleKey &&
          userNameKey == nameKey &&
          userNumberKey == numberKey) {
        return user;
      }
    }

    return null;
  }

  Future<void> sendPasswordRequest({
    required String role,
    required String name,
    required String number,
    required String note,
  }) async {
    final cleanRole = AppHelpers.normalizeRoleForSave(role);
    final cleanName = name.trim();
    final cleanNumber = AppHelpers.onlyDigits(number);
    final cleanNote = note.trim();

    if (cleanRole.isEmpty) {
      throw const AuthException('Rol boş bırakılamaz.');
    }

    if (cleanName.isEmpty) {
      throw const AuthException('Ad Soyad boş bırakılamaz.');
    }

    if (cleanNumber.isEmpty) {
      throw const AuthException('Numara boş bırakılamaz.');
    }

    final user = await findUserByRoleNameAndNumber(
      role: cleanRole,
      name: cleanName,
      number: cleanNumber,
    );

    if (user == null) {
      throw const AuthException(
        'Ad Soyad, rol ve numara birbiriyle uyuşmuyor. Bilgilerinizi kontrol edin.',
      );
    }

    final hasPending = await hasPendingPasswordRequest(
      role: cleanRole,
      number: cleanNumber,
      userId: user.id,
    );

    if (hasPending) {
      throw const AuthException(
        'Bu kullanıcı için zaten bekleyen bir şifre talebi var.',
      );
    }

    final requestKey = AppHelpers.buildRequestKey(
      role: cleanRole,
      number: cleanNumber,
      userId: user.id,
    );

    final now = Timestamp.now();

    final data = <String, dynamic>{
      'requestKey': requestKey,
      'userId': user.id,
      'name': user.name,
      'userName': user.name,
      'fullName': user.name,
      'role': cleanRole,
      'number': cleanNumber,
      'schoolNo': cleanNumber,
      'studentNo': cleanNumber,
      'note': cleanNote,
      'message': cleanNote,
      'status': 'Bekliyor',
      'createdAt': now,
      'updatedAt': now,
      'isDeleted': false,
      'isActive': true,
    };

    await _db
        .collection('passwordRequests')
        .doc(requestKey)
        .set(data, SetOptions(merge: true));

    await _db
        .collection('password_requests')
        .doc(requestKey)
        .set(data, SetOptions(merge: true));
  }

  Future<bool> hasPendingPasswordRequest({
    required String role,
    required String number,
    required String userId,
  }) async {
    final collections = ['passwordRequests', 'password_requests'];

    final roleKey = AppHelpers.normalizeKey(role);
    final numberKey = AppHelpers.onlyDigits(number);

    for (final collection in collections) {
      final snapshot = await _db.collection(collection).get();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (AppHelpers.isDeleted(data)) {
          continue;
        }

        final requestRole = AppHelpers.normalizeKey(
          AppHelpers.getText(data, ['role', 'Role']),
        );

        final requestNumber = AppHelpers.onlyDigits(
          AppHelpers.getText(data, [
            'number',
            'Number',
            'schoolNo',
            'SchoolNo',
            'studentNo',
            'StudentNo',
          ]),
        );

        final requestUserId = AppHelpers.getText(data, ['userId', 'UserId']);

        final status = AppHelpers.getText(data, ['status', 'Status']);

        final sameUser =
            requestUserId == userId ||
            (requestRole == roleKey && requestNumber == numberKey);

        if (sameUser && AppHelpers.isPendingStatus(status)) {
          return true;
        }
      }
    }

    return false;
  }

  Future<AppUser> changePassword({
    required AppUser user,
    required String newPassword,
  }) async {
    final cleanPassword = newPassword.trim();

    if (cleanPassword.length < 4) {
      throw const AuthException('Yeni şifre en az 4 karakter olmalı.');
    }

    final now = Timestamp.now();

    await _db.collection('users').doc(user.id).set({
      'password': cleanPassword,
      'mustChangePassword': false,
      'activationCode': '',
      'updatedAt': now,
      'passwordChangedAt': now,
    }, SetOptions(merge: true));

    await _completePasswordRequestsForUser(user);

    return user.copyWith(
      password: cleanPassword,
      mustChangePassword: false,
      activationCode: '',
    );
  }

  Future<void> _completePasswordRequestsForUser(AppUser user) async {
    final collections = ['passwordRequests', 'password_requests'];

    for (final collection in collections) {
      final snapshot = await _db.collection(collection).get();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final requestUserId = AppHelpers.getText(data, ['userId', 'UserId']);

        final requestRole = AppHelpers.normalizeKey(
          AppHelpers.getText(data, ['role', 'Role']),
        );

        final requestNumber = AppHelpers.onlyDigits(
          AppHelpers.getText(data, [
            'number',
            'Number',
            'schoolNo',
            'SchoolNo',
            'studentNo',
            'StudentNo',
          ]),
        );

        final same =
            requestUserId == user.id ||
            (requestRole == AppHelpers.normalizeKey(user.role) &&
                requestNumber == AppHelpers.onlyDigits(user.number));

        if (!same) {
          continue;
        }

        await doc.reference.set({
          'status': 'Tamamlandı',
          'isActive': false,
          'completedAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));
      }
    }
  }
}
