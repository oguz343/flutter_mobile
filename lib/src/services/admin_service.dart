import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_helpers.dart';
import '../models/announcement_model.dart';
import '../models/app_user.dart';
import '../models/lesson_model.dart';
import '../models/submission_model.dart';

class PasswordRequestModel {
  final String id;
  final String name;
  final String role;
  final String number;
  final String note;
  final String status;
  final DateTime? createdAt;

  const PasswordRequestModel({
    required this.id,
    required this.name,
    required this.role,
    required this.number,
    required this.note,
    required this.status,
    required this.createdAt,
  });

  bool get isPending => AppHelpers.isPendingStatus(status);

  factory PasswordRequestModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return PasswordRequestModel(
      id: doc.id,
      name: AppHelpers.getText(
        data,
        [
          'name',
          'Name',
          'userName',
          'UserName',
          'fullName',
          'FullName',
        ],
        defaultValue: '-',
      ),
      role: AppHelpers.normalizeRoleForSave(
        AppHelpers.getText(
          data,
          [
            'role',
            'Role',
          ],
          defaultValue: '-',
        ),
      ),
      number: AppHelpers.onlyDigits(
        AppHelpers.getText(
          data,
          [
            'number',
            'Number',
            'schoolNo',
            'SchoolNo',
            'studentNo',
            'StudentNo',
          ],
        ),
      ),
      note: AppHelpers.getText(
        data,
        [
          'note',
          'Note',
          'message',
          'Message',
        ],
      ),
      status: AppHelpers.getText(
        data,
        [
          'status',
          'Status',
        ],
        defaultValue: 'Bekliyor',
      ),
      createdAt: AppHelpers.getDate(
        data,
        [
          'createdAt',
          'CreatedAt',
        ],
      ),
    );
  }
}

class SchoolClassModel {
  final String id;
  final String name;
  final String teacherName;
  final String teacherNo;

  const SchoolClassModel({
    required this.id,
    required this.name,
    required this.teacherName,
    required this.teacherNo,
  });

  factory SchoolClassModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final className = AppHelpers.normalizeClassName(
      AppHelpers.getText(
        data,
        [
          'name',
          'Name',
          'className',
          'ClassName',
          'class',
          'Class',
        ],
      ),
    );

    return SchoolClassModel(
      id: doc.id,
      name: className.isEmpty ? '-' : className,
      teacherName: AppHelpers.getText(
        data,
        [
          'teacherName',
          'TeacherName',
          'classTeacherName',
          'ClassTeacherName',
        ],
        defaultValue: '-',
      ),
      teacherNo: AppHelpers.onlyDigits(
        AppHelpers.getText(
          data,
          [
            'teacherNo',
            'TeacherNo',
            'classTeacherNo',
            'ClassTeacherNo',
          ],
        ),
      ),
    );
  }
}

class AdminDashboardBundle {
  final List<AppUser> users;
  final List<AppUser> students;
  final List<AppUser> teachers;
  final List<AppUser> parents;
  final List<AppUser> admins;
  final List<SchoolClassModel> classes;
  final List<LessonModel> lessons;
  final List<AnnouncementModel> announcements;
  final List<SubmissionModel> submissions;
  final List<PasswordRequestModel> passwordRequests;

  const AdminDashboardBundle({
    required this.users,
    required this.students,
    required this.teachers,
    required this.parents,
    required this.admins,
    required this.classes,
    required this.lessons,
    required this.announcements,
    required this.submissions,
    required this.passwordRequests,
  });

  int get pendingPasswordRequestCount =>
      passwordRequests.where((x) => x.isPending).length;

  int get evaluatedSubmissionCount =>
      submissions.where((x) => x.isEvaluated).length;

