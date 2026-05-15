import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const QuickReplyApp());
}

// 悬浮窗入口
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OverlayApp());
}

class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const _OverlayQuickReply(),
    );
  }
}

// ============== 数据模型 ==============

class Category {
  final String id;
  final String name;
  final String icon;
  final String color;
  final int sortOrder;
  final String parentId;
  final String scope;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    this.icon = 'folder',
    this.color = '#4CAF50',
    this.sortOrder = 0,
    this.parentId = '',
    this.scope = 'public',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color': color,
    'sortOrder': sortOrder,
    'parentId': parentId,
    'scope': scope,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    icon: json['icon'] ?? 'folder',
    color: json['color'] ?? '#4CAF50',
    sortOrder: json['sortOrder'] ?? 0,
    parentId: json['parentId'] ?? '',
    scope: json['scope'] ?? 'public',
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
  );
}

class ReplyTemplate {
  final String id;
  final String title;
  final String content;
  final String categoryId;
  final bool isFavorite;
  final String scope;
  int useCount;
  final List<String> attachments;
  final String titleColor;
  final DateTime createdAt;
  DateTime updatedAt;

  ReplyTemplate({
    required this.id,
    required this.title,
    required this.content,
    this.categoryId = '',
    this.isFavorite = false,
    this.scope = 'public',
    this.useCount = 0,
    this.attachments = const [],
    this.titleColor = '#2196F3',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(), updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'categoryId': categoryId,
    'isFavorite': isFavorite,
    'scope': scope,
    'useCount': useCount,
    'attachments': attachments,
    'titleColor': titleColor,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ReplyTemplate.fromJson(Map<String, dynamic> json) => ReplyTemplate(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    categoryId: json['categoryId'] ?? '',
    isFavorite: json['isFavorite'] ?? false,
    scope: json['scope'] ?? 'public',
    useCount: json['useCount'] ?? 0,
    attachments: json['attachments'] != null ? List<String>.from(json['attachments']) : [],
    titleColor: json['titleColor'] ?? '#2196F3',
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
  );
}

class Customer {
  final String id;
  final String name;
  final String phone;
  final String wechat;
  final String company;
  final String notes;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.wechat = '',
    this.company = '',
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'wechat': wechat,
    'company': company,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    phone: json['phone'] ?? '',
    wechat: json['wechat'] ?? '',
    company: json['company'] ?? '',
    notes: json['notes'] ?? '',
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
  );
}

class NoteItem {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  DateTime updatedAt;

