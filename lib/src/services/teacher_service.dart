import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_helpers.dart';
import '../models/app_user.dart';
import '../models/assignment_model.dart';
import '../models/lesson_model.dart';
import '../models/submission_model.dart';

class TeacherDashboardBundle {
  final List<LessonModel> lessons;
  final List<AssignmentModel> assignments;
  final List<SubmissionModel> submissions;

  const TeacherDashboardBundle({
    required this.lessons,
    required this.assignments,
    required this.submissions,
  });

  int get evaluatedCount => submissions.where((x) => x.isEvaluated).length;

  int get pendingCount => submissions.where((x) => !x.isEvaluated).length;
}

class TeacherService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<TeacherDashboardBundle> watchTeacherDashboard(AppUser teacher) {
    final controller = StreamController<TeacherDashboardBundle>();
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
        final lessons = await loadTeacherLessons(teacher);

        final assignments = await loadTeacherAssignments(
          teacher: teacher,
          lessons: lessons,
        );

        final submissions = await loadTeacherSubmissions(
          teacher: teacher,
          lessons: lessons,
          assignments: assignments,
        );

        if (!controller.isClosed) {
          controller.add(
            TeacherDashboardBundle(
              lessons: lessons,
              assignments: assignments,
              submissions: submissions,
            ),
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
      final sub = _db.collection(collection).snapshots().listen(
        (_) {
          emit();
        },
        onError: (error) {
          if (!controller.isClosed) {
            controller.addError(error);
          }
        },
      );

      subscriptions.add(sub);
    }

    listenTo('lessons');
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

  Future<List<LessonModel>> loadTeacherLessons(AppUser teacher) async {
    final result = <LessonModel>[];
    final seen = <String>{};

    final teacherNo = AppHelpers.onlyDigits(teacher.number);
    final teacherNameKey = AppHelpers.normalizeKey(teacher.name);
    final branchKey = AppHelpers.normalizeKey(teacher.branch);

    try {
      final snapshot = await _db.collection('lessons').get();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (AppHelpers.isDeleted(data)) {
          continue;
        }

        final lesson = LessonModel.fromDoc(doc);

        final docTeacherNo = AppHelpers.onlyDigits(lesson.teacherNo);
        final docTeacherNameKey = AppHelpers.normalizeKey(lesson.teacherName);
        final docBranchKey = AppHelpers.normalizeKey(lesson.branch);

        final sameTeacher =
            (teacherNo.isNotEmpty && docTeacherNo == teacherNo) ||
            (teacherNameKey.isNotEmpty && docTeacherNameKey == teacherNameKey) ||
            (branchKey.isNotEmpty && docBranchKey == branchKey);

        if (!sameTeacher) {
          continue;
        }

        final key = AppHelpers.normalizeKey(
          '${lesson.name}_${lesson.className}_${lesson.teacherNo}',
        );

        if (seen.contains(key)) {
          continue;
        }

        seen.add(key);
        result.add(lesson);
      }
    } catch (_) {}

    result.sort((a, b) {
      final classCompare = a.className.compareTo(b.className);

      if (classCompare != 0) {
        return classCompare;
      }

      return a.name.compareTo(b.name);
    });

    return result;
  }

