import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/education_article.dart';
import '../../core/theme/app_theme.dart';

class ManageMaterialsScreen extends StatelessWidget {
  const ManageMaterialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Materials')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Article'),
        backgroundColor: EcoColors.primaryGreen,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(context, null),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('education_articles')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.library_books,
                      size: 56, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No articles yet.',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Tap + Add Article to create one.',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Article'),
                    onPressed: () => _openForm(context, null),
                  ),
                ],
              ),
            );
          }

          final articles = docs
              .map((d) => EducationArticle.fromMap(
                  d.id, d.data() as Map<String, dynamic>))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: articles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final article = articles[i];
              final color = _categoryColor(article.category);
              return Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_categoryIcon(article.category),
                        color: color),
                  ),
                  title: Text(article.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${article.category} • ${article.createdAt.day}/${article.createdAt.month}/${article.createdAt.year}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: EcoColors.primaryGreen),
                        onPressed: () => _openForm(context, article),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () =>
                            _deleteArticle(context, article.id, article.title),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

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

  Future<void> _deleteArticle(
      BuildContext context, String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Article'),
        content: Text('Remove "$title"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('education_articles')
          .doc(id)
          .delete();
    }
  }

  void _openForm(BuildContext context, EducationArticle? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ArticleForm(existing: existing),
    );
  }
}

class _ArticleForm extends StatefulWidget {
  final EducationArticle? existing;
  const _ArticleForm({this.existing});

  @override
  State<_ArticleForm> createState() => _ArticleFormState();
}

class _ArticleFormState extends State<_ArticleForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _summaryCtrl;
  late final TextEditingController _contentCtrl;
  late String _category;
  bool _saving = false;

  final List<String> _categories = [
    'General', 'Recycling', 'Composting', 'Waste Reduction'
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _summaryCtrl = TextEditingController(text: e?.summary ?? '');
    _contentCtrl = TextEditingController(text: e?.content ?? '');
    _category = e?.category ?? 'General';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'title': _titleCtrl.text.trim(),
      'summary': _summaryCtrl.text.trim(),
      'content': _contentCtrl.text.trim(),
      'category': _category,
      'imageUrl': '',
      'createdAt': widget.existing?.createdAt != null
          ? Timestamp.fromDate(widget.existing!.createdAt)
          : Timestamp.now(),
    };

    final col =
        FirebaseFirestore.instance.collection('education_articles');
    if (widget.existing != null) {
      await col.doc(widget.existing!.id).update(data);
    } else {
      await col.add(data);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? 'Edit Article' : 'New Article',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _summaryCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Summary *',
                  prefixIcon: Icon(Icons.short_text),
                  hintText: 'Short description shown in card view',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _contentCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Content *',
                  prefixIcon: Icon(Icons.article_outlined),
                  hintText: 'Full article content...',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Icon(isEdit ? Icons.save_outlined : Icons.add),
                  label: Text(_saving
                      ? 'Saving...'
                      : isEdit
                          ? 'Save Changes'
                          : 'Publish Article'),
                  onPressed: _saving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}