import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/customer_provider.dart';
import '../models/customer.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Customer> _filterCustomers(List<Customer> customers) {
    var filtered = customers;

    // 分类筛选
    if (_selectedCategory != null && _selectedCategory != '全部') {
      filtered = filtered.where((c) => c.category == _selectedCategory).toList();
    }

    return filtered;
  }

  List<String> _getCategories(List<Customer> customers) {
    final cats = <String>{'全部'};
    for (var c in customers) {
      cats.add(c.category.isEmpty ? '未分类' : c.category);
    }
    return cats.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 搜索栏
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索客户姓名、公司、电话...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<CustomerProvider>().search('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onChanged: (value) {
                context.read<CustomerProvider>().search(value);
              },
            ),
          ),

          // 客户列表
          Expanded(
            child: Consumer<CustomerProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allCustomers = provider.customers;
                final categories = _getCategories(allCustomers);
                final filteredCustomers = _filterCustomers(allCustomers);

                if (allCustomers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          '暂无客户',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '点击右下角➕添加客户',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // 分类筛选栏
                    if (categories.length > 1)
                      Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final isSelected = _selectedCategory == cat ||
                                (_selectedCategory == null && cat == '全部');
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = selected ? cat : null;
                                  });
                                },
                                selectedColor: Colors.blue.shade100,
                                checkmarkColor: Colors.blue,
                              ),
                            );
                          },
                        ),
                      ),

                    // 客户列表
                    Expanded(
                      child: filteredCustomers.isEmpty
                          ? Center(
                              child: Text(
                                '该分类暂无客户',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: filteredCustomers.length,
                              itemBuilder: (context, index) {
                                final customer = filteredCustomers[index];
                                return _buildCustomerCard(context, customer, provider);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CustomerDetailScreen(),
            ),
          );
          if (mounted) {
            context.read<CustomerProvider>().loadCustomers();
          }
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, Customer customer, CustomerProvider provider) {
    final dateFormatter = DateFormat('yyyy-MM-dd');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: customer.isPinned ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: customer.isPinned
            ? const BorderSide(color: Colors.orange, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerDetailScreen(customer: customer),
            ),
          );
          if (mounted) {
            provider.loadCustomers();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：姓名 + 公司 + 置顶图标
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getAvatarColor(customer),
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0] : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              customer.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (customer.isPinned) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.push_pin, size: 16, color: Colors.orange),
                            ],
                          ],
                        ),
                        if (customer.company.isNotEmpty)
                          Text(
                            customer.company,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // 分类标签
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      customer.category.isEmpty ? '未分类' : customer.category,
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 详细信息
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (customer.phone != null && customer.phone!.isNotEmpty)
                    _buildInfoChip(Icons.phone, customer.phone!),
                  if (customer.researchGroup != null && customer.researchGroup!.isNotEmpty)
                    _buildInfoChip(Icons.group, customer.researchGroup!),
                  if (customer.product != null && customer.product!.isNotEmpty)
                    _buildInfoChip(Icons.shopping_bag, customer.product!),
                ],
              ),

              if (customer.followResult != null && customer.followResult!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    customer.followResult!,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // 底部：跟进日期 + 操作按钮
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    dateFormatter.format(customer.followDate),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const Spacer(),
                  // 编辑按钮
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerDetailScreen(customer: customer),
                        ),
                      );
                      if (mounted) {
                        provider.loadCustomers();
                      }
                    },
                    tooltip: '编辑',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  // 删除按钮
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => _confirmDelete(context, customer, provider),
                    tooltip: '删除',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  // 置顶按钮
                  IconButton(
                    icon: Icon(
                      customer.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 20,
                      color: customer.isPinned ? Colors.orange : Colors.grey,
                    ),
                    onPressed: () => _togglePin(customer, provider),
                    tooltip: customer.isPinned ? '取消置顶' : '置顶',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey.shade700)),
      ],
    );
  }

  Color _getAvatarColor(Customer customer) {
    final colors = [
      Colors.blue, Colors.green, Colors.orange, Colors.purple,
      Colors.teal, Colors.pink, Colors.indigo, Colors.cyan,
    ];
    final index = customer.name.isNotEmpty
        ? customer.name.codeUnitAt(0) % colors.length
        : 0;
    return colors[index];
  }

  void _togglePin(Customer customer, CustomerProvider provider) async {
    final updated = customer.copyWith(
      isPinned: !customer.isPinned,
      updatedAt: DateTime.now(),
    );
    await provider.updateCustomer(updated);
  }

  void _confirmDelete(BuildContext context, Customer customer, CustomerProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除客户"${customer.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteCustomer(customer.id!);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
