import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/education_article.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/eco_app_bar.dart';

class ManageMaterialsScreen extends StatelessWidget {
  const ManageMaterialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EcoAppBar(
        title: 'Manage Materials',
        showHomeLeading: true,
        homeLocation: '/admin/dashboard',
      ),
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
                  const Icon(Icons.library_books, size: 56, color: Colors.grey),
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
                    child: Icon(_categoryIcon(article.category), color: color),
                  ),
                  title: Text(article.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  subtitle: Row(children: [
                    Text(
                      '${article.category} • ${article.createdAt.day}/${article.createdAt.month}/${article.createdAt.year}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (article.hasFile) ...[
                      const SizedBox(width: 6),
                      Icon(_fileIcon(article.fileType),
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text(article.fileType.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ],
                  ]),
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
                        onPressed: () => _deleteArticle(context, article),
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

  IconData _fileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc': case 'docx': return Icons.description;
      case 'ppt': case 'pptx': return Icons.slideshow;
      default: return Icons.attach_file;
    }
  }

  Future<void> _deleteArticle(
      BuildContext context, EducationArticle article) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Article'),
        content: Text('Remove "${article.title}"?'
            '${article.hasFile ? '\n\nThe attached file will also be deleted from storage.' : ''}'),
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
      if (article.hasFile) {
        try {
          await FirebaseStorage.instance.refFromURL(article.fileUrl).delete();
        } catch (_) {}
      }
      await FirebaseFirestore.instance
          .collection('education_articles')
          .doc(article.id)
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

// ─────────────────────────────────────────────
// Article form with file upload
// ─────────────────────────────────────────────
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

  PlatformFile? _pickedFile;
  String? _existingFileUrl;
  String? _existingFileName;
  String? _existingFileType;
  bool _removeExistingFile = false;

  bool _saving = false;
  double _uploadProgress = 0;

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
    _existingFileUrl =
        (e?.fileUrl.isNotEmpty == true) ? e!.fileUrl : null;
    _existingFileName = e?.fileName;
    _existingFileType = e?.fileType;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFile = result.files.first;
        _removeExistingFile = true;
      });
    }
  }

  String _extOf(String name) {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  String _contentTypeOf(String ext) {
    switch (ext) {
      case 'pdf': return 'application/pdf';
      case 'doc': return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'ppt': return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      default: return 'application/octet-stream';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _uploadProgress = 0; });

    String fileUrl = _existingFileUrl ?? '';
    String fileName = _existingFileName ?? '';
    String fileType = _existingFileType ?? '';

    try {
      // Delete old file if being replaced
      if (_removeExistingFile && _existingFileUrl != null) {
        try {
          await FirebaseStorage.instance.refFromURL(_existingFileUrl!).delete();
        } catch (_) {}
        fileUrl = ''; fileName = ''; fileType = '';
      }

      // Upload new file
      if (_pickedFile != null && _pickedFile!.bytes != null) {
        final ext = _extOf(_pickedFile!.name);
        final path =
            'education_files/${DateTime.now().millisecondsSinceEpoch}_${_pickedFile!.name}';
        final ref = FirebaseStorage.instance.ref(path);
        final task = ref.putData(
          _pickedFile!.bytes!,
          SettableMetadata(contentType: _contentTypeOf(ext)),
        );

        task.snapshotEvents.listen((snap) {
          final p = snap.bytesTransferred /
              (snap.totalBytes == 0 ? 1 : snap.totalBytes);
          if (mounted) setState(() => _uploadProgress = p);
        });

        await task;
        fileUrl = await ref.getDownloadURL();
        fileName = _pickedFile!.name;
        fileType = ext;
      }

      final data = {
        'title': _titleCtrl.text.trim(),
        'summary': _summaryCtrl.text.trim(),
        'content': _contentCtrl.text.trim(),
        'category': _category,
        'imageUrl': '',
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileType': fileType,
        'createdAt': widget.existing?.createdAt != null
            ? Timestamp.fromDate(widget.existing!.createdAt)
            : Timestamp.now(),
      };

      final col = FirebaseFirestore.instance.collection('education_articles');
      if (widget.existing != null) {
        await col.doc(widget.existing!.id).update(data);
      } else {
        await col.add(data);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final hasExistingFile = _existingFileUrl != null && !_removeExistingFile;

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

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
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _summaryCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Summary *',
                  prefixIcon: Icon(Icons.short_text),
                  hintText: 'Short description shown in the card',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _contentCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  prefixIcon: Icon(Icons.article_outlined),
                  hintText: 'Article body (optional if file attached)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              // ── File section ──
              const Text('Attachment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),

              if (hasExistingFile)
                _FileChip(
                  name: _existingFileName ?? 'Attached file',
                  type: _existingFileType ?? '',
                  color: EcoColors.backgroundGreen,
                  borderColor: EcoColors.accentGreen,
                  iconColor: EcoColors.primaryGreen,
                  onRemove: () => setState(() => _removeExistingFile = true),
                ),

              if (_pickedFile != null)
                _FileChip(
                  name: _pickedFile!.name,
                  type: _extOf(_pickedFile!.name),
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderColor: Colors.blue.shade200,
                  iconColor: Colors.blue,
                  subtitle:
                      '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                  onRemove: () => setState(() {
                    _pickedFile = null;
                    if (widget.existing?.fileUrl.isNotEmpty == true) {
                      _removeExistingFile = false;
                    }
                  }),
                ),

              if (_saving && _uploadProgress > 0 && _uploadProgress < 1) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _uploadProgress),
                const SizedBox(height: 4),
                Text(
                  'Uploading ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],

              if (_pickedFile == null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: Text(hasExistingFile
                      ? 'Replace File'
                      : 'Attach File  (PDF, DOC, PPT, Image)'),
                  onPressed: _saving ? null : _pickFile,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _saving
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Icon(isEdit ? Icons.save_outlined : Icons.add),
                  label: Text(_saving
                      ? (_uploadProgress > 0 ? 'Uploading...' : 'Saving...')
                      : isEdit ? 'Save Changes' : 'Publish Article'),
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

class _FileChip extends StatelessWidget {
  final String name, type;
  final Color color, borderColor, iconColor;
  final String? subtitle;
  final VoidCallback onRemove;

  const _FileChip({
    required this.name,
    required this.type,
    required this.color,
    required this.borderColor,
    required this.iconColor,
    this.subtitle,
    required this.onRemove,
  });

  IconData get _icon {
    switch (type.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc': case 'docx': return Icons.description;
      case 'ppt': case 'pptx': return Icons.slideshow;
      case 'jpg': case 'jpeg': case 'png': return Icons.image;
      default: return Icons.attach_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(children: [
        Icon(_icon, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis),
              if (subtitle != null)
                Text(subtitle!,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red, size: 20),
          onPressed: onRemove,
        ),
      ]),
    );
  }
}