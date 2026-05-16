import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_helpers.dart';
import '../models/app_user.dart';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';
import 'student_assignment_service.dart';

class ParentStudentBundle {
  final AppUser? student;
  final List<StudentAssignmentBundle> assignments;

  const ParentStudentBundle({required this.student, required this.assignments});

  int get totalAssignments => assignments.length;

  int get submittedCount =>
      assignments.where((x) => x.submission != null).length;

  int get evaluatedCount =>
      assignments.where((x) => x.submission?.isEvaluated ?? false).length;

  int get pendingCount => totalAssignments - submittedCount;
}

class ParentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<ParentStudentBundle> watchParentStudent(AppUser parent) {
    final controller = StreamController<ParentStudentBundle>();
    final subscriptions = <StreamSubscription>[];

    bool loading = false;
    bool pendingReload = false;

    Future<void> emit() async {
      if (loading) {
        pendingReload = true;
        return;
      }

      loading = true;

      try {
        final student = await findLinkedStudent(parent);
        final assignments = student == null
            ? <StudentAssignmentBundle>[]
            : await _loadAssignmentsForStudentOnce(student);

        if (!controller.isClosed) {
          controller.add(
            ParentStudentBundle(student: student, assignments: assignments),
          );
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      } finally {
        loading = false;

        if (pendingReload) {
          pendingReload = false;
          await emit();
        }
      }
    }

    void listenTo(String collection) {
      final sub = _db
          .collection(collection)
          .snapshots()
          .listen(
            (_) => emit(),
            onError: (error) {
              if (!controller.isClosed) {
                controller.addError(error);
              }
            },
          );

      subscriptions.add(sub);
    }

    listenTo('users');
    listenTo('homeworks');
    listenTo('assignments');
    listenTo('homework_submissions');
    listenTo('submissions');

    emit();

    controller.onCancel = () async {
      for (final sub in subscriptions) {
        await sub.cancel();
      }
    };

    return controller.stream;
  }

  Future<AppUser?> findLinkedStudent(AppUser parent) async {
    final parentNumber = AppHelpers.onlyDigits(parent.number);
    final linkedStudentNo = AppHelpers.onlyDigits(parent.linkedStudentNo);

    try {
      final snapshot = await _db.collection('users').get();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (AppHelpers.isDeletedOrInactive(data)) {
          continue;
        }

        final user = AppUser.fromDoc(doc);

        if (AppHelpers.normalizeKey(user.role) != 'ogrenci') {
          continue;
        }

        final studentNo = AppHelpers.onlyDigits(user.number);

        final studentLinkedParentNo = AppHelpers.onlyDigits(
          AppHelpers.getText(data, [
            'parentNo',
            'ParentNo',
            'parentNumber',
            'ParentNumber',
            'veliNo',
            'VeliNo',
            'linkedParentNo',
            'LinkedParentNo',
          ]),
        );

        final studentParentPhone = AppHelpers.onlyDigits(
          AppHelpers.getText(data, [
            'parentPhone',
            'ParentPhone',
            'veliTelefon',
            'VeliTelefon',
            'parentPhoneNumber',
            'ParentPhoneNumber',
          ]),
        );

        final parentPhone = AppHelpers.onlyDigits(parent.phone);

        final matchByParentLinkedStudent =
            linkedStudentNo.isNotEmpty && studentNo == linkedStudentNo;

        final matchByStudentParentNo =
            parentNumber.isNotEmpty && studentLinkedParentNo == parentNumber;

        final matchByPhone =
            parentPhone.isNotEmpty && studentParentPhone == parentPhone;

        if (matchByParentLinkedStudent ||
            matchByStudentParentNo ||
            matchByPhone) {
          return user;
        }
      }
    } catch (_) {}

    return null;
  }

  Future<List<StudentAssignmentBundle>> _loadAssignmentsForStudentOnce(
    AppUser student,
  ) async {
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
        StudentAssignmentBundle(assignment: assignment, submission: submission),
      );
    }

    result.sort((a, b) {
      final ad =
          a.assignment.dueDate ??
          a.assignment.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);

      final bd =
          b.assignment.dueDate ??
          b.assignment.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);

      return bd.compareTo(ad);
    });

    return result;
  }

  Future<List<AssignmentModel>> _loadAssignments(AppUser student) async {
    final collections = ['homeworks', 'assignments'];

    final result = <AssignmentModel>[];
    final seen = <String>{};

    final studentClass = AppHelpers.normalizeClassName(student.className);

    for (final collection in collections) {
      try {
        final snapshot = await _db.collection(collection).get();

        for (final doc in snapshot.docs) {
          final data = doc.data();

          if (AppHelpers.isDeletedOrInactive(data)) {
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
    final collections = ['homework_submissions', 'submissions'];

    final result = <SubmissionModel>[];
    final seen = <String>{};

    final studentNo = AppHelpers.onlyDigits(student.number);

    for (final collection in collections) {
      try {
        final snapshot = await _db.collection(collection).get();

        for (final doc in snapshot.docs) {
          final data = doc.data();

          if (AppHelpers.isDeletedOrInactive(data)) {
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
            final oldIndex = result.indexWhere(
              (x) =>
                  AppHelpers.normalizeKey(
                    '${x.assignmentId}_${x.studentNo}_${x.title}_${x.lessonName}_${x.className}',
                  ) ==
                  key,
            );

            if (oldIndex >= 0 && submission.isEvaluated) {
              result[oldIndex] = submission;
            }

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

      final sameStudent =
          AppHelpers.onlyDigits(submission.studentNo) ==
          AppHelpers.onlyDigits(student.number);

      if (sameStudent && submissionKey == assignmentKey) {
        return submission;
      }
    }

    return null;
  }
}