  NoteItem({
    required this.id,
    required this.title,
    required this.content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(), updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory NoteItem.fromJson(Map<String, dynamic> json) => NoteItem(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
  );
}

class CallRecordItem {
  final String id;
  final String customerName;
  final String phone;
  final DateTime callTime;
  final int duration;
  final String callType; // 'incoming', 'outgoing', 'missed'

  CallRecordItem({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.callTime,
    required this.duration,
    required this.callType,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerName': customerName,
    'phone': phone,
    'callTime': callTime.toIso8601String(),
    'duration': duration,
    'callType': callType,
  };

  factory CallRecordItem.fromJson(Map<String, dynamic> json) => CallRecordItem(
    id: json['id'] ?? '',
    customerName: json['customerName'] ?? '',
    phone: json['phone'] ?? '',
    callTime: json['callTime'] != null ? DateTime.parse(json['callTime']) : DateTime.now(),
    duration: json['duration'] ?? 0,
    callType: json['callType'] ?? 'outgoing',
  );
}

// ============== 存储服务 ==============

class StorageService {
  static late SharedPreferences _prefs;
  static List<Category> _categories = [];
  static List<ReplyTemplate> _templates = [];
  static List<Customer> _customers = [];
  static List<NoteItem> _notes = [];
  static List<CallRecordItem> _callRecords = [];

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadAll();
  }

  static void _loadAll() {
    // 加载分类
    final catsJson = _prefs.getString('categories');
    if (catsJson != null) {
      final List<dynamic> catsList = jsonDecode(catsJson);
      _categories = catsList.map((e) => Category.fromJson(e)).toList();
    } else {
      // 默认分类
      _categories = [
        Category(id: 'cat1', name: '公司话术', color: '#4CAF50', scope: 'public'),
        Category(id: 'cat2', name: '产品介绍', color: '#2196F3', scope: 'public', parentId: 'cat1'),
        Category(id: 'cat3', name: '常见问题', color: '#FF9800', scope: 'public', parentId: 'cat1'),
      ];
      _saveCategories();
    }

    // 加载话术
    final tempsJson = _prefs.getString('templates');
    if (tempsJson != null) {
      final List<dynamic> tempsList = jsonDecode(tempsJson);
      _templates = tempsList.map((e) => ReplyTemplate.fromJson(e)).toList();
    } else {
      _templates = [
        ReplyTemplate(id: 't1', title: '您好', content: '您好，很高兴为您服务！有什么可以帮助您的吗？', categoryId: 'cat2'),
        ReplyTemplate(id: 't2', title: '感谢咨询', content: '感谢您的咨询，如有其他问题请随时联系我们。', categoryId: 'cat3'),
      ];
      _saveTemplates();
    }

    // 加载客户
    final custJson = _prefs.getString('customers');
    if (custJson != null) {
      final List<dynamic> custList = jsonDecode(custJson);
      _customers = custList.map((e) => Customer.fromJson(e)).toList();
    }

    // 加载笔记
    final notesJson = _prefs.getString('notes');
    if (notesJson != null) {
      final List<dynamic> notesList = jsonDecode(notesJson);
      _notes = notesList.map((e) => NoteItem.fromJson(e)).toList();
    }

    // 加载通话记录
    final callsJson = _prefs.getString('callRecords');
    if (callsJson != null) {
      final List<dynamic> callsList = jsonDecode(callsJson);
      _callRecords = callsList.map((e) => CallRecordItem.fromJson(e)).toList();
    }
  }

  static List<Category> getCategories() => _categories;
  static List<ReplyTemplate> getTemplates() => _templates;
  static List<Customer> getCustomers() => _customers;
  static List<NoteItem> getNotes() => _notes;
  static List<CallRecordItem> getCallRecords() => _callRecords;

  static void _saveCategories() {
    _prefs.setString('categories', jsonEncode(_categories.map((e) => e.toJson()).toList()));
  }

  static void _saveTemplates() {
    _prefs.setString('templates', jsonEncode(_templates.map((e) => e.toJson()).toList()));
  }

  static void _saveCustomers() {
    _prefs.setString('customers', jsonEncode(_customers.map((e) => e.toJson()).toList()));
  }

  static void _saveNotes() {
    _prefs.setString('notes', jsonEncode(_notes.map((e) => e.toJson()).toList()));
  }

  static void _saveCallRecords() {
    _prefs.setString('callRecords', jsonEncode(_callRecords.map((e) => e.toJson()).toList()));
  }

  static void saveCategory(Category cat) {
    final index = _categories.indexWhere((c) => c.id == cat.id);
    if (index >= 0) {
      _categories[index] = cat;
    } else {
      _categories.add(cat);
    }
    _saveCategories();
  }

  static void deleteCategory(String id) {
    _categories.removeWhere((c) => c.id == id);
    _saveCategories();
  }

  static void saveTemplate(ReplyTemplate t) {
    final index = _templates.indexWhere((x) => x.id == t.id);
    if (index >= 0) {
      t = ReplyTemplate(
        id: t.id,
        title: t.title,
        content: t.content,
        categoryId: t.categoryId,
        isFavorite: t.isFavorite,
        scope: t.scope,
        useCount: t.useCount,
        attachments: t.attachments,
        titleColor: t.titleColor,
        createdAt: t.createdAt,
        updatedAt: DateTime.now(),
      );
      _templates[index] = t;
    } else {
      _templates.add(t);
    }
    _saveTemplates();
  }

  static void deleteTemplate(String id) {
    _templates.removeWhere((t) => t.id == id);
    _saveTemplates();
  }

  static void incrementUseCount(String id) {
    final index = _templates.indexWhere((t) => t.id == id);
    if (index >= 0) {
      _templates[index].useCount++;
      _saveTemplates();
    }
  }

  static void saveCustomer(Customer c) {
    final index = _customers.indexWhere((x) => x.id == c.id);
    if (index >= 0) {
      _customers[index] = c;
    } else {
      _customers.add(c);
    }
    _saveCustomers();
  }

  static void deleteCustomer(String id) {
    _customers.removeWhere((c) => c.id == id);
    _saveCustomers();
  }

  static void saveNote(NoteItem n) {
    final index = _notes.indexWhere((x) => x.id == n.id);
    if (index >= 0) {
      n = NoteItem(id: n.id, title: n.title, content: n.content, createdAt: n.createdAt, updatedAt: DateTime.now());
      _notes[index] = n;
    } else {
      _notes.add(n);
    }
    _saveNotes();
  }

  static void deleteNote(String id) {
    _notes.removeWhere((n) => n.id == id);
    _saveNotes();
  }

  static String exportAll() {
    return jsonEncode({
      'categories': _categories.map((e) => e.toJson()).toList(),
      'templates': _templates.map((e) => e.toJson()).toList(),
      'customers': _customers.map((e) => e.toJson()).toList(),
      'notes': _notes.map((e) => e.toJson()).toList(),
      'callRecords': _callRecords.map((e) => e.toJson()).toList(),
    });
  }

  static void importAll(String json) {
    final data = jsonDecode(json);
    if (data['categories'] != null) {
      _categories = (data['categories'] as List).map((e) => Category.fromJson(e)).toList();
      _saveCategories();
    }
    if (data['templates'] != null) {
      _templates = (data['templates'] as List).map((e) => ReplyTemplate.fromJson(e)).toList();
      _saveTemplates();
    }
    if (data['customers'] != null) {
      _customers = (data['customers'] as List).map((e) => Customer.fromJson(e)).toList();
      _saveCustomers();
    }
    if (data['notes'] != null) {
      _notes = (data['notes'] as List).map((e) => NoteItem.fromJson(e)).toList();
      _saveNotes();
    }
    if (data['callRecords'] != null) {
      _callRecords = (data['callRecords'] as List).map((e) => CallRecordItem.fromJson(e)).toList();
      _saveCallRecords();
    }
  }
}


// ============== 主应用 ==============

class QuickReplyApp extends StatelessWidget {
  const QuickReplyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '快回复 Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1)),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _floatingEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkFloatingPermission();
  }

  Future<void> _checkFloatingPermission() async {
    final granted = await FlutterOverlayWindow.isPermissionGranted() ?? false;
    setState(() => _floatingEnabled = granted);
  }

  Future<void> _toggleFloating(bool value) async {
    if (value) {
      final granted = await FlutterOverlayWindow.requestPermission() ?? false;
      if (granted) {
        await FlutterOverlayWindow.showOverlay(
          height: 500,
          width: 300,
          alignment: OverlayAlignment.centerRight,
          enableDrag: true,
        );
        setState(() => _floatingEnabled = true);
      }
    } else {
      await FlutterOverlayWindow.closeOverlay();
      setState(() => _floatingEnabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      TemplateScreen(floatingEnabled: _floatingEnabled, onFloatingToggle: _toggleFloating),
      const CustomerScreen(),
      const NoteScreen(),
      const CallRecordScreen(),
      SettingsScreen(floatingEnabled: _floatingEnabled, onFloatingToggle: _toggleFloating),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_outlined), selectedIcon: Icon(Icons.chat), label: '话术'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: '客户'),
          NavigationDestination(icon: Icon(Icons.note_outlined), selectedIcon: Icon(Icons.note), label: '笔记'),
          NavigationDestination(icon: Icon(Icons.phone_outlined), selectedIcon: Icon(Icons.phone), label: '通话'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}

// ============== 话术管理页面 ==============

class TemplateScreen extends StatefulWidget {
  final bool floatingEnabled;
  final ValueChanged<bool> onFloatingToggle;

  const TemplateScreen({super.key, required this.floatingEnabled, required this.onFloatingToggle});

  @override
  State<TemplateScreen> createState() => _TemplateScreenState();
}

class _TemplateScreenState extends State<TemplateScreen> {
  List<Category> _categories = [];
  List<ReplyTemplate> _templates = [];
  String _selectedScope = 'company';
  String? _selectedTopCategoryId;
  String _searchQuery = '';
  Set<String> _expandedCategories = {};
  // int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _categories = StorageService.getCategories();
      _templates = StorageService.getTemplates();
    });
  }

