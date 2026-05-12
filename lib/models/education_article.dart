import 'package:cloud_firestore/cloud_firestore.dart';

enum ArticleFileType { none, pdf, doc, image, other }

class EducationArticle {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String category;
  final String imageUrl;
  final String fileUrl;       // Firebase Storage download URL
  final String fileName;      // original file name e.g. "guide.pdf"
  final String fileType;      // 'pdf', 'doc', 'docx', 'image', ''
  final DateTime createdAt;

  const EducationArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.category,
    required this.imageUrl,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.createdAt,
  });

  bool get hasFile => fileUrl.isNotEmpty;

  ArticleFileType get resolvedFileType {
    switch (fileType.toLowerCase()) {
      case 'pdf': return ArticleFileType.pdf;
      case 'doc':
      case 'docx': return ArticleFileType.doc;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif': return ArticleFileType.image;
      case '': return ArticleFileType.none;
      default: return ArticleFileType.other;
    }
  }

  factory EducationArticle.fromMap(String id, Map<String, dynamic> map) {
    return EducationArticle(
      id: id,
      title: map['title'] ?? '',
      summary: map['summary'] ?? '',
      content: map['content'] ?? '',
      category: map['category'] ?? 'General',
      imageUrl: map['imageUrl'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      fileType: map['fileType'] ?? '',
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
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}