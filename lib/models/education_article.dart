import 'package:cloud_firestore/cloud_firestore.dart';

class EducationArticle {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String category;   // 'Recycling', 'Composting', 'Waste Reduction', 'General'
  final String imageUrl;
  final DateTime createdAt;

  const EducationArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.category,
    required this.imageUrl,
    required this.createdAt,
  });

  factory EducationArticle.fromMap(String id, Map<String, dynamic> map) {
    return EducationArticle(
      id: id,
      title: map['title'] ?? '',
      summary: map['summary'] ?? '',
      content: map['content'] ?? '',
      category: map['category'] ?? 'General',
      imageUrl: map['imageUrl'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'summary': summary,
      'content': content,
      'category': category,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}