  bool _categoryMatchesScope(String? catScope) {
    if (catScope == null) return _selectedScope == 'company';
    if (_selectedScope == 'company') return catScope == 'public' || catScope == 'company';
    if (_selectedScope == 'team') return catScope == 'public' || catScope == 'team';
    return catScope == 'personal';
  }

  List<Category> get _topCategories {
    final tops = _categories.where((c) => c.parentId.isEmpty && _categoryMatchesScope(c.scope)).toList();
    tops.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return tops;
  }

  List<Category> _subCategories(String parentId) {
    return _categories.where((c) => c.parentId == parentId && _categoryMatchesScope(c.scope)).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<ReplyTemplate> _templatesInCategory(String catId) {
    final subIds = _subCategories(catId).map((c) => c.id).toSet()..add(catId);
    return _templates.where((t) => subIds.contains(t.categoryId)).toList();
  }

  List<ReplyTemplate> get _searchResults {
    if (_searchQuery.isEmpty) return [];
    final q = _searchQuery.toLowerCase();
    return _templates.where((t) =>
      t.title.toLowerCase().contains(q) || t.content.toLowerCase().contains(q)
    ).toList();
  }

  void _addTemplate() {
    if (_selectedTopCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先选择一个分类')));
      return;
    }
    _showEditTemplateDialog();
  }

  void _showEditTemplateDialog({ReplyTemplate? template}) {
    final isEdit = template != null;
    String title = template?.title ?? '';
    String content = template?.content ?? '';
    String categoryId = template?.categoryId ?? _selectedTopCategoryId ?? '';
    List<String> attachments = template?.attachments != null ? List.from(template!.attachments) : [];
    String titleColor = template?.titleColor ?? '#2196F3';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? '编辑话术' : '新建话术'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 所属一级分类
                DropdownButtonFormField<String>(
                  value: _topCategories.any((c) => c.id == categoryId) ? categoryId : null,
                  decoration: const InputDecoration(labelText: '所属一级分类', border: OutlineInputBorder()),
                  items: _topCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) => setDialogState(() => categoryId = v ?? ''),
                ),
                const SizedBox(height: 12),
                // 所属二级分类
                DropdownButtonFormField<String>(
                  value: _subCategories(categoryId).any((c) => c.id == categoryId) ? categoryId : null,
                  decoration: const InputDecoration(labelText: '所属二级分类（可选）', border: OutlineInputBorder()),
                  items: _subCategories(categoryId).map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) { if (v != null) setDialogState(() => categoryId = v); },
                ),
                const SizedBox(height: 12),
                // 标题
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: '话术标题', border: OutlineInputBorder()),
                        controller: TextEditingController(text: title),
                        onChanged: (v) => title = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(color: _hexColor(titleColor), borderRadius: BorderRadius.circular(4)),
                      ),
                      onPressed: () {
                        final colors = ['#F44336', '#E91E63', '#9C27B0', '#673AB7', '#3F51B5', '#2196F3', '#03A9F4', '#00BCD4', '#009688', '#4CAF50', '#FF9800', '#FF5722'];
                        final idx = colors.indexOf(titleColor);
                        setDialogState(() => titleColor = colors[(idx + 1) % colors.length]);
                      },
                      tooltip: '选择标题背景色',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 内容
                TextField(
                  decoration: const InputDecoration(labelText: '话术内容', border: OutlineInputBorder()),
                  controller: TextEditingController(text: content),
                  maxLines: 4,
                  onChanged: (v) => content = v,
                ),
                const SizedBox(height: 12),
                // 附件
                if (attachments.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: attachments.asMap().entries.map((e) => Chip(
                      label: Text(e.value.split('/').last, style: const TextStyle(fontSize: 12)),
                      onDeleted: () => setDialogState(() => attachments.removeAt(e.key)),
                    )).toList(),
                  ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles();
                    if (result?.files.isNotEmpty ?? false) {
                      setDialogState(() => attachments.add(result!.files.first.path!));
                    }
                  },
                  icon: const Icon(Icons.attach_file),
                  label: const Text('添加附件'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                if (title.isEmpty || content.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写标题和内容')));
                  return;
                }
                final t = ReplyTemplate(
                  id: template?.id ?? 't${DateTime.now().millisecondsSinceEpoch}',
                  title: title,
                  content: content,
                  categoryId: categoryId,
                  attachments: attachments,
                  titleColor: titleColor,
                  scope: _selectedScope,
                );
                StorageService.saveTemplate(t);
                _loadData();
                Navigator.pop(ctx);
              },
              child: Text(isEdit ? '保存' : '添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog({String? parentId}) {
    final nameCtrl = TextEditingController();
    String color = '#4CAF50';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(parentId == null ? '新建一级分类' : '新建二级分类'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: '分类名称', border: OutlineInputBorder()),
                controller: nameCtrl,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['#4CAF50', '#2196F3', '#FF9800', '#E91E63', '#9C27B0', '#00BCD4', '#FF5722', '#795548'].map((c) => 
                  InkWell(
                    onTap: () => setDialogState(() => color = c),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: _hexColor(c),
                        borderRadius: BorderRadius.circular(8),
                        border: color == c ? Border.all(width: 3, color: Colors.black) : null,
                      ),
                    ),
                  ),
                ).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty) return;
                final cat = Category(
                  id: 'cat${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text,
                  color: color,
                  parentId: parentId ?? '',
                  scope: _selectedScope == 'company' ? 'public' : _selectedScope,
                );
                StorageService.saveCategory(cat);
                _loadData();
                Navigator.pop(ctx);
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCategory(Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除分类'),
        content: Text('确定删除"${cat.name}"吗？该分类下的话术也会被删除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              StorageService.deleteCategory(cat.id);
              _templates.where((t) => t.categoryId == cat.id).forEach((t) => StorageService.deleteTemplate(t.id));
              _loadData();
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _hexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      return Colors.green;
    }
  }

  IconData _iconData(String name) {
    const icons = {
      'folder': Icons.folder, 'chat': Icons.chat, 'star': Icons.star,
      'favorite': Icons.favorite, 'lightbulb': Icons.lightbulb,
      'campaign': Icons.campaign, 'shopping_cart': Icons.shopping_cart,
      'local_offer': Icons.local_offer, 'phone': Icons.phone,
      'email': Icons.email, 'person': Icons.person, 'group': Icons.group,
    };
    return icons[name] ?? Icons.folder;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('快回复 Pro'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => setState(() {})),
          PopupMenuButton(
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'add_top_cat', child: Text('新建一级分类')),
              const PopupMenuItem(value: 'add_template', child: Text('新建话术')),
            ],
            onSelected: (v) {
              if (v == 'add_top_cat') _showAddCategoryDialog();
              if (v == 'add_template') _addTemplate();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索话术...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          // 三标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'company', label: Text('公司话术'), icon: Icon(Icons.business)),
                ButtonSegment(value: 'team', label: Text('小组话术'), icon: Icon(Icons.group)),
                ButtonSegment(value: 'personal', label: Text('私人话术'), icon: Icon(Icons.person)),
              ],
              selected: {_selectedScope},
              onSelectionChanged: (s) => setState(() {
                _selectedScope = s.first;
                _selectedTopCategoryId = null;
              }),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return _selectedScope == 'company' ? Colors.green :
                           _selectedScope == 'team' ? Colors.blue : Colors.grey;
                  }
                  return null;
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 一级分类横向标签栏
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _topCategories.length,
              itemBuilder: (ctx, i) {
                final cat = _topCategories[i];
                final selected = _selectedTopCategoryId == cat.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTopCategoryId = cat.id),
                    onLongPress: () => _showCategoryMenu(cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? _hexColor(cat.color) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(_iconData(cat.icon), size: 16, color: selected ? Colors.white : _hexColor(cat.color)),
                          const SizedBox(width: 4),
                          Text(cat.name, style: TextStyle(color: selected ? Colors.white : Colors.black87, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // 内容区
          Expanded(
            child: _searchQuery.isNotEmpty
                ? _buildSearchResults()
                : _selectedTopCategoryId == null
                    ? const Center(child: Text('请选择一个分类'))
                    : _buildCategoryContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTemplate,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryContent() {
    final topCat = _categories.firstWhere((c) => c.id == _selectedTopCategoryId, orElse: () => Category(id: '', name: '', color: '#4CAF50'));
    final subs = _subCategories(_selectedTopCategoryId!);
    final templates = _templatesInCategory(_selectedTopCategoryId!);

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // 二级分类
        ...subs.map((sub) {
          final subTemplates = _templatesInCategory(sub.id);
          final expanded = _expandedCategories.contains(sub.id);
          return Column(
            children: [
              ListTile(
                dense: true,
                leading: Icon(_iconData(sub.icon), color: _hexColor(sub.color), size: 16),
                title: Text(sub.name, style: const TextStyle(fontSize: 13)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('(${subTemplates.length})', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Icon(expanded ? Icons.expand_less : Icons.chevron_right, size: 18),
                  ],
                ),
                onTap: () => setState(() => _expandedCategories.contains(sub.id) ? _expandedCategories.remove(sub.id) : _expandedCategories.add(sub.id)),
              ),
              if (expanded) ...subTemplates.map((t) => _buildTemplateItem(t, indent: 20)),
            ],
          );
        }),
        // 直接话术
        ...templates.where((t) => _categories.firstWhere((c) => c.id == t.categoryId, orElse: () => Category(id: '', name: '', parentId: '')).parentId.isEmpty).map((t) => _buildTemplateItem(t)),
      ],
    );
  }

  Widget _buildTemplateItem(ReplyTemplate t, {double indent = 0}) {
    final borderColor = t.titleColor.isNotEmpty ? _hexColor(t.titleColor) : Colors.green;
    return GestureDetector(
      onLongPress: () => _showTemplateMenu(t),
      onTap: () {
        Clipboard.setData(ClipboardData(text: t.content));
        StorageService.incrementUseCount(t.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制到剪贴板')));
      },
      child: Container(
        margin: EdgeInsets.only(left: indent, right: 8, top: 4, bottom: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: borderColor, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w500))),
                if (t.useCount > 0) Text('${t.useCount}次', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              ],
            ),
            const SizedBox(height: 4),
            Text(t.content.length > 60 ? '${t.content.substring(0, 60)}...' : t.content, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = _searchResults;
    if (results.isEmpty) {
      return Center(child: Text('未找到"$_searchQuery"'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: results.length,
      itemBuilder: (ctx, i) => _buildTemplateItem(results[i]),
    );
  }

  void _showCategoryMenu(Category cat) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.add), title: const Text('新建二级分类'), onTap: () { Navigator.pop(ctx); _showAddCategoryDialog(parentId: cat.id); }),
            ListTile(leading: const Icon(Icons.add_circle_outline), title: const Text('新建话术'), onTap: () { Navigator.pop(ctx); setState(() => _selectedTopCategoryId = cat.id); _addTemplate(); }),
            ListTile(leading: const Icon(Icons.edit), title: const Text('重命名'), onTap: () { Navigator.pop(ctx); /* TODO */ }),
            ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('删除'), onTap: () { Navigator.pop(ctx); _deleteCategory(cat); }),
          ],
        ),
      ),
    );
  }

  void _showTemplateMenu(ReplyTemplate t) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.copy), title: const Text('复制'), onTap: () { Navigator.pop(ctx); Clipboard.setData(ClipboardData(text: t.content)); StorageService.incrementUseCount(t.id); }),
            ListTile(leading: const Icon(Icons.edit), title: const Text('编辑'), onTap: () { Navigator.pop(ctx); _showEditTemplateDialog(template: t); }),
            ListTile(leading: const Icon(Icons.share), title: const Text('转发'), onTap: () async { Navigator.pop(ctx); await Share.share(t.content); }),
            ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('删除'), onTap: () { Navigator.pop(ctx); StorageService.deleteTemplate(t.id); _loadData(); }),
          ],
        ),
      ),
    );
  }
}