  Future<List<AssignmentModel>> loadTeacherAssignments({
    required AppUser teacher,
    required List<LessonModel> lessons,
  }) async {
    final collections = [
      'homeworks',
      'assignments',
    ];

    final result = <AssignmentModel>[];
    final seen = <String>{};

    final teacherNo = AppHelpers.onlyDigits(teacher.number);
    final teacherNameKey = AppHelpers.normalizeKey(teacher.name);
    final branchKey = AppHelpers.normalizeKey(teacher.branch);

    final lessonKeys = lessons
        .map(
          (x) => AppHelpers.normalizeKey('${x.name}_${x.className}'),
        )
        .toSet();

    for (final collection in collections) {
      try {
        final snapshot = await _db.collection(collection).get();

        for (final doc in snapshot.docs) {
          final data = doc.data();

          if (AppHelpers.isDeleted(data)) {
            continue;
          }

          final assignment = AssignmentModel.fromDoc(doc);

          final docTeacherNo = AppHelpers.onlyDigits(
            AppHelpers.getText(
              data,
              [
                'teacherNo',
                'TeacherNo',
                'teacherNumber',
                'TeacherNumber',
                'number',
                'Number',
              ],
            ),
          );

          final docTeacherNameKey = AppHelpers.normalizeKey(
            AppHelpers.getText(
              data,
              [
                'teacherName',
                'TeacherName',
                'teacher',
                'Teacher',
              ],
            ),
          );

          final docBranchKey = AppHelpers.normalizeKey(
            AppHelpers.getText(
              data,
              [
                'branch',
                'Branch',
                'teacherBranch',
                'TeacherBranch',
              ],
            ),
          );

          final assignmentLessonKey = AppHelpers.normalizeKey(
            '${assignment.lessonName}_${assignment.className}',
          );

          final sameTeacher =
              (teacherNo.isNotEmpty && docTeacherNo == teacherNo) ||
              (teacherNameKey.isNotEmpty && docTeacherNameKey == teacherNameKey) ||
              (branchKey.isNotEmpty && docBranchKey == branchKey) ||
              lessonKeys.contains(assignmentLessonKey);

          if (!sameTeacher) {
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

    result.sort((a, b) {
      final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return bd.compareTo(ad);
    });

    return result;
  }

  Future<List<SubmissionModel>> loadTeacherSubmissions({
    required AppUser teacher,
    required List<LessonModel> lessons,
    required List<AssignmentModel> assignments,
  }) async {
    final collections = [
      'homework_submissions',
      'submissions',
    ];

    final result = <SubmissionModel>[];
    final seen = <String>{};

    final teacherNo = AppHelpers.onlyDigits(teacher.number);
    final teacherNameKey = AppHelpers.normalizeKey(teacher.name);
    final branchKey = AppHelpers.normalizeKey(teacher.branch);

    final assignmentIds = assignments.map((x) => x.id).toSet();

    final assignmentKeys = assignments
        .map(
          (x) => AppHelpers.normalizeKey(
            '${x.title}_${x.lessonName}_${x.className}',
          ),
        )
        .toSet();

    final lessonKeys = lessons
        .map(
          (x) => AppHelpers.normalizeKey('${x.name}_${x.className}'),
        )
        .toSet();

    for (final collection in collections) {
      try {
        final snapshot = await _db.collection(collection).get();

        for (final doc in snapshot.docs) {
          final data = doc.data();

          if (AppHelpers.isDeleted(data)) {
            continue;
          }

          final submission = SubmissionModel.fromDoc(doc);

          final docTeacherNo = AppHelpers.onlyDigits(
            AppHelpers.getText(
              data,
              [
                'teacherNo',
                'TeacherNo',
                'teacherNumber',
                'TeacherNumber',
                'number',
                'Number',
              ],
            ),
          );

          final docTeacherNameKey = AppHelpers.normalizeKey(
            AppHelpers.getText(
              data,
              [
                'teacherName',
                'TeacherName',
                'teacher',
                'Teacher',
              ],
            ),
          );

          final docBranchKey = AppHelpers.normalizeKey(
            AppHelpers.getText(
              data,
              [
                'branch',
                'Branch',
                'teacherBranch',
                'TeacherBranch',
              ],
            ),
          );

          final submissionAssignmentKey = AppHelpers.normalizeKey(
            '${submission.title}_${submission.lessonName}_${submission.className}',
          );

          final submissionLessonKey = AppHelpers.normalizeKey(
            '${submission.lessonName}_${submission.className}',
          );

          final sameTeacher =
              (submission.assignmentId.isNotEmpty &&
                  assignmentIds.contains(submission.assignmentId)) ||
              assignmentKeys.contains(submissionAssignmentKey) ||
              lessonKeys.contains(submissionLessonKey) ||
              (teacherNo.isNotEmpty && docTeacherNo == teacherNo) ||
              (teacherNameKey.isNotEmpty && docTeacherNameKey == teacherNameKey) ||
              (branchKey.isNotEmpty && docBranchKey == branchKey);

          if (!sameTeacher) {
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

    result.sort((a, b) {
      final ad = a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return bd.compareTo(ad);
    });

    return result;
  }

  Future<void> createAssignment({
    required AppUser teacher,
    required LessonModel lesson,
    required String title,
    required String description,
    required DateTime? dueDate,
    required String fileType,
  }) async {
    final cleanTitle = title.trim();
    final cleanDescription = description.trim();
    final cleanFileType = fileType.trim().isEmpty ? 'Metin / Link' : fileType.trim();

    if (cleanTitle.isEmpty) {
      throw Exception('Ödev başlığı boş bırakılamaz.');
    }

    final now = Timestamp.now();

    final data = <String, dynamic>{
      'title': cleanTitle,
      'name': cleanTitle,
      'homeworkTitle': cleanTitle,
      'assignmentTitle': cleanTitle,
      'description': cleanDescription,
      'content': cleanDescription,
      'text': cleanDescription,
      'lessonId': lesson.id,
      'lessonName': lesson.name,
      'lesson': lesson.name,
      'courseName': lesson.name,
      'course': lesson.name,
      'className': lesson.className,
      'class': lesson.className,
      'targetClass': lesson.className,
      'teacherName': teacher.name,
      'teacher': teacher.name,
      'teacherNo': AppHelpers.onlyDigits(teacher.number),
      'teacherNumber': AppHelpers.onlyDigits(teacher.number),
      'branch': teacher.branch.trim().isEmpty ? lesson.branch : teacher.branch,
      'teacherBranch': teacher.branch.trim().isEmpty ? lesson.branch : teacher.branch,
      'fileType': cleanFileType,
      'type': cleanFileType,
      'submissionType': cleanFileType,
      'status': 'Aktif',
      'createdAt': now,
      'updatedAt': now,
      'isDeleted': false,
      'isActive': true,
    };

    if (dueDate != null) {
      final normalizedDue = Timestamp.fromDate(dueDate);
      data['dueDate'] = normalizedDue;
      data['deadline'] = normalizedDue;
      data['endDate'] = normalizedDue;
    }

    final ref = await _db.collection('homeworks').add(data);

    data['id'] = ref.id;
    data['Id'] = ref.id;

    await _db.collection('assignments').doc(ref.id).set(
          data,
          SetOptions(merge: true),
        );
  }

  Future<void> evaluateSubmission({
    required SubmissionModel submission,
    required String score,
    required String feedback,
  }) async {
    final cleanScore = score.trim();
    final cleanFeedback = feedback.trim();

    if (cleanScore.isEmpty && cleanFeedback.isEmpty) {
      throw Exception('Not veya geri dönüş alanlarından en az biri doldurulmalı.');
    }

    final update = <String, dynamic>{
      'score': cleanScore,
      'Score': cleanScore,
      'grade': cleanScore,
      'Grade': cleanScore,
      'point': cleanScore,
      'Point': cleanScore,
      'not': cleanScore,
      'Not': cleanScore,
      'feedback': cleanFeedback,
      'Feedback': cleanFeedback,
      'comment': cleanFeedback,
      'Comment': cleanFeedback,
      'geriDonus': cleanFeedback,
      'GeriDonus': cleanFeedback,
      'status': 'Değerlendirildi',
      'Status': 'Değerlendirildi',
      'evaluatedAt': Timestamp.now(),
      'EvaluatedAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'UpdatedAt': Timestamp.now(),
    };

    final collections = [
      'homework_submissions',
      'submissions',
    ];

    for (final collection in collections) {
      await _updateSubmissionInCollection(
        collection: collection,
        submission: submission,
        update: update,
      );
    }
  }

  Future<void> _updateSubmissionInCollection({
    required String collection,
    required SubmissionModel submission,
    required Map<String, dynamic> update,
  }) async {
    try {
      final directDoc = await _db.collection(collection).doc(submission.id).get();

      if (directDoc.exists) {
        await directDoc.reference.set(
          update,
          SetOptions(merge: true),
        );

        return;
      }
    } catch (_) {}

    try {
      final snapshot = await _db.collection(collection).get();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (AppHelpers.isDeleted(data)) {
          continue;
        }

        final candidate = SubmissionModel.fromDoc(doc);

        final sameByAssignmentId = candidate.assignmentId.trim().isNotEmpty &&
            submission.assignmentId.trim().isNotEmpty &&
            candidate.assignmentId == submission.assignmentId &&
            AppHelpers.onlyDigits(candidate.studentNo) ==
                AppHelpers.onlyDigits(submission.studentNo);

        final sameByContent = AppHelpers.normalizeKey(
              '${candidate.title}_${candidate.lessonName}_${candidate.className}_${candidate.studentNo}',
            ) ==
            AppHelpers.normalizeKey(
              '${submission.title}_${submission.lessonName}_${submission.className}_${submission.studentNo}',
            );

        if (sameByAssignmentId || sameByContent) {
          await doc.reference.set(
            update,
            SetOptions(merge: true),
          );
        }
      }
    } catch (_) {}
  }
}