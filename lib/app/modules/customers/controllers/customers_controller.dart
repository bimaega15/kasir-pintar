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
  }

  void prepareEdit(CustomerModel c) {
    editingCustomer = c;
    nameController.text = c.name;
    phoneController.text = c.phone;
    addressController.text = c.address;
    notesController.text = c.notes;
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
    if (editingCustomer == null) {
      final c = CustomerModel(
        name: name,
        phone: phoneController.text.trim(),
        address: addressController.text.trim(),
        notes: notesController.text.trim(),
      );
      await _repo.save(c);
    } else {
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
