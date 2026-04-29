import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../services/database_service.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer? customer;

  const CustomerDetailScreen({super.key, this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _followDate;
  late TextEditingController _companyController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _researchGroupController;
  late TextEditingController _productController;
  late TextEditingController _followResultController;
  String _category = '鏈垎绫?;
  String _categoryColor = '#9CA3AF';
  late bool _isPinned;
  
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _followDate = c?.followDate ?? DateTime.now();
    _companyController = TextEditingController(text: c?.company ?? '');
    _nameController = TextEditingController(text: c?.name ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _researchGroupController = TextEditingController(text: c?.researchGroup ?? '');
    _productController = TextEditingController(text: c?.product ?? '');
    _followResultController = TextEditingController(text: c?.followResult ?? '');
    _category = c?.category ?? '鏈垎绫?;
    _isPinned = c?.isPinned ?? false;
    _loadCategories();
  }
  
  Future<void> _loadCategories() async {
    final cats = await DatabaseService().getCustomerCategories();
    setState(() {
      _categories = cats;
      _isLoadingCategories = false;
      // 鎵惧埌褰撳墠鍒嗙被鐨勯鑹?      final currentCat = cats.firstWhere(
        (c) => c['name'] == _category,
        orElse: () => {'color': '#9CA3AF'},
      );
      _categoryColor = currentCat['color'] ?? '#9CA3AF';
    });
  }

  @override
  void dispose() {
    _companyController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _researchGroupController.dispose();
    _productController.dispose();
    _followResultController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _followDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) {
      setState(() => _followDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final customer = Customer(
      id: widget.customer?.id,
      followDate: _followDate,
      company: _companyController.text.trim(),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      researchGroup: _researchGroupController.text.trim().isEmpty ? null : _researchGroupController.text.trim(),
      product: _productController.text.trim().isEmpty ? null : _productController.text.trim(),
      followResult: _followResultController.text.trim().isEmpty ? null : _followResultController.text.trim(),
      category: _category,
      isPinned: _isPinned,
      createdAt: widget.customer?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final provider = context.read<CustomerProvider>();
      if (widget.customer == null) {
        await provider.addCustomer(customer);
      } else {
        await provider.updateCustomer(customer);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('淇濆瓨澶辫触: $e')),
        );
      }
    }
  }

  Future<void> _delete() async {
    if (widget.customer == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('纭鍒犻櫎'),
        content: Text('纭畾瑕佸垹闄ゅ鎴?"${widget.customer!.name}" 鍚楋紵'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('鍙栨秷')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('鍒犻櫎'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<CustomerProvider>().deleteCustomer(widget.customer!.id!);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('鍒犻櫎澶辫触: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '缂栬緫瀹㈡埛' : '鏂板缓瀹㈡埛'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _delete,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 璺熻繘鏃ユ湡
            ListTile(
              title: const Text('璺熻繘鏃ユ湡'),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_followDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
            ),
            const Divider(),

            // 鍏徃锛堝鏍★級- 蹇呭～
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: '鍏徃锛堝鏍★級',
                prefixIcon: Icon(Icons.business),
                hintText: '渚嬪锛氬寳浜ぇ瀛?,
              ),
              validator: (v) => v?.trim().isEmpty == true ? '璇疯緭鍏ュ叕鍙告垨瀛︽牎' : null,
            ),
            const SizedBox(height: 16),

            // 濮撳悕 - 蹇呭～
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '濮撳悕',
                prefixIcon: Icon(Icons.person),
                hintText: '渚嬪锛氬紶涓?,
              ),
              validator: (v) => v?.trim().isEmpty == true ? '璇疯緭鍏ュ鍚? : null,
            ),
            const SizedBox(height: 16),

            // 鐢佃瘽
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '鐢佃瘽',
                prefixIcon: Icon(Icons.phone),
                hintText: '渚嬪锛?3800138000',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // 璇鹃缁?            TextFormField(
              controller: _researchGroupController,
              decoration: const InputDecoration(
                labelText: '璇鹃缁?,
                prefixIcon: Icon(Icons.group),
                hintText: '渚嬪锛氫汉宸ユ櫤鑳藉疄楠屽',
              ),
            ),
            const SizedBox(height: 16),

            // 鍜ㄨ浜у搧
            TextFormField(
              controller: _productController,
              decoration: const InputDecoration(
                labelText: '鍜ㄨ浜у搧',
                prefixIcon: Icon(Icons.shopping_bag),
                hintText: '渚嬪锛欰I璇剧▼銆佹暟鎹垎鏋愭湇鍔?,
              ),
            ),
            const SizedBox(height: 16),

            // 璺熻繘缁撴灉
            TextFormField(
              controller: _followResultController,
              decoration: const InputDecoration(
                labelText: '璺熻繘缁撴灉',
                prefixIcon: Icon(Icons.note),
                hintText: '渚嬪锛氬凡鎶ヤ环锛屽緟纭',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // 鍒嗙被閫夋嫨
            ListTile(
              title: const Text('鍒嗙被'),
              subtitle: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _parseColor(_categoryColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(_category),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showCategorySelector,
            ),
            const Divider(),

            // 缃《寮€鍏?            SwitchListTile(
              title: const Text('缃《姝ゅ鎴?),
              subtitle: const Text('缃《鍚庡皢鍦ㄥ垪琛ㄩ《閮ㄦ樉绀?),
              secondary: Icon(
                _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: _isPinned ? Colors.orange : null,
              ),
              value: _isPinned,
              onChanged: (v) => setState(() => _isPinned = v),
            ),
            const SizedBox(height: 32),

            // 淇濆瓨鎸夐挳
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(isEditing ? '淇濆瓨淇敼' : '娣诲姞瀹㈡埛'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _parseColor(String colorHex) {
    try {
      return Color(
        int.parse(colorHex.replaceFirst('#', '0xFF')),
      );
    } catch (e) {
      return Colors.grey;
    }
  }
  
  void _showCategorySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 鏍囬鏍?              Row(
                children: [
                  const Text(
                    '閫夋嫨鍒嗙被',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('娣诲姞'),
                    onPressed: () => _showAddCategoryDialog(setModalState),
                  ),
                ],
              ),
              const Divider(),
              
              // 鍒嗙被鍒楄〃
              Expanded(
                child: _isLoadingCategories
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _categories.length,
                        itemBuilder: (ctx, index) {
                          final cat = _categories[index];
                          final isSelected = cat['name'] == _category;
                          return ListTile(
                            leading: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _parseColor(cat['color']),
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(
                              cat['name'],
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: Colors.blue)
                                : null,
                            onTap: () {
                              setState(() {
                                _category = cat['name'];
                                _categoryColor = cat['color'];
                              });
                              Navigator.pop(ctx);
                            },
                            onLongPress: () => _showEditCategoryDialog(cat, setModalState),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showAddCategoryDialog(StateSetter setModalState) {
    final nameController = TextEditingController();
    String selectedColor = '#10B981';
    final colors = ['#10B981', '#F59E0B', '#EF4444', '#8B5CF6', '#2563EB', '#EC4899', '#14B8A6', '#6366F1'];
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, dialogSetState) => AlertDialog(
          title: const Text('娣诲姞鍒嗙被'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '鍒嗙被鍚嶇О',
                  hintText: '渚嬪锛氭剰鍚戝鎴?,
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text('閫夋嫨棰滆壊锛?),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: colors.map((color) =>
                  GestureDetector(
                    onTap: () => dialogSetState(() => selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _parseColor(color),
                        shape: BoxShape.circle,
                        border: selectedColor == color
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                      ),
                      child: selectedColor == color
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
                ).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('鍙栨秷'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                
                await DatabaseService().insertCustomerCategory({
                  'name': name,
                  'color': selectedColor,
                  'sort': _categories.length,
                });
                
                final cats = await DatabaseService().getCustomerCategories();
                setState(() => _categories = cats);
                setModalState(() {});
                Navigator.pop(ctx);
              },
              child: const Text('娣诲姞'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEditCategoryDialog(Map<String, dynamic> cat, StateSetter setModalState) {
    final nameController = TextEditingController(text: cat['name']);
    String selectedColor = cat['color'];
    final colors = ['#10B981', '#F59E0B', '#EF4444', '#8B5CF6', '#2563EB', '#EC4899', '#14B8A6', '#6366F1'];
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, dialogSetState) => AlertDialog(
          title: const Text('缂栬緫鍒嗙被'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '鍒嗙被鍚嶇О'),
              ),
              const SizedBox(height: 16),
              const Text('閫夋嫨棰滆壊锛?),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: colors.map((color) =>
                  GestureDetector(
                    onTap: () => dialogSetState(() => selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _parseColor(color),
                        shape: BoxShape.circle,
                        border: selectedColor == color
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                      ),
                      child: selectedColor == color
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
                ).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('鍙栨秷'),
            ),
            TextButton(
              onPressed: () async {
                await DatabaseService().deleteCustomerCategory(cat['id']);
                final cats = await DatabaseService().getCustomerCategories();
                setState(() => _categories = cats);
                setModalState(() {});
                Navigator.pop(ctx);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('鍒犻櫎'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                
                await DatabaseService().updateCustomerCategory(cat['id'], {
                  'name': name,
                  'color': selectedColor,
                });
                
                final cats = await DatabaseService().getCustomerCategories();
                setState(() => _categories = cats);
                setModalState(() {});
                Navigator.pop(ctx);
              },
              child: const Text('淇濆瓨'),
            ),
          ],
        ),
      ),
    );
  }
}
