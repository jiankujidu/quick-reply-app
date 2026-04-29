import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../services/database_service.dart';

class CustomerProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Customer> _customers = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Customer> get customers {
    if (_searchQuery.isEmpty) return _customers;
    return _customers.where((c) => 
      c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      c.company.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (c.phone?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
      (c.researchGroup?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
      (c.product?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
      (c.followResult?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  bool get isLoading => _isLoading;

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _customers = await _db.getCustomers();
    } catch (e) {
      debugPrint('鍔犺浇瀹㈡埛澶辫触: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCustomer(Customer customer) async {
    try {
      await _db.insertCustomer(customer);
      await loadCustomers();
    } catch (e) {
      debugPrint('娣诲姞瀹㈡埛澶辫触: $e');
      rethrow;
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      await _db.updateCustomer(customer);
      await loadCustomers();
    } catch (e) {
      debugPrint('鏇存柊瀹㈡埛澶辫触: $e');
      rethrow;
    }
  }

  Future<void> deleteCustomer(int id) async {
    try {
      await _db.deleteCustomer(id);
      await loadCustomers();
    } catch (e) {
      debugPrint('鍒犻櫎瀹㈡埛澶辫触: $e');
      rethrow;
    }
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<String> exportToExcel() async {
    return await _db.exportCustomersToExcel();
  }
}
