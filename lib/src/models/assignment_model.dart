import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_helpers.dart';

class AssignmentModel {
  final String id;
  final String title;
  final String description;
  final String lessonName;
  final String className;
  final String teacherName;
  final String teacherNo;
  final String branch;
  final String fileType;
  final DateTime? createdAt;
  final DateTime? dueDate;

  const AssignmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.lessonName,
    required this.className,
    required this.teacherName,
    required this.teacherNo,
    required this.branch,
    required this.fileType,
    required this.createdAt,
    required this.dueDate,
  });

  factory AssignmentModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final title = AppHelpers.getText(
      data,
      [
        'title',
        'Title',
        'name',
        'Name',
        'homeworkTitle',
        'HomeworkTitle',
        'assignmentTitle',
        'AssignmentTitle',
      ],
      defaultValue: 'Ödev',
    );

    final description = AppHelpers.getText(
      data,
      [
        'description',
        'Description',
        'content',
        'Content',
        'text',
        'Text',
      ],
      defaultValue: '-',
    );

    final lessonName = AppHelpers.getText(
      data,
      [
        'lessonName',
        'LessonName',
        'lesson',
        'Lesson',
        'courseName',
        'CourseName',
        'course',
        'Course',
      ],
      defaultValue: '-',
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
      defaultValue: '-',
    );

    final teacherNo = AppHelpers.onlyDigits(
      AppHelpers.getText(
        data,
        [
          'teacherNo',
          'TeacherNo',
          'teacherNumber',
          'TeacherNumber',
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

    final fileType = AppHelpers.getText(
      data,
      [
        'fileType',
        'FileType',
        'type',
        'Type',
        'submissionType',
        'SubmissionType',
      ],
      defaultValue: 'Metin / Dosya',
    );

    final createdAt = AppHelpers.getDate(
      data,
      [
        'createdAt',
        'CreatedAt',
      ],
    );

    final dueDate = AppHelpers.getDate(
      data,
      [
        'dueDate',
        'DueDate',
        'deadline',
        'Deadline',
        'endDate',
        'EndDate',
      ],
    );

    return AssignmentModel(
      id: doc.id,
      title: title.trim().isEmpty ? 'Ödev' : title.trim(),
      description: description.trim().isEmpty ? '-' : description.trim(),
      lessonName: lessonName.trim().isEmpty ? '-' : lessonName.trim(),
      className: className.trim().isEmpty ? '-' : className.trim(),
      teacherName: teacherName.trim().isEmpty ? '-' : teacherName.trim(),
      teacherNo: teacherNo,
      branch: branch.trim().isEmpty ? '-' : branch.trim(),
      fileType: fileType.trim().isEmpty ? 'Metin / Dosya' : fileType.trim(),
      createdAt: createdAt,
      dueDate: dueDate,
    );
  }
}