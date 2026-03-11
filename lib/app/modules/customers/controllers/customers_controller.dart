import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/customer_repository.dart';

class CustomersController extends GetxController {
  final _repo = Get.find<CustomerRepository>();

  final customers = <CustomerModel>[].obs;
  final searchQuery = ''.obs;
  final isLoading = false.obs;

  // Add/Edit form
  CustomerModel? editingCustomer;
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final notesController = TextEditingController();

  // Autocomplete for name field
  final searchNameQuery = ''.obs;
  final suggestedCustomers = <CustomerModel>[].obs;
  final selectedCustomer = Rx<CustomerModel?>(null);

  @override
  void onInit() {
    super.onInit();
    loadCustomers();
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    notesController.dispose();
    super.onClose();
  }

  Future<void> loadCustomers() async {
    isLoading.value = true;
    customers.value = await _repo.getAll();
    isLoading.value = false;
  }

  List<CustomerModel> get filteredCustomers {
    if (searchQuery.isEmpty) return customers;
    final q = searchQuery.value.toLowerCase();
    return customers
        .where((c) =>
            c.name.toLowerCase().contains(q) || c.phone.contains(q))
        .toList();
  }

  void prepareAdd() {
    editingCustomer = null;
    nameController.clear();
    phoneController.clear();
    addressController.clear();
    notesController.clear();
    searchNameQuery.value = '';
    selectedCustomer.value = null;
  }

  void prepareEdit(CustomerModel c) {
    editingCustomer = c;
    nameController.text = c.name;
    phoneController.text = c.phone;
    addressController.text = c.address;
    notesController.text = c.notes;
    searchNameQuery.value = c.name;
    selectedCustomer.value = c;
  }

  // Search customers by name for autocomplete
  void searchCustomersByName(String query) {
    searchNameQuery.value = query;
    if (query.isEmpty) {
      suggestedCustomers.clear();
      selectedCustomer.value = null;
      return;
    }

    final q = query.toLowerCase();
    final filtered = customers
        .where((c) => c.name.toLowerCase().contains(q))
        .take(5)
        .toList();
    suggestedCustomers.value = filtered;
  }

  // Select customer from suggestions
  void selectCustomerFromSuggestion(CustomerModel customer) {
    selectedCustomer.value = customer;
    nameController.text = customer.name;
    phoneController.text = customer.phone;
    addressController.text = customer.address;
    notesController.text = customer.notes;
    searchNameQuery.value = customer.name;
    suggestedCustomers.clear();
  }

  // Create new customer from autocomplete
  void createNewCustomerFromSearch(String name) {
    selectedCustomer.value = null;
    nameController.text = name;
    phoneController.clear();
    addressController.clear();
    notesController.clear();
    suggestedCustomers.clear();
  }

  Future<bool> saveCustomer() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar(
        'Gagal',
        'Nama pelanggan wajib diisi',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    // Check for duplicate name
    if (editingCustomer == null) {
      // Creating new customer - check if name exists
      final nameExists =
          customers.any((c) => c.name.toLowerCase() == name.toLowerCase());
      if (nameExists) {
        Get.snackbar(
          'Gagal',
          'Nama pelanggan "$name" sudah terdaftar',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }

      final c = CustomerModel(
        name: name,
        phone: phoneController.text.trim(),
        address: addressController.text.trim(),
        notes: notesController.text.trim(),
      );
      await _repo.save(c);
    } else {
      // Editing existing customer - check if name is used by another customer
      final isDuplicate = customers.any((c) =>
          c.id != editingCustomer!.id &&
          c.name.toLowerCase() == name.toLowerCase());
      if (isDuplicate) {
        Get.snackbar(
          'Gagal',
          'Nama pelanggan "$name" sudah terdaftar',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }

      editingCustomer!
        ..name = name
        ..phone = phoneController.text.trim()
        ..address = addressController.text.trim()
        ..notes = notesController.text.trim();
      await _repo.update(editingCustomer!);
    }
    await loadCustomers();
    return true;
  }

  Future<void> deleteCustomer(CustomerModel c) async {
    await _repo.delete(c.id);
    await loadCustomers();
  }

  Future<List<TransactionModel>> getTransactions(String customerId) =>
      _repo.getTransactions(customerId);
}
