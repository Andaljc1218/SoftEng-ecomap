import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../models/education_article.dart';
import '../../core/theme/app_theme.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All', 'Recycling', 'Composting', 'Waste Reduction', 'General',
  ];

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Recycling': return Colors.blue;
      case 'Composting': return Colors.green;
      case 'Waste Reduction': return Colors.orange;
      default: return Colors.purple;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Recycling': return Icons.recycling;
      case 'Composting': return Icons.eco;
      case 'Waste Reduction': return Icons.delete_outline;
      default: return Icons.library_books;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Education')),
      body: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 56,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = _selectedCategory == cat;
                return FilterChip(
                  avatar: cat == 'All'
                      ? null
                      : Icon(_categoryIcon(cat),
                          size: 16,
                          color: selected ? Colors.white : _categoryColor(cat)),
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = cat),
                  selectedColor: EcoColors.primaryGreen,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : null,
                    fontWeight: selected ? FontWeight.w600 : null,
                  ),
                  checkmarkColor: Colors.white,
                );
              },
            ),
          ),

          // Articles list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('education_articles')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error loading articles.',
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                var articles = docs
                    .map((d) => EducationArticle.fromMap(
                        d.id, d.data() as Map<String, dynamic>))
                    .toList();

                if (_selectedCategory != 'All') {
                  articles = articles
                      .where((a) => a.category == _selectedCategory)
                      .toList();
                }

                if (articles.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.library_books,
                            size: 56, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No articles yet.',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Educational content will appear here.',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: articles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _ArticleCard(
                    article: articles[i],
                    color: _categoryColor(articles[i].category),
                    icon: _categoryIcon(articles[i].category),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Article card
// ─────────────────────────────────────────────
class _ArticleCard extends StatelessWidget {
  final EducationArticle article;
  final Color color;
  final IconData icon;

  const _ArticleCard({
    required this.article,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _ArticleDetailScreen(
                article: article, color: color),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(article.category,
                          style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 6),
                    Text(article.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(article.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13)),
                    if (article.hasFile) ...[
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(_fileIcon(article.fileType),
                            size: 14, color: color),
                        const SizedBox(width: 4),
                        Text(article.fileName,
                            style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis),
                      ]),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Read more',
                            style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        Icon(Icons.arrow_forward_ios, size: 12, color: color),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _fileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc': case 'docx': return Icons.description;
      case 'ppt': case 'pptx': return Icons.slideshow;
      default: return Icons.attach_file;
    }
  }
}

// ─────────────────────────────────────────────
// Article detail screen
// ─────────────────────────────────────────────
class _ArticleDetailScreen extends StatelessWidget {
  final EducationArticle article;
  final Color color;

  const _ArticleDetailScreen({
    required this.article,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(article.category)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(article.category,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            Text(article.title,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '${article.createdAt.day}/${article.createdAt.month}/${article.createdAt.year}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),

            // File attachment button
            if (article.hasFile) ...[
              const SizedBox(height: 16),
              _FileAttachmentButton(article: article, color: color),
            ],

            const Divider(height: 28),

            if (article.content.isNotEmpty)
              Text(article.content,
                  style: const TextStyle(fontSize: 15, height: 1.7))
            else
              const Text(
                'Open the attached file to view the full content.',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// File attachment button — handles PDF + others
// ─────────────────────────────────────────────
class _FileAttachmentButton extends StatefulWidget {
  final EducationArticle article;
  final Color color;

  const _FileAttachmentButton({
    required this.article,
    required this.color,
  });

  @override
  State<_FileAttachmentButton> createState() => _FileAttachmentButtonState();
}

class _FileAttachmentButtonState extends State<_FileAttachmentButton> {
  bool _loading = false;

  IconData get _icon {
    switch (widget.article.fileType.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc': case 'docx': return Icons.description;
      case 'ppt': case 'pptx': return Icons.slideshow;
      default: return Icons.attach_file;
    }
  }

  Future<void> _open() async {
    setState(() => _loading = true);
    try {
      if (widget.article.resolvedFileType == ArticleFileType.pdf) {
        await _openPdf();
      } else {
        await _openInBrowser();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not open file: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openPdf() async {
    // Download PDF to temp directory then open with flutter_pdfview
    final response =
        await http.get(Uri.parse(widget.article.fileUrl));
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/${widget.article.fileName.isEmpty ? 'file.pdf' : widget.article.fileName}');
    await file.writeAsBytes(response.bodyBytes);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PdfViewerScreen(
          filePath: file.path,
          title: widget.article.title,
        ),
      ),
    );
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.article.fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Cannot open this file type.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: _loading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
          : Icon(_icon),
      label: Text(_loading
          ? 'Opening...'
          : 'Open ${widget.article.fileType.toUpperCase()} — ${widget.article.fileName}'),
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
      ),
      onPressed: _loading ? null : _open,
    );
  }
}

// ─────────────────────────────────────────────
// In-app PDF viewer
// ─────────────────────────────────────────────
class _PdfViewerScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const _PdfViewerScreen({required this.filePath, required this.title});

  @override
  State<_PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<_PdfViewerScreen> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (_ready)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('$_currentPage / $_totalPages',
                    style: const TextStyle(color: Colors.white70)),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.filePath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            onRender: (pages) => setState(() {
              _totalPages = pages ?? 0;
              _ready = true;
            }),
            onPageChanged: (page, _) =>
                setState(() => _currentPage = (page ?? 0) + 1),
          ),
          if (!_ready)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}