import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_helpers.dart';
import '../models/app_user.dart';
import '../models/announcement_model.dart';
import '../models/lesson_model.dart';
import 'admin_service.dart';

class AdminSchoolException implements Exception {
  final String message;

  const AdminSchoolException(this.message);

  @override
  String toString() => message;
}

class AdminSchoolData {
  final List<SchoolClassModel> classes;
  final List<LessonModel> lessons;
  final List<AppUser> teachers;
  final List<AnnouncementModel> announcements;

  const AdminSchoolData({
    required this.classes,
    required this.lessons,
    required this.teachers,
    required this.announcements,
  });
}

class AdminSchoolService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<AdminSchoolData> watchSchoolData() {
    return _db.collection('classes').snapshots().asyncMap((_) async {
      final classes = await AdminService().loadClasses();
      final lessons = await AdminService().loadLessons();
      final announcements = await AdminService().loadAnnouncements();
      final teachers = await _loadTeachers();

      return AdminSchoolData(
        classes: classes,
        lessons: lessons,
        teachers: teachers,
        announcements: announcements,
      );
    });
  }

  Stream<AdminSchoolData> watchAnnouncementsData() {
    return _db.collection('announcements').snapshots().asyncMap((_) async {
      final classes = await AdminService().loadClasses();
      final lessons = await AdminService().loadLessons();
      final announcements = await AdminService().loadAnnouncements();
      final teachers = await _loadTeachers();

      return AdminSchoolData(
        classes: classes,
        lessons: lessons,
        teachers: teachers,
        announcements: announcements,
      );
    });
  }

  Future<List<AppUser>> _loadTeachers() async {
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

        if (AppHelpers.normalizeKey(user.role) != 'ogretmen') {
          continue;
        }

        final key = AppHelpers.onlyDigits(user.number);

        if (key.isEmpty || seen.contains(key)) {
          continue;
        }

        seen.add(key);
        result.add(user);
      }
    } catch (_) {}

    result.sort((a, b) => a.name.compareTo(b.name));

    return result;
  }

  Future<void> createClass({
    required String className,
    required AppUser? classTeacher,
  }) async {
    final cleanClass = AppHelpers.normalizeClassName(className);

    if (cleanClass.isEmpty) {
      throw const AdminSchoolException('Sınıf seçmelisiniz.');
    }

    final exists = await classExists(cleanClass);

    if (exists) {
      throw const AdminSchoolException('Bu sınıf zaten kayıtlı.');
    }

    final now = Timestamp.now();

    await _db.collection('classes').add(
      {
        'name': cleanClass,
        'Name': cleanClass,
        'className': cleanClass,
        'ClassName': cleanClass,
        'class': cleanClass,
        'Class': cleanClass,
        'teacherName': classTeacher?.name ?? '',
        'TeacherName': classTeacher?.name ?? '',
        'classTeacherName': classTeacher?.name ?? '',
        'ClassTeacherName': classTeacher?.name ?? '',
        'teacherNo': classTeacher?.number ?? '',
        'TeacherNo': classTeacher?.number ?? '',
        'classTeacherNo': classTeacher?.number ?? '',
        'ClassTeacherNo': classTeacher?.number ?? '',
        'isDeleted': false,
        'IsDeleted': false,
        'isActive': true,
        'IsActive': true,
        'createdAt': now,
        'CreatedAt': now,
        'updatedAt': now,
        'UpdatedAt': now,
      },
    );
  }

  Future<void> updateClass({
    required SchoolClassModel schoolClass,
    required String className,
    required AppUser? classTeacher,
  }) async {
    final cleanClass = AppHelpers.normalizeClassName(className);

    if (cleanClass.isEmpty) {
      throw const AdminSchoolException('Sınıf seçmelisiniz.');
    }

    final exists = await classExists(
      cleanClass,
      exceptClassId: schoolClass.id,
    );

    if (exists) {
      throw const AdminSchoolException('Bu sınıf zaten kayıtlı.');
    }

    await _db.collection('classes').doc(schoolClass.id).set(
      {
        'name': cleanClass,
        'Name': cleanClass,
        'className': cleanClass,
        'ClassName': cleanClass,
        'class': cleanClass,
        'Class': cleanClass,
        'teacherName': classTeacher?.name ?? '',
        'TeacherName': classTeacher?.name ?? '',
        'classTeacherName': classTeacher?.name ?? '',
        'ClassTeacherName': classTeacher?.name ?? '',
        'teacherNo': classTeacher?.number ?? '',
        'TeacherNo': classTeacher?.number ?? '',
        'classTeacherNo': classTeacher?.number ?? '',
        'ClassTeacherNo': classTeacher?.number ?? '',
        'updatedAt': Timestamp.now(),
        'UpdatedAt': Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteClass(SchoolClassModel schoolClass) async {
    await _db.collection('classes').doc(schoolClass.id).set(
      {
        'isDeleted': true,
        'IsDeleted': true,
        'isActive': false,
        'IsActive': false,
        'deletedAt': Timestamp.now(),
        'DeletedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'UpdatedAt': Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }

  Future<bool> classExists(
    String className, {
    String? exceptClassId,
  }) async {
    final cleanClass = AppHelpers.normalizeClassName(className);

    final snapshot = await _db.collection('classes').get();

    for (final doc in snapshot.docs) {
      if (exceptClassId != null && doc.id == exceptClassId) {
        continue;
      }

      final data = doc.data();

      if (AppHelpers.isDeleted(data)) {
        continue;
      }

      final current = AppHelpers.normalizeClassName(
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

      if (current == cleanClass) {
        return true;
      }
    }

    return false;
  }

  Future<void> createLesson({
    required String lessonName,
    required String className,
    required AppUser? teacher,
  }) async {
    final cleanLesson = lessonName.trim();
    final cleanClass = AppHelpers.normalizeClassName(className);

    if (cleanLesson.isEmpty) {
      throw const AdminSchoolException('Ders adı boş bırakılamaz.');
    }

    if (cleanClass.isEmpty) {
      throw const AdminSchoolException('Sınıf seçmelisiniz.');
    }

    if (teacher == null) {
      throw const AdminSchoolException('Öğretmen seçmelisiniz.');
    }

    final exists = await lessonExists(
      lessonName: cleanLesson,
      className: cleanClass,
      teacherNo: teacher.number,
    );

    if (exists) {
      throw const AdminSchoolException(
        'Bu sınıf, ders ve öğretmen eşleşmesi zaten kayıtlı.',
      );
    }

    final now = Timestamp.now();

    await _db.collection('lessons').add(
      {
        'name': cleanLesson,
        'Name': cleanLesson,
        'lessonName': cleanLesson,
        'LessonName': cleanLesson,
        'title': cleanLesson,
        'Title': cleanLesson,
        'courseName': cleanLesson,
        'CourseName': cleanLesson,
        'className': cleanClass,
        'ClassName': cleanClass,
        'class': cleanClass,
        'Class': cleanClass,
        'targetClass': cleanClass,
        'TargetClass': cleanClass,
        'teacherName': teacher.name,
        'TeacherName': teacher.name,
        'teacher': teacher.name,
        'Teacher': teacher.name,
        'teacherNo': teacher.number,
        'TeacherNo': teacher.number,
        'teacherNumber': teacher.number,
        'TeacherNumber': teacher.number,
        'branch': teacher.branch,
        'Branch': teacher.branch,
        'teacherBranch': teacher.branch,
        'TeacherBranch': teacher.branch,
        'isDeleted': false,
        'IsDeleted': false,
        'isActive': true,
        'IsActive': true,
        'createdAt': now,
        'CreatedAt': now,
        'updatedAt': now,
        'UpdatedAt': now,
      },
    );
  }

  Future<void> updateLesson({
    required LessonModel lesson,
    required String lessonName,
    required String className,
    required AppUser? teacher,
  }) async {
    final cleanLesson = lessonName.trim();
    final cleanClass = AppHelpers.normalizeClassName(className);

    if (cleanLesson.isEmpty) {
      throw const AdminSchoolException('Ders adı boş bırakılamaz.');
    }

    if (cleanClass.isEmpty) {
      throw const AdminSchoolException('Sınıf seçmelisiniz.');
    }

    if (teacher == null) {
      throw const AdminSchoolException('Öğretmen seçmelisiniz.');
    }

    final exists = await lessonExists(
      lessonName: cleanLesson,
      className: cleanClass,
      teacherNo: teacher.number,
      exceptLessonId: lesson.id,
    );

    if (exists) {
      throw const AdminSchoolException(
        'Bu sınıf, ders ve öğretmen eşleşmesi zaten kayıtlı.',
      );
    }

    await _db.collection('lessons').doc(lesson.id).set(
      {
        'name': cleanLesson,
        'Name': cleanLesson,
        'lessonName': cleanLesson,
        'LessonName': cleanLesson,
        'title': cleanLesson,
        'Title': cleanLesson,
        'courseName': cleanLesson,
        'CourseName': cleanLesson,
        'className': cleanClass,
        'ClassName': cleanClass,
        'class': cleanClass,
        'Class': cleanClass,
        'targetClass': cleanClass,
        'TargetClass': cleanClass,
        'teacherName': teacher.name,
        'TeacherName': teacher.name,
        'teacher': teacher.name,
        'Teacher': teacher.name,
        'teacherNo': teacher.number,
        'TeacherNo': teacher.number,
        'teacherNumber': teacher.number,
        'TeacherNumber': teacher.number,
        'branch': teacher.branch,
        'Branch': teacher.branch,
        'teacherBranch': teacher.branch,
        'TeacherBranch': teacher.branch,
        'updatedAt': Timestamp.now(),
        'UpdatedAt': Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteLesson(LessonModel lesson) async {
    await _db.collection('lessons').doc(lesson.id).set(
      {
        'isDeleted': true,
        'IsDeleted': true,
        'isActive': false,
        'IsActive': false,
        'deletedAt': Timestamp.now(),
        'DeletedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'UpdatedAt': Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }

  Future<bool> lessonExists({
    required String lessonName,
    required String className,
    required String teacherNo,
    String? exceptLessonId,
  }) async {
    final lessonKey = AppHelpers.normalizeKey(lessonName);
    final classKey = AppHelpers.normalizeClassName(className);
    final teacherKey = AppHelpers.onlyDigits(teacherNo);

    final snapshot = await _db.collection('lessons').get();

    for (final doc in snapshot.docs) {
      if (exceptLessonId != null && doc.id == exceptLessonId) {
        continue;
      }

      final data = doc.data();

      if (AppHelpers.isDeleted(data)) {
        continue;
      }

      final currentLesson = AppHelpers.normalizeKey(
        AppHelpers.getText(
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
        ),
      );

      final currentClass = AppHelpers.normalizeClassName(
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

      final currentTeacher = AppHelpers.onlyDigits(
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

      if (currentLesson == lessonKey &&
          currentClass == classKey &&
          currentTeacher == teacherKey) {
        return true;
      }
    }

    return false;
  }

  Future<void> createAnnouncement({
    required String title,
    required String content,
    required String target,
  }) async {
    final cleanTitle = title.trim();
    final cleanContent = content.trim();
    final cleanTarget = target.trim().isEmpty ? 'Tüm Okul' : target.trim();

    if (cleanTitle.isEmpty) {
      throw const AdminSchoolException('Duyuru başlığı boş bırakılamaz.');
    }

    if (cleanContent.isEmpty) {
      throw const AdminSchoolException('Duyuru içeriği boş bırakılamaz.');
    }

    final now = Timestamp.now();

    await _db.collection('announcements').add(
      {
        'title': cleanTitle,
        'Title': cleanTitle,
        'name': cleanTitle,
        'Name': cleanTitle,
        'content': cleanContent,
        'Content': cleanContent,
        'message': cleanContent,
        'Message': cleanContent,
        'description': cleanContent,
        'Description': cleanContent,
        'target': cleanTarget,
        'Target': cleanTarget,
        'targetRole': cleanTarget,
        'TargetRole': cleanTarget,
        'audience': cleanTarget,
        'Audience': cleanTarget,
        'author': 'Admin',
        'Author': 'Admin',
        'createdBy': 'Admin',
        'CreatedBy': 'Admin',
        'isDeleted': false,
        'IsDeleted': false,
        'isActive': true,
        'IsActive': true,
        'createdAt': now,
        'CreatedAt': now,
        'publishedAt': now,
        'PublishedAt': now,
        'updatedAt': now,
        'UpdatedAt': now,
      },
    );
  }

  Future<void> deleteAnnouncement(AnnouncementModel announcement) async {
    await _db.collection('announcements').doc(announcement.id).set(
      {
        'isDeleted': true,
        'IsDeleted': true,
        'isActive': false,
        'IsActive': false,
        'deletedAt': Timestamp.now(),
        'DeletedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'UpdatedAt': Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }
}