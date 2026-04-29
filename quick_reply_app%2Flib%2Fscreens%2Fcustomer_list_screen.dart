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

    // 鍒嗙被绛涢€?    if (_selectedCategory != null && _selectedCategory != '鍏ㄩ儴') {
      filtered = filtered.where((c) => c.category == _selectedCategory).toList();
    }

    return filtered;
  }

  List<String> _getCategories(List<Customer> customers) {
    final cats = <String>{'鍏ㄩ儴'};
    for (var c in customers) {
      cats.add(c.category.isEmpty ? '鏈垎绫? : c.category);
    }
    return cats.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 鎼滅储鏍?          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '鎼滅储瀹㈡埛濮撳悕銆佸叕鍙搞€佺數璇?..',
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

          // 瀹㈡埛鍒楄〃
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
                          '鏆傛棤瀹㈡埛',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '鐐瑰嚮鍙充笅瑙掆灂娣诲姞瀹㈡埛',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // 鍒嗙被绛涢€夋爮
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
                                (_selectedCategory == null && cat == '鍏ㄩ儴');
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

                    // 瀹㈡埛鍒楄〃
                    Expanded(
                      child: filteredCustomers.isEmpty
                          ? Center(
                              child: Text(
                                '璇ュ垎绫绘殏鏃犲鎴?,
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
              // 澶撮儴锛氬鍚?+ 鍏徃 + 缃《鍥炬爣
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
                  // 鍒嗙被鏍囩
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      customer.category.isEmpty ? '鏈垎绫? : customer.category,
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 璇︾粏淇℃伅
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

              // 搴曢儴锛氳窡杩涙棩鏈?+ 鎿嶄綔鎸夐挳
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    dateFormatter.format(customer.followDate),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const Spacer(),
                  // 缂栬緫鎸夐挳
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
                    tooltip: '缂栬緫',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  // 鍒犻櫎鎸夐挳
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => _confirmDelete(context, customer, provider),
                    tooltip: '鍒犻櫎',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  // 缃《鎸夐挳
                  IconButton(
                    icon: Icon(
                      customer.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 20,
                      color: customer.isPinned ? Colors.orange : Colors.grey,
                    ),
                    onPressed: () => _togglePin(customer, provider),
                    tooltip: customer.isPinned ? '鍙栨秷缃《' : '缃《',
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
        title: const Text('纭鍒犻櫎'),
        content: Text('纭畾瑕佸垹闄ゅ鎴?${customer.name}"鍚楋紵'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('鍙栨秷'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteCustomer(customer.id!);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('鍒犻櫎'),
          ),
        ],
      ),
    );
  }
}