  int get pendingSubmissionCount =>
      submissions.where((x) => !x.isEvaluated).length;
}

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<AdminDashboardBundle> watchDashboard() {
    final controller = StreamController<AdminDashboardBundle>();
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
        final users = await loadUsers();
        final classes = await loadClasses();
        final lessons = await loadLessons();
        final announcements = await loadAnnouncements();
        final submissions = await loadSubmissions();
        final requests = await loadPasswordRequests();

        final students = users
            .where((x) => AppHelpers.normalizeKey(x.role) == 'ogrenci')
            .toList();

        final teachers = users
            .where((x) => AppHelpers.normalizeKey(x.role) == 'ogretmen')
            .toList();

        final parents = users
            .where((x) => AppHelpers.normalizeKey(x.role) == 'veli')
            .toList();

        final admins = users
            .where((x) => AppHelpers.normalizeKey(x.role) == 'admin')
            .toList();

        if (!controller.isClosed) {
          controller.add(
            AdminDashboardBundle(
              users: users,
              students: students,
              teachers: teachers,
              parents: parents,
              admins: admins,
              classes: classes,
              lessons: lessons,
              announcements: announcements,
              submissions: submissions,
              passwordRequests: requests,
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
    listenTo('classes');
    listenTo('lessons');
    listenTo('announcements');
    listenTo('homework_submissions');
    listenTo('submissions');
    listenTo('passwordRequests');
    listenTo('password_requests');

    emit();

    controller.onCancel = () async {
      for (final sub in subscriptions) {
        await sub.cancel();
      }
    };

    return controller.stream;
  }

  Future<List<AppUser>> loadUsers() async {
    final result = <AppUser>[];
    final seen = <String>{};

    try {
      final snapshot = await _db.collection('users').get();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (AppHelpers.isDeleted(data)) {
          continue;
        }

        final user = AppUser.fromDoc(doc);

        if (user.role.trim().isEmpty || user.number.trim().isEmpty) {
          continue;
        }

        final key = AppHelpers.normalizeKey('${user.role}_${user.number}');

        if (seen.contains(key)) {
          continue;
        }

        seen.add(key);
        result.add(user);
      }
    } catch (_) {}

    result.sort((a, b) {
      final roleCompare = a.role.compareTo(b.role);

      if (roleCompare != 0) {
        return roleCompare;
      }

      return a.name.compareTo(b.name);
    });

    return result;
  }

  Future<List<SchoolClassModel>> loadClasses() async {
    final result = <SchoolClassModel>[];
    final seen = <String>{};

    try {
      final snapshot = await _db.collection('classes').get();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (AppHelpers.isDeleted(data)) {
          continue;
        }

        final item = SchoolClassModel.fromDoc(doc);

        if (item.name == '-') {
          continue;
        }

        final key = AppHelpers.normalizeClassName(item.name);

        if (seen.contains(key)) {
          continue;
        }

        seen.add(key);
        result.add(item);
      }
    } catch (_) {}

    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  Future<List<LessonModel>> loadLessons() async {
    final result = <LessonModel>[];
    final seen = <String>{};

    try {
      final snapshot = await _db.collection('lessons').get();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (AppHelpers.isDeleted(data)) {
          continue;
        }

        final lesson = LessonModel.fromDoc(doc);

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

  Future<List<AnnouncementModel>> loadAnnouncements() async {
    final result = <AnnouncementModel>[];

    try {
      final snapshot = await _db.collection('announcements').get();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (AppHelpers.isDeleted(data)) {
          continue;
        }

        final title = AppHelpers.getText(
          data,
          [
            'title',
            'Title',
            'name',
            'Name',
          ],
        );

        final content = AppHelpers.getText(
          data,
          [
            'content',
            'Content',
            'message',
            'Message',
            'description',
            'Description',
          ],
        );

        if (title.trim().isEmpty && content.trim().isEmpty) {
          continue;
        }

        result.add(AnnouncementModel.fromDoc(doc));
      }
    } catch (_) {}

    result.sort((a, b) {
      final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return bd.compareTo(ad);
    });

    return result;
  }

  Future<List<SubmissionModel>> loadSubmissions() async {
    final collections = [
      'homework_submissions',
      'submissions',
    ];

    final result = <SubmissionModel>[];
    final seen = <String>{};

    for (final collection in collections) {
      try {
        final snapshot = await _db.collection(collection).get();

        for (final doc in snapshot.docs) {
          final data = doc.data();

          if (AppHelpers.isDeleted(data)) {
            continue;
          }

          final submission = SubmissionModel.fromDoc(doc);

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

  Future<List<PasswordRequestModel>> loadPasswordRequests() async {
    final collections = [
      'passwordRequests',
      'password_requests',
    ];

    final result = <PasswordRequestModel>[];
    final seen = <String>{};

    for (final collection in collections) {
      try {
        final snapshot = await _db.collection(collection).get();

        for (final doc in snapshot.docs) {
          final data = doc.data();

          if (AppHelpers.isDeleted(data)) {
            continue;
          }

          final item = PasswordRequestModel.fromDoc(doc);

          final key = AppHelpers.normalizeKey('${item.role}_${item.number}');

          if (seen.contains(key)) {
            final oldIndex = result.indexWhere(
              (x) => AppHelpers.normalizeKey('${x.role}_${x.number}') == key,
            );

            if (oldIndex >= 0 && item.isPending) {
              result[oldIndex] = item;
            }

            continue;
          }

          seen.add(key);
          result.add(item);
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
}