import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_helpers.dart';
import '../models/announcement_model.dart';

class AnnouncementService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<AnnouncementModel>> watchAnnouncementsForRole(String role) {
    return _db.collection('announcements').snapshots().map((snapshot) {
      final roleKey = AppHelpers.normalizeKey(role);

      final list = <AnnouncementModel>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (AppHelpers.isDeleted(data)) {
          continue;
        }

        final title = AppHelpers.getText(data, [
          'title',
          'Title',
          'name',
          'Name',
        ]);

        final content = AppHelpers.getText(data, [
          'content',
          'Content',
          'message',
          'Message',
          'description',
          'Description',
        ]);

        if (title.trim().isEmpty && content.trim().isEmpty) {
          continue;
        }

        final target = AppHelpers.getText(data, [
          'target',
          'Target',
          'targetRole',
          'TargetRole',
          'audience',
          'Audience',
        ], defaultValue: 'Tüm Okul');

        if (!_isForRole(target: target, roleKey: roleKey)) {
          continue;
        }

        list.add(AnnouncementModel.fromDoc(doc));
      }

      list.sort((a, b) {
        final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bd.compareTo(ad);
      });

      return list;
    });
  }

  bool _isForRole({required String target, required String roleKey}) {
    final targetKey = AppHelpers.normalizeKey(target);

    if (targetKey.isEmpty) {
      return true;
    }

    if (targetKey.contains('tum') ||
        targetKey.contains('herkes') ||
        targetKey.contains('genel') ||
        targetKey.contains('okul') ||
        targetKey.contains('all')) {
      return true;
    }

    if (roleKey == 'ogrenci') {
      return targetKey.contains('ogrenci') || targetKey.contains('student');
    }

    if (roleKey == 'ogretmen') {
      return targetKey.contains('ogretmen') || targetKey.contains('teacher');
    }

    if (roleKey == 'veli') {
      return targetKey.contains('veli') || targetKey.contains('parent');
    }

    if (roleKey == 'admin') {
      return targetKey.contains('admin');
    }

    return false;
  }
}
