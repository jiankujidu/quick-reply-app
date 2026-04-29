import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/message_provider.dart';
import '../models/message.dart';
import '../models/tag.dart';
import '../services/database_service.dart';

class EditorScreen extends StatefulWidget {
  final Message? message;
  final String defaultLevel;

  const EditorScreen({
    super.key,
    this.message,
    this.defaultLevel = 'private',
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String _level = 'private';
  List<String> _selectedTags = [];
  List<String> _images = [];
  List<String> _files = [];
  String _category = '';
  String? _subcategory;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subcategories = [];
  List<Tag> _allTags = [];

  Future<String> _getAbsolutePath(String relativePath) async {
    if (relativePath.startsWith('/')) return relativePath;
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/$relativePath';
  }

  @override
  void initState() {
    super.initState();
    if (widget.message != null) {
      _titleController.text = widget.message!.title;
      _contentController.text = widget.message!.content;
      _level = widget.message!.level;
      _selectedTags = List.from(widget.message!.tags);
      _images = List.from(widget.message!.images);
      _files = List.from(widget.message!.files);
      _category = widget.message!.category;
      _subcategory = widget.message!.subcategory;
    } else {
      _level = widget.defaultLevel;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final db = DatabaseService();
    final all = await db.getAllCategories();
    final tags = await db.getTags();
    if (mounted) {
      setState(() {
        _categories = all.where((c) => c['parentId'] == null).toList();
        _subcategories = all.where((c) => c['parentId'] != null).toList();
        _allTags = tags; // List<Tag> from database
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.message != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '鉁忥笍 缂栬緫璇濇湳' : '鉃?鏂板缓璇濇湳'),
        actions: [
          TextButton(
            onPressed: _saveMessage,
            child: Text(
              '淇濆瓨',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildContentField(),
            const SizedBox(height: 24),
            _buildLevelSelector(),
            const SizedBox(height: 24),
            _buildCategorySelector(),
            const SizedBox(height: 24),
            _buildTagsSection(),
            const SizedBox(height: 24),
            _buildImagesSection(),
            const SizedBox(height: 24),
            _buildFilesSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('璇濇湳鏍囬', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: '杈撳叆璇濇湳鏍囬',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return '璇疯緭鍏ヨ瘽鏈爣棰?;
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('璇濇湳鍐呭', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _contentController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: '杈撳叆璇濇湳鍐呭...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            // 鍐呭鏀逛负閫夊～
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLevelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('鍙鑼冨洿', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildLevelChip('馃彚', '鍏徃绾?, 'company', Colors.blue),
            const SizedBox(width: 12),
            _buildLevelChip('馃懃', '灏忕粍绾?, 'group', Colors.orange),
            const SizedBox(width: 12),
            _buildLevelChip('馃懁', '绉佷汉', 'private', Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildLevelChip(String emoji, String label, String value, Color color) {
    final isSelected = _level == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _level = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    // 鎸夊綋鍓嶉€夋嫨鐨刲evel杩囨护鍒嗙被
    final filteredCategories = _categories.where((c) => c['level'] == _level).toList();
    final filteredSubcategories = _subcategories.where((s) => s['level'] == _level).toList();

    // 鏋勫缓瀛愬垎绫诲尯鍩?
    Widget? subcategoryWidget;
    if (_category.isNotEmpty) {
      final parentCat = _categories.firstWhere(
        (c) => c['name'] == _category,
        orElse: () => <String, dynamic>{},
      );
      if (parentCat.isNotEmpty) {
        final children = filteredSubcategories.where((s) => s['parentId'] == parentCat['id']).toList();
        if (children.isNotEmpty) {
          subcategoryWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text('瀛愬垎绫?, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('涓嶉€夋嫨'),
                    selected: _subcategory == null,
                    onSelected: (_) => setState(() => _subcategory = null),
                  ),
                  ...children.map((subcat) {
                    final name = subcat['name'] as String;
                    return FilterChip(
                      label: Text(name),
                      selected: _subcategory == name,
                      onSelected: (_) => setState(() => _subcategory = name),
                    );
                  }),
                ],
              ),
            ],
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('鍒嗙被', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            TextButton.icon(
              onPressed: _showAddCategoryDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('娣诲姞鍒嗙被'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (filteredCategories.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('褰撳墠绾у埆鏆傛棤鍒嗙被锛岃鍏堟坊鍔?, style: TextStyle(color: Colors.grey[500])),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filteredCategories.map((cat) {
              final name = cat['name'] as String;
              final color = _parseColor(cat['color'] as String);
              final isSelected = _category == name;
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(name),
                  ],
                ),
                selected: isSelected,
                selectedColor: color.withOpacity(0.2),
                onSelected: (selected) {
                  setState(() {
                    _category = name;
                    _subcategory = null;
                  });
                },
              );
            }).toList(),
          ),
        if (subcategoryWidget != null) subcategoryWidget,
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('鏍囩', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton.icon(
              onPressed: _showAddTagDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('娣诲姞鏍囩'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_allTags.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '鏆傛棤鏍囩锛岃鍏堟坊鍔?,
              style: TextStyle(color: Colors.grey[500]),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allTags.map((tag) {
              final color = _parseColor(tag.color);
              final isSelected = _selectedTags.contains(tag.name);
              return FilterChip(
                label: Text(tag.name),
                selected: isSelected,
                selectedColor: color.withOpacity(0.2),
                checkmarkColor: color,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag.name);
                    } else {
                      _selectedTags.remove(tag.name);
                    }
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('鍥剧墖闄勪欢', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image, size: 18),
              label: const Text('娣诲姞鍥剧墖'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_images.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.photo_library, size: 32, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('鏆傛棤鍥剧墖', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _images.asMap().entries.map((entry) {
              return Stack(
                children: [
                  FutureBuilder<String>(
                    future: _getAbsolutePath(entry.value),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final file = File(snapshot.data!);
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: file.existsSync()
                              ? Image.file(file, width: 80, height: 80, fit: BoxFit.cover)
                              : Container(width: 80, height: 80, color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                        );
                      }
                      return Container(width: 80, height: 80, color: Colors.grey[200], child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
                    },
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: IconButton(
                      icon: const Icon(Icons.cancel, size: 18, color: Colors.red),
                      onPressed: () => setState(() => _images.removeAt(entry.key)),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildFilesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('鏂囦欢闄勪欢', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            TextButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file, size: 18),
              label: const Text('娣诲姞鏂囦欢'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_files.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.folder_open, size: 32, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('鏆傛棤鏂囦欢', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            ),
          )
        else
          Column(
            children: _files.asMap().entries.map((entry) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(entry.value.split('/').last.split('\\').last),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _files.removeAt(entry.key)),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  void _showAddTagDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('娣诲姞鏍囩'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: '杈撳叆鏍囩鍚嶇О')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('鍙栨秷')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  if (!_selectedTags.contains(controller.text)) {
                    _selectedTags.add(controller.text);
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('娣诲姞'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    String selectedLevel = _level;
    String selectedColor = '#10B981';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('娣诲姞鍒嗙被'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '鍒嗙被鍚嶇О', hintText: '杈撳叆鍒嗙被鍚嶇О'),
                ),
                const SizedBox(height: 16),
                const Text('绾у埆', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(label: const Text('馃彚 鍏徃绾?), selected: selectedLevel == 'company', onSelected: (s) => setDialogState(() => selectedLevel = 'company')),
                    ChoiceChip(label: const Text('馃懃 灏忕粍绾?), selected: selectedLevel == 'group', onSelected: (s) => setDialogState(() => selectedLevel = 'group')),
                    ChoiceChip(label: const Text('馃懁 鎴戠殑'), selected: selectedLevel == 'private', onSelected: (s) => setDialogState(() => selectedLevel = 'private')),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('棰滆壊', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['#10B981', '#F59E0B', '#EF4444', '#8B5CF6', '#2563EB', '#EC4899'].map((color) {
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: _parseColor(color),
                          shape: BoxShape.circle,
                          border: selectedColor == color ? Border.all(color: Colors.black, width: 2) : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('鍙栨秷')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('璇疯緭鍏ュ垎绫诲悕绉?)));
                  return;
                }
                final db = DatabaseService();
                await db.insertCategory({
                  'name': nameController.text,
                  'color': selectedColor,
                  'level': selectedLevel,
                  'parentId': null,
                  'sort': 0,
                });
                await _loadCategories();
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('鉁?鍒嗙被宸叉坊鍔?), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('娣诲姞'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    if (!mounted) return;
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage(imageQuality: 85);
      if (images.isNotEmpty) {
        final appDir = await getApplicationDocumentsDirectory();
        final attachDir = Directory('${appDir.path}/attachments');
        if (!await attachDir.exists()) {
          await attachDir.create(recursive: true);
        }
        setState(() {
          for (final img in images) {
            final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}_${img.name}';
            final destPath = '${attachDir.path}/$fileName';
            File(img.path).copySync(destPath);
            final relativePath = 'attachments/$fileName';
            if (!_images.contains(relativePath)) {
              _images.add(relativePath);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('鍥剧墖閫夋嫨澶辫触: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    if (!mounted) return;
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        final appDir = await getApplicationDocumentsDirectory();
        final attachDir = Directory('${appDir.path}/attachments');
        if (!await attachDir.exists()) {
          await attachDir.create(recursive: true);
        }
        setState(() {
          for (final file in result.files) {
            if (file.path != null) {
              final fileName = 'file_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
              final destPath = '${attachDir.path}/$fileName';
              File(file.path!).copySync(destPath);
              final relativePath = 'attachments/$fileName';
              if (!_files.contains(relativePath)) {
                _files.add(relativePath);
              }
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('鏂囦欢閫夋嫨澶辫触: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveMessage() async {
    if (!_formKey.currentState!.validate()) return;

    // 濡傛灉鍐呭涓虹┖涓旀病鏈夐檮浠讹紝鎻愮ず鐢ㄦ埛
    final hasContent = _contentController.text.trim().isNotEmpty;
    final hasAttachments = _images.isNotEmpty || _files.isNotEmpty;
    if (!hasContent && !hasAttachments) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('鉂?璇峰～鍐欒瘽鏈唴瀹规垨娣诲姞鍥剧墖/鏂囦欢'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('鉂?璇烽€夋嫨鍒嗙被'), backgroundColor: Colors.red),
      );
      return;
    }

    final provider = context.read<MessageProvider>();
    final now = DateTime.now();

    final message = Message(
      id: widget.message?.id,
      title: _titleController.text,
      content: _contentController.text,
      images: _images,
      files: _files,
      tags: _selectedTags,
      level: _level,
      userId: 1,
      category: _category,
      subcategory: _subcategory,
      createdAt: widget.message?.createdAt ?? now,
      updatedAt: now,
    );

    // 鏄剧ず淇濆瓨涓姸鎬?
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('馃捑 淇濆瓨涓?..', style: TextStyle(color: Colors.white)), backgroundColor: Colors.blue, duration: Duration(seconds: 1)),
    );

    try {
      if (widget.message != null) {
        await provider.updateMessage(message);
      } else {
        await provider.addMessage(message);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.message != null ? '鉁?缂栬緫鎴愬姛' : '鉁?娣诲姞鎴愬姛', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true); // 杩斿洖true琛ㄧず淇濆瓨鎴愬姛
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('鉂?淇濆瓨澶辫触: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    }
  }
}
