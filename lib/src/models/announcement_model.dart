import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_helpers.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String target;
  final String author;
  final DateTime? createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.target,
    required this.author,
    required this.createdAt,
  });

  factory AnnouncementModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final title = AppHelpers.getText(
      data,
      [
        'title',
        'Title',
        'name',
        'Name',
      ],
      defaultValue: 'Duyuru',
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
      defaultValue: '-',
    );

    final target = AppHelpers.getText(
      data,
      [
        'target',
        'Target',
        'targetRole',
        'TargetRole',
        'audience',
        'Audience',
      ],
      defaultValue: 'Tüm Okul',
    );

    final author = AppHelpers.getText(
      data,
      [
        'author',
        'Author',
        'createdBy',
        'CreatedBy',
        'publisher',
        'Publisher',
      ],
      defaultValue: 'Admin',
    );

    final createdAt = AppHelpers.getDate(
      data,
      [
        'createdAt',
        'CreatedAt',
        'publishedAt',
        'PublishedAt',
        'date',
        'Date',
      ],
    );

    return AnnouncementModel(
      id: doc.id,
      title: title.trim().isEmpty ? 'Duyuru' : title.trim(),
      content: content.trim().isEmpty ? '-' : content.trim(),
      target: target.trim().isEmpty ? 'Tüm Okul' : target.trim(),
      author: author.trim().isEmpty ? 'Admin' : author.trim(),
      createdAt: createdAt,
    );
  }
}