// ============== 客户管理页面 ==============

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  List<Customer> _customers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() => _customers = StorageService.getCustomers());
  }

  List<Customer> get _filtered {
    if (_searchQuery.isEmpty) return _customers;
    final q = _searchQuery.toLowerCase();
    return _customers.where((c) =>
      c.name.toLowerCase().contains(q) ||
      c.phone.contains(q) ||
      c.wechat.toLowerCase().contains(q)
    ).toList();
  }

  void _showEditDialog({Customer? customer}) {
    final isEdit = customer != null;
    final nameCtrl = TextEditingController(text: customer?.name ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    final wechatCtrl = TextEditingController(text: customer?.wechat ?? '');
    final companyCtrl = TextEditingController(text: customer?.company ?? '');
    final notesCtrl = TextEditingController(text: customer?.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? '编辑客户' : '添加客户'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '姓名 *')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: '电话'), keyboardType: TextInputType.phone),
              TextField(controller: wechatCtrl, decoration: const InputDecoration(labelText: '微信')),
              TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: '公司')),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: '备注'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty) return;
              final c = Customer(
                id: customer?.id ?? 'cust${DateTime.now().millisecondsSinceEpoch}',
                name: nameCtrl.text,
                phone: phoneCtrl.text,
                wechat: wechatCtrl.text,
                company: companyCtrl.text,
                notes: notesCtrl.text,
              );
              StorageService.saveCustomer(c);
              _loadData();
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('客户管理'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索客户...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('暂无客户'))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final c = _filtered[i];
                      return ListTile(
                        leading: CircleAvatar(child: Text(c.name[0])),
                        title: Text(c.name),
                        subtitle: Text('${c.phone} ${c.wechat}'),
                        onTap: () => _showEditDialog(customer: c),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            StorageService.deleteCustomer(c.id);
                            _loadData();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============== 笔记页面 ==============

class NoteScreen extends StatefulWidget {
  const NoteScreen({super.key});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  List<NoteItem> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() => _notes = StorageService.getNotes());
  }

  void _showEditDialog({NoteItem? note}) {
    final isEdit = note != null;
    final titleCtrl = TextEditingController(text: note?.title ?? '');
    final contentCtrl = TextEditingController(text: note?.content ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? '编辑笔记' : '新建笔记'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '标题')),
            TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: '内容'), maxLines: 4),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final n = NoteItem(
                id: note?.id ?? 'note${DateTime.now().millisecondsSinceEpoch}',
                title: titleCtrl.text,
                content: contentCtrl.text,
              );
              StorageService.saveNote(n);
              _loadData();
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('笔记')),
      body: _notes.isEmpty
          ? const Center(child: Text('暂无笔记'))
          : ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (ctx, i) {
                final n = _notes[i];
                return ListTile(
                  title: Text(n.title),
                  subtitle: Text(n.content.length > 50 ? '${n.content.substring(0, 50)}...' : n.content),
                  onTap: () => _showEditDialog(note: n),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () { StorageService.deleteNote(n.id); _loadData(); },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============== 通话记录页面 ==============

class CallRecordScreen extends StatefulWidget {
  const CallRecordScreen({super.key});

  @override
  State<CallRecordScreen> createState() => _CallRecordScreenState();
}

class _CallRecordScreenState extends State<CallRecordScreen> {
  List<CallRecordItem> _records = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() => _records = StorageService.getCallRecords());
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通话记录')),
      body: _records.isEmpty
          ? const Center(child: Text('暂无通话记录'))
          : ListView.builder(
              itemCount: _records.length,
              itemBuilder: (ctx, i) {
                final r = _records[i];
                final icon = r.callType == 'incoming' ? Icons.call_received :
                            r.callType == 'outgoing' ? Icons.call_made : Icons.call_missed;
                final color = r.callType == 'missed' ? Colors.red : Colors.green;
                return ListTile(
                  leading: Icon(icon, color: color),
                  title: Text(r.customerName),
                  subtitle: Text('${r.phone} • ${_formatDuration(r.duration)}'),
                  trailing: Text('${r.callTime.month}/${r.callTime.day}', style: TextStyle(color: Colors.grey[600])),
                );
              },
            ),
    );
  }
}

