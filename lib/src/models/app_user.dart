import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_helpers.dart';

class AppUser {
  final String id;
  final String role;
  final String name;
  final String number;
  final String tc;
  final String phone;
  final String className;
  final String branch;
  final String linkedStudentNo;
  final String password;
  final String activationCode;
  final bool mustChangePassword;
  final bool isDeleted;

  const AppUser({
    required this.id,
    required this.role,
    required this.name,
    required this.number,
    required this.tc,
    required this.phone,
    required this.className,
    required this.branch,
    required this.linkedStudentNo,
    required this.password,
    required this.activationCode,
    required this.mustChangePassword,
    required this.isDeleted,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final role = AppHelpers.normalizeRoleForSave(
      AppHelpers.getText(data, ['role', 'Role', 'userRole', 'UserRole']),
    );

    final name = AppHelpers.getText(data, [
      'name',
      'Name',
      'fullName',
      'FullName',
      'userName',
      'UserName',
      'displayName',
      'DisplayName',
    ], defaultValue: 'Kullanıcı');

    final number = AppHelpers.onlyDigits(
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
        'adminNumber',
        'AdminNumber',
      ]),
    );

    final tc = AppHelpers.onlyDigits(
      AppHelpers.getText(data, ['tc', 'TC', 'identityNo', 'IdentityNo']),
    );

    final phone = AppHelpers.getText(data, [
      'phone',
      'Phone',
      'telephone',
      'Telephone',
      'parentPhone',
      'ParentPhone',
    ]);

    final className = AppHelpers.normalizeClassName(
      AppHelpers.getText(data, [
        'className',
        'ClassName',
        'class',
        'Class',
        'studentClass',
        'StudentClass',
      ]),
    );

    final branch = AppHelpers.getText(data, [
      'branch',
      'Branch',
      'teacherBranch',
      'TeacherBranch',
    ]);

    final linkedStudentNo = AppHelpers.onlyDigits(
      AppHelpers.getText(data, [
        'linkedStudentNo',
        'LinkedStudentNo',
        'studentNumber',
        'StudentNumber',
        'childNo',
        'ChildNo',
      ]),
    );

    final password = AppHelpers.getText(data, [
      'password',
      'Password',
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

    return AppUser(
      id: doc.id,
      role: role,
      name: name.trim().isEmpty ? 'Kullanıcı' : name.trim(),
      number: number,
      tc: tc,
      phone: phone.trim(),
      className: className.trim(),
      branch: branch.trim(),
      linkedStudentNo: linkedStudentNo,
      password: password,
      activationCode: activationCode,
      mustChangePassword: mustChangePassword,
      isDeleted: AppHelpers.isDeleted(data),
    );
  }

  AppUser copyWith({
    String? id,
    String? role,
    String? name,
    String? number,
    String? tc,
    String? phone,
    String? className,
    String? branch,
    String? linkedStudentNo,
    String? password,
    String? activationCode,
    bool? mustChangePassword,
    bool? isDeleted,
  }) {
    return AppUser(
      id: id ?? this.id,
      role: role ?? this.role,
      name: name ?? this.name,
      number: number ?? this.number,
      tc: tc ?? this.tc,
      phone: phone ?? this.phone,
      className: className ?? this.className,
      branch: branch ?? this.branch,
      linkedStudentNo: linkedStudentNo ?? this.linkedStudentNo,
      password: password ?? this.password,
      activationCode: activationCode ?? this.activationCode,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
