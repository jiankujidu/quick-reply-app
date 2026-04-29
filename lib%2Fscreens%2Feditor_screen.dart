import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/message_provider.dart';
import '../models/message.dart';
import '../models/tag.dart';

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
  final ImagePicker _picker = ImagePicker();

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
    } else {
      _level = widget.defaultLevel;
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
        const Text(
          '璇濇湳鏍囬',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: '杈撳叆璇濇湳鏍囬',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '璇疯緭鍏ヨ瘽鏈爣棰?;
            }
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
        const Text(
          '璇濇湳鍐呭',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _contentController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: '杈撳叆璇濇湳鍐呭...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '璇疯緭鍏ヨ瘽鏈唴瀹?;
            }
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
        const Text(
          '鍙鑼冨洿',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
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
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
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

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '鏍囩',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextButton.icon(
              onPressed: _showAddTagDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('娣诲姞鏍囩'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Consumer<MessageProvider>(
          builder: (context, provider, _) {
            final availableTags = ['娆㈣繋璇?, '鍜ㄨ', '鍞悗', '娲诲姩', '甯哥敤'];
            
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                  selectedColor: Colors.blue.withOpacity(0.2),
                  checkmarkColor: Colors.blue,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  '鍥剧墖闄勪欢',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${_images.length}/9)',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
            if (_images.length < 9)
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate, size: 18),
                label: const Text('娣诲姞鍥剧墖'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_images.isEmpty)
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 32, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('鏆傛棤鍥剧墖', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.image, size: 40),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => setState(() => _images.removeAt(index)),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
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
            const Text(
              '鏂囦欢闄勪欢',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
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
                  title: Text(entry.value),
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

  void _showAddTagDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('娣诲姞鏍囩'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '杈撳叆鏍囩鍚嶇О',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('鍙栨秷'),
          ),
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

  Future<void> _pickImage() async {
    if (_images.length >= 9) {
      Fluttertoast.showToast(msg: '鏈€澶氭坊鍔?寮犲浘鐗?);
      return;
    }
    
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _images.add(image.path);
      });
    }
  }

  Future<void> _pickFile() async {
    Fluttertoast.showToast(msg: '鏂囦欢閫夋嫨鍔熻兘婕旂ず');
  }

  void _saveMessage() {
    if (!_formKey.currentState!.validate()) return;

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
      createdAt: widget.message?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.message != null) {
      provider.updateMessage(message);
      Fluttertoast.showToast(msg: '鉁?璇濇湳宸叉洿鏂?);
    } else {
      provider.addMessage(message);
      Fluttertoast.showToast(msg: '鉁?璇濇湳宸插垱寤?);
    }

    Navigator.pop(context);
  }
}
