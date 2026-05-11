import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    'All',
    'Recycling',
    'Composting',
    'Waste Reduction',
    'General',
  ];

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Recycling':
        return Colors.blue;
      case 'Composting':
        return Colors.green;
      case 'Waste Reduction':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Recycling':
        return Icons.recycling;
      case 'Composting':
        return Icons.eco;
      case 'Waste Reduction':
        return Icons.delete_outline;
      default:
        return Icons.library_books;
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text('Error loading articles',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
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
                        const Text('No articles yet',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text(
                          'Educational content will appear here.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
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
        onTap: () => _openArticle(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          article.category,
                          style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      article.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Read more',
                            style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        Icon(Icons.arrow_forward_ios,
                            size: 12, color: color),
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

  void _openArticle(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ArticleDetailScreen(article: article, color: color),
      ),
    );
  }
}

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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            const Divider(height: 28),
            Text(
              article.content,
              style: const TextStyle(fontSize: 15, height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}