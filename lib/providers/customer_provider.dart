import 'package:flutter/material.dart';
import '../customers/customer_model.dart';
import '../data/mock_data.dart';

class CustomerProvider with ChangeNotifier {
  final List<Customer> _customers = [];

  CustomerProvider() {
    _initializeCustomers();
  }

  void _initializeCustomers() {
    _customers.addAll(sharedMockCustomers);
  }

  List<Customer> get customers => _customers;

  void addCustomer(Customer customer) {
    _customers.add(customer);
    notifyListeners();
  }
  
  Customer? getCustomerById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  void updateCustomer(Customer updatedCustomer) {
    final index = _customers.indexWhere((c) => c.id == updatedCustomer.id);
    if (index != -1) {
      _customers[index] = updatedCustomer;
      notifyListeners();
    }
  }

  void deleteCustomer(String id) {
    _customers.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
