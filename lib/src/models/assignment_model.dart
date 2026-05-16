import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_helpers.dart';

class AssignmentModel {
  final String id;
  final String title;
  final String description;
  final String lessonId;
  final String lessonName;
  final String className;
  final String teacherId;
  final String teacherName;
  final String teacherNo;
  final String teacherNumber;
  final String branch;
  final String fileType;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? dueDate;
  final bool isDeleted;
  final bool isActive;

  const AssignmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.lessonId,
    required this.lessonName,
    required this.className,
    required this.teacherId,
    required this.teacherName,
    required this.teacherNo,
    required this.teacherNumber,
    required this.branch,
    required this.fileType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.dueDate,
    required this.isDeleted,
    required this.isActive,
  });

  factory AssignmentModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final title = AppHelpers.getText(data, [
      'title',
      'Title',
      'name',
      'Name',
      'homeworkTitle',
      'HomeworkTitle',
      'assignmentTitle',
      'AssignmentTitle',
    ], defaultValue: 'Ödev');

    final description = AppHelpers.getText(data, [
      'description',
      'Description',
      'content',
      'Content',
      'text',
      'Text',
    ], defaultValue: '-');

    final lessonId = AppHelpers.getText(data, ['lessonId', 'LessonId']);

    final lessonName = AppHelpers.getText(data, [
      'lessonName',
      'LessonName',
      'lesson',
      'Lesson',
      'courseName',
      'CourseName',
      'course',
      'Course',
    ], defaultValue: '-');

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
    ], defaultValue: '-');

    final teacherNo = AppHelpers.onlyDigits(
      AppHelpers.getText(data, ['teacherNo', 'TeacherNo']),
    );

    final teacherNumber = AppHelpers.onlyDigits(
      AppHelpers.getText(data, [
        'teacherNumber',
        'TeacherNumber',
        'number',
        'Number',
      ]),
    );

    final branch = AppHelpers.getText(data, [
      'branch',
      'Branch',
      'teacherBranch',
      'TeacherBranch',
    ], defaultValue: '-');

    final fileType = AppHelpers.getText(data, [
      'fileType',
      'FileType',
      'type',
      'Type',
      'submissionType',
      'SubmissionType',
    ], defaultValue: 'Metin / Dosya');

    final status = AppHelpers.getText(data, [
      'status',
      'Status',
    ], defaultValue: 'Aktif');

    final createdAt = AppHelpers.getDate(data, ['createdAt', 'CreatedAt']);

    final updatedAt = AppHelpers.getDate(data, ['updatedAt', 'UpdatedAt']);

    final dueDate = AppHelpers.getDate(data, [
      'dueDate',
      'DueDate',
      'deadline',
      'Deadline',
      'endDate',
      'EndDate',
    ]);

    return AssignmentModel(
      id: doc.id,
      title: title.trim().isEmpty ? 'Ödev' : title.trim(),
      description: description.trim().isEmpty ? '-' : description.trim(),
      lessonId: lessonId.trim(),
      lessonName: lessonName.trim().isEmpty ? '-' : lessonName.trim(),
      className: className.trim().isEmpty ? '-' : className.trim(),
      teacherId: teacherId.trim(),
      teacherName: teacherName.trim().isEmpty ? '-' : teacherName.trim(),
      teacherNo: teacherNo,
      teacherNumber: teacherNumber,
      branch: branch.trim().isEmpty ? '-' : branch.trim(),
      fileType: fileType.trim().isEmpty ? 'Metin / Dosya' : fileType.trim(),
      status: status.trim().isEmpty ? 'Aktif' : status.trim(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      dueDate: dueDate,
      isDeleted: AppHelpers.isDeleted(data),
      isActive: !AppHelpers.isInactive(data),
    );
  }
}