// ============== 设置页面 ==============

class SettingsScreen extends StatelessWidget {
  final bool floatingEnabled;
  final ValueChanged<bool> onFloatingToggle;

  const SettingsScreen({super.key, required this.floatingEnabled, required this.onFloatingToggle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('悬浮窗'),
            subtitle: const Text('开启后可在其他应用上方显示快捷回复'),
            value: floatingEnabled,
            onChanged: onFloatingToggle,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('备份数据'),
            subtitle: const Text('导出所有数据到剪贴板'),
            onTap: () {
              final data = StorageService.exportAll();
              Clipboard.setData(ClipboardData(text: data));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数据已复制到剪贴板')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('恢复数据'),
            subtitle: const Text('从剪贴板导入数据'),
            onTap: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data?.text != null) {
                try {
                  StorageService.importAll(data!.text!);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数据已恢复')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数据格式错误')));
                }
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于'),
            subtitle: const Text('快回复 Pro v3.6'),
          ),
        ],
      ),
    );
  }
}


// ============== 悬浮窗 Widget ==============

class _OverlayQuickReply extends StatefulWidget {
  const _OverlayQuickReply();

  @override
  State<_OverlayQuickReply> createState() => _OverlayQuickReplyState();
}

class _OverlayQuickReplyState extends State<_OverlayQuickReply> {
  List<Category> _categories = [];
  List<ReplyTemplate> _templates = [];
  String _searchQuery = '';
  bool _showCategories = true;
  String? _selectedCategoryId;
  Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data != null) _loadData();
    });
  }

  void _loadData() {
    final cats = StorageService.getCategories();
    final temps = StorageService.getTemplates();
    setState(() {
      _categories = cats;
      _templates = temps;
    });
  }

  List<Category> get _topCategories => _categories.where((c) => c.parentId.isEmpty).toList();

  List<Category> _subCategories(String parentId) => _categories.where((c) => c.parentId == parentId).toList();

  List<ReplyTemplate> _templatesInCategory(String catId) {
    final subIds = _subCategories(catId).map((c) => c.id).toSet()..add(catId);
    return _templates.where((t) => subIds.contains(t.categoryId)).toList();
  }

  List<ReplyTemplate> get _allFiltered {
    if (_searchQuery.isEmpty) return [];
    final q = _searchQuery.toLowerCase();
    return _templates.where((t) =>
      t.title.toLowerCase().contains(q) || t.content.toLowerCase().contains(q)
    ).take(30).toList();
  }

  void _selectCategory(String catId) {
    setState(() {
      _selectedCategoryId = catId;
      _showCategories = false;
    });
  }

  void _backToCategories() {
    setState(() {
      _showCategories = true;
      _selectedCategoryId = null;
    });
  }

  void _copyAndClose(String content) {
    Clipboard.setData(ClipboardData(text: content));
    FlutterOverlayWindow.shareData('copied:$content');
    FlutterOverlayWindow.closeOverlay();
  }

  IconData _iconData(String name) {
    const icons = {
      'folder': Icons.folder, 'chat': Icons.chat, 'star': Icons.star,
      'favorite': Icons.favorite, 'lightbulb': Icons.lightbulb,
      'campaign': Icons.campaign, 'shopping_cart': Icons.shopping_cart,
      'local_offer': Icons.local_offer, 'phone': Icons.phone,
      'email': Icons.email, 'person': Icons.person, 'group': Icons.group,
    };
    return icons[name] ?? Icons.folder;
  }

  Color _hexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: Column(
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  if (!_showCategories)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: _backToCategories,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  Expanded(
                    child: Text(
                      _showCategories ? '选择话术' : (_categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => Category(id: '', name: '话术', color: '#4CAF50')).name),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => FlutterOverlayWindow.closeOverlay(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            // 搜索框
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '搜索话术...',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            // 内容区
            Expanded(
              child: _searchQuery.isNotEmpty
                  ? _buildSearchResults()
                  : (_showCategories ? _buildCategoryList() : _buildTemplateList()),
            ),
            // 快捷短语
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final phrase in ['在的', '您好', '好的', '收到', '谢谢'])
                    GestureDetector(
                      onTap: () => _copyAndClose(phrase),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(phrase, style: const TextStyle(fontSize: 13, color: Colors.green)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    final tops = _topCategories;
    if (tops.isEmpty) {
      return const Center(child: Text('暂无分类', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: tops.length,
      itemBuilder: (context, index) {
        final cat = tops[index];
        final subs = _subCategories(cat.id);
        final count = _templatesInCategory(cat.id).length;
        final isExpanded = _expandedCategories.contains(cat.id);

        return Column(
          children: [
            InkWell(
              onTap: () => _selectCategory(cat.id),
              onLongPress: () {
                setState(() {
                  if (isExpanded) {
                    _expandedCategories.remove(cat.id);
                  } else {
                    _expandedCategories.add(cat.id);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(_iconData(cat.icon), color: _hexColor(cat.color), size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(cat.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                    Text('($count)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    if (subs.isNotEmpty)
                      Icon(isExpanded ? Icons.expand_less : Icons.chevron_right, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),
            if (isExpanded && subs.isNotEmpty)
              ...subs.map((sub) {
                final subCount = _templatesInCategory(sub.id).length;
                return InkWell(
                  onTap: () => _selectCategory(sub.id),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 36, top: 8, bottom: 8, right: 12),
                    child: Row(
                      children: [
                        Icon(_iconData(sub.icon), color: _hexColor(sub.color), size: 16),
                        const SizedBox(width: 6),
                        Expanded(child: Text(sub.name, style: const TextStyle(fontSize: 13))),
                        Text('($subCount)', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildTemplateList() {
    final templates = _selectedCategoryId != null ? _templatesInCategory(_selectedCategoryId!) : [];
    if (templates.isEmpty) {
      return const Center(child: Text('该分类暂无话术', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final t = templates[index];
        final borderColor = t.titleColor.isNotEmpty ? _hexColor(t.titleColor) : Colors.green;
        return InkWell(
          onTap: () => _copyAndClose(t.content),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border(left: BorderSide(color: borderColor, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(t.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                    if (t.useCount > 0)
                      Text('${t.useCount}次', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  t.content.length > 50 ? '${t.content.substring(0, 50)}...' : t.content,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    final results = _allFiltered;
    if (results.isEmpty) {
      return Center(child: Text('未找到"$_searchQuery"', style: const TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final t = results[index];
        final cat = _categories.firstWhere((c) => c.id == t.categoryId, orElse: () => Category(id: '', name: '未分类', color: '#9E9E9E'));
        final borderColor = t.titleColor.isNotEmpty ? _hexColor(t.titleColor) : Colors.green;
        return InkWell(
          onTap: () => _copyAndClose(t.content),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border(left: BorderSide(color: borderColor, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: _hexColor(cat.color).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(cat.name, style: TextStyle(fontSize: 10, color: _hexColor(cat.color))),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(t.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  t.content.length > 60 ? '${t.content.substring(0, 60)}...' : t.content,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
