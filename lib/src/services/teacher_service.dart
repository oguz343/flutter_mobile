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
      final sub = _db
          .collection(collection)
          .snapshots()
          .listen(
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

        if (AppHelpers.isDeletedOrInactive(data)) {
          continue;
        }

        final lesson = LessonModel.fromDoc(doc);

        if (!_lessonBelongsToTeacher(
          lesson: lesson,
          data: data,
          teacher: teacher,
          teacherNo: teacherNo,
          teacherNameKey: teacherNameKey,
          branchKey: branchKey,
        )) {
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
    final collections = ['homeworks', 'assignments'];

    final result = <AssignmentModel>[];
    final seen = <String>{};

    final teacherNo = AppHelpers.onlyDigits(teacher.number);
    final teacherNameKey = AppHelpers.normalizeKey(teacher.name);
    final branchKey = AppHelpers.normalizeKey(teacher.branch);

    final lessonKeys = lessons
        .map((x) => AppHelpers.normalizeKey('${x.name}_${x.className}'))
        .toSet();
    final lessonIds = lessons.map((x) => x.id).toSet();

    for (final collection in collections) {
      try {
        final snapshot = await _db.collection(collection).get();

        for (final doc in snapshot.docs) {
          final data = doc.data();

          if (AppHelpers.isDeletedOrInactive(data)) {
            continue;
          }

          final assignment = AssignmentModel.fromDoc(doc);

          final assignmentLessonKey = AppHelpers.normalizeKey(
            '${assignment.lessonName}_${assignment.className}',
          );

          final sameTeacher =
              _assignmentBelongsToTeacher(
                assignment: assignment,
                data: data,
                teacher: teacher,
                teacherNo: teacherNo,
                teacherNameKey: teacherNameKey,
                branchKey: branchKey,
              ) ||
              (assignment.lessonId.isNotEmpty &&
                  lessonIds.contains(assignment.lessonId)) ||
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
    final collections = ['homework_submissions', 'submissions'];

    final result = <SubmissionModel>[];
    final seen = <String>{};

    final teacherNo = AppHelpers.onlyDigits(teacher.number);
    final teacherNameKey = AppHelpers.normalizeKey(teacher.name);
    final branchKey = AppHelpers.normalizeKey(teacher.branch);

    final assignmentIds = assignments.map((x) => x.id).toSet();
    final studentNamesByNo = await _loadStudentNamesByNumber();

    final assignmentKeys = assignments
        .map(
          (x) => AppHelpers.normalizeKey(
            '${x.title}_${x.lessonName}_${x.className}',
          ),
        )
        .toSet();

    final lessonKeys = lessons
        .map((x) => AppHelpers.normalizeKey('${x.name}_${x.className}'))
        .toSet();

    for (final collection in collections) {
      try {
        final snapshot = await _db.collection(collection).get();

        for (final doc in snapshot.docs) {
          final data = Map<String, dynamic>.from(doc.data());

          if (AppHelpers.isDeletedOrInactive(data)) {
            continue;
          }

          final studentNo = AppHelpers.onlyDigits(
            AppHelpers.getText(data, [
              'studentNo',
              'StudentNo',
              'studentNumber',
              'StudentNumber',
              'schoolNo',
              'SchoolNo',
              'number',
              'Number',
            ]),
          );

          final studentName = AppHelpers.getText(data, [
            'studentName',
            'StudentName',
            'name',
            'Name',
          ]);

          if (studentName.trim().isEmpty && studentNo.isNotEmpty) {
            final knownName = studentNamesByNo[studentNo];

            if (knownName != null && knownName.trim().isNotEmpty) {
              data['studentName'] = knownName;
              data['StudentName'] = knownName;
            }
          }

          final submission = SubmissionModel.fromData(doc.id, data);

          final docTeacherNo = AppHelpers.onlyDigits(
            AppHelpers.getText(data, [
              'teacherNo',
              'TeacherNo',
              'teacherNumber',
              'TeacherNumber',
              'number',
              'Number',
            ]),
          );

          final docTeacherNameKey = AppHelpers.normalizeKey(
            AppHelpers.getText(data, [
              'teacherName',
              'TeacherName',
              'teacher',
              'Teacher',
            ]),
          );

          final docBranchKey = AppHelpers.normalizeKey(
            AppHelpers.getText(data, [
              'branch',
              'Branch',
              'teacherBranch',
              'TeacherBranch',
            ]),
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
              (teacherNameKey.isNotEmpty &&
                  docTeacherNameKey == teacherNameKey) ||
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

  bool _lessonBelongsToTeacher({
    required LessonModel lesson,
    required Map<String, dynamic> data,
    required AppUser teacher,
    required String teacherNo,
    required String teacherNameKey,
    required String branchKey,
  }) {
    final docTeacherId = AppHelpers.getText(data, [
      'teacherId',
      'TeacherId',
    ]).trim();
    final docTeacherNo = AppHelpers.onlyDigits(
      AppHelpers.getText(data, ['teacherNo', 'TeacherNo']),
    );
    final docTeacherNumber = AppHelpers.onlyDigits(
      AppHelpers.getText(data, ['teacherNumber', 'TeacherNumber']),
    );
    final docNumber = AppHelpers.onlyDigits(
      AppHelpers.getText(data, ['number', 'Number']),
    );
    final docTeacherNameKey = AppHelpers.normalizeKey(
      AppHelpers.getText(data, ['teacherName', 'TeacherName']),
    );

    final hasTeacherIdentity =
        docTeacherId.isNotEmpty ||
        docTeacherNo.isNotEmpty ||
        docTeacherNumber.isNotEmpty ||
        docTeacherNameKey.isNotEmpty;

    final identityMatches =
        (docTeacherId.isNotEmpty && docTeacherId == teacher.id) ||
        (teacherNo.isNotEmpty && docTeacherNo == teacherNo) ||
        (teacherNo.isNotEmpty && docTeacherNumber == teacherNo) ||
        (hasTeacherIdentity &&
            teacherNo.isNotEmpty &&
            docNumber == teacherNo) ||
        (teacherNameKey.isNotEmpty && docTeacherNameKey == teacherNameKey);

    if (hasTeacherIdentity) {
      return identityMatches;
    }

    final docBranchKey = AppHelpers.normalizeKey(
      AppHelpers.getText(data, [
        'branch',
        'Branch',
        'teacherBranch',
        'TeacherBranch',
      ], defaultValue: lesson.branch),
    );

    return branchKey.isNotEmpty && docBranchKey == branchKey;
  }

  bool _assignmentBelongsToTeacher({
    required AssignmentModel assignment,
    required Map<String, dynamic> data,
    required AppUser teacher,
    required String teacherNo,
    required String teacherNameKey,
    required String branchKey,
  }) {
    final docTeacherId = assignment.teacherId.isNotEmpty
        ? assignment.teacherId
        : AppHelpers.getText(data, ['teacherId', 'TeacherId']).trim();
    final docTeacherNo = AppHelpers.onlyDigits(assignment.teacherNo);
    final docTeacherNumber = AppHelpers.onlyDigits(assignment.teacherNumber);
    final docTeacherNameKey = AppHelpers.normalizeKey(assignment.teacherName);

    final hasTeacherIdentity =
        docTeacherId.isNotEmpty ||
        docTeacherNo.isNotEmpty ||
        docTeacherNumber.isNotEmpty ||
        docTeacherNameKey.isNotEmpty;

    final identityMatches =
        (docTeacherId.isNotEmpty && docTeacherId == teacher.id) ||
        (teacherNo.isNotEmpty && docTeacherNo == teacherNo) ||
        (teacherNo.isNotEmpty && docTeacherNumber == teacherNo) ||
        (teacherNameKey.isNotEmpty && docTeacherNameKey == teacherNameKey);

    if (hasTeacherIdentity) {
      return identityMatches;
    }

    final docBranchKey = AppHelpers.normalizeKey(assignment.branch);

    return branchKey.isNotEmpty && docBranchKey == branchKey;
  }

  Future<Map<String, String>> _loadStudentNamesByNumber() async {
    final result = <String, String>{};

    try {
      final snapshot = await _db.collection('users').get();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (AppHelpers.isDeleted(data)) {
          continue;
        }

        final role = AppHelpers.normalizeKey(
          AppHelpers.getText(data, ['role', 'Role', 'userRole', 'UserRole']),
        );

        if (role != 'ogrenci') {
          continue;
        }

        final number = AppHelpers.onlyDigits(
          AppHelpers.getText(data, [
            'number',
            'Number',
            'schoolNo',
            'SchoolNo',
            'studentNo',
            'StudentNo',
          ]),
        );

        final name = AppHelpers.getText(data, [
          'name',
          'Name',
          'fullName',
          'FullName',
          'userName',
          'UserName',
        ]);

        if (number.isNotEmpty && name.trim().isNotEmpty) {
          result[number] = name.trim();
        }
      }
    } catch (_) {}

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
    await createHomeworkForLessonAssignments(
      teacher: teacher,
      selectedLessonIds: [lesson.id],
      title: title,
      description: description,
      dueDate: dueDate,
      fileType: fileType,
    );
  }

  Future<void> createHomeworkForLessonAssignments({
    required AppUser teacher,
    required List<String> selectedLessonIds,
    required String title,
    required String description,
    required DateTime? dueDate,
    required String fileType,
  }) async {
    final cleanTitle = title.trim();
    final cleanDescription = description.trim();
    final cleanFileType = fileType.trim().isEmpty
        ? 'Metin / Link'
        : fileType.trim();

    if (cleanTitle.isEmpty) {
      throw Exception('Ödev başlığı boş bırakılamaz.');
    }

    final cleanLessonIds = selectedLessonIds
        .map((x) => x.trim())
        .where((x) => x.isNotEmpty)
        .toSet()
        .toList();

    if (cleanLessonIds.isEmpty) {
      throw Exception('En az bir ders ataması seçmelisiniz.');
    }

    final now = Timestamp.now();

    for (final lessonId in cleanLessonIds) {
      final lessonDoc = await _db.collection('lessons').doc(lessonId).get();

      if (!lessonDoc.exists) {
        continue;
      }

      final lessonData = lessonDoc.data() ?? <String, dynamic>{};

      if (AppHelpers.isDeletedOrInactive(lessonData)) {
        continue;
      }

      final lesson = LessonModel.fromDoc(lessonDoc);
      final teacherNo = AppHelpers.onlyDigits(teacher.number);
      final teacherNameKey = AppHelpers.normalizeKey(teacher.name);
      final branchKey = AppHelpers.normalizeKey(teacher.branch);

      if (!_lessonBelongsToTeacher(
        lesson: lesson,
        data: lessonData,
        teacher: teacher,
        teacherNo: teacherNo,
        teacherNameKey: teacherNameKey,
        branchKey: branchKey,
      )) {
        continue;
      }

      final branch = teacher.branch.trim().isEmpty
          ? lesson.displayBranch
          : teacher.branch.trim();
      final ref = _db.collection('homeworks').doc();
      final normalizedDue = dueDate == null
          ? null
          : Timestamp.fromDate(dueDate);

      final data = <String, dynamic>{
        'id': ref.id,
        'Id': ref.id,
        'title': cleanTitle,
        'description': cleanDescription,
        'lessonId': lesson.id,
        'lessonName': lesson.displayLessonName,
        'className': lesson.displayClassName,
        'teacherId': teacher.id,
        'teacherNo': teacherNo,
        'teacherNumber': teacherNo,
        'teacherName': teacher.name,
        'teacherBranch': branch,
        'branch': branch,
        'fileType': cleanFileType,
        'dueDate': normalizedDue,
        'deadline': normalizedDue,
        'createdAt': now,
        'updatedAt': now,
        'status': 'Aktif',
        'isDeleted': false,
        'isActive': true,
      };

      await ref.set(data, SetOptions(merge: true));
      await _db
          .collection('assignments')
          .doc(ref.id)
          .set(data, SetOptions(merge: true));
    }
  }

  Future<void> evaluateSubmission({
    required SubmissionModel submission,
    required String score,
    required String feedback,
  }) async {
    final cleanScore = score.trim();
    final cleanFeedback = feedback.trim();

    if (cleanScore.isEmpty && cleanFeedback.isEmpty) {
      throw Exception(
        'Not veya geri dönüş alanlarından en az biri doldurulmalı.',
      );
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

    final collections = ['homework_submissions', 'submissions'];

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
      final directDoc = await _db
          .collection(collection)
          .doc(submission.id)
          .get();

      if (directDoc.exists) {
        await directDoc.reference.set(update, SetOptions(merge: true));

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

        final sameByAssignmentId =
            candidate.assignmentId.trim().isNotEmpty &&
            submission.assignmentId.trim().isNotEmpty &&
            candidate.assignmentId == submission.assignmentId &&
            AppHelpers.onlyDigits(candidate.studentNo) ==
                AppHelpers.onlyDigits(submission.studentNo);

        final sameByContent =
            AppHelpers.normalizeKey(
              '${candidate.title}_${candidate.lessonName}_${candidate.className}_${candidate.studentNo}',
            ) ==
            AppHelpers.normalizeKey(
              '${submission.title}_${submission.lessonName}_${submission.className}_${submission.studentNo}',
            );

        if (sameByAssignmentId || sameByContent) {
          await doc.reference.set(update, SetOptions(merge: true));
        }
      }
    } catch (_) {}
  }
}
