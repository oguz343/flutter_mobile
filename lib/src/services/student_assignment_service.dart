import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_helpers.dart';
import '../models/app_user.dart';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';

class StudentAssignmentBundle {
  final AssignmentModel assignment;
  final SubmissionModel? submission;

  const StudentAssignmentBundle({
    required this.assignment,
    required this.submission,
  });

  bool get submitted => submission != null;
}

class StudentAssignmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<StudentAssignmentBundle>> watchAssignmentsForStudent(
    AppUser student,
  ) {
    return _db.collection('homeworks').snapshots().asyncMap((_) async {
      final assignments = await _loadAssignments(student);
      final submissions = await _loadSubmissions(student);

      final result = <StudentAssignmentBundle>[];

      for (final assignment in assignments) {
        final submission = _findSubmissionForAssignment(
          assignment: assignment,
          submissions: submissions,
          student: student,
        );

        result.add(
          StudentAssignmentBundle(
            assignment: assignment,
            submission: submission,
          ),
        );
      }

      result.sort((a, b) {
        final ad = a.assignment.dueDate ??
            a.assignment.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);

        final bd = b.assignment.dueDate ??
            b.assignment.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return bd.compareTo(ad);
      });

      return result;
    });
  }

  Future<List<AssignmentModel>> _loadAssignments(AppUser student) async {
    final collections = [
      'homeworks',
      'assignments',
    ];

    final result = <AssignmentModel>[];
    final seen = <String>{};

    final studentClass = AppHelpers.normalizeClassName(student.className);

    for (final collection in collections) {
      try {
        final snapshot = await _db.collection(collection).get();

        for (final doc in snapshot.docs) {
          final data = doc.data();

          if (AppHelpers.isDeleted(data)) {
            continue;
          }

          final assignment = AssignmentModel.fromDoc(doc);

          final assignmentClass = AppHelpers.normalizeClassName(
            assignment.className,
          );

          if (studentClass.isEmpty || assignmentClass.isEmpty) {
            continue;
          }

          if (studentClass != assignmentClass) {
            continue;
          }

          final key = AppHelpers.normalizeKey(
            '${assignment.title}_${assignment.lessonName}_${assignment.className}',
          );

          if (seen.contains(key)) {
            continue;
          }

          seen.add(key);
          result.add(assignment);
        }
      } catch (_) {
        continue;
      }
    }

    return result;
  }

  Future<List<SubmissionModel>> _loadSubmissions(AppUser student) async {
    final collections = [
      'homework_submissions',
      'submissions',
    ];

    final result = <SubmissionModel>[];
    final seen = <String>{};

    final studentNo = AppHelpers.onlyDigits(student.number);

    for (final collection in collections) {
      try {
        final snapshot = await _db.collection(collection).get();

        for (final doc in snapshot.docs) {
          final data = doc.data();

          if (AppHelpers.isDeleted(data)) {
            continue;
          }

          final submission = SubmissionModel.fromDoc(doc);

          if (AppHelpers.onlyDigits(submission.studentNo) != studentNo) {
            continue;
          }

          final key = AppHelpers.normalizeKey(
            '${submission.assignmentId}_${submission.studentNo}_${submission.title}_${submission.lessonName}_${submission.className}',
          );

          if (seen.contains(key)) {
            continue;
          }

          seen.add(key);
          result.add(submission);
        }
      } catch (_) {
        continue;
      }
    }

    return result;
  }

  SubmissionModel? _findSubmissionForAssignment({
    required AssignmentModel assignment,
    required List<SubmissionModel> submissions,
    required AppUser student,
  }) {
    for (final submission in submissions) {
      if (submission.assignmentId.trim().isNotEmpty &&
          submission.assignmentId == assignment.id) {
        return submission;
      }

      final submissionKey = AppHelpers.normalizeKey(
        '${submission.title}_${submission.lessonName}_${submission.className}',
      );

      final assignmentKey = AppHelpers.normalizeKey(
        '${assignment.title}_${assignment.lessonName}_${assignment.className}',
      );

      final sameStudent = AppHelpers.onlyDigits(submission.studentNo) ==
          AppHelpers.onlyDigits(student.number);

      if (sameStudent && submissionKey == assignmentKey) {
        return submission;
      }
    }

    return null;
  }

  Future<void> submitAssignment({
    required AppUser student,
    required AssignmentModel assignment,
    required String answer,
    required String link,
  }) async {
    final cleanAnswer = answer.trim();
    final cleanLink = link.trim();

    if (cleanAnswer.isEmpty && cleanLink.isEmpty) {
      throw Exception('Cevap veya link alanlarından en az biri doldurulmalı.');
    }

    final studentNo = AppHelpers.onlyDigits(student.number);

    final submissionKey = AppHelpers.buildSubmissionKey(
      assignmentId: assignment.id,
      studentNo: studentNo,
      title: assignment.title,
      lessonName: assignment.lessonName,
      className: assignment.className,
    );

    final now = Timestamp.now();

    final data = <String, dynamic>{
      'homeworkId': assignment.id,
      'assignmentId': assignment.id,

      'assignmentTitle': assignment.title,
      'homeworkTitle': assignment.title,
      'title': assignment.title,
      'name': assignment.title,

      'lessonName': assignment.lessonName,
      'lesson': assignment.lessonName,
      'courseName': assignment.lessonName,
      'course': assignment.lessonName,

      'className': assignment.className,
      'class': assignment.className,
      'targetClass': assignment.className,

      'teacherName': assignment.teacherName,
      'teacher': assignment.teacherName,
      'teacherNo': assignment.teacherNo,
      'branch': assignment.branch,
      'teacherBranch': assignment.branch,

      'studentId': student.id,
      'studentName': student.name,
      'studentNo': studentNo,
      'studentNumber': studentNo,
      'schoolNo': studentNo,

      'answerText': cleanAnswer,
      'answer': cleanAnswer,
      'content': cleanAnswer,
      'text': cleanAnswer,

      'answerLink': cleanLink,
      'link': cleanLink,
      'url': cleanLink,

      'status': 'Bekliyor',
      'submittedAt': now,
      'createdAt': now,
      'updatedAt': now,
      'isDeleted': false,
      'isActive': true,
    };

    await _db
        .collection('homework_submissions')
        .doc(submissionKey)
        .set(data, SetOptions(merge: true));

    await _db
        .collection('submissions')
        .doc(submissionKey)
        .set(data, SetOptions(merge: true));
  }
}