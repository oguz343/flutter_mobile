import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_helpers.dart';

class LessonModel {
  final String id;
  final String name;
  final String className;
  final String teacherId;
  final String teacherName;
  final String teacherNo;
  final String teacherNumber;
  final String branch;
  final bool isDeleted;
  final bool isActive;
  final DateTime? createdAt;

  const LessonModel({
    required this.id,
    required this.name,
    required this.className,
    required this.teacherId,
    required this.teacherName,
    required this.teacherNo,
    required this.teacherNumber,
    required this.branch,
    required this.isDeleted,
    required this.isActive,
    required this.createdAt,
  });

  String get displayLessonName => name.trim().isEmpty ? 'Ders' : name;

  String get displayClassName => className.trim().isEmpty ? '-' : className;

  String get displayTeacherName =>
      teacherName.trim().isEmpty ? '-' : teacherName;

  String get displayBranch => branch.trim().isEmpty ? '-' : branch;

  factory LessonModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final name = AppHelpers.getText(data, [
      'name',
      'Name',
      'lessonName',
      'LessonName',
      'title',
      'Title',
      'courseName',
      'CourseName',
    ], defaultValue: 'Ders');

    final className = AppHelpers.normalizeClassName(
      AppHelpers.getText(data, [
        'className',
        'ClassName',
        'class',
        'Class',
        'targetClass',
        'TargetClass',
      ]),
    );

    final teacherId = AppHelpers.getText(data, ['teacherId', 'TeacherId']);

    final teacherName = AppHelpers.getText(data, [
      'teacherName',
      'TeacherName',
      'teacher',
      'Teacher',
    ]);

    final teacherNo = AppHelpers.onlyDigits(
      AppHelpers.getText(data, ['teacherNo', 'TeacherNo']),
    );

    final teacherNumber = AppHelpers.onlyDigits(
      AppHelpers.getText(data, [
        'teacherNumber',
        'TeacherNumber',
        'number',
        'Number',
        'schoolNo',
        'SchoolNo',
      ]),
    );

    final branch = AppHelpers.getText(data, [
      'branch',
      'Branch',
      'teacherBranch',
      'TeacherBranch',
    ], defaultValue: '-');

    return LessonModel(
      id: doc.id,
      name: name.trim().isEmpty ? 'Ders' : name.trim(),
      className: className.trim().isEmpty ? '-' : className.trim(),
      teacherId: teacherId.trim(),
      teacherName: teacherName.trim(),
      teacherNo: teacherNo,
      teacherNumber: teacherNumber,
      branch: branch.trim().isEmpty ? '-' : branch.trim(),
      isDeleted: AppHelpers.isDeleted(data),
      isActive: !AppHelpers.isInactive(data),
      createdAt: AppHelpers.getDate(data, ['createdAt', 'CreatedAt']),
    );
  }
}
