import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_helpers.dart';

class SubmissionModel {
  final String id;
  final String assignmentId;
  final String studentNo;
  final String studentName;
  final String title;
  final String lessonName;
  final String className;
  final String answer;
  final String link;
  final String score;
  final String feedback;
  final String status;
  final DateTime? submittedAt;
  final DateTime? evaluatedAt;

  const SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentNo,
    required this.studentName,
    required this.title,
    required this.lessonName,
    required this.className,
    required this.answer,
    required this.link,
    required this.score,
    required this.feedback,
    required this.status,
    required this.submittedAt,
    required this.evaluatedAt,
  });

  factory SubmissionModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final assignmentId = AppHelpers.getText(
      data,
      [
        'homeworkId',
        'HomeworkId',
        'assignmentId',
        'AssignmentId',
      ],
    );

    final studentNo = AppHelpers.onlyDigits(
      AppHelpers.getText(
        data,
        [
          'studentNo',
          'StudentNo',
          'studentNumber',
          'StudentNumber',
          'schoolNo',
          'SchoolNo',
          'number',
          'Number',
        ],
      ),
    );

    final title = AppHelpers.getText(
      data,
      [
        'assignmentTitle',
        'AssignmentTitle',
        'homeworkTitle',
        'HomeworkTitle',
        'title',
        'Title',
        'name',
        'Name',
      ],
      defaultValue: 'Ödev',
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

    final answer = AppHelpers.getText(
      data,
      [
        'answerText',
        'AnswerText',
        'answer',
        'Answer',
        'content',
        'Content',
        'text',
        'Text',
      ],
      defaultValue: '-',
    );

    final link = AppHelpers.getText(
      data,
      [
        'answerLink',
        'AnswerLink',
        'fileUrl',
        'FileUrl',
        'submissionFileUrl',
        'SubmissionFileUrl',
        'link',
        'Link',
        'url',
        'Url',
      ],
    );

    final score = AppHelpers.getText(
      data,
      [
        'score',
        'Score',
        'grade',
        'Grade',
        'point',
        'Point',
        'not',
        'Not',
      ],
    );

    final feedback = AppHelpers.getText(
      data,
      [
        'feedback',
        'Feedback',
        'comment',
        'Comment',
        'geriDonus',
        'GeriDonus',
      ],
    );

    final rawStatus = AppHelpers.getText(
      data,
      [
        'status',
        'Status',
      ],
    );

    final status = rawStatus.trim().isNotEmpty
        ? rawStatus
        : score.trim().isNotEmpty || feedback.trim().isNotEmpty
            ? 'Değerlendirildi'
            : 'Bekliyor';

    return SubmissionModel(
      id: doc.id,
      assignmentId: assignmentId,
      studentNo: studentNo,
      studentName: AppHelpers.getText(
        data,
        [
          'studentName',
          'StudentName',
          'name',
          'Name',
        ],
        defaultValue: '-',
      ),
      title: title.trim().isEmpty ? 'Ödev' : title.trim(),
      lessonName: lessonName.trim().isEmpty ? '-' : lessonName.trim(),
      className: className.trim().isEmpty ? '-' : className.trim(),
      answer: answer.trim().isEmpty ? '-' : answer.trim(),
      link: link.trim(),
      score: score.trim(),
      feedback: feedback.trim(),
      status: status.trim().isEmpty ? 'Bekliyor' : status.trim(),
      submittedAt: AppHelpers.getDate(
        data,
        [
          'submittedAt',
          'SubmittedAt',
          'createdAt',
          'CreatedAt',
        ],
      ),
      evaluatedAt: AppHelpers.getDate(
        data,
        [
          'evaluatedAt',
          'EvaluatedAt',
          'updatedAt',
          'UpdatedAt',
        ],
      ),
    );
  }

  bool get isEvaluated {
    return AppHelpers.isEvaluatedStatus(status) ||
        score.trim().isNotEmpty ||
        feedback.trim().isNotEmpty;
  }
}