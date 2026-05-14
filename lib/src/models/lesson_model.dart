import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_helpers.dart';

class LessonModel {
  final String id;
  final String name;
  final String className;
  final String teacherName;
  final String teacherNo;
  final String branch;

  const LessonModel({
    required this.id,
    required this.name,
    required this.className,
    required this.teacherName,
    required this.teacherNo,
    required this.branch,
  });

  factory LessonModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final name = AppHelpers.getText(
      data,
      [
        'name',
        'Name',
        'lessonName',
        'LessonName',
        'title',
        'Title',
        'courseName',
        'CourseName',
      ],
      defaultValue: 'Ders',
    );

    final className = AppHelpers.normalizeClassName(
      AppHelpers.getText(
        data,
        [
          'className',
          'ClassName',
          'class',
          'Class',
          'targetClass',
          'TargetClass',
        ],
      ),
    );

    final teacherName = AppHelpers.getText(
      data,
      [
        'teacherName',
        'TeacherName',
        'teacher',
        'Teacher',
      ],
    );

    final teacherNo = AppHelpers.onlyDigits(
      AppHelpers.getText(
        data,
        [
          'teacherNo',
          'TeacherNo',
          'teacherNumber',
          'TeacherNumber',
          'number',
          'Number',
          'schoolNo',
          'SchoolNo',
        ],
      ),
    );

    final branch = AppHelpers.getText(
      data,
      [
        'branch',
        'Branch',
        'teacherBranch',
        'TeacherBranch',
      ],
      defaultValue: '-',
    );

    return LessonModel(
      id: doc.id,
      name: name.trim().isEmpty ? 'Ders' : name.trim(),
      className: className.trim().isEmpty ? '-' : className.trim(),
      teacherName: teacherName.trim(),
      teacherNo: teacherNo,
      branch: branch.trim().isEmpty ? '-' : branch.trim(),
    );
  }